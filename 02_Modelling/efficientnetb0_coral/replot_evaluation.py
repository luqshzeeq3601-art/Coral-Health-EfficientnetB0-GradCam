import io
import json
import os
import sys
from typing import List, Tuple

import cv2
import matplotlib
import matplotlib.pyplot as plt
import numpy as np
import seaborn as sns
import tensorflow as tf
from sklearn.metrics import classification_report, confusion_matrix
from sklearn.model_selection import train_test_split
from tensorflow.keras.applications import EfficientNetB0
from tensorflow.keras.layers import Dense, Dropout, GlobalAveragePooling2D, Input
from tensorflow.keras.models import Sequential

matplotlib.use("Agg")
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")


IMG_SIZE = 224
CLASS_NAMES = ["Healthy", "Bleached", "Dead"]
SEEDS = [42, 43, 44, 45, 46]

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(os.path.dirname(BASE_DIR))
DATASET_DIR = os.path.join(PROJECT_ROOT, "Dataset", "BHD Kaggle")
MODEL_DIR = os.path.join(BASE_DIR, "models")
PRIMARY_OUTPUT_DIR = os.path.join(BASE_DIR, "outputs")
MIRROR_OUTPUT_DIR = os.path.join(PROJECT_ROOT, "03_Model_Evaluation", "01_EfficientNetB0_Evaluation")
REPORT_OUTPUT_DIR = os.path.join(PROJECT_ROOT, "Fyp_Report")
OUTPUT_DIRS = [PRIMARY_OUTPUT_DIR, MIRROR_OUTPUT_DIR]


def build_model() -> tf.keras.Model:
    base_model = EfficientNetB0(include_top=False, weights="imagenet", input_shape=(IMG_SIZE, IMG_SIZE, 3))
    base_model.trainable = True
    for layer in base_model.layers[:-100]:
        layer.trainable = False

    return Sequential(
        [
            Input(shape=(IMG_SIZE, IMG_SIZE, 3)),
            base_model,
            GlobalAveragePooling2D(),
            Dropout(0.4),
            Dense(3, activation="softmax", kernel_regularizer=tf.keras.regularizers.l2(0.0002)),
        ]
    )


def collect_dataset_entries() -> Tuple[List[str], np.ndarray]:
    file_paths: List[str] = []
    labels: List[int] = []

    for cls_idx, cls_name in enumerate(CLASS_NAMES):
        class_dir = os.path.join(DATASET_DIR, cls_name)
        if not os.path.exists(class_dir):
            class_dir = os.path.join(DATASET_DIR, cls_name.lower())

        if not os.path.exists(class_dir):
            raise FileNotFoundError(f"Dataset class folder not found: {class_dir}")

        for fname in sorted(os.listdir(class_dir)):
            if not fname.lower().endswith((".png", ".jpg", ".jpeg")):
                continue
            file_paths.append(os.path.join(class_dir, fname))
            labels.append(cls_idx)

    return file_paths, np.array(labels, dtype=np.int32)


def load_test_split() -> Tuple[np.ndarray, np.ndarray, List[str]]:
    """
    Reconstruct the canonical deterministic split directly from the dataset.

    This avoids relying on stale cached split files that can drift from the
    benchmark artefacts.
    """
    file_paths, labels = collect_dataset_entries()
    indices = np.arange(len(file_paths))

    _, temp_idx = train_test_split(
        indices,
        test_size=0.2,
        random_state=42,
        stratify=labels,
    )
    temp_labels = labels[temp_idx]
    _, test_idx = train_test_split(
        temp_idx,
        test_size=0.5,
        random_state=42,
        stratify=temp_labels,
    )

    images: List[np.ndarray] = []
    y_true: List[int] = []
    test_paths: List[str] = []
    for idx in test_idx:
        img_bgr = cv2.imread(file_paths[idx])
        if img_bgr is None:
            raise RuntimeError(f"Could not read image: {file_paths[idx]}")
        img_rgb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)
        img_rgb = cv2.resize(img_rgb, (IMG_SIZE, IMG_SIZE))
        images.append(img_rgb.astype("float32"))
        y_true.append(int(labels[idx]))
        test_paths.append(file_paths[idx])

    return np.array(images, dtype="float32"), np.array(y_true, dtype=np.int32), test_paths


def load_models() -> List[tf.keras.Model]:
    models: List[tf.keras.Model] = []
    for seed in SEEDS:
        checkpoint_path = os.path.join(MODEL_DIR, f"efficientnetb0_v4robust_seed{seed}_swa.h5")
        if not os.path.exists(checkpoint_path):
            raise FileNotFoundError(f"Missing deployment checkpoint: {checkpoint_path}")

        model = build_model()
        model.load_weights(checkpoint_path)
        models.append(model)
        print(f"  Loaded deployment checkpoint for seed {seed}")
    return models


