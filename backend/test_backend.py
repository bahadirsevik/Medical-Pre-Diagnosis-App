from fastapi.testclient import TestClient
from main import app
import os

# Ensure API Key is loaded (it should be from .env, but we check here)
# os.environ["OPENAI_API_KEY"] = ... (loaded by dotenv in main)

client = TestClient(app)

def test_read_root():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"status": "online", "message": "Medical AI API is running."}

def test_diagnosis_flow():
    # Test with a simple symptom description
    payload = {"text": "I have a severe headache and nausea."}
    
    print(f"\nTesting with payload: {payload}")
    response = client.post("/diagnosis", json=payload)
    
    print(f"Status Code: {response.status_code}")
    print(f"Response: {response.json()}")
    
    assert response.status_code == 200
    data = response.json()
    
    # Check structure
    assert "mapped_symptoms" in data
    assert "predictions" in data
    assert "max_probability" in data
    assert "alert_level" in data
    
    # Check logic (assuming LLM works)
    # We expect 'headache' and 'nausea' or similar to be mapped
    if data["mapped_symptoms"]:
        print("✅ Symptoms mapped successfully.")
    else:
        print("⚠️ No symptoms mapped (LLM might have failed or strict mapping issue).")

if __name__ == "__main__":
    test_read_root()
    test_diagnosis_flow()
    print("\n✅ All tests passed!")
