from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

from core.model import classifier
from core.llm import extract_symptoms, translate_diseases
from schemas import DiagnosisResponse, SymptomInput, DiseasePrediction

app = FastAPI(
    title="Medical Pre-Diagnosis API",
    description="AI-powered backend for symptom analysis and disease prediction.",
    version="1.0.0"
)

# CORS (Allow all for now, restrict in production)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    return {"status": "online", "message": "Medical AI API is running."}

@app.post("/diagnosis", response_model=DiagnosisResponse)
async def diagnose(input_data: SymptomInput):
    """
    Full pipeline: User Text -> LLM Extraction -> ML Prediction -> Result
    """
    user_text = input_data.text
    print(f"📩 Received input: {user_text}")

    # 1. Extract Symptoms using LLM
    # We pass the valid symptom names from our classifier to the LLM
    valid_symptoms = classifier.symptom_names
    mapped_symptoms = extract_symptoms(user_text, valid_symptoms)
    
    print(f"🧬 Mapped Symptoms: {mapped_symptoms}")

    if not mapped_symptoms:
        return DiagnosisResponse(
            mapped_symptoms=[],
            predictions=[],
            max_probability=0.0,
            alert_level="Unknown"
        )

    # 2. Predict Disease using ML Model
    predictions, max_prob = classifier.predict(mapped_symptoms)

    # 3. Translate Disease Names to Turkish
    disease_names = [p['disease'] for p in predictions]
    translated_names = translate_diseases(disease_names)
    
    # Update predictions with translated names
    for i, p in enumerate(predictions):
        p['disease'] = translated_names[i]

    # 4. Determine Alert Level
    alert_level = "Low"
    if max_prob > 50:
        alert_level = "Medium"
    if max_prob > 80:
        alert_level = "High"

    return DiagnosisResponse(
        mapped_symptoms=mapped_symptoms,
        predictions=[DiseasePrediction(**p) for p in predictions],
        max_probability=max_prob,
        alert_level=alert_level
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
