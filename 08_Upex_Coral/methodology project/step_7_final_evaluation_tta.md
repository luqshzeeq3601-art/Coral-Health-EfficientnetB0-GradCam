# Step 7: Final Model Evaluation & Test-Time Augmentation (Penilaian Akhir & TTA)

Dokumen ini menerangkan proses ketujuh dalam projek **Coral Reef Health Assessment** iaitu menilai prestasi model secara tegar pada set data ujian (Test Set) yang tidak pernah dilihat menggunakan kaedah Test-Time Augmentation (TTA) dan Penyelarasan Suhu (Temperature Scaling).

---

## 1. Library yang Digunakan
* **`cv2` (OpenCV)**: Digunakan untuk mengubah suai saiz imej dan menterbalikkan imej semasa proses TTA berjalan di peringkat ramalan.
* **`numpy` (`np`)**: Digunakan untuk mengira nilai purata (`np.mean`) keputusan ramalan dan manipulasi matriks kebarangkalian.
* **`sklearn.metrics`**: Menyediakan fungsi pengiraan automatik bagi *Classification Report* (Accuracy, Precision, Recall, F1-score) dan *Confusion Matrix*.

---

## 2. Kenapa Kita Buat Langkah Ini? (Why We Do That)
* **Menguji Prestasi Sebenar (Held-out Test Set):** Menilai ketepatan model menggunakan 159 gambar ujian yang diasingkan sepenuhnya dari pusingan latihan untuk mensimulasikan penggunaan di dunia nyata.
* **Test-Time Augmentation (TTA):** 
  * Di dunia nyata, gambar karang mungkin diambil dari jarak yang berbeza atau kedudukan kiri/kanan yang terbalik.
  * TTA menyelesaikan masalah ini dengan menduplikasi gambar input kepada **4 versi berbeza** (Saiz 224 Asal, Saiz 224 Terbalik Melintang, Saiz 256 Center-Crop, Saiz 256 Center-Crop Terbalik Melintang).
  * Keempat-empat versi ini diuji pada kesemua 5 model ensemble (menghasilkan 20 ramalan per gambar).
* **Kebarangkalian yang Tepat (Temperature Scaling):** Model neural network moden sering kali tersalah ramal dengan keyakinan yang melampau tinggi (cth: 99% yakin tapi salah). Kita melaraskan kebarangkalian menggunakan parameter suhu ($T = 0.441$) bagi memastikan tahap keyakinan model (*confidence*) selaras dengan kadar ketepatan yang sebenar.

---

## 3. Kod Implementasi & Huraian (Example Code)

### A. Kod Test-Time Augmentation (TTA)
Fungsi [predict_with_tta](file:///c:/Users/ZeeqRyz/Desktop/BASEPROJECT/02_Modelling/efficientnetb0_coral/train_v4_robust.py#L429-L453) menguruskan ramalan tegar semasa penilaian model:

```python
def predict_with_tta(models, X_test):
    all_ensemble_preds = []
    
    # 1. Kitar setiap satu imej dalam set data ujian
    for i, img in enumerate(X_test):
        tta_preds = []
        img_uint8 = img.astype(np.uint8) if img.max() > 1.0 else (img * 255).astype(np.uint8)
        
        # Penjanaan 4 variasi TTA: 2 skala (224 & 256) x 2 kedudukan (Asal & Terbalik)
        for scale in TTA_SCALES: # TTA_SCALES = [224, 256]
            scaled_img = cv2.resize(img_uint8, (scale, scale))
            
            if scale == IMG_SIZE: # Saiz 224
                inp = scaled_img
            else: # Saiz 256 (lakukan center crop ke 224)
                start = (scale - IMG_SIZE) // 2
                inp = scaled_img[start:start+IMG_SIZE, start:start+IMG_SIZE]
            
            # Tukar format dan sediakan imej asal dan imej pantulan melintang
            inp_orig = np.expand_dims(inp.astype('float32'), axis=0)
            inp_flip = np.expand_dims(cv2.flip(inp, 1).astype('float32'), axis=0)
            
            # Dapatkan ramalan bagi setiap 5 model ensemble untuk kedua-dua versi imej
            for model in models:
                tta_preds.append(model.predict(inp_orig, verbose=0)[0])
                tta_preds.append(model.predict(inp_flip, verbose=0)[0])
        
        # Hitung purata kebarangkalian daripada kesemua 20 keputusan ramalan (5 model x 4 TTA)
        avg_pred = np.mean(tta_preds, axis=0)
        all_ensemble_preds.append(avg_pred)
        
    return np.array(all_ensemble_preds)
```

---

### B. Kod Penyelarasan Suhu (Temperature Scaling)
Ditulis di dalam fail [app.py:L237-L248](file:///c:/Users/ZeeqRyz/Desktop/BASEPROJECT/04_Web_Application/app.py#L237-L248):

```python
def temperature_scale_from_probs(probs, temperature):
    probs = np.asarray(probs, dtype=np.float64)
    probs = np.clip(probs, 1e-8, 1.0)
    
    # Formula penentukuran kebarangkalian: p^(1/T) dibahagi dengan jumlah kebarangkalian baharu
    scaled = np.power(probs, 1.0 / float(temperature))
    scaled_sum = np.sum(scaled)
    
    return scaled / scaled_sum # Kembalikan kebarangkalian yang telah ditentukur
```
