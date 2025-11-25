from pydantic import BaseModel
from typing import List, Optional

class SymptomInput(BaseModel):
    text: str

class Symptom(BaseModel):
    name: str

class DiseasePrediction(BaseModel):
    disease: str
    probability: float
    probability_str: str

class DiagnosisResponse(BaseModel):
    mapped_symptoms: List[str]
    predictions: List[DiseasePrediction]
    max_probability: float
    alert_level: str  # "Low", "Medium", "High"
    reasoning: Optional[str] = None
    advice: Optional[str] = None

# --- Auth Schemas ---
class UserBase(BaseModel):
    email: str

class UserCreate(UserBase):
    password: str

class UserLogin(UserBase):
    password: str

class UserUpdate(BaseModel):
    age: Optional[int] = None
    gender: Optional[str] = None
    chronic_conditions: Optional[str] = None

class User(UserBase):
    id: int
    age: Optional[int] = None
    gender: Optional[str] = None
    chronic_conditions: Optional[str] = None
    
    class Config:
        orm_mode = True

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: Optional[str] = None
