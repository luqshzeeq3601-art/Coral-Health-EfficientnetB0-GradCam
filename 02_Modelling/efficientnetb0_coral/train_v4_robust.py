import os
import sys
import io
import json
import time
import numpy as np
import tensorflow as tf
from tensorflow.keras.models import Sequential
from tensorflow.keras.applications import EfficientNetB0
from tensorflow.keras.layers import GlobalAveragePooling2D, Dropout, Dense, Input
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.callbacks import ModelCheckpoint, LearningRateScheduler
from sklearn.utils import class_weight, shuffle
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, confusion_matrix
import cv2
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import seaborn as sns

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

# ============================================================
# TETAPAN KONFIGURASI PROJEK (Project Configuration)
# ============================================================
IMG_SIZE = 224
CLASS_NAMES = ['Healthy', 'Bleached', 'Dead']
SEEDS = [42, 43, 44, 45, 46]
SPLIT_SEED = 42
EPOCHS = 30
BATCH_SIZE = 16
LABEL_SMOOTHING = 0.05
INITIAL_LR = 8e-5
OVERSAMPLE_FACTOR = 20
GPU_COOLDOWN_SECONDS = 60  # Pause between seeds to prevent GPU overheating
TTA_SCALES = [224, 256]    # Multi-scale TTA for robust evaluation

HARD_EXAMPLES = {
    'Bleached': ['157.png','158.png','193.png','194.png','199.png','200.png',
                 '205.png','206.png','240.png','252.png','37.png','38.png',
                 '438.png','445.png','471.png','477.png','480.png','55.png','56.png',
                 '568.png','569.png','590.png','659.png','665.png','671.png',
                 '685.png','686.png','689.png','695.png'],
    'Dead':     ['83.png','84.png','85.png','86.png','112.png','116.png',
                 '119.png','123.png','130.png','131.png','139.png','142.png',
                 '145.png','137.png','67.png'],
    'Healthy':  ['292.png', '34.png'],
}

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_DIR = os.path.join(BASE_DIR, 'models')
OUTPUT_DIR = os.path.join(BASE_DIR, 'outputs')
SPLIT_INFO_PATH = os.path.join(BASE_DIR, 'split_info_v3.json')
DATASET_PATH = r"c:\Users\ZeeqRyz\Desktop\BASEPROJECT\Dataset"

os.makedirs(MODEL_DIR, exist_ok=True)
os.makedirs(OUTPUT_DIR, exist_ok=True)

# ============================================================
# LANGKAH 1: Pengambilan Data (Data Acquisition) 
# & LANGKAH 3 (A): Pra-pemprosesan Imej (Image Preprocessing)
# ============================================================
def collect_file_paths(dataset_path):
    # Menyimpan laluan fail (file paths), label kelas, dan nama fail secara berasingan
    file_paths, labels, filenames = [], [], []
    # Kitar semula untuk setiap kelas: 0 = Healthy, 1 = Bleached, 2 = Dead
    for cls_idx, cls_name in enumerate(CLASS_NAMES):
        cls_dir = os.path.join(dataset_path, cls_name)
        # Sokong nama folder sekiranya ditulis dalam huruf kecil
        if not os.path.exists(cls_dir):
            cls_dir = os.path.join(dataset_path, cls_name.lower())
        if os.path.exists(cls_dir):
            # Imbas setiap fail di dalam direktori folder kelas tersebut
            for fname in sorted(os.listdir(cls_dir)):
                # Pastikan hanya imej (format .png, .jpg, .jpeg) yang diproses
                if not fname.lower().endswith(('.png', '.jpg', '.jpeg')): continue
                # Masukkan laluan penuh fail imej
                file_paths.append(os.path.join(cls_dir, fname))
                # Masukkan label kelas sebagai integer (0, 1, atau 2)
                labels.append(cls_idx)
                # Simpan format relatif nama fail, contoh: "Healthy/1.png"
                filenames.append(f"{cls_name}/{fname}")
    return file_paths, np.array(labels), filenames

def load_images(file_paths):
    images = []
    # Kitar dan muat naik setiap imej berdasarkan senarai laluan fail
    for path in file_paths:
        try:
            # Baca imej menggunakan OpenCV (format laluan BGR)
            img = cv2.imread(path)
            if img is not None:
                # Tukar format warna daripada BGR (OpenCV) ke RGB (Model)
                img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
                # Ubah saiz imej ke format model (224x224)
                img = cv2.resize(img, (IMG_SIZE, IMG_SIZE))
            images.append(img)
        except:
            # Sekiranya gagal memuat naik imej, simpan sebagai None
            images.append(None)
    return images

