# Step 6: SWA Optimization (Pengoptimuman Stochastic Weight Averaging)

Dokumen ini menerangkan proses keenam dalam projek **Coral Reef Health Assessment** iaitu menggunakan teknik Stochastic Weight Averaging (SWA) untuk mengoptimumkan keupayaan generalisasi berat model neural network.

---

## 1. Library yang Digunakan
* **`tensorflow.keras.callbacks.Callback`**: Kelas asas TensorFlow Keras yang membolehkan kita melaksanakan tindakan tersuai (custom actions) pada setiap permulaan atau akhir latihan epoch.

---

## 2. Kenapa Kita Buat Langkah Ini? (Why We Do That)
* **Kelemahan Awal Latihan Biasa:** Latihan neural network konvensional biasanya mencari berat terbaik berdasarkan pencapaian satu-satu epoch (misalnya melalui early stopping). Namun, berat ini selalunya berada di lembah minima yang sempit (*narrow local minima*), menjadikannya mudah tersasar (overfit) apabila diuji dengan data luar.
* **Kelebihan SWA (Purata Berat Latihan):** SWA mencatat berat model pada beberapa epoch terakhir latihan (dalam projek ini: **5 epoch terakhir, dari epoch 26 hingga 30**) dan mengira nilai purata berat tersebut secara matematik.
* **Kesan Flat Minima:** Berat purata yang terhasil akan berganjak ke bahagian tengah lembah ralat yang rata (*flat minima*). Ini menjamin prestasi model yang jauh lebih stabil dan kalis variasi imej terumbu karang yang diambil dari kawasan laut berbeza.

---

## 3. Kod Implementasi & Huraian (Example Code)

Kod ini diambil terus dari fail [train_v4_robust.py](file:///c:/Users/ZeeqRyz/Desktop/BASEPROJECT/02_Modelling/efficientnetb0_coral/train_v4_robust.py#L199-L223):

```python
class SWACallback(tf.keras.callbacks.Callback):
    def __init__(self, start_epoch, swa_path):
        super(SWACallback, self).__init__()
        self.start_epoch = start_epoch # Epoch permulaan mula mengumpul berat (cth: epoch 26)
        self.swa_path = swa_path       # Alamat fail untuk menyimpan berat purata SWA (.h5)
        self.swa_weights = None        # Pembolehubah untuk menyimpan berat terkumpul
        self.n_models = 0              # Jumlah model/epoch yang telah di-puratakan

    def on_epoch_end(self, epoch, logs=None):
        # Mula mengumpul berat hanya apabila mencapai start_epoch (Epoch 26 ke atas)
        if epoch >= self.start_epoch:
            current_weights = self.model.get_weights()
            if self.swa_weights is None:
                # Salin berat epoch pertama (Epoch 26)
                self.swa_weights = [np.copy(w) for w in current_weights]
            else:
                # Kirakan nilai purata bergerak (moving average) bagi setiap berat parameter
                for i in range(len(self.swa_weights)):
                    self.swa_weights[i] = (self.swa_weights[i] * self.n_models + current_weights[i]) / (self.n_models + 1)
            self.n_models += 1
            print(f"  [SWA] Averaged weights from epoch {epoch+1} ({self.n_models} models)")

    def on_train_end(self, logs=None):
        # Apabila latihan tamat sepenuhnya, gantikan berat model semasa kepada berat purata SWA
        if self.swa_weights is not None:
            self.model.set_weights(self.swa_weights)
            # Simpan berat purata tersebut ke fail storan (.h5)
            self.model.save_weights(self.swa_path)
            print(f"  [SWA] Final averaged weights saved to {self.swa_path}")
```
