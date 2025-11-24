# train_model.py

import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split, GridSearchCV
from sklearn.naive_bayes import MultinomialNB
from imblearn.over_sampling import SMOTE
import joblib # Modeli kaydetmek için

print("1. Veri yükleniyor...")
df = pd.read_parquet('cleaned_data.parquet')
diseases = df.iloc[:, 0]
symptoms = df.iloc[:, 1:]
symptom_names = symptoms.columns.tolist()

print("2. Veri eğitim ve test olarak ayrılıyor...")
X = symptoms.values
y = diseases.values
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)

print("3. SMOTE ile eğitim verisi dengeleniyor (Bu işlem biraz sürebilir)...")
smote = SMOTE(random_state=42, k_neighbors=1)
X_train_resampled, y_train_resampled = smote.fit_resample(X_train, y_train)

print("4. Naive Bayes modeli en iyi hiperparametrelerle eğitiliyor...")
param_grid = {'alpha': np.linspace(0.01, 1.0, 20)}
nb_model = MultinomialNB()

grid_search = GridSearchCV(nb_model, param_grid, cv=3, verbose=1)
grid_search.fit(X_train_resampled, y_train_resampled)

best_model = grid_search.best_estimator_
print(f"En iyi alpha değeri bulundu: {grid_search.best_params_}")

# Modelin doğruluğunu hesapla
score = best_model.score(X_test, y_test)
print(f"Modelin test doğruluğu: %{score * 100:.1f}")


print("5. Eğitilmiş model ve semptom listesi dosyalara kaydediliyor...")
# Modeli kaydet
joblib.dump(best_model, 'trained_model.joblib')
# Semptom listesini kaydet (tahmin için gerekli)
joblib.dump(symptom_names, 'symptom_names.joblib')

print("\n🎉 İşlem tamamlandı! 'trained_model.joblib' ve 'symptom_names.joblib' dosyaları oluşturuldu.")