# ============================================================
# LANGKAH 2: Pembahagian Data (Data Splitting - Train/Val/Test)
# ============================================================
def split_dataset(dataset_path):
    # Jika fail pembahagian sebelum ini wujud, muat naik fail tersebut agar pembahagian data sentiasa konsisten
    if os.path.exists(SPLIT_INFO_PATH):
        print(f"Loading existing split from {SPLIT_INFO_PATH}")
        with open(SPLIT_INFO_PATH, 'r') as f:
            split_info = json.load(f)
        # Fungsi pembantu untuk menukar senarai nama fail kepada laluan penuh dan label integer
        def get_paths(filenames):
            paths, lbls = [], []
            for fname in filenames:
                full = os.path.join(dataset_path, fname)
                if os.path.exists(full):
                    paths.append(full)
                    cls = fname.split('/')[0]
                    if cls in CLASS_NAMES: lbls.append(CLASS_NAMES.index(cls))
            return paths, np.array(lbls)
        # Ekstrak data pembahagian Train, Validation, dan Test
        train_paths, train_labels = get_paths(split_info['train_files'])
        val_paths, val_labels = get_paths(split_info['val_files'])
        test_paths, test_labels = get_paths(split_info['test_files'])
        return train_paths, train_labels, val_paths, val_labels, test_paths, test_labels
    else:
        # Jika tiada fail pembahagian wujud, cipta pembahagian baharu secara rawak
        print("Creating new split...")
        file_paths, labels, _ = collect_file_paths(dataset_path)
        indices = np.arange(len(file_paths))
        # Pisahkan 80% untuk Train dan 20% untuk data sementara (temp) dengan stratifikasi kelas
        train_idx, temp_idx = train_test_split(indices, test_size=0.2, random_state=SPLIT_SEED, stratify=labels)
        temp_labels = labels[temp_idx]
        # Pisahkan baki 20% (temp) kepada 10% Validation dan 10% Test dengan stratifikasi kelas
        val_idx, test_idx = train_test_split(temp_idx, test_size=0.5, random_state=SPLIT_SEED, stratify=temp_labels)
        # Kembalikan senarai fail imej dan label untuk setiap set
        return ([file_paths[i] for i in train_idx], labels[train_idx],
                [file_paths[i] for i in val_idx],   labels[val_idx],
                [file_paths[i] for i in test_idx],  labels[test_idx])

# ============================================================
# LANGKAH 3 (Sambungan): Penapisan Piksel & Augmentasi Generator
# ============================================================
def prepare_set(paths, labels):
    # Muat naik piksel imej sebenar daripada senarai fail
    images = load_images(paths)
    valid_imgs, valid_lbls = [], []
    # Hanya tapis dan simpan imej yang berjaya dibaca (tidak None)
    for img, label in zip(images, labels):
        if img is not None:
            valid_imgs.append(img)
            valid_lbls.append(label)
    # Tukar senarai imej kepada NumPy array berformat float32 (decimal)
    X = np.array(valid_imgs, dtype='float32')
    # Tukar label integer (0, 1, 2) kepada format One-Hot Encoding (contoh: 1 -> [0, 1, 0])
    y = tf.keras.utils.to_categorical(np.array(valid_lbls), num_classes=3)
    return X, y

def get_augmenter():
    # Menggunakan ImageDataGenerator TensorFlow Keras untuk melakukan transformasi imej rawak
    return tf.keras.preprocessing.image.ImageDataGenerator(
        rotation_range=20,          # Putaran imej secara rawak sehingga 20 darjah
        width_shift_range=0.15,     # Peralihan melintang (kiri/kanan) secara rawak sehingga 15%
        height_shift_range=0.15,    # Peralihan menegak (atas/bawah) secara rawak sehingga 15%
        horizontal_flip=True,       # Balikkan imej secara kiri-ke-kanan secara rawak
        vertical_flip=False,        # Tiada balikkan menegak (kerana kedudukan karang bawah air sentiasa menegak)
        zoom_range=0.15,            # Zum masuk/keluar secara rawak sebanyak 15%
        shear_range=0.05,           # Ricihan (distortion) perspektif imej sebanyak 5%
        fill_mode='nearest',        # Isi kawasan kosong (akibat putaran/peralihan) dengan piksel terdekat
        brightness_range=[0.8, 1.2] # Ubah kecerahan imej secara rawak antara 80% hingga 120%
    )

# ============================================================
# LANGKAH 5: Pembangunan Seni Bina Model (EfficientNet-B0)
# ============================================================
def build_model(weights='imagenet'):
    base_model = EfficientNetB0(include_top=False, weights=weights, input_shape=(IMG_SIZE, IMG_SIZE, 3))
    base_model.trainable = True
    for layer in base_model.layers[:-100]:
        layer.trainable = False
    model = Sequential([
        Input(shape=(IMG_SIZE, IMG_SIZE, 3)),
        base_model,
        GlobalAveragePooling2D(),
        Dropout(0.4),
        Dense(3, activation='softmax', kernel_regularizer=tf.keras.regularizers.l2(0.0002))
    ])
    return model