def predict_single_scale_ensemble(models: List[tf.keras.Model], x_test: np.ndarray) -> np.ndarray:
    """
    Canonical academic benchmark:
    224x224 single-scale ensemble averaging, no TTA, no deployment calibration.
    """
    all_probs = [model.predict(x_test, verbose=0) for model in models]
    return np.mean(all_probs, axis=0)


def save_report_text(report_text: str, accuracy: float, cm: np.ndarray) -> None:
    payload = (
        "V4 Robust (EfficientNetB0) - 5-Seed SWA Ensemble (224px Canonical Benchmark)\n"
        f"Ensemble Accuracy: {accuracy * 100:.2f}%\n\n"
        f"{report_text}"
    )

    raw_payload = {
        "protocol": "224px canonical benchmark, 5-seed SWA ensemble, single-scale, no TTA",
        "accuracy": accuracy,
        "class_order": CLASS_NAMES,
        "confusion_matrix": cm.tolist(),
    }

    for output_dir in OUTPUT_DIRS:
        os.makedirs(output_dir, exist_ok=True)
        with open(os.path.join(output_dir, "classification_report_ensemble.txt"), "w", encoding="utf-8") as f:
            f.write(payload)
        with open(os.path.join(output_dir, "confusion_matrix_ensemble.json"), "w", encoding="utf-8") as f:
            json.dump(raw_payload, f, indent=2)


def save_report_table(report_dict: dict) -> None:
    fig, ax = plt.subplots(figsize=(11, 5.5), facecolor="white")
    ax.axis("off")
    ax.set_title("Classification Report - EfficientNetB0", fontsize=18, fontweight="bold", pad=35)

    headers = ["Class", "Precision", "Recall", "F1-Score", "Support"]
    table_data = []
    for cls_name in CLASS_NAMES:
        row = report_dict[cls_name]
        table_data.append(
            [
                cls_name,
                f"{row['precision']:.4f}",
                f"{row['recall']:.4f}",
                f"{row['f1-score']:.4f}",
                f"{int(row['support'])}",
            ]
        )
    table_data.append(["", "", "", "", ""])
    table_data.append(
        [
            "Accuracy",
            "",
            "",
            f"{report_dict['accuracy']:.4f}",
            f"{int(report_dict['weighted avg']['support'])}",
        ]
    )
    table_data.append(
        [
            "Macro Avg",
            f"{report_dict['macro avg']['precision']:.4f}",
            f"{report_dict['macro avg']['recall']:.4f}",
            f"{report_dict['macro avg']['f1-score']:.4f}",
            f"{int(report_dict['macro avg']['support'])}",
        ]
    )
    table_data.append(
        [
            "Weighted Avg",
            f"{report_dict['weighted avg']['precision']:.4f}",
            f"{report_dict['weighted avg']['recall']:.4f}",
            f"{report_dict['weighted avg']['f1-score']:.4f}",
            f"{int(report_dict['weighted avg']['support'])}",
        ]
    )

    table = ax.table(cellText=table_data, colLabels=headers, loc="center", cellLoc="center", bbox=[0.05, 0.05, 0.9, 0.85])
    table.auto_set_font_size(False)
    table.set_fontsize(13)

    for col in range(len(headers)):
        table[0, col].set_facecolor("#4472C4")
        table[0, col].set_text_props(color="white", fontweight="bold", fontsize=13)
    for row in range(1, len(table_data) + 1):
        for col in range(len(headers)):
            cell = table[row, col]
            cell.set_facecolor("#D6E4F0" if row <= len(CLASS_NAMES) else "#F2F2F2")
            if row <= len(CLASS_NAMES) or row > len(CLASS_NAMES) + 1:
                is_bold = (col == 0)
                cell.set_text_props(weight="bold" if is_bold else "normal", fontsize=12)

    # Save to original output directories and Fyp_Report
    paths_to_save = [os.path.join(REPORT_OUTPUT_DIR, "classification_report_ensemble.png")]
    for output_dir in OUTPUT_DIRS:
        paths_to_save.append(os.path.join(output_dir, "classification_report_ensemble.png"))

    for p in paths_to_save:
        os.makedirs(os.path.dirname(p), exist_ok=True)
        fig.savefig(p, dpi=300, bbox_inches="tight")
    plt.close(fig)


def save_confusion_matrix(cm: np.ndarray) -> None:
    fig, ax = plt.subplots(figsize=(8, 6), facecolor="white")
    sns.heatmap(
        cm,
        annot=True,
        fmt="d",
        cmap="Blues",
        xticklabels=CLASS_NAMES,
        yticklabels=CLASS_NAMES,
        annot_kws={"size": 14},
        ax=ax,
    )
    ax.set_title("Confusion Matrix - EfficientNetB0", fontsize=14, fontweight="bold")
    ax.set_xlabel("Predicted", fontsize=12)
    ax.set_ylabel("Actual", fontsize=12)
    plt.tight_layout()

    for output_dir in OUTPUT_DIRS:
        fig.savefig(
            os.path.join(output_dir, "confusion_matrix_ensemble.png"),
            dpi=150,
            bbox_inches="tight",
        )
    plt.close(fig)


