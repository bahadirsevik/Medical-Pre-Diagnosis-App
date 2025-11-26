from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from typing import List
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

from core.model import classifier
from core.llm import extract_symptoms, translate_diseases, generate_advice


from core.security import verify_supabase_token
from database import engine, get_db, Base
import models
import schemas
from datetime import timedelta

# Create Tables
models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Medical Pre-Diagnosis API",
    description="AI-powered backend for symptom analysis and disease prediction.",
    version="1.0.0"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/token") # Keep for Swagger UI compatibility, though not used directly

# --- Auth Dependencies ---
async def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    # Verify token with Supabase
    try:
        supabase_user_response = verify_supabase_token(token)
        supabase_user = supabase_user_response.user
        
        if not supabase_user or not supabase_user.email:
            raise HTTPException(status_code=401, detail="Invalid token or missing email")
            
        email = supabase_user.email
        
        # Check if user exists in our DB (synced)
        user = db.query(models.User).filter(models.User.email == email).first()
        
        if not user:
            # Auto-create user in our DB if they exist in Supabase but not here
            print(f"🆕 Creating local user for {email}")
            # We use a dummy password since Supabase handles auth
            new_user = models.User(email=email, hashed_password="supabase_managed")
            db.add(new_user)
            db.commit()
            db.refresh(new_user)
            user = new_user
            
        return user
        
    except Exception as e:
        print(f"Auth Error: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )

# --- User Endpoints ---
@app.get("/users/me", response_model=schemas.User)
async def read_users_me(current_user: models.User = Depends(get_current_user)):
    return current_user

@app.put("/users/me", response_model=schemas.User)
def update_user_profile(profile: schemas.UserUpdate, current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    if profile.age is not None: current_user.age = profile.age
    if profile.gender is not None: current_user.gender = profile.gender
    if profile.chronic_conditions is not None: current_user.chronic_conditions = profile.chronic_conditions
    db.commit()
    db.refresh(current_user)
    return current_user

# --- Diagnosis Endpoint (Protected) ---
@app.post("/diagnosis", response_model=schemas.DiagnosisResponse)
async def diagnose(input_data: schemas.SymptomInput, current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    """
    Full pipeline: User Text -> LLM Extraction -> ML Prediction -> Result
    Saves result to history.
    """
    try:
        user_text = input_data.text
        print(f"📩 Received input from {current_user.email}: {user_text}")

        # 1. Extract Symptoms using LLM
        valid_symptoms = classifier.symptom_names
        mapped_symptoms = extract_symptoms(user_text, valid_symptoms)
        
        if not mapped_symptoms:
            return schemas.DiagnosisResponse(
                mapped_symptoms=[], predictions=[], max_probability=0.0, alert_level="Unknown"
            )

        # 2. Predict Disease using ML Model
        predictions, max_prob = classifier.predict(mapped_symptoms)

        # 3. Translate Disease Names to Turkish
        disease_names = [p['disease'] for p in predictions]
        translated_names = translate_diseases(disease_names)
        
        for i, p in enumerate(predictions):
            p['disease'] = translated_names[i]

        # 4. Determine Alert Level
        alert_level = "Low"
        if max_prob > 50: alert_level = "Medium"
        if max_prob > 80: alert_level = "High"

        # 5. Generate Advice (New Step)
        top_disease = predictions[0]['disease'] if predictions else "Unknown"
        print(f"🤔 Generating advice for: {top_disease}")
        advice_data = generate_advice(top_disease, user_text)
        print(f"💡 Advice Data: {advice_data}")
        
        # Ensure reasoning and advice are strings
        reasoning_val = advice_data.get("reasoning")
        if isinstance(reasoning_val, list):
            reasoning_val = " ".join(reasoning_val)
        elif reasoning_val is not None:
            reasoning_val = str(reasoning_val)
            
        advice_val = advice_data.get("advice")
        if isinstance(advice_val, list):
            advice_val = "\n".join(advice_val)
        elif advice_val is not None:
            advice_val = str(advice_val)

        # 6. Save to History
        print(f"💾 Saving diagnosis for user {current_user.id}: {top_disease}")
        
        # Add advice to full_result to persist it
        full_result_data = [p for p in predictions]
        full_result_data.append({"type": "advice", "data": advice_data})

        new_diagnosis = models.Diagnosis(
            user_id=current_user.id,
            symptoms=user_text,
            predicted_disease=top_disease,
            probability=max_prob,
            full_result=full_result_data 
        )
        db.add(new_diagnosis)
        db.commit()

        return schemas.DiagnosisResponse(
            mapped_symptoms=mapped_symptoms,
            predictions=[schemas.DiseasePrediction(**p) for p in predictions],
            max_probability=max_prob,
            alert_level=alert_level,
            reasoning=reasoning_val,
            advice=advice_val
        )
    except Exception as e:
        import traceback
        print(f"❌ CRITICAL ERROR in diagnose: {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/history", response_model=List[schemas.DiagnosisResponse])
def get_history(current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    diagnoses = db.query(models.Diagnosis).filter(models.Diagnosis.user_id == current_user.id).order_by(models.Diagnosis.created_at.desc()).all()
    print(f"📜 Fetching history for user {current_user.id}. Found {len(diagnoses)} records.")
    
    history_response = []
    for d in diagnoses:
        # Determine alert level based on probability
        alert_level = "Low"
        if d.probability > 50: alert_level = "Medium"
        if d.probability > 80: alert_level = "High"
        
        # Parse full_result (list of dicts)
        predictions = []
        reasoning = None
        advice = None
        
        if d.full_result:
            for item in d.full_result:
                # Check if it's an advice item
                if isinstance(item, dict) and item.get("type") == "advice":
                    advice_data = item.get("data", {})
                    
                    # Safely extract and convert reasoning
                    r_val = advice_data.get("reasoning")
                    if isinstance(r_val, list):
                        reasoning = " ".join(r_val)
                    elif r_val is not None:
                        reasoning = str(r_val)
                        
                    # Safely extract and convert advice
                    a_val = advice_data.get("advice")
                    if isinstance(a_val, list):
                        advice = "\n".join(a_val)
                    elif a_val is not None:
                        advice = str(a_val)
                else:
                    # Assume it's a prediction
                    try:
                        predictions.append(schemas.DiseasePrediction(**item))
                    except:
                        pass # Skip invalid items
        
        history_response.append(schemas.DiagnosisResponse(
            mapped_symptoms=[], 
            predictions=predictions,
            max_probability=d.probability,
            alert_level=alert_level,
            reasoning=reasoning,
            advice=advice
        ))
    return history_response

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