# ============================================================
# LANGKAH 5: Jadual Kadar Pembelajaran (Cosine Decay Scheduler)
# ============================================================
def cosine_decay(epoch):
    initial_lr = INITIAL_LR
    decay_steps = EPOCHS
    alpha = 0.0
    cosine_decay_val = 0.5 * (1 + np.cos(np.pi * epoch / decay_steps))
    decayed = (1 - alpha) * cosine_decay_val + alpha
    return initial_lr * decayed

# ============================================================
# LANGKAH 6: Pengoptimuman Stochastic Weight Averaging (SWA)
# ============================================================
# SWA Callback
# ==========================================
class SWACallback(tf.keras.callbacks.Callback):
    def __init__(self, start_epoch, swa_path):
        super(SWACallback, self).__init__()
        self.start_epoch = start_epoch
        self.swa_path = swa_path
        self.swa_weights = None
        self.n_models = 0

    def on_epoch_end(self, epoch, logs=None):
        if epoch >= self.start_epoch:
            current_weights = self.model.get_weights()
            if self.swa_weights is None:
                self.swa_weights = [np.copy(w) for w in current_weights]
            else:
                for i in range(len(self.swa_weights)):
                    self.swa_weights[i] = (self.swa_weights[i] * self.n_models + current_weights[i]) / (self.n_models + 1)
            self.n_models += 1
            print(f"  [SWA] Averaged weights from epoch {epoch+1} ({self.n_models} models)")

    def on_train_end(self, logs=None):
        if self.swa_weights is not None:
            self.model.set_weights(self.swa_weights)
            self.model.save_weights(self.swa_path)
            print(f"  [SWA] Final averaged weights saved to {self.swa_path}")

# ============================================================
# LANGKAH 3 (B): Augmentasi Termaju (Mixup & Color Jitter)
# ============================================================
class AugmentedMixupGenerator(tf.keras.utils.Sequence):
    def __init__(self, X, y, batch_size, augment_gen, alpha=0.1, class_weights_dict=None):
        self.gen = augment_gen.flow(X, y, batch_size=batch_size)
        self.alpha = alpha
        self.batch_size = batch_size
        self.class_weights_dict = class_weights_dict
    
    def __len__(self): return len(self.gen)
    
    def __getitem__(self, index):
        X_batch, y_batch = self.gen[index]
        # Environmental Color Jitter (water color invariance)
        X_batch = tf.image.random_hue(X_batch, 0.05).numpy()
        X_batch = tf.image.random_saturation(X_batch, 0.8, 1.2).numpy()
        
        batch_size = len(X_batch)
        if batch_size < 2: return X_batch, y_batch
        
        lam = np.random.beta(self.alpha, self.alpha, batch_size)
        perm_index = np.random.permutation(batch_size)
        lam_img = lam.reshape(batch_size, 1, 1, 1)
        lam_lbl = lam.reshape(batch_size, 1)
        
        X_mixed = lam_img * X_batch + (1 - lam_img) * X_batch[perm_index]
        y_mixed = lam_lbl * y_batch + (1 - lam_lbl) * y_batch[perm_index]
        
        if self.class_weights_dict:
            y_i1 = np.argmax(y_batch, axis=1)
            y_i2 = np.argmax(y_batch[perm_index], axis=1)
            w1 = np.array([self.class_weights_dict[i] for i in y_i1])
            w2 = np.array([self.class_weights_dict[i] for i in y_i2])
            lam_squeeze = lam.squeeze() 
            sample_weights = lam_squeeze * w1 + (1 - lam_squeeze) * w2
            return X_mixed, y_mixed, sample_weights
        
        return X_mixed, y_mixed

