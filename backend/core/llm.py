import os
from openai import OpenAI
from typing import List
import json

# Initialize OpenAI Client
# Expects OPENAI_API_KEY in environment variables
client = OpenAI(api_key=os.environ.get("OPENAI_API_KEY"))

def extract_symptoms(user_text: str, valid_symptoms: List[str]) -> List[str]:
    """
    Uses OpenAI to map user text to the list of valid symptoms.
    """
    if not user_text:
        return []

    system_prompt = f"""
    You are a medical assistant AI. Your goal is to extract symptoms from the user's description and map them EXACTLY to the provided list of valid symptoms.
    
    RULES:
    1. Return a JSON object with a single key "symptoms" containing a list of strings.
    2. The strings in the list MUST be exact matches from the 'Valid Symptoms List' provided below.
    3. If a symptom described by the user is not in the list, try to find the closest semantic match.
    4. If no symptoms are found, return an empty list.
    5. Do not include any explanation, only the JSON.

    Valid Symptoms List:
    {", ".join(valid_symptoms)}
    """

    try:
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_text}
            ],
            response_format={"type": "json_object"},
            temperature=0.0
        )
        
        content = response.choices[0].message.content
        data = json.loads(content)
        return data.get("symptoms", [])
    except Exception as e:
        print(f"❌ Error in LLM symptom extraction: {e}")
        return []

def translate_diseases(diseases: List[str]) -> List[str]:
    """
    Translates a list of disease names from English to Turkish using OpenAI.
    """
    if not diseases:
        return []

    system_prompt = """
    You are a helpful medical translator for patients. 
    Translate the following list of disease names from English to Turkish.
    
    RULES:
    1. Return a JSON object with a single key "translations" containing a list of strings.
    2. The order of the list MUST match the input order exactly.
    3. USE COMMON, PATIENT-FRIENDLY TURKISH NAMES. Avoid heavy medical jargon if a common name exists.
       - Example: "Intracranial abscess" -> "Beyin Apsesi" (NOT "İntrakranyal apse")
       - Example: "Hypertension" -> "Yüksek Tansiyon"
       - Example: "Gastroenteritis" -> "Mide Üşütmesi / İshal"
    4. If there is no common name, use the Turkish medical term but keep it readable.
    5. Do not include any explanation, only the JSON.
    """

    try:
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": json.dumps(diseases)}
            ],
            response_format={"type": "json_object"},
            temperature=0.0
        )
        
        content = response.choices[0].message.content
        data = json.loads(content)
        return data.get("translations", diseases) # Fallback to original if key missing
    except Exception as e:
        print(f"❌ Error in LLM translation: {e}")
        return diseases # Fallback to original on error

def generate_advice(disease: str, symptoms: str) -> dict:
    system_prompt = """
    Sen uzman bir doktorsun. Hastanın semptomlarına ve olası teşhise göre kısa bir açıklama ve evde uygulanabilecek tavsiyeler ver.
    Yanıtın JSON formatında olmalı ve şu anahtarları içermeli:
    {
        "reasoning": "Neden bu teşhis konulduğuna dair 1-2 cümlelik açıklama.",
        "advice": "Evde yapılabilecek 3-4 maddelik basit tavsiyeler."
    }
    Yanıtın Türkçe olsun.
    """
    
    try:
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": f"Teşhis: {disease}\nSemptomlar: {symptoms}"}
            ],
            response_format={"type": "json_object"},
            temperature=0.7
        )
        
        content = response.choices[0].message.content
        return json.loads(content)
    except Exception as e:
        print(f"❌ Error in LLM advice generation: {e}")
        return {
            "reasoning": "Detaylı analiz oluşturulamadı.",
            "advice": "Lütfen bir sağlık kuruluşuna başvurun."
        }
