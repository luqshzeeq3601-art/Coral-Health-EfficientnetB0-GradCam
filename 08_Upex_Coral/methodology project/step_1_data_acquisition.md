# Step 1: Data Acquisition (Pengambilan Data)

Dokumen ini menerangkan proses pertama dalam projek **Coral Reef Health Assessment** iaitu mengambil dan menguruskan imej-imej terumbu karang daripada direktori storan.

---

## 1. Library yang Digunakan
* **`os`**: Pustaka standard Python yang digunakan untuk berinteraksi dengan sistem operasi, seperti membaca nama fail dalam folder dan membina laluan fail (`os.path.join`).
* **`numpy` (`np`)**: Digunakan untuk menyimpan label kelas dalam bentuk struktur array NumPy yang optimum untuk pengiraan.

---

## 2. Kenapa Kita Buat Langkah Ini? (Why We Do That)
* **Memetakan Folder ke Label (Mapping):** Komputer memerlukan label bernombor untuk melakukan pengkelasan. Kita memetakan folder `/Healthy` sebagai kelas `0`, `/Bleached` sebagai kelas `1`, dan `/Dead` sebagai kelas `2`.
* **Menapis Fail yang Rosak:** Hanya fail dengan sambungan `.png`, `.jpg`, atau `.jpeg` sahaja dibenarkan masuk, manakala fail tersembunyi atau format lain akan diabaikan bagi mengelakkan ralat semasa latihan.
* **Persediaan Pembahagian Data:** Langkah ini mengumpulkan senarai alamat penuh gambar (`file_paths`) agar langkah kedua (Data Splitting) boleh dilakukan secara teratur.

---

## 3. Kod Implementasi & Huraian (Example Code)

Kod ini diambil terus dari fail [train_v4_robust.py](file:///c:/Users/ZeeqRyz/Desktop/BASEPROJECT/02_Modelling/efficientnetb0_coral/train_v4_robust.py#L63-L84):

```python
def collect_file_paths(dataset_path):
    # file_paths: Menyimpan alamat penuh imej
    # labels: Menyimpan label integer (0, 1, 2)
    # filenames: Menyimpan nama relatif fail (contoh: "Healthy/1.png")
    file_paths, labels, filenames = [], [], []
    
    # 1. Kitar semula (loop) setiap kelas: 0 = Healthy, 1 = Bleached, 2 = Dead
    for cls_idx, cls_name in enumerate(CLASS_NAMES):
        cls_dir = os.path.join(dataset_path, cls_name)
        
        # Menyokong sekiranya nama folder ditulis dalam huruf kecil
        if not os.path.exists(cls_dir):
            cls_dir = os.path.join(dataset_path, cls_name.lower())
            
        if os.path.exists(cls_dir):
            # 2. Imbas setiap fail di dalam direktori folder kelas tersebut
            for fname in sorted(os.listdir(cls_dir)):
                # Tapis format fail; hanya fail imej sahaja yang diterima
                if not fname.lower().endswith(('.png', '.jpg', '.jpeg')): 
                    continue
                    
                # Masukkan laluan penuh fail imej ke dalam senarai
                file_paths.append(os.path.join(cls_dir, fname))
                
                # Masukkan label kelas sebagai integer (0, 1, atau 2)
                labels.append(cls_idx)
                
                # Simpan nama relatif fail (untuk kegunaan log/audit)
                filenames.append(f"{cls_name}/{fname}")
                
    return file_paths, np.array(labels), filenames
```
