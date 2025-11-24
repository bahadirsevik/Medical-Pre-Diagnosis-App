import pandas as pd
import numpy as np
# Artık canlı uygulamada eğitime gerek olmadığı için aşağıdaki kütüphaneler silinebilir
# ama kodun kalanında bir sorun yaratmadığı için şimdilik kalabilirler.
from sklearn.metrics import classification_report, confusion_matrix
import streamlit as st
import plotly.express as px
import plotly.graph_objects as go
import joblib # YENİ: Modeli yüklemek için eklendi

# ==================== ÖNCEDEN EĞİTİLMİŞ MODELİ YÜKLEME =====================
@st.cache_resource
def load_assets():
    """
    Önceden eğitilmiş modeli ve gerekli diğer varlıkları (semptom listesi, dataframe) yükler.
    Bu fonksiyon @st.cache_resource sayesinde sadece uygulama ilk başladığında bir kez çalışır.
    """
    model = joblib.load('trained_model.joblib')
    symptom_names = joblib.load('symptom_names.joblib')
    df = pd.read_parquet('cleaned_data.parquet')
    diseases = df.iloc[:, 0]
    
    # Modelin doğruluk skorunu train_model.py çıktısından alarak buraya sabit yazıyoruz.
    score = 0.87 # Senin belirttiğin %87'lik doğruluk oranı
    
    return model, score, symptom_names, diseases, df


# ==================== TAHMİN VE GÖRSELLEŞTİRME FONKSİYONLARI (DEĞİŞİKLİK YOK) ====================
def predict_diseases(selected_symptoms, symptom_names, model, threshold=0.01, top_k=5):
    symptom_vector = np.zeros(len(symptom_names))
    for symptom in selected_symptoms:
        if symptom in symptom_names:
            idx = symptom_names.index(symptom)
            symptom_vector[idx] = 1
    probabilities = model.predict_proba([symptom_vector])[0]
    disease_classes = model.classes_
    results = []
    for disease, prob in zip(disease_classes, probabilities):
        if prob >= threshold:
            results.append({
                'hastalık': disease,
                'olasılık': prob * 100,
                'olasılık_str': f'%{prob * 100:.1f}'
            })
    results = sorted(results, key=lambda x: x['olasılık'], reverse=True)[:top_k]
    max_prob = results[0]['olasılık'] if results else 0
    return results, max_prob

def create_probability_chart(results):
    if not results: return None
    df_results = pd.DataFrame(results)
    fig = go.Figure(data=[go.Bar(
        x=df_results['olasılık'], y=df_results['hastalık'], orientation='h',
        marker=dict(color=df_results['olasılık'], colorscale='RdYlGn_r', showscale=True,
                    colorbar=dict(title="Olasılık %")),
        text=df_results['olasılık_str'], textposition='auto',
    )])
    fig.update_layout(title='Hastalık Olasılık Dağılımı', xaxis_title='Olasılık (%)', yaxis_title='', height=400,
                      yaxis={'categoryorder': 'total ascending'})
    return fig

def create_pie_chart(results):
    if not results: return None
    df_results = pd.DataFrame(results)
    fig = px.pie(df_results, values='olasılık', names='hastalık', title='Hastalık Dağılımı', hole=0.3)
    fig.update_traces(textposition='inside', textinfo='percent+label')
    return fig


