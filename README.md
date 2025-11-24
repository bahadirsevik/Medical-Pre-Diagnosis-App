# Medical AI Pre-Diagnosis App

A professional medical pre-diagnosis application using Flutter, FastAPI, and OpenAI.

## 🚀 Features
- **Voice Input**: Speak your symptoms naturally.
- **AI Analysis**: Uses OpenAI to extract symptoms from natural language.
- **Disease Prediction**: Uses a Machine Learning model (Random Forest/XGBoost) to predict diseases.
- **Voice Output**: Reads the diagnosis results aloud.
- **Professional UI**: Clean, medical-grade interface.

## 🛠️ Setup & Run

### 1. Backend (Python/FastAPI)
You need Python 3.10+ installed.

1. Navigate to the backend folder:
   ```powershell
   cd backend
   ```
2. Create a virtual environment (optional but recommended):
   ```powershell
   python -m venv venv
   .\venv\Scripts\activate
   ```
3. Install dependencies:
   ```powershell
   pip install -r requirements.txt
   ```
4. Run the server:
   ```powershell
   uvicorn main:app --host 0.0.0.0 --port 8000 --reload
   ```
   *The API will be available at `http://localhost:8000`.*

### 2. Mobile App (Flutter)
You need Flutter installed and an Android Emulator running.

1. Navigate to the mobile app folder:
   ```powershell
   cd mobile_app
   ```
2. Install dependencies:
   ```powershell
   flutter pub get
   ```
3. Run the app:
   ```powershell
   flutter run
   ```

## 🐳 Docker Setup (Optional)
If you have Docker installed, you can run the backend easily:

```powershell
docker-compose up --build
```

## 🔑 Configuration
Ensure you have your OpenAI API Key in `backend/.env`:
```
OPENAI_API_KEY=sk-proj-...
```
