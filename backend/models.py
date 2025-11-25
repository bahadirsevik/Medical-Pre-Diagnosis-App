from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, Float, DateTime, JSON
from sqlalchemy.orm import relationship
from database import Base
import datetime

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    
    # Profile Info
    age = Column(Integer, nullable=True)
    gender = Column(String, nullable=True)
    chronic_conditions = Column(String, nullable=True) # Stored as comma-separated string or JSON

    diagnoses = relationship("Diagnosis", back_populates="owner")

class Diagnosis(Base):
    __tablename__ = "diagnoses"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    
    symptoms = Column(String) # User input text
    predicted_disease = Column(String)
    probability = Column(Float)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    
    # Store full result as JSON for details
    full_result = Column(JSON)

    owner = relationship("User", back_populates="diagnoses")