# ============================================================
# LANGKAH 8: Penerangan Model Boleh Tafsir (Grad-CAM XAI)
# ============================================================
def make_gradcam_heatmap(img_array, model, layer_name='top_conv', eigen_smooth=False):
    """Generate Grad-CAM heatmap for EfficientNetB0 Sequential model.
    
    Args:
        img_array: Input image tensor (batch dimension included).
        model: The full Sequential model.
        layer_name: Name of the target conv layer inside EfficientNet.
        eigen_smooth: If True, use PCA (first principal component) of
                      activations*weights instead of standard weighted sum.
                      Removes noise with minimal speed cost.
    """
    efficientnet = None
    for layer in model.layers:
        if 'efficientnet' in layer.name.lower():
            efficientnet = layer
            break
    if efficientnet is None:
        return np.zeros((IMG_SIZE, IMG_SIZE))

    target_layer = None
    try:
        target_layer = efficientnet.get_layer(layer_name)
    except Exception:
        for layer in reversed(efficientnet.layers):
            if isinstance(layer, tf.keras.layers.Conv2D):
                target_layer = layer
                break
    if target_layer is None:
        return np.zeros((IMG_SIZE, IMG_SIZE))

    grad_model_part1 = tf.keras.models.Model(
        inputs=efficientnet.input,
        outputs=target_layer.output
    )
    try:
        top_bn = efficientnet.get_layer('top_bn')
        top_activation = efficientnet.get_layer('top_activation')
        has_top_layers = True
    except:
        has_top_layers = False

    with tf.GradientTape() as tape:
        conv_outputs = grad_model_part1(img_array)
        tape.watch(conv_outputs)
        x = conv_outputs
        if has_top_layers:
            x = top_bn(x)
            x = top_activation(x)
        eff_index = -1
        for i, layer in enumerate(model.layers):
            if layer == efficientnet:
                eff_index = i
                break
        if eff_index != -1:
            for layer in model.layers[eff_index+1:]:
                x = layer(x)
        model_outputs = x
        pred_idx = tf.argmax(model_outputs[0])
        loss = model_outputs[:, pred_idx]

    grads = tape.gradient(loss, conv_outputs)
    if grads is None:
        return np.zeros((IMG_SIZE, IMG_SIZE))

    if eigen_smooth:
        # ---- Eigen Smooth: PCA on activations * weights ----
        # Instead of standard weighted sum, extract the first principal
        # component. This removes noisy minor channels and keeps only
        # the dominant spatial activation pattern.
        pooled_grads = tf.reduce_mean(grads, axis=(0, 1, 2)).numpy()
        conv_out = conv_outputs[0].numpy()  # (H, W, C)
        
        # 1. Reference standard Grad-CAM heatmap (before ReLU)
        std_heatmap = np.sum(conv_out * pooled_grads, axis=-1)
        
        # 2. Extract PCA dominant component
        weighted_activations = conv_out * pooled_grads[np.newaxis, np.newaxis, :]  # (H, W, C)
        h, w, c = weighted_activations.shape
        reshaped = weighted_activations.reshape(h * w, c)
        U, S, Vt = np.linalg.svd(reshaped, full_matrices=False)
        heatmap = U[:, 0] * S[0]
        heatmap = heatmap.reshape(h, w)
        
        # 3. Fix Sign Ambiguity:
        # PCA eigenvectors have arbitrary signs. If the dominant component points
        # negatively compared to standard Grad-CAM, flip it right-side up.
        correlation = np.sum(heatmap * std_heatmap)
        if correlation < 0:
            heatmap = -heatmap
        
        # Apply ReLU
        heatmap = np.maximum(heatmap, 0)
    else:
        # ---- Standard Grad-CAM weighted sum ----
        pooled_grads = tf.reduce_mean(grads, axis=(0, 1, 2))
        conv_out = conv_outputs[0]
        heatmap = conv_out @ pooled_grads[..., tf.newaxis]
        heatmap = tf.squeeze(heatmap)
        heatmap = tf.nn.relu(heatmap)
        heatmap = heatmap.numpy()

    heatmap = cv2.resize(heatmap, (IMG_SIZE, IMG_SIZE), interpolation=cv2.INTER_LINEAR)
    if np.max(heatmap) > 0:
        heatmap = heatmap / np.max(heatmap)
    return heatmap


def make_gradcam_heatmap_smooth(img_array, model, layer_name='top_conv',
                                aug_smooth=False, eigen_smooth=False):
    """Grad-CAM with optional smoothing for cleaner, more focused heatmaps.
    
    Args:
        img_array: Input image tensor (batch dimension included).
        model: The full Sequential model.
        layer_name: Target conv layer name inside EfficientNet.
        aug_smooth: If True, apply test-time augmentation smoothing.
                    Runs 6 augmented versions (3 brightness × 2 flip)
                    and averages the CAMs. 6× slower but better centering.
        eigen_smooth: If True, use PCA denoising on each CAM.
                      Removes noise with minimal speed impact.
    """
    if not aug_smooth:
        return make_gradcam_heatmap(img_array, model, layer_name,
                                    eigen_smooth=eigen_smooth)

    # ---- Aug Smooth: TTA with brightness jitter + horizontal flips ----
    heatmaps = []
    brightness_factors = [1.0, 1.1, 0.9]

    for flip in [False, True]:
        for brightness in brightness_factors:
            augmented = img_array.copy() * brightness
            augmented = np.clip(augmented, 0, 255)

            if flip:
                augmented = np.flip(augmented, axis=2)  # Horizontal flip (W axis)

            hm = make_gradcam_heatmap(augmented, model, layer_name,
                                       eigen_smooth=eigen_smooth)

            if flip:
                hm = np.flip(hm, axis=1)  # Un-flip heatmap to re-align

            heatmaps.append(hm)

    avg_heatmap = np.mean(heatmaps, axis=0)
    if np.max(avg_heatmap) > 0:
        avg_heatmap = avg_heatmap / np.max(avg_heatmap)
    return avg_heatmap

