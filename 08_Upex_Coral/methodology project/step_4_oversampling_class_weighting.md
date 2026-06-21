# Step 4: Hard-Example Oversampling & Class Weighting (Penyalinan Imej Sukar & Pemberat Kelas)

Dokumen ini menerangkan proses keempat dalam projek **Coral Reef Health Assessment** iaitu menangani isu ketidakseimbangan dataset dan imej yang sukar dipelajari oleh model neural network.

---

## 1. Library yang Digunakan
* **`sklearn.utils.class_weight`**: Pustaka Scikit-learn yang digunakan untuk mengira pemberat kelas seimbang secara automatik berdasarkan jumlah sampel dalam setiap kelas.
* **`sklearn.utils.shuffle`**: Digunakan untuk mengocok (shuffle) semula senarai imej gabungan secara rawak supaya imej yang disalin tidak bertumpu di satu tempat semasa latihan.
* **Python Loops**: Digunakan untuk melakukan penggandaan fail secara manual dalam memori sebelum data diserahkan kepada generator TensorFlow.

---

## 2. Kenapa Kita Buat Langkah Ini? (Why We Do That)
* **Mengatasi Imbalance Data (Ketidakseimbangan):** Bilangan data bagi karang mati (`Dead`) adalah sangat terhad (15 imej ujian) berbanding karang sihat (`Healthy` - 72 imej) dan karang luntur (`Bleached` - 72 imej). AI cenderung meneka kelas majoriti jika tiada pengimbangan dilakukan.
* **Fokus Kepada Edge-Cases (Hard Examples):** Sesetengah imej sangat sukar diklasifikasikan kerana alga tebal atau biasan cahaya. Oversampling menggandakan fail ini agar model dapat melatih pemberatnya berulang-ulang kali pada sampel bermasalah tersebut.
* **Pemberatan Ralat Dinamik (Class Weighting Penalty):** Jika model salah mengelaskan karang mati (`Dead`), pemberat ralat yang lebih tinggi (didenda 1.3 kali ganda lebih berat) memaksa model melakukan kemas kini parameter (*backpropagation*) yang drastik untuk mengelakkan ralat yang sama.

---

## 3. Kod Implementasi & Huraian (Example Code)

Kod ini diambil terus dari fail [train_v4_robust.py](file:///c:/Users/ZeeqRyz/Desktop/BASEPROJECT/02_Modelling/efficientnetb0_coral/train_v4_robust.py):

### A. Kod Hard-Example Oversampling
Fungsi [prepare_training_data](file:///c:/Users/ZeeqRyz/Desktop/BASEPROJECT/02_Modelling/efficientnetb0_coral/train_v4_robust.py#L466-L496) menyalin fail bermasalah sebanyak 30x (Dead) atau 20x (Bleached/Healthy) di dalam RAM:

```python
    def prepare_training_data(paths, labels, seed):
        # 1. Bina nama fail relatif seperti "Dead/83.png"
        train_filenames = [f"{p.replace(chr(92), '/').split('/')[-2]}/{p.replace(chr(92), '/').split('/')[-1]}" for p in paths]
        
        # 2. Muatkan senarai imej sukar (hard examples)
        hard_filenames = set()
        for cls, files in HARD_EXAMPLES.items():
            for f in files: 
                hard_filenames.add(f"{cls}/{f}")
            
        images = load_images(paths)
        base_imgs, base_lbls = [], []
        hard_imgs, hard_lbls = [], []
        
        # 3. Kitar imej latihan dan gandakan jika tersenarai sebagai imej sukar
        for img, label, fname in zip(images, labels, train_filenames):
            if img is None: continue
            base_imgs.append(img)
            base_lbls.append(label)
            
            # BAHAGIAN A: Gandakan imej sukar
            if fname in hard_filenames:
                cls_name = fname.split('/')[0]
                # Kelas minoriti Dead digandakan 30x, manakala yang lain 20x
                factor = 30 if cls_name == 'Dead' else OVERSAMPLE_FACTOR
                for _ in range(factor):
                    hard_imgs.append(img)
                    hard_lbls.append(label)

        # Gabungkan imej asal dan imej gandaan
        X = np.array(base_imgs + hard_imgs, dtype='float32')
        y = np.array(base_lbls + hard_lbls)
        y = tf.keras.utils.to_categorical(y, num_classes=3)
        
        # Kocok (shuffle) semula data latihan agar susunan imej rawak
        X, y = shuffle(X, y, random_state=seed)
        return X, y
```

---

### B. Kod Class Weighting (Pemberat Kelas)
Pengiraan pemberat ralat ditulis pada baris [train_v4_robust.py:L533-L540](file:///c:/Users/ZeeqRyz/Desktop/BASEPROJECT/02_Modelling/efficientnetb0_coral/train_v4_robust.py#L533-L540):

```python
        y_integers = np.argmax(y_train, axis=1)
        # Kira pemberat seimbang secara automatik menggunakan Scikit-learn
        class_weights = class_weight.compute_class_weight(
            class_weight='balanced', classes=np.unique(y_integers), y=y_integers
        )
        class_weights_dict = dict(enumerate(class_weights))
        
        # BAHAGIAN B: Tingkatkan pemberat ralat kelas Dead (index 2) sebanyak 1.3x
        # Model didenda 30% lebih berat jika gagal mengecam karang mati
        class_weights_dict[2] = class_weights_dict[2] * 1.3
```
