# Step 9: ReefGuide Deployment (Penyebaran Web & Pembantu AI ReefGuide)

Dokumen ini menerangkan proses kesembilan dalam projek **Coral Reef Health Assessment** iaitu menyebarkan model yang telah dilatih ke dalam aplikasi web interaktif Flask & React serta menyepadukan ejen chatbot AI (ReefGuide) berasaskan LLM Gemini.

---

## 1. Library yang Digunakan
* **`Flask` (Python)**: Rangka kerja aplikasi web (web framework) mikro yang digunakan untuk membina pelayan (server) backend dan menyediakan laluan API (REST API) bagi tujuan ramalan `/api/predict` dan sembang `/api/chat`.
* **`google-genai` (Gemini SDK)**: Digunakan untuk berhubung secara rasmi dengan model bahasa besar (LLM) **Gemini-2.5-Flash** milik Google bagi memberikan respon chatbot pintar.
* **`base64` & `io`**: Digunakan untuk menukar array gambar visual hasil ramalan model dan overlay Grad-CAM kepada format string base64 untuk dihantar ke frontend React secara JSON.

---

## 2. Kenapa Kita Buat Langkah Ini? (Why We Do That)
* **Ketersediaan Dunia Nyata (Real-world Usability):** Model deep learning di dalam fail Jupyter Notebook sukar digunakan oleh orang awam. Mengubahnya kepada aplikasi web membolehkan penyelidik marin dan penyelam menguji imej secara terus dari komputer atau peranti mudah alih.
* **Interaktiviti Pintar (ReefGuide Assistant):**
  * Orang awam mungkin sukar memahami maksud angka peratusan kebarangkalian (probability) dan peta haba Grad-CAM.
  * Chatbot **ReefGuide** (dikuasakan oleh Gemini API) membaca output model neural network, rujukan visual Grad-CAM, dan sejarah sembang pengguna secara serentak.
  * Chatbot menterjemahkan data visual/nombor tersebut kepada penerangan saintifik ekologi terumbu karang bawah laut yang mesra pengguna dalam bentuk bahasa semula jadi.
* **Integrasi Selamat & Audit Penyelidikan:** Menyediakan mod pertukaran antara "Ensemble Model" tegar (98.11% ketepatan) dengan "Baseline Model" untuk tujuan perbandingan akademik dan penanda aras kajian.

---

## 3. Kod Implementasi & Huraian (Example Code)

### A. API Ramalan Web (predict endpoint)
Fungsi [predict](file:///c:/Users/ZeeqRyz/Desktop/BASEPROJECT/04_Web_Application/app.py#L1204-L1213) di dalam fail pelayan `app.py`:

```python
@app.route('/api/predict', methods=['POST'])
def predict():
    # 1. Pastikan fail imej telah dihantar oleh frontend
    if 'file' not in request.files and 'image' not in request.files:
        return jsonify({'error': 'No file uploaded'}), 400
        
    file = request.files.get('file') or request.files.get('image')
    
    try:
        # Baca imej yang dihantar, tukar warna ke RGB dan saiz ke 224x224
        file_bytes = np.frombuffer(file.read(), np.uint8)
        img_bgr = cv2.imdecode(file_bytes, cv2.IMREAD_COLOR)
        img_rgb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)
        img_resized = cv2.resize(img_rgb, (IMG_SIZE, IMG_SIZE))
        
        # 2. Jalankan ramalan tegar Test-Time Augmentation (TTA) dan puratakan keputusan ensemble
        # (Sila rujuk Langkah 7 untuk proses terperinci TTA & Purata Ensemble)
        
        # 3. Jana peta haba Grad-CAM secara purata ensemble
        # (Sila rujuk Langkah 8 untuk pengiraan Grad-CAM)
        
        # 4. Bina struktur respon data status kesihatan karang untuk dihantar semula ke frontend
        result = {
            'prediction': final_label,        # Cth: "Healthy", "Bleached" atau "Dead"
            'confidence': final_conf,         # Nilai peratusan keyakinan ditentukur
            'probabilities': probabilities,   # Taburan kebarangkalian 3 kelas
            'gradcam': gradcam_data,          # String Base64 bagi gambar overlay Grad-CAM
            'original_image': original_b64,   # String Base64 bagi gambar asal
            'uncertainty': final_conf < 75.0, # Flag amaran jika keyakinan model rendah (<75%)
            'model_used': 'EfficientNetB0 SWA Ensemble (5-seed)'
        }
        return jsonify(result)
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500
```

---

### B. Penyepaduan Chatbot AI ReefGuide (Gemini API Integration)
Ditulis pada baris [app.py:L811-L848](file:///c:/Users/ZeeqRyz/Desktop/BASEPROJECT/04_Web_Application/app.py#L811-L848) untuk menjana jawapan chatbot:

```python
def generate_gemini_reply(message, history, prediction_context):
    from google import genai
    from google.genai import types

    api_key = os.environ.get('GEMINI_API_KEY')
    if not api_key:
        raise RuntimeError('GEMINI_API_KEY is not configured')

    client = genai.Client(api_key=api_key)
    
    # 1. Bina teks sejarah perbualan sebelumnya
    history_text = "\n".join(
        f"{item['role'].title()}: {item['content']}" for item in history
    )
    
    # 2. Bina Prompt Arahan Utama (System Prompt) berserta konteks output CNN semasa
    prompt = (
        f"{CHAT_SYSTEM_PROMPT}\n\n"
        f"Latest prediction context:\n{format_prediction_context(prediction_context)}\n\n"
        f"Recent chat:\n{history_text}\n\n"
        f"User question:\n{message}\n\n"
        "Answer in 1-3 short paragraphs."
    )

    # 3. Hantar kepada Gemini API menggunakan model Gemini-2.5-Flash
    response = client.models.generate_content(
        model='gemini-2.5-flash',
        contents=prompt
    )
    
    return response.text
```
