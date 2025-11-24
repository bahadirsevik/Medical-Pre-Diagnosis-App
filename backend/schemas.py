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