# ==========================================
# Standalone Grad-CAM Implementations
# ==========================================
def make_gradcam_heatmap(img_array, model, layer_name='top_conv', eigen_smooth=False):
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
        pooled_grads = tf.reduce_mean(grads, axis=(0, 1, 2)).numpy()
        conv_out = conv_outputs[0].numpy()  # (H, W, C)
        std_heatmap = np.sum(conv_out * pooled_grads, axis=-1)
        weighted_activations = conv_out * pooled_grads[np.newaxis, np.newaxis, :]  # (H, W, C)
        h, w, c = weighted_activations.shape
        reshaped = weighted_activations.reshape(h * w, c)
        U, S, Vt = np.linalg.svd(reshaped, full_matrices=False)
        heatmap = U[:, 0] * S[0]
        heatmap = heatmap.reshape(h, w)
        correlation = np.sum(heatmap * std_heatmap)
        if correlation < 0:
            heatmap = -heatmap
        heatmap = np.maximum(heatmap, 0)
    else:
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
    if not aug_smooth:
        return make_gradcam_heatmap(img_array, model, layer_name, eigen_smooth=eigen_smooth)

    heatmaps = []
    brightness_factors = [1.0, 1.1, 0.9]
    for flip in [False, True]:
        for brightness in brightness_factors:
            augmented = img_array.copy() * brightness
            augmented = np.clip(augmented, 0, 255)
            if flip:
                augmented = np.flip(augmented, axis=2)  # flip W axis
            hm = make_gradcam_heatmap(augmented, model, layer_name, eigen_smooth=eigen_smooth)
            if flip:
                hm = np.flip(hm, axis=1)  # unflip W
            heatmaps.append(hm)

    avg_heatmap = np.mean(heatmaps, axis=0)
    if np.max(avg_heatmap) > 0:
        avg_heatmap = avg_heatmap / np.max(avg_heatmap)
    return avg_heatmap


def build_baseline_model() -> tf.keras.Model:
    base_model = EfficientNetB0(include_top=False, weights="imagenet", input_shape=(IMG_SIZE, IMG_SIZE, 3))
    base_model.trainable = False
    return Sequential(
        [
            Input(shape=(IMG_SIZE, IMG_SIZE, 3)),
            base_model,
            GlobalAveragePooling2D(),
            Dense(3, activation="softmax"),
        ]
    )