# ==================== STREAMLIT ARAYÜZÜ (GÜNCELLENDİ) ====================
def main():
    st.set_page_config(page_title="Hastalık Ön Tanı Sistemi", page_icon="🏥", layout="wide")
    st.title("🏥 Yapay Zeka Destekli Hastalık Ön Tanı Sistemi")
    st.markdown("---")

    # DEĞİŞİKLİK: Veri ve model artık doğrudan yükleniyor, dosya yükleme arayüzü kaldırıldı.
    model, score, symptom_names, diseases, df = load_assets()

    st.sidebar.header("✅ Veri ve Model")
    st.sidebar.success(f"Model ve {len(df)} kayıt başarıyla yüklendi.")
    st.sidebar.info(f"📊 {len(symptom_names)} semptom")
    st.sidebar.info(f"🦠 {diseases.nunique()} farklı hastalık")
    st.sidebar.header("⚙️ Model Bilgileri")
    st.sidebar.metric("Model Doğruluğu (Accuracy)", f"%{score * 100:.1f}")

    if 'selected_symptoms' not in st.session_state:
        st.session_state.selected_symptoms = []
    
    # YENİ: Gelişmiş Performans Analizi Paneli (Statik Bilgilerle Güncellendi)
    with st.sidebar.expander("🔬 Gelişmiş Performans Analizi"):
        st.markdown("#### Sınıf Dengesizliği Grafiği")
        st.info("Veri setindeki en yaygın 20 hastalığın dağılımı.")
        disease_counts = diseases.value_counts().head(20)
        st.bar_chart(disease_counts)

        st.markdown("#### Sınıflandırma Raporu")
        st.info(
            "`train_model.py` betiğini çalıştırdıktan sonra terminalde çıkan raporu aşağıdaki kod bloğuna yapıştırabilirsiniz."
        )
        # DEĞİŞİKLİK: Bu rapor artık canlı hesaplanmıyor. Offline eğitim sonrası çıkan sonucu buraya yapıştırın.
        classification_report_str = """
              precision    recall  f1-score   support

     Asthma       0.89      0.92      0.90        12
  Depression      0.95      0.95      0.95        20
   Diabetes       0.88      0.91      0.89        23
      GERD        0.91      0.87      0.89        15
      ...         ...       ...       ...       ...
   (ÖRNEKTİR, KENDİ SONUCUNUZU YAPIŞTIRIN)
        """
        st.code(classification_report_str)

        st.markdown("#### Karmaşıklık Matrisi (Confusion Matrix)")
        st.info(
            "Bu matris, modelin hangi hastalıkları birbiriyle karıştırdığını gösterir. Bu grafiği lokalde oluşturup ekran görüntüsü olarak buraya ekleyebilirsiniz: `st.image('confusion_matrix.png')`"
        )

    st.sidebar.header("⚙️ Analiz Ayarları")
    threshold = st.sidebar.slider("Minimum Olasılık Eşiği (%)", 1, 20, 1, 1) / 100
    top_k = st.sidebar.slider("Gösterilecek Hastalık Sayısı", 3, 10, 5)

    col1, col2 = st.columns([1, 1])
    with col1:
        st.header("🩺 Semptom Seçimi")
        search = st.text_input("🔍 Semptom Ara", placeholder="Örn: fever, headache, cough...")
        filtered_symptoms = [s for s in symptom_names if search.lower() in s.lower()] if search else symptom_names
        options_for_multiselect = sorted(list(set(st.session_state.selected_symptoms + filtered_symptoms)))
        selected_symptoms = st.multiselect(f"Semptomlarınızı seçin ({len(options_for_multiselect)} semptom)",
                                           options=options_for_multiselect,
                                           default=st.session_state.selected_symptoms,
                                           help="Birden fazla semptom seçebilirsiniz")
        st.session_state.selected_symptoms = selected_symptoms
        st.info(f"✅ Seçilen semptom sayısı: **{len(st.session_state.selected_symptoms)}**")

        if st.button("🔬 Analiz Et", type="primary", use_container_width=True):
            if not st.session_state.selected_symptoms:
                st.warning("⚠️ Lütfen en az bir semptom seçin!")
            else:
                with st.spinner('🔍 Analiz yapılıyor...'):
                    results, max_prob = predict_diseases(st.session_state.selected_symptoms, symptom_names, model,
                                                         threshold=threshold, top_k=top_k)
                    st.session_state['results'] = results
                    st.session_state['max_prob'] = max_prob

    with col2:
        st.header("📊 Analiz Sonuçları")
        if 'results' in st.session_state and st.session_state['results']:
            results, max_prob = st.session_state['results'], st.session_state['max_prob']
            if max_prob < 30:
                st.error("⚠️ **UYARI:** Belirsiz tanı. Mutlaka bir sağlık uzmanına başvurun!")
            elif max_prob < 50:
                st.warning("⚠️ Düşük güven seviyesi. Doktor kontrolü önerilir.")
            else:
                st.info("ℹ️ Bu bir ön tanıdır. Kesin tanı için doktora başvurun.")

            st.subheader("🎯 Olası Hastalıklar")
            st.dataframe(pd.DataFrame(results)[['hastalık', 'olasılık_str']], use_container_width=True,
                         hide_index=True)

            tab1, tab2 = st.tabs(["📊 Çubuk Grafik", "🥧 Pasta Grafik"])
            with tab1:
                st.plotly_chart(create_probability_chart(results), use_container_width=True)
            with tab2:
                st.plotly_chart(create_pie_chart(results), use_container_width=True)

            with st.expander("📋 Detaylı Bilgi"):
                st.markdown(f"""
                **Analiz Detayları:**
                - **Seçilen Semptom Sayısı:** {len(st.session_state.selected_symptoms)}
                - **Bulunan Hastalık Sayısı:** {len(results)}
                - **En Yüksek Olasılık:** %{max_prob:.1f}
                - **Kullanılan Model:** Naive Bayes (SMOTE ile dengelenmiş veri)
                - **Model Doğruluğu:** %{score * 100:.1f}
                """)
        else:
            st.info("👈 Soldaki panelden semptomlarınızı seçin ve 'Analiz Et' butonuna basın")

    st.markdown("---")
    st.caption("⚕️ **Sorumluluk Reddi:** Bu uygulama yalnızca eğitim ve ön bilgilendirme amaçlıdır. Tıbbi tavsiye yerine geçmez.")


if __name__ == "__main__":
    main()