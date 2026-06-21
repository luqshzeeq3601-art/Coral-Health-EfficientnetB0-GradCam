# Step 3: Data Preprocessing & Augmentation (Pra-pemprosesan & Augmentasi Data)

Dokumen ini menerangkan proses ketiga dalam projek **Coral Reef Health Assessment** iaitu menyelaraskan saiz imej (preprocessing) dan menambah kepelbagaian corak imej (augmentation).

---

## 1. Library yang Digunakan
* **`OpenCV` (`cv2`)**: Digunakan untuk membaca imej mentah (`cv2.imread`), menukar format warna (`cv2.cvtColor`), dan menukar saiz resolusi piksel imej (`cv2.resize`).
* **`numpy` (`np`)**: Digunakan untuk menukar senarai imej kepada array dimensi-4 (4D Tensor) berformat `float32` untuk dihantar ke GPU.
* **`TensorFlow` / `Keras`**:
  * `ImageDataGenerator`: Digunakan untuk melakukan augmentasi rawak tradisional (putaran, zum, dll.).
  * `tf.image`: Digunakan untuk mengubah suai nilai ton (hue) dan kepekatan warna (saturation) rawak.

---

## 2. Kenapa Kita Buat Langkah Ini? (Why We Do That)
* **Penjajaran Saiz ($224 \times 224$):** Seni bina rangkaian neural EfficientNet-B0 direka khas secara lalai untuk menerima input matriks $224 \times 224$ piksel. Saiz yang tetap membolehkan data diproses secara kelompok (batch processing) dengan pantas.
* **Penukaran Warna (BGR ke RGB):** OpenCV membaca imej sebagai BGR, tetapi model EfficientNet dilatih menggunakan RGB. Penukaran ini penting supaya ciri warna (seperti pelunturan karang) tidak ditafsir secara salah oleh model.
* **Mencegah Overfitting:** Augmentasi fizikal (putar, balik, zum) menghasilkan variasi gambar seolah-olah ditangkap dari sudut dan jarak yang berbeza, mengajar model mengenali ciri umum karang dan bukannya menghafal gambar mentah.
* **Simulasi Air Laut (Environmental Jitter):** Pengubahsuaian ton warna (Hue/Saturation) rawak mensimulasikan keadaan air laut bawah laut (kekeruhan, kedalaman, warna air biru/hijau) supaya model menjadi kalis gangguan warna air.
* **Mixup Augmentation ($\alpha=0.1$):** Menggabungkan imej secara bertindih untuk melembutkan sempadan keputusan model, mengurangkan sensitiviti terhadap ralat label, dan meningkatkan ketahanan model.

---

## 3. Kod Implementasi & Huraian (Example Code)

Kod ini diambil dari fail [train_v4_robust.py](file:///c:/Users/ZeeqRyz/Desktop/BASEPROJECT/02_Modelling/efficientnetb0_coral/train_v4_robust.py):

### A. Kod Pra-pemprosesan Imej (Preprocessing)
Fungsi [load_images](file:///c:/Users/ZeeqRyz/Desktop/BASEPROJECT/02_Modelling/efficientnetb0_coral/train_v4_robust.py#L85-L101) dan [prepare_set](file:///c:/Users/ZeeqRyz/Desktop/BASEPROJECT/02_Modelling/efficientnetb0_coral/train_v4_robust.py#L139-L152):

```python
def load_images(file_paths):
    images = []
    for path in file_paths:
        try:
            # Baca fail imej daripada storan (Format BGR)
            img = cv2.imread(path)
            if img is not None:
                # Tukar format warna kepada standard RGB
                img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
                # Ubah saiz kepada resolusi standard 224x224 piksel
                img = cv2.resize(img, (IMG_SIZE, IMG_SIZE))
            images.append(img)
        except:
            images.append(None)
    return images

def prepare_set(paths, labels):
    images = load_images(paths)
    valid_imgs, valid_lbls = [], []
    for img, label in zip(images, labels):
        if img is not None:
            valid_imgs.append(img)
            valid_lbls.append(label)
    # Tukar imej kepada NumPy array 4D berformat float32
    X = np.array(valid_imgs, dtype='float32')
    # Tukar label kepada One-Hot Encoding (contoh: 1 -> [0, 1, 0])
    y = tf.keras.utils.to_categorical(np.array(valid_lbls), num_classes=3)
    return X, y
```

---

### B. Kod Augmentasi Data (Augmentation)
Fungsi [get_augmenter](file:///c:/Users/ZeeqRyz/Desktop/BASEPROJECT/02_Modelling/efficientnetb0_coral/train_v4_robust.py#L154-L166) dan sebahagian generator [AugmentedMixupGenerator](file:///c:/Users/ZeeqRyz/Desktop/BASEPROJECT/02_Modelling/efficientnetb0_coral/train_v4_robust.py#L196-L231):

```python
def get_augmenter():
    # Menjana variasi fizikal gambar rawak semasa latihan
    return tf.keras.preprocessing.image.ImageDataGenerator(
        rotation_range=20,          # Putaran rawak sehingga 20 darjah
        width_shift_range=0.15,     # Peralihan melintang sehingga 15%
        height_shift_range=0.15,    # Peralihan menegak sehingga 15%
        horizontal_flip=True,       # Balik secara melintang (kiri-kanan)
        vertical_flip=False,        # Tiada balik menegak (karang sentiasa tumbuh dari bawah)
        zoom_range=0.15,            # Zum rawak sehingga 15%
        shear_range=0.05,           # Ricihan perspektif rawak sebanyak 5%
        fill_mode='nearest',        # Isi bahagian kosong dengan piksel terdekat
        brightness_range=[0.8, 1.2] # Cerahkan/gelapkan imej antara 80% hingga 120%
    )

# Di dalam AugmentedMixupGenerator -> __getitem__
# 1. Jiter Warna Air (Color Jitter) untuk melatih ketahanan warna air
X_batch = tf.image.random_hue(X_batch, 0.05).numpy()
X_batch = tf.image.random_saturation(X_batch, 0.8, 1.2).numpy()

# 2. Linear Mixup (Pertindihan imej secara rawak)
X_mixed = lam_img * X_batch + (1 - lam_img) * X_batch[perm_index]
y_mixed = lam_lbl * y_batch + (1 - lam_lbl) * y_batch[perm_index]
```