def main() -> None:
    print("Regenerating canonical current-model evaluation artefacts...")
    print("Protocol: 224x224 single-scale 5-seed SWA ensemble (no TTA)")

    x_test, y_true, test_paths = load_test_split()
    print(f"  Test images loaded: {len(x_test)}")

    models = load_models()
    avg_probs = predict_single_scale_ensemble(models, x_test)
    y_pred = np.argmax(avg_probs, axis=1)

    accuracy = float(np.mean(y_pred == y_true))
    cm = confusion_matrix(y_true, y_pred, labels=list(range(len(CLASS_NAMES))))
    report_text = classification_report(y_true, y_pred, target_names=CLASS_NAMES)
    report_dict = classification_report(y_true, y_pred, target_names=CLASS_NAMES, output_dict=True)

    print(f"  Canonical accuracy: {accuracy * 100:.2f}%")
    print(f"  Confusion matrix: {cm.tolist()}")

    save_report_text(report_text, accuracy, cm)
    save_report_table(report_dict)
    save_confusion_matrix(cm)

    # 1. Generate 3x3 Ensemble Grad-CAM Grid
    print("\nGenerating 3x3 Ensemble Grad-CAM Grid...")
    samples_ensemble = []
    gradcam_model = models[0] # Seed 42 SWA model for CAM

    for cls_idx, cls_name in enumerate(CLASS_NAMES):
        idxs = np.where(y_true == cls_idx)[0]
        correct_idxs = [j for j in idxs if y_pred[j] == cls_idx]
        sorted_idxs = sorted(correct_idxs, key=lambda j: avg_probs[j][cls_idx], reverse=True)
        for best_idx in sorted_idxs[:3]:
            conf = avg_probs[best_idx][cls_idx]
            samples_ensemble.append((x_test[best_idx], cls_idx, y_pred[best_idx], conf))

    fig, axes = plt.subplots(3, 3, figsize=(15, 14), facecolor="white")
    plt.subplots_adjust(top=0.90, hspace=0.35, wspace=0.15) # Proper gap at the top

    for idx, (img, true_lbl, pred_lbl, conf) in enumerate(samples_ensemble):
        row = idx // 3
        col = idx % 3
        ax = axes[row, col]
        img_array = np.expand_dims(img, axis=0)
        # aug + eigen smooth CAM
        heatmap = make_gradcam_heatmap_smooth(img_array, gradcam_model, aug_smooth=True, eigen_smooth=True)
        ax.imshow(img.astype(np.uint8))
        if heatmap.max() > 0:
            ax.imshow(heatmap, cmap='jet', alpha=0.4)
        ax.axis('off')
        label_text = f"True: {CLASS_NAMES[true_lbl]}\nPred: {CLASS_NAMES[pred_lbl]} ({conf*100:.1f}%)"
        ax.set_title(label_text, fontsize=13, color='black', fontweight='normal', pad=10)

    plt.suptitle("Grad-CAM EfficientnetB0", fontsize=22, fontweight="bold", y=0.96)
    
    paths_to_save_ensemble_cam = [
        os.path.join(REPORT_OUTPUT_DIR, "gradcamensemble_outputs.png"),
        os.path.join(MIRROR_OUTPUT_DIR, "gradcamensemble_outputs.png")
    ]
    for p in paths_to_save_ensemble_cam:
        os.makedirs(os.path.dirname(p), exist_ok=True)
        fig.savefig(p, dpi=300, bbox_inches="tight")
    plt.close(fig)
    print("  Saved 3x3 Ensemble Grad-CAM Grid successfully at 300 DPI.")

    # 2. Generate 1x3 Baseline Grad-CAM Grid
    print("\nLoading Baseline Model...")
    tf.keras.backend.clear_session() # Clear naming counters for clean baseline load
    baseline_path = os.path.join(PROJECT_ROOT, "05_Baseline_Model", "models", "efficientnetb0_baseline.weights.h5")
    baseline_model = build_baseline_model()
    baseline_model.load_weights(baseline_path, skip_mismatch=True)
    print("  Loaded Baseline model weights.")

    print("Running baseline predictions...")
    avg_baseline_preds = baseline_model.predict(x_test, verbose=0)
    y_pred_baseline = np.argmax(avg_baseline_preds, axis=1)

    # Select single best correct prediction for each class
    samples_baseline = []
    for cls_idx, cls_name in enumerate(CLASS_NAMES):
        idxs = np.where(y_true == cls_idx)[0]
        correct_idxs = [j for j in idxs if y_pred_baseline[j] == cls_idx]
        if len(correct_idxs) > 0:
            best_idx = max(correct_idxs, key=lambda j: avg_baseline_preds[j][cls_idx])
            conf = avg_baseline_preds[best_idx][cls_idx]
            samples_baseline.append((x_test[best_idx], cls_idx, y_pred_baseline[best_idx], conf))

    fig, axes = plt.subplots(1, 3, figsize=(15, 6), facecolor="white")
    plt.subplots_adjust(top=0.85, wspace=0.15) # Proper gap at the top

    for idx, (img, true_lbl, pred_lbl, conf) in enumerate(samples_baseline):
        ax = axes[idx]
        img_array = np.expand_dims(img, axis=0)
        # Standard CAM (no smoothing)
        heatmap = make_gradcam_heatmap_smooth(img_array, baseline_model, aug_smooth=False, eigen_smooth=False)
        ax.imshow(img.astype(np.uint8))
        if heatmap.max() > 0:
            ax.imshow(heatmap, cmap='jet', alpha=0.4)
        ax.axis('off')
        label_text = f"True: {CLASS_NAMES[true_lbl]}\nPred: {CLASS_NAMES[pred_lbl]} ({conf*100:.1f}%)"
        ax.set_title(label_text, fontsize=13, color='black', fontweight='normal', pad=10)

    plt.suptitle("Grad-CAM - Baseline EfficientNetB0 (Standard)", fontsize=18, fontweight="bold", y=0.96)
    
    paths_to_save_baseline_cam = [
        os.path.join(REPORT_OUTPUT_DIR, "gradcambaseline_outputs.png"),
        os.path.join(PROJECT_ROOT, "05_Baseline_Model", "outputs", "baseline_model", "gradcambaseline_outputs.png")
    ]
    for p in paths_to_save_baseline_cam:
        os.makedirs(os.path.dirname(p), exist_ok=True)
        fig.savefig(p, dpi=300, bbox_inches="tight")
    plt.close(fig)
    print("  Saved 1x3 Baseline Grad-CAM Grid successfully at 300 DPI.")

    print("  Saved synced report + confusion matrix to:")
    for output_dir in OUTPUT_DIRS:
        print(f"    - {output_dir}")


if __name__ == "__main__":
    main()