# ============================================================
# LANGKAH 7 (Inference): Ramalan Tegar TTA (Test-Time Augmentation)
# ============================================================
def predict_with_tta(models, X_test):
    """Robust ensemble prediction using SWA models + Multi-Scale TTA."""
    print("  Running TTA inference (multi-scale + flip)...")
    all_ensemble_preds = []
    
    for i, img in enumerate(X_test):
        tta_preds = []
        img_uint8 = img.astype(np.uint8) if img.max() > 1.0 else (img * 255).astype(np.uint8)
        
        for scale in TTA_SCALES:
            scaled_img = cv2.resize(img_uint8, (scale, scale))
            
            if scale == IMG_SIZE:
                inp = scaled_img
            else:
                # Center Crop
                start = (scale - IMG_SIZE) // 2
                inp = scaled_img[start:start+IMG_SIZE, start:start+IMG_SIZE]
            
            # Original
            inp_orig = np.expand_dims(inp.astype('float32'), axis=0)
            # Horizontal flip
            inp_flip = np.expand_dims(cv2.flip(inp, 1).astype('float32'), axis=0)
            
            for model in models:
                tta_preds.append(model.predict(inp_orig, verbose=0)[0])
                tta_preds.append(model.predict(inp_flip, verbose=0)[0])
        
        avg_pred = np.mean(tta_preds, axis=0)
        all_ensemble_preds.append(avg_pred)
    
    return np.array(all_ensemble_preds)

