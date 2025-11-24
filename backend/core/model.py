import joblib
import numpy as np
import os
from typing import List, Dict, Tuple

# Paths
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS_DIR = os.path.join(BASE_DIR, "assets")
MODEL_PATH = os.path.join(ASSETS_DIR, "trained_model.joblib")
SYMPTOMS_PATH = os.path.join(ASSETS_DIR, "symptom_names.joblib")

class DiseaseClassifier:
    def __init__(self):
        self.model = None
        self.symptom_names = []
        self.load_model()

    def load_model(self):
        """Loads the pre-trained model and symptom names."""
        try:
            self.model = joblib.load(MODEL_PATH)
            self.symptom_names = joblib.load(SYMPTOMS_PATH)
            print("✅ Model and assets loaded successfully.")
        except Exception as e:
            print(f"❌ Error loading model: {e}")
            raise e

    def predict(self, selected_symptoms: List[str], top_k: int = 5) -> Tuple[List[Dict], float]:
        """
        Predicts diseases based on the list of selected symptoms.
        """
        if not self.model or not self.symptom_names:
            raise ValueError("Model not loaded.")

        # Create input vector
        symptom_vector = np.zeros(len(self.symptom_names))
        for symptom in selected_symptoms:
            if symptom in self.symptom_names:
                idx = self.symptom_names.index(symptom)
                symptom_vector[idx] = 1
        
        # Predict
        probabilities = self.model.predict_proba([symptom_vector])[0]
        disease_classes = self.model.classes_
        
        results = []
        for disease, prob in zip(disease_classes, probabilities):
            if prob > 0.0: # Filter out zero probabilities
                results.append({
                    'disease': disease,
                    'probability': float(prob * 100),
                    'probability_str': f"%{prob * 100:.1f}"
                })
        
        # Sort and get top K
        results = sorted(results, key=lambda x: x['probability'], reverse=True)[:top_k]
        max_prob = results[0]['probability'] if results else 0.0
        
        return results, max_prob

# Singleton instance
classifier = DiseaseClassifier()
