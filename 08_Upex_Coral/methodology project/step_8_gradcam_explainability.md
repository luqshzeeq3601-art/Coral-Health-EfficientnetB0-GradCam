# Step 8: Grad-CAM Explainability (Penerangan Model Boleh Tafsir - XAI)

Dokumen ini menerangkan proses kelapan dalam projek **Coral Reef Health Assessment** iaitu menjana visualisasi peta haba (heatmap) bagi menerangkan kawasan visual imej yang mendorong keputusan ramalan model (XAI - Explainable AI).

---

## 1. Library yang Digunakan
* **`tensorflow` (`tf.GradientTape`)**: Digunakan untuk mengira nilai kecerunan (*gradients*) bagi lapisan konvolusi terpilih berbanding keputusan ramalan akhir model secara automatik.
* **`cv2` (OpenCV)**: Digunakan untuk membesarkan saiz peta haba yang kasar ($7 \times 7$) kepada saiz imej asal ($224 \times 224$) dan bertindak menindih (*overlay*) peta haba tersebut pada imej asal menggunakan colormap JET.
* **`numpy` (`np`)**: Digunakan untuk melakukan operasi matematik linear, seperti mencari nilai purata kecerunan (*pooled gradients*) dan manipulasi matriks.

---

## 2. Kenapa Kita Buat Langkah Ini? (Why We Do That)
* **Menyelesaikan Isu Black-Box:** Model deep learning konvensional melabelkan imej tanpa memberikan sebarang penjelasan. Penyelidik marin perlu tahu *kenapa* model meneka sesuatu label (contoh: adakah model fokus pada struktur tisu karang atau sekadar melihat warna pasir di latar belakang?).
* **Membina Kepercayaan Saintifik (Trust Validation):** Dengan Grad-CAM, kita dapat melihat kawasan bertanda merah (fokus tinggi) dan biru (fokus rendah). Model yang baik mesti memberikan fokus pada kawasan tisu karang yang terjejas.
* **Averaged Grad-CAM (Ensemble XAI):** Disebabkan kita mempunyai 5 model ensemble, kita menjana Grad-CAM bagi setiap model dan mengira nilai purata peta haba tersebut untuk mendapatkan peta visualisasi yang paling stabil dan kurang gangguan *noise*.
* **Eigen-Smooth Grad-CAM (PCA Denoising):** Menggunakan konsep Principal Component Analysis (PCA) untuk menapis keluar saluran kecerunan yang tidak penting (*noise*) dan mengekalkan hanya komponen arah yang paling dominan bagi visualisasi yang lebih kemas.

---

## 3. Kod Implementasi & Huraian (Example Code)

Kod ini diambil dari fail [train_v4_robust.py](file:///c:/Users/ZeeqRyz/Desktop/BASEPROJECT/02_Modelling/efficientnetb0_coral/train_v4_robust.py#L238-L342):

```python
def make_gradcam_heatmap(img_array, model, layer_name='top_conv', eigen_smooth=False):
    # 1. Cari lapisan konvolusi terakhir (top_conv) daripada model tulang belakang EfficientNet
    efficientnet = None
    for layer in model.layers:
        if 'efficientnet' in layer.name.lower():
            efficientnet = layer
            break
            
    target_layer = efficientnet.get_layer(layer_name)
    
    # 2. Bina sub-model dari input sehingga output lapisan 'top_conv'
    grad_model_part1 = tf.keras.models.Model(
        inputs=efficientnet.input,
        outputs=target_layer.output
    )
    
    # Dapatkan lapisan seterusnya (top_bn dan top_activation) untuk menyambung graf pengiraan ralat
    top_bn = efficientnet.get_layer('top_bn')
    top_activation = efficientnet.get_layer('top_activation')
    
    # 3. Gunakan tf.GradientTape untuk merakam pengiraan kecerunan model
    with tf.GradientTape() as tape:
        conv_outputs = grad_model_part1(img_array)
        tape.watch(conv_outputs)
        
        # Lengkapkan baki forward pass model
        x = top_bn(conv_outputs)
        x = top_activation(x)
        
        # Alirkan melalui lapisan pengelas tersuai model sequential
        eff_index = model.layers.index(efficientnet)
        for layer in model.layers[eff_index+1:]:
            x = layer(x)
            
        model_outputs = x
        pred_idx = tf.argmax(model_outputs[0])
        loss = model_outputs[:, pred_idx] # Dapatkan skor bagi kelas yang diramal
        
    # 4. Kirakan kecerunan (gradients) output kelas berbanding output lapisan 'top_conv'
    grads = tape.gradient(loss, conv_outputs)
    
    if eigen_smooth:
        # ---- EIGEN SMOOTH: Menggunakan PCA untuk denoising ----
        pooled_grads = tf.reduce_mean(grads, axis=(0, 1, 2)).numpy()
        conv_out = conv_outputs[0].numpy()
        weighted_activations = conv_out * pooled_grads[np.newaxis, np.newaxis, :]
        
        # Jalankan singular value decomposition (SVD) untuk mengekstrak komponen dominan pertama
        h, w, c = weighted_activations.shape
        reshaped = weighted_activations.reshape(h * w, c)
        U, S, Vt = np.linalg.svd(reshaped, full_matrices=False)
        heatmap = U[:, 0] * S[0]
        heatmap = heatmap.reshape(h, w)
        heatmap = np.maximum(heatmap, 0) # Lakukan ReLU
    else:
        # ---- GRAD-CAM STANDARD: Menggunakan purata pemberat biasa ----
        pooled_grads = tf.reduce_mean(grads, axis=(0, 1, 2))
        conv_out = conv_outputs[0]
        heatmap = conv_out @ pooled_grads[..., tf.newaxis]
        heatmap = tf.squeeze(heatmap)
        heatmap = tf.nn.relu(heatmap).numpy() # Relu mengekalkan ralat positif sahaja
        
    # 5. Ubah saiz peta haba kasar kepada saiz gambar input asal (224x224)
    heatmap = cv2.resize(heatmap, (IMG_SIZE, IMG_SIZE), interpolation=cv2.INTER_LINEAR)
    
    # Normalisasikan nilai peta haba antara julat 0 hingga 1
    if np.max(heatmap) > 0:
        heatmap = heatmap / np.max(heatmap)
        
    return heatmap
```
