# Step 2: Data Splitting (Pembahagian Data)

Dokumen ini menerangkan proses kedua dalam projek **Coral Reef Health Assessment** iaitu membahagikan dataset kepada subset latihan (training), pengesahan (validation), dan ujian (test).

---

## 1. Library yang Digunakan
* **`scikit-learn` (`sklearn.model_selection.train_test_split`)**: Pustaka popular machine learning yang digunakan untuk melakukan pembahagian dataset secara rawak dan seimbang (stratified).
* **`json`**: Digunakan untuk menyimpan dan memuat naik fail indeks pembahagian data (`split_info_v3.json`) agar set data tidak bertukar setiap kali model dilatih semula.

---

## 2. Kenapa Kita Buat Langkah Ini? (Why We Do That)
* **Mengelakkan Data Leakage (Kebocoran Data):** Imej yang digunakan untuk melatih model tidak boleh digunakan untuk menguji model. Pembahagian yang jelas memastikan penilaian model adalah jujur dan boleh dipercayai.
* **Stratifikasi Kelas (`stratify`):** Disebabkan dataset terumbu karang tidak seimbang (contoh: kelas `Dead` mempunyai sampel yang sangat sedikit), fungsi `stratify` memastikan nisbah setiap kelas dalam Train, Val, dan Test set adalah sama rata dengan dataset asal. Ini menghalang model daripada kekurangan contoh latihan bagi kelas minoriti.
* **Keputusan yang Konsisten (Reproducibility):** Menggunakan `random_state=42` dan menyimpan pembahagian ke dalam JSON memastikan setiap kali penyelidik melatih semula model, fail pembahagian yang sama akan dirujuk.

---

## 3. Kod Implementasi & Huraian (Example Code)

Kod ini diambil terus dari fail [train_v4_robust.py](file:///c:/Users/ZeeqRyz/Desktop/BASEPROJECT/02_Modelling/efficientnetb0_coral/train_v4_robust.py#L103-L137):

```python
def split_dataset(dataset_path):
    # 1. KONSISTENSI: Jika fail pembahagian indeks (.json) wujud, muat naik fail tersebut
    if os.path.exists(SPLIT_INFO_PATH):
        print(f"Loading existing split from {SPLIT_INFO_PATH}")
        with open(SPLIT_INFO_PATH, 'r') as f:
            split_info = json.load(f)
            
        def get_paths(filenames):
            paths, lbls = [], []
            for fname in filenames:
                full = os.path.join(dataset_path, fname)
                if os.path.exists(full):
                    paths.append(full)
                    cls = fname.split('/')[0]
                    if cls in CLASS_NAMES: 
                        lbls.append(CLASS_NAMES.index(cls))
            return paths, np.array(lbls)
            
        # Ekstrak semula laluan fail bagi set Train, Val, dan Test
        train_paths, train_labels = get_paths(split_info['train_files'])
        val_paths, val_labels = get_paths(split_info['val_files'])
        test_paths, test_labels = get_paths(split_info['test_files'])
        return train_paths, train_labels, val_paths, val_labels, test_paths, test_labels
        
    else:
        # 2. PEMBAHAGIAN BARU: Jika tiada fail .json, lakukan pembahagian rawak baharu
        print("Creating new split...")
        file_paths, labels, _ = collect_file_paths(dataset_path)
        indices = np.arange(len(file_paths))
        
        # Pisahkan 80% untuk Train dan 20% untuk data sementara (temp)
        # stratify=labels mengekalkan peratusan kelas dalam set Train dan temp
        train_idx, temp_idx = train_test_split(
            indices, test_size=0.2, random_state=SPLIT_SEED, stratify=labels
        )
        temp_labels = labels[temp_idx]
        
        # Pisahkan baki 20% (temp) kepada 10% Validation dan 10% Test
        val_idx, test_idx = train_test_split(
            temp_idx, test_size=0.5, random_state=SPLIT_SEED, stratify=temp_labels
        )
        
        # Kembalikan senarai laluan fail dan label bagi setiap set
        return ([file_paths[i] for i in train_idx], labels[train_idx],
                [file_paths[i] for i in val_idx],   labels[val_idx],
                [file_paths[i] for i in test_idx],  labels[test_idx])
```