# ============================================================
# ALIRAN UTAMA: Proses Latihan, Oversampling, Evaluasi & Output
# (Main Training, Step 4, 5, 6, 7, 8 Orchestration)
# ============================================================
def train_model():
    print("=" * 55)
    print("V4 ROBUST - EfficientNetB0 Training (SWA + TTA)")
    print("=" * 55)
    
    print("\nLoading Dataset...")
    train_paths, train_labels, val_paths, val_labels, test_paths, test_labels = split_dataset(DATASET_PATH)

    def prepare_training_data(paths, labels, seed):
        # Membina format nama fail relatif seperti "Healthy/1.png" untuk pemadanan dengan senarai imej sukar
        train_filenames = [f"{p.replace(chr(92), '/').split('/')[-2]}/{p.replace(chr(92), '/').split('/')[-1]}" for p in paths]
        # Mengumpulkan semua nama fail imej sukar ke dalam struktur data Set untuk carian pantas
        hard_filenames = set()
        for cls, files in HARD_EXAMPLES.items():
            for f in files: hard_filenames.add(f"{cls}/{f}")
            
        images = load_images(paths)
        base_imgs, base_lbls = [], []
        hard_imgs, hard_lbls = [], []
        
        # Proses setiap imej asal di dalam senarai data latihan
        for img, label, fname in zip(images, labels, train_filenames):
            if img is None: continue
            base_imgs.append(img)
            base_lbls.append(label)
            # BAHAGIAN A: Hard-Example Oversampling (Penyalinan Imej Sukar)
            if fname in hard_filenames:
                # Kelas minoriti Dead mendapat gandaan lebih tinggi (30x) berbanding kelas lain (20x)
                cls_name = fname.split('/')[0]
                factor = 30 if cls_name == 'Dead' else OVERSAMPLE_FACTOR
                for _ in range(factor):
                    hard_imgs.append(img)
                    hard_lbls.append(label)

        print(f"  Base training images: {len(base_imgs)}")
        print(f"  Hard images (oversampled): {len(hard_imgs)}")
        
        # Menggabungkan imej asal dan imej gandaan (oversampled) ke dalam array tunggal
        X = np.array(base_imgs + hard_imgs, dtype='float32')
        y = np.array(base_lbls + hard_lbls)
        y = tf.keras.utils.to_categorical(y, num_classes=3)
        # Kocok (shuffle) semula dataset secara rawak mengikut seed latihan semasa
        X, y = shuffle(X, y, random_state=seed)
        print(f"  Total training samples: {len(X)}")
        return X, y

    X_val, y_val = prepare_set(val_paths, val_labels)
    X_test, y_test = prepare_set(test_paths, test_labels)
    
    aug = get_augmenter()
    
    # Store histories for plotting
    all_train_acc = []
    all_val_acc = []
    all_train_loss = []
    all_val_loss = []

    print(f"\nTraining Config:")
    print(f"  Model: EfficientNetB0 (V4 Robust)")
    print(f"  Label Smoothing: {LABEL_SMOOTHING}")
    print(f"  Learning Rate Schedule: Cosine Decay (initial={INITIAL_LR})")
    print(f"  Ensemble Size: {len(SEEDS)} seeds")
    print(f"  Epochs: {EPOCHS}")
    print(f"  Batch Size: {BATCH_SIZE}")
    print(f"  SWA: Last 5 epochs")
    print(f"  TTA: Multi-scale {TTA_SCALES} + Horizontal Flip")
    print(f"  GPU Cooldown: {GPU_COOLDOWN_SECONDS}s between seeds")

    for seed_idx, seed in enumerate(SEEDS):
        print(f"\n{'='*40}")
        print(f"--- Training Seed {seed} ({seed_idx+1}/{len(SEEDS)}) ---")
        print(f"{'='*40}")
        
        # GPU Cooldown between seeds (skip first)
        if seed_idx > 0:
            print(f"\n🌡️ GPU Cooldown: Waiting {GPU_COOLDOWN_SECONDS}s to prevent overheating...")
            time.sleep(GPU_COOLDOWN_SECONDS)
            print("  Cooldown complete. Resuming training.\n")
        
        X_train, y_train = prepare_training_data(train_paths, train_labels, seed)

        y_integers = np.argmax(y_train, axis=1)
        # BAHAGIAN B: Class Weighting (Pengiraan berat kelas seimbang bagi mengatasi ketidakseimbangan dataset)
        class_weights = class_weight.compute_class_weight(
            class_weight='balanced', classes=np.unique(y_integers), y=y_integers
        )
        class_weights_dict = dict(enumerate(class_weights))
        # Tingkatkan pemberat ralat kelas Dead (Karang Mati) sebanyak 1.3 kali ganda (30% lebih tinggi) untuk ketepatan ekstra
        class_weights_dict[2] = class_weights_dict[2] * 1.3
        print(f"  Class Weights: {class_weights_dict}")
        
        model = build_model()
        loss_fn = tf.keras.losses.CategoricalCrossentropy(label_smoothing=LABEL_SMOOTHING)
        model.compile(optimizer=Adam(learning_rate=INITIAL_LR), loss=loss_fn, metrics=['accuracy'])
        
        model_path = os.path.join(MODEL_DIR, f"efficientnetb0_v4robust_seed{seed}.weights.h5")
        checkpoint = ModelCheckpoint(model_path, monitor='val_accuracy', save_best_only=True, verbose=1, save_weights_only=True)
        lr_scheduler = LearningRateScheduler(cosine_decay)
        
        train_gen = AugmentedMixupGenerator(
            X_train, y_train, batch_size=BATCH_SIZE, augment_gen=aug, 
            alpha=0.1, class_weights_dict=class_weights_dict
        )

        swa_path = os.path.join(MODEL_DIR, f"efficientnetb0_v4robust_seed{seed}_swa.weights.h5")
        swa_callback = SWACallback(start_epoch=EPOCHS-5, swa_path=swa_path)

        history = model.fit(
            train_gen, validation_data=(X_val, y_val), epochs=EPOCHS,
            callbacks=[checkpoint, lr_scheduler, swa_callback], verbose=1
        )
        
        all_train_acc.append(history.history['accuracy'])
        all_val_acc.append(history.history['val_accuracy'])
        all_train_loss.append(history.history['loss'])
        all_val_loss.append(history.history['val_loss'])
        
        print(f"  ✅ Finished Seed {seed}. Weights saved.")

    # ==========================================
    # Training History Plot
    # ==========================================
    print("\n📊 Generating Training History Plot...")
    avg_train_acc = np.mean(all_train_acc, axis=0)
    avg_val_acc = np.mean(all_val_acc, axis=0)
    avg_train_loss = np.mean(all_train_loss, axis=0)
    avg_val_loss = np.mean(all_val_loss, axis=0)

    plt.figure(figsize=(14, 5), facecolor='white')
    epochs_range = range(1, len(avg_train_acc) + 1)
    
    train_color = 'tab:blue'
    val_color = 'tab:red'
    
    # Accuracy Subplot
    ax1 = plt.subplot(1, 2, 1)
    ax1.plot(epochs_range, avg_train_acc, label='Training Accuracy', color=train_color, linewidth=2.5)
    ax1.plot(epochs_range, avg_val_acc, label='Validation Accuracy', color=val_color, linewidth=2.5)
    ax1.set_title('Training and Validation Accuracy', fontsize=14, fontweight='bold')
    ax1.set_xlabel('Epoch', fontsize=12)
    ax1.set_ylabel('Accuracy', fontsize=12)
    ax1.set_ylim([0.60, 1.00])
    ax1.set_xticks([1, 5, 10, 15, 20, 25, 30])
    ax1.tick_params(labelsize=11)
    ax1.legend(loc='lower right', frameon=True, facecolor='white', edgecolor='gray', fontsize=11)
    ax1.grid(True, linestyle='--', color='#E0E0E0', alpha=0.5, linewidth=0.7)
    
    # Loss Subplot
    ax2 = plt.subplot(1, 2, 2)
    ax2.plot(epochs_range, avg_train_loss, label='Training Loss', color=train_color, linewidth=2.5)
    ax2.plot(epochs_range, avg_val_loss, label='Validation Loss', color=val_color, linewidth=2.5)
    ax2.set_title('Training and Validation Loss', fontsize=14, fontweight='bold')
    ax2.set_xlabel('Epoch', fontsize=12)
    ax2.set_ylabel('Loss', fontsize=12)
    ax2.set_ylim([0.25, 0.95])
    ax2.set_xticks([1, 5, 10, 15, 20, 25, 30])
    ax2.tick_params(labelsize=11)
    ax2.legend(loc='upper right', frameon=True, facecolor='white', edgecolor='gray', fontsize=11)
    ax2.grid(True, linestyle='--', color='#E0E0E0', alpha=0.5, linewidth=0.7)
    
    plt.tight_layout()
    plt.savefig(os.path.join(OUTPUT_DIR, 'training_history_ensemble.png'), dpi=150, bbox_inches='tight')
    plt.close()
    print(f"  Saved: training_history_ensemble.png")

    # Save the raw history data to JSON so we can replot it later
    history_data = {
        'avg_train_acc': avg_train_acc.tolist(),
        'avg_val_acc': avg_val_acc.tolist(),
        'avg_train_loss': avg_train_loss.tolist(),
        'avg_val_loss': avg_val_loss.tolist()
    }
    with open(os.path.join(OUTPUT_DIR, 'training_history_ensemble.json'), 'w') as f:
        json.dump(history_data, f, indent=4)
    print(f"  Saved: training_history_ensemble.json")

    # ==========================================
    # Load SWA Models for Evaluation
    # ==========================================
    print("\n🔍 Loading SWA models for Robust TTA Evaluation...")
    models = []
    for seed in SEEDS:
        swa_path = os.path.join(MODEL_DIR, f"efficientnetb0_v4robust_seed{seed}_swa.weights.h5")
        m = build_model(weights=None)
        m.load_weights(swa_path)
        models.append(m)
        print(f"  ✅ Loaded SWA model seed {seed}")

    # ==========================================
    # Robust Ensemble Evaluation (SWA + TTA)
    # ==========================================
    print("\n⚡ Evaluating V4 Robust Ensemble (SWA + Multi-Scale TTA)...")
    avg_preds = predict_with_tta(models, X_test)
    y_pred_classes = np.argmax(avg_preds, axis=1)
    y_true_classes = np.argmax(y_test, axis=1)
    
    ensemble_acc = np.mean(y_pred_classes == y_true_classes)
    print(f"\n✅ V4 Robust Ensemble Test Accuracy (SWA+TTA): {ensemble_acc*100:.2f}%")
    
    # ==========================================
    # Classification Report (text + image)
    # ==========================================
    report_text = classification_report(y_true_classes, y_pred_classes, target_names=CLASS_NAMES)
    print("\nEnsemble Classification Report:\n", report_text)
    
    with open(os.path.join(OUTPUT_DIR, 'classification_report_ensemble.txt'), 'w') as f:
        f.write(f"V4 Robust (EfficientNetB0) - SWA + TTA Ensemble\n")
        f.write(f"Ensemble Accuracy: {ensemble_acc*100:.2f}%\n\n")
        f.write(report_text)

    report_dict = classification_report(y_true_classes, y_pred_classes, target_names=CLASS_NAMES, output_dict=True)
    
    fig, ax = plt.subplots(figsize=(10, 5))
    ax.axis('off')
    ax.set_title('Classification Report - EfficientNetB0', fontsize=14, fontweight='bold', pad=20)
    
    headers = ['Class', 'Precision', 'Recall', 'F1-Score', 'Support']
    table_data = []
    for cls_name in CLASS_NAMES:
        row = report_dict[cls_name]
        table_data.append([cls_name, f"{row['precision']:.4f}", f"{row['recall']:.4f}", 
                          f"{row['f1-score']:.4f}", f"{int(row['support'])}"])
    table_data.append(['', '', '', '', ''])
    table_data.append(['Accuracy', '', '', f"{report_dict['accuracy']:.4f}", 
                      f"{int(report_dict['weighted avg']['support'])}"])
    table_data.append(['Macro Avg', f"{report_dict['macro avg']['precision']:.4f}", 
                      f"{report_dict['macro avg']['recall']:.4f}",
                      f"{report_dict['macro avg']['f1-score']:.4f}",
                      f"{int(report_dict['macro avg']['support'])}"])
    table_data.append(['Weighted Avg', f"{report_dict['weighted avg']['precision']:.4f}", 
                      f"{report_dict['weighted avg']['recall']:.4f}",
                      f"{report_dict['weighted avg']['f1-score']:.4f}",
                      f"{int(report_dict['weighted avg']['support'])}"])
    
    table = ax.table(cellText=table_data, colLabels=headers, loc='center', cellLoc='center')
    table.auto_set_font_size(False)
    table.set_fontsize(11)
    table.scale(1.2, 1.5)
    
    for j in range(len(headers)):
        table[0, j].set_facecolor('#4472C4')
        table[0, j].set_text_props(color='white', fontweight='bold')
    for i in range(1, len(table_data) + 1):
        for j in range(len(headers)):
            if i <= len(CLASS_NAMES):
                table[i, j].set_facecolor('#D6E4F0')
            else:
                table[i, j].set_facecolor('#F2F2F2')
    
    plt.tight_layout()
    plt.savefig(os.path.join(OUTPUT_DIR, 'classification_report_ensemble.png'), dpi=150, bbox_inches='tight')
    plt.close()
    print(f"  Saved: classification_report_ensemble.png")

    # ==========================================
    # Confusion Matrix
    # ==========================================
    cm = confusion_matrix(y_true_classes, y_pred_classes)
    plt.figure(figsize=(8, 6))
    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', xticklabels=CLASS_NAMES, yticklabels=CLASS_NAMES,
                annot_kws={'size': 14})
    plt.title('Confusion Matrix - EfficientNetB0', fontsize=14, fontweight='bold')
    plt.xlabel('Predicted', fontsize=12)
    plt.ylabel('Actual', fontsize=12)
    plt.tight_layout()
    plt.savefig(os.path.join(OUTPUT_DIR, 'confusion_matrix_ensemble.png'), dpi=150)
    plt.close()
    print(f"  Saved: confusion_matrix_ensemble.png")

    # ==========================================
    # Grad-CAM Visualization
    # ==========================================
    print("\n🔬 Generating Grad-CAM visualizations (with smoothing)...")
    # Pick correctly classified samples for each class for cleaner Grad-CAM
    samples = []
    for cls_idx in range(3):
        idxs = np.where(y_true_classes == cls_idx)[0]
        # Prefer correctly classified samples
        correct_idxs = [j for j in idxs if y_pred_classes[j] == cls_idx]
        if len(correct_idxs) > 0:
            # Pick the one with the highest confidence
            best_idx = max(correct_idxs, key=lambda j: avg_preds[j][cls_idx])
            confidence = avg_preds[best_idx][cls_idx]
            samples.append((X_test[best_idx], cls_idx, y_pred_classes[best_idx], confidence))
        elif len(idxs) > 0:
            confidence = avg_preds[idxs[0]][y_pred_classes[idxs[0]]]
            samples.append((X_test[idxs[0]], y_true_classes[idxs[0]], y_pred_classes[idxs[0]], confidence))

    plt.figure(figsize=(15, 5))
    gradcam_model = models[0]  # Use seed 42 SWA model
    for i, (img, true_lbl, pred_lbl, conf) in enumerate(samples):
        img_array = np.expand_dims(img, axis=0)
        # Use both aug_smooth + eigen_smooth for clean, publication-quality CAMs
        heatmap = make_gradcam_heatmap_smooth(img_array, gradcam_model,
                                               aug_smooth=True, eigen_smooth=True)
        
        plt.subplot(1, len(samples), i+1)
        plt.imshow(img.astype(np.uint8))
        if heatmap.max() > 0:
            plt.imshow(heatmap, cmap='jet', alpha=0.4)
        plt.title(f"True: {CLASS_NAMES[true_lbl]}\nPred: {CLASS_NAMES[pred_lbl]} ({conf*100:.1f}%)", fontsize=11)
        plt.axis('off')
        
    plt.suptitle('Grad-CAM - EfficientNetB0 (aug+eigen smooth)', fontsize=14, fontweight='bold')
    plt.tight_layout()
    plt.savefig(os.path.join(OUTPUT_DIR, 'gradcam_outputs.png'), dpi=150)
    plt.close()
    print(f"  Saved: gradcam_outputs.png")
    
    print(f"\n{'='*55}")
    print(f"✅ V4 ROBUST Training Complete!")
    print(f"   Ensemble Accuracy (SWA+TTA): {ensemble_acc*100:.2f}%")
    print(f"   All outputs saved to: {OUTPUT_DIR}")
    print(f"{'='*55}")

if __name__ == "__main__":
    train_model()
