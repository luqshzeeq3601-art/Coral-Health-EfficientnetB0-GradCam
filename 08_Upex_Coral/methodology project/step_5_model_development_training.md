# Step 5: Model Development & Training (Pembangunan & Latihan Model)

Dokumen ini menerangkan proses kelima dalam projek **Coral Reef Health Assessment** iaitu mereka bentuk seni bina model deep learning berasaskan seni bina EfficientNet-B0 dan menguruskan jadual latihan model secara ensemble.

---

## 1. Library yang Digunakan
* **`tensorflow.keras.applications.EfficientNetB0`**: Pustaka deep learning yang membekalkan model EfficientNet-B0 yang telah dilatih awal pada dataset ImageNet.
* **`tensorflow.keras.layers`**: Mengandungi lapisan spatial pooling (`GlobalAveragePooling2D`), pelindung overfitting (`Dropout`), dan lapisan output keputusan (`Dense`, `Input`).
* **`tensorflow.keras.optimizers.Adam`**: Pustaka pengoptimum berat neural network menggunakan konsep momentum dinamik.
* **`tensorflow.keras.callbacks.LearningRateScheduler`**: Kelas panggilan balik yang digunakan untuk menukar kadar pembelajaran (learning rate) secara dinamik mengikut jadual pusingan (epoch).

---

## 2. Kenapa Kita Buat Langkah Ini? (Why We Do That)
* **Sebab Memilih EfficientNet-B0:** Rangkaian ini sangat cekap (hanya 5.3 juta parameter) menggunakan kaedah Compound Scaling (keseimbangan kedalaman, kelebaran, dan resolusi imej). Ia sangat sesuai digunakan untuk aplikasi berasaskan web dan komputer berspesifikasi rendah tanpa mengorbankan ketepatan pengelasan.
* **Fine-Tuning (Talaan Halus):** Kita membekukan (*freeze*) lapisan awal model dan hanya menyahbekukan (*unfreeze*) **100 lapisan teratas** (lihat kod `base_model.layers[:-100]`). Ini membolehkan model mengekalkan keupayaan mengesan ciri umum (seperti garisan/sudut) daripada ImageNet dan melatih semula model untuk mengesan ciri khusus terumbu karang.
* **Penjadual Cosine Decay:** Memulakan kadar pembelajaran pada nilai sederhana ($8 \times 10^{-5}$) dan menurunkannya secara perlahan-lahan mengikut lengkungan kosinus sehingga menghampiri nilai sifar pada akhir epoch. Ini membantu model meluncur lancar ke arah lembah ralat terendah (*global minima*) tanpa terbabas.
* **Latihan Multi-Seed Ensemble (5-Seeds):** Melatih model sebanyak 5 kali secara berasingan menggunakan 5 nilai permulaan rawak (*seed 42, 43, 44, 45, 46*) untuk mengurangkan ralat variasi individu model dan meningkatkan keupayaan tekaan yang stabil.
* **L2 Regularization ($0.0002$) & Dropout ($0.4$):** Menyekat berat parameter daripada bernilai terlampau besar bagi mengelakkan overfitting.

---

## 3. Kod Implementasi & Huraian (Example Code)

Kod ini diambil terus dari fail [train_v4_robust.py](file:///c:/Users/ZeeqRyz/Desktop/BASEPROJECT/02_Modelling/efficientnetb0_coral/train_v4_robust.py):

### A. Seni Bina Model (build_model)
Ditulis pada baris [train_v4_robust.py:L171-L183](file:///c:/Users/ZeeqRyz/Desktop/BASEPROJECT/02_Modelling/efficientnetb0_coral/train_v4_robust.py#L171-L183):

```python
def build_model(weights='imagenet'):
    # 1. Muat turun model tulang belakang (backbone) EfficientNet-B0
    base_model = EfficientNetB0(include_top=False, weights=weights, input_shape=(IMG_SIZE, IMG_SIZE, 3))
    
    # 2. Talaan Halus (Fine-Tuning): Kekalkan pembekuan lapisan awal, buka 100 lapisan teratas sahaja
    base_model.trainable = True
    for layer in base_model.layers[:-100]:
        layer.trainable = False
        
    # 3. Struktur Lapisan Output Baharu
    model = Sequential([
        Input(shape=(IMG_SIZE, IMG_SIZE, 3)), # Menerima input saiz 224x224x3
        base_model,
        GlobalAveragePooling2D(), # Tukar peta ciri 2D kepada vektor 1D
        Dropout(0.4), # Matikan 40% neuron rawak untuk mengelakkan model menghafal data
        Dense(3, activation='softmax', kernel_regularizer=tf.keras.regularizers.l2(0.0002)) 
        # Output 3 kelas (Healthy, Bleached, Dead) menggunakan fungsi Softmax
    ])
    return model
```

---

### B. Penjadual Kadar Pembelajaran (Cosine Decay)
Ditulis pada baris [train_v4_robust.py:L188-L194](file:///c:/Users/ZeeqRyz/Desktop/BASEPROJECT/02_Modelling/efficientnetb0_coral/train_v4_robust.py#L188-L194):

```python
def cosine_decay(epoch):
    initial_lr = INITIAL_LR # 8e-5 (Kadar pembelajaran awal)
    decay_steps = EPOCHS    # 30 (Latihan selama 30 epochs)
    alpha = 0.0
    
    # Formula lengkungan kosinus untuk melancarkan penurunan kadar pembelajaran
    cosine_decay_val = 0.5 * (1 + np.cos(np.pi * epoch / decay_steps))
    decayed = (1 - alpha) * cosine_decay_val + alpha
    return initial_lr * decayed
```
