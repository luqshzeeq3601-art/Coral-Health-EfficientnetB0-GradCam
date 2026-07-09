"""
Ablation Study: Justifying TTA and Multi-Seed (5) Ensemble Choices
==================================================================
Evaluates 8 configurations (seeds × TTA) on the frozen 159-image test set
using saved SWA weights.  No retraining needed.

Outputs → 03_Model_Evaluation/Ablation_TTA_MultiSeed/
  - ablation_results.csv
  - ablation_results.json
  - ablation_summary_table.png
"""

import os
import sys
import io
import json
import numpy as np
import cv2
import tensorflow as tf
from tensorflow.keras.models import Sequential
from tensorflow.keras.applications import EfficientNetB0
from tensorflow.keras.layers import GlobalAveragePooling2D, Dropout, Dense, Input
from sklearn.metrics import classification_report, f1_score
from sklearn.model_selection import train_test_split
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

# ============================================================
# Configuration — matches train_v4_robust.py exactly
# ============================================================
IMG_SIZE = 224
CLASS_NAMES = ['Healthy', 'Bleached', 'Dead']
SEEDS = [42, 43, 44, 45, 46]
SPLIT_SEED = 42
TTA_SCALES = [224, 256]

# Paths
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.normpath(os.path.join(SCRIPT_DIR, '..'))
MODEL_DIR = os.path.join(PROJECT_ROOT, '02_Modelling', 'efficientnetb0_coral', 'models')
OUTPUT_DIR = os.path.join(SCRIPT_DIR, 'Ablation_TTA_MultiSeed')

# Dataset path — with BHD Kaggle subfolder
DATASET_PATH = os.path.join(PROJECT_ROOT, 'Dataset', 'BHD Kaggle')

# Split info — primary location
SPLIT_INFO_PATH = os.path.join(PROJECT_ROOT, '05_Baseline_Model', 'split_info_v3.json')
# Fallback
SPLIT_INFO_FALLBACK = os.path.join(PROJECT_ROOT, '02_Modelling', 'efficientnetb0_coral', 'split_info_v3.json')

os.makedirs(OUTPUT_DIR, exist_ok=True)


# ============================================================
# Model Architecture — must match train_v4_robust.py
# ============================================================
def build_model():
    """Build EfficientNetB0 with architecture matching training script.
    Uses weights=None since we load saved SWA weights manually.
    """
    base_model = EfficientNetB0(include_top=False, weights=None, input_shape=(IMG_SIZE, IMG_SIZE, 3))
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
# Data Loading
# ============================================================
def collect_file_paths(dataset_path):
    """Collect all image file paths and labels from dataset directory."""
    file_paths, labels, filenames = [], [], []
    for cls_idx, cls_name in enumerate(CLASS_NAMES):
        cls_dir = os.path.join(dataset_path, cls_name)
        if not os.path.exists(cls_dir):
            cls_dir = os.path.join(dataset_path, cls_name.lower())
        if os.path.exists(cls_dir):
            for fname in sorted(os.listdir(cls_dir)):
                if not fname.lower().endswith(('.png', '.jpg', '.jpeg')):
                    continue
                file_paths.append(os.path.join(cls_dir, fname))
                labels.append(cls_idx)
                filenames.append(f"{cls_name}/{fname}")
    return file_paths, np.array(labels), filenames


def load_test_set():
    """Load test set images and labels from split_info_v3.json."""
    # Find split file
    split_path = SPLIT_INFO_PATH
    if not os.path.exists(split_path):
        split_path = SPLIT_INFO_FALLBACK
    if not os.path.exists(split_path):
        print("❌ split_info_v3.json not found at either location.")
        print(f"   Checked: {SPLIT_INFO_PATH}")
        print(f"   Checked: {SPLIT_INFO_FALLBACK}")
        print("   Falling back to deterministic split reconstruction...")
        return _reconstruct_test_split()

    print(f"📂 Loading split from: {split_path}")
    with open(split_path, 'r') as f:
        split_info = json.load(f)

    test_files = split_info['test_files']
    print(f"   Test files in split: {len(test_files)}")

    images, labels, filenames = [], [], []
    missing = 0
    for fname in test_files:
        full_path = os.path.join(DATASET_PATH, fname)
        if not os.path.exists(full_path):
            missing += 1
            continue

        img = cv2.imread(full_path)
        if img is None:
            missing += 1
            continue

        img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        img = cv2.resize(img, (IMG_SIZE, IMG_SIZE))

        cls_name = fname.split('/')[0]
        if cls_name in CLASS_NAMES:
            images.append(img)
            labels.append(CLASS_NAMES.index(cls_name))
            filenames.append(fname)

    if missing > 0:
        print(f"   ⚠️ {missing} test files could not be loaded")

    X = np.array(images, dtype='float32')
    y = np.array(labels)
    print(f"   ✅ Loaded {len(X)} test images")

    # Print class distribution
    for i, cls_name in enumerate(CLASS_NAMES):
        count = np.sum(y == i)
        print(f"      {cls_name}: {count}")

    return X, y, filenames


def _reconstruct_test_split():
    """Reconstruct the same deterministic split as train_v4_robust.py."""
    print("   Reconstructing split with seed=42, 80/10/10 stratified...")
    file_paths, labels, filenames = collect_file_paths(DATASET_PATH)
    indices = np.arange(len(file_paths))
    train_idx, temp_idx = train_test_split(
        indices, test_size=0.2, random_state=SPLIT_SEED, stratify=labels
    )
    temp_labels = labels[temp_idx]
    _, test_idx = train_test_split(
        temp_idx, test_size=0.5, random_state=SPLIT_SEED, stratify=temp_labels
    )

    test_paths = [file_paths[i] for i in test_idx]
    test_labels = labels[test_idx]
    test_filenames = [filenames[i] for i in test_idx]

    images = []
    valid_labels = []
    valid_filenames = []
    for path, label, fname in zip(test_paths, test_labels, test_filenames):
        img = cv2.imread(path)
        if img is not None:
            img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
            img = cv2.resize(img, (IMG_SIZE, IMG_SIZE))
            images.append(img)
            valid_labels.append(label)
            valid_filenames.append(fname)

    X = np.array(images, dtype='float32')
    y = np.array(valid_labels)
    print(f"   ✅ Reconstructed {len(X)} test images")
    return X, y, valid_filenames


# ============================================================
# Prediction Functions
# ============================================================
def predict_no_tta(model, X_test):
    """Single 224px forward pass — no augmentation."""
    preds = model.predict(X_test, verbose=0, batch_size=16)
    return preds


def predict_with_tta_single_model(model, X_test):
    """Multi-Scale TTA for a single model.
    For each image: 2 scales × 2 (orig+flip) = 4 views.
    Returns averaged predictions across all views.
    """
    all_preds = []

    for img in X_test:
        tta_preds = []
        img_uint8 = img.astype(np.uint8) if img.max() > 1.0 else (img * 255).astype(np.uint8)

        for scale in TTA_SCALES:
            scaled_img = cv2.resize(img_uint8, (scale, scale))

            if scale == IMG_SIZE:
                inp = scaled_img
            else:
                # Center Crop to IMG_SIZE
                start = (scale - IMG_SIZE) // 2
                inp = scaled_img[start:start + IMG_SIZE, start:start + IMG_SIZE]

            # Original
            inp_orig = np.expand_dims(inp.astype('float32'), axis=0)
            tta_preds.append(model.predict(inp_orig, verbose=0)[0])

            # Horizontal flip
            inp_flip = np.expand_dims(cv2.flip(inp, 1).astype('float32'), axis=0)
            tta_preds.append(model.predict(inp_flip, verbose=0)[0])

        # Average across all TTA views for this single model
        avg_pred = np.mean(tta_preds, axis=0)
        all_preds.append(avg_pred)

    return np.array(all_preds)


# ============================================================
# Configuration Definitions
# ============================================================
CONFIGS = [
    {'name': 'A', 'seeds': [42],                 'tta': False, 'desc': 'Single model, no TTA'},
    {'name': 'B', 'seeds': [42],                 'tta': True,  'desc': 'Single model + TTA'},
    {'name': 'C', 'seeds': [42, 43],             'tta': False, 'desc': '2-seed ensemble, no TTA'},
    {'name': 'D', 'seeds': [42, 43],             'tta': True,  'desc': '2-seed ensemble + TTA'},
    {'name': 'E', 'seeds': [42, 43, 44],         'tta': False, 'desc': '3-seed ensemble, no TTA'},
    {'name': 'F', 'seeds': [42, 43, 44],         'tta': True,  'desc': '3-seed ensemble + TTA'},
    {'name': 'G', 'seeds': [42, 43, 44, 45, 46], 'tta': False, 'desc': '5-seed ensemble, no TTA (canonical)'},
    {'name': 'H', 'seeds': [42, 43, 44, 45, 46], 'tta': True,  'desc': '5-seed ensemble + TTA (full pipeline)'},
]


# ============================================================
# Metrics Computation
# ============================================================
def compute_metrics(y_true, y_pred_classes, pred_probs, config_name, ref_preds_5seed=None):
    """Compute all ablation metrics for a single configuration."""
    n = len(y_true)
    correct_mask = (y_pred_classes == y_true)
    total_correct = np.sum(correct_mask)
    total_errors = n - total_correct
    accuracy = total_correct / n

    # Per-class metrics
    report = classification_report(y_true, y_pred_classes, target_names=CLASS_NAMES, output_dict=True, zero_division=0)
    macro_f1 = f1_score(y_true, y_pred_classes, average='macro', zero_division=0)

    # Confidence metrics
    max_confidences = np.max(pred_probs, axis=1)

    if np.sum(correct_mask) > 0:
        mean_conf_correct = float(np.mean(max_confidences[correct_mask]))
    else:
        mean_conf_correct = 0.0

    if np.sum(~correct_mask) > 0:
        mean_conf_wrong = float(np.mean(max_confidences[~correct_mask]))
    else:
        mean_conf_wrong = 0.0

    # Prediction stability vs full 5-seed ensemble
    stability_flips = 0
    if ref_preds_5seed is not None:
        stability_flips = int(np.sum(y_pred_classes != ref_preds_5seed))

    return {
        'config': config_name,
        'accuracy': round(accuracy * 100, 2),
        'total_errors': int(total_errors),
        'total_correct': int(total_correct),
        'macro_f1': round(macro_f1, 4),
        'mean_conf_correct': round(mean_conf_correct * 100, 2),
        'mean_conf_wrong': round(mean_conf_wrong * 100, 2),
        'confidence_gap': round((mean_conf_correct - mean_conf_wrong) * 100, 2),
        'stability_flips_vs_5seed': stability_flips,
        'per_class': {
            cls: {
                'precision': round(report[cls]['precision'], 4),
                'recall': round(report[cls]['recall'], 4),
                'f1': round(report[cls]['f1-score'], 4),
                'support': int(report[cls]['support']),
            }
            for cls in CLASS_NAMES
        },
    }


# ============================================================
# Summary Table Generation
# ============================================================
def generate_summary_table(results, output_dir):
    """Generate a publication-ready summary table image."""
    fig, ax = plt.subplots(figsize=(16, 6))
    ax.axis('off')
    ax.set_title('Ablation Study: TTA & Multi-Seed Ensemble',
                 fontsize=16, fontweight='bold', pad=20)

    headers = ['Config', 'Seeds', 'TTA', 'Accuracy (%)', 'Errors',
               'Macro F1', 'Conf. Correct (%)', 'Conf. Wrong (%)',
               'Gap (%)', 'Flips vs 5-seed']

    table_data = []
    for r in results:
        cfg = [c for c in CONFIGS if c['name'] == r['config']][0]
        table_data.append([
            r['config'],
            str(len(cfg['seeds'])),
            '✓' if cfg['tta'] else '✗',
            f"{r['accuracy']:.2f}",
            str(r['total_errors']),
            f"{r['macro_f1']:.4f}",
            f"{r['mean_conf_correct']:.2f}",
            f"{r['mean_conf_wrong']:.2f}",
            f"{r['confidence_gap']:.2f}",
            str(r['stability_flips_vs_5seed']),
        ])

    table = ax.table(cellText=table_data, colLabels=headers,
                     loc='center', cellLoc='center')
    table.auto_set_font_size(False)
    table.set_fontsize(10)
    table.scale(1.0, 1.6)

    # Style header
    for j in range(len(headers)):
        cell = table[0, j]
        cell.set_facecolor('#2c7fb8')
        cell.set_text_props(color='white', fontweight='bold')

    # Highlight Config G (canonical benchmark)
    for row_idx, r in enumerate(results):
        if r['config'] == 'G':
            for j in range(len(headers)):
                cell = table[row_idx + 1, j]
                cell.set_facecolor('#ffffcc')

    # Alternate row colors
    for row_idx in range(len(results)):
        if results[row_idx]['config'] != 'G':
            color = '#f0f0f0' if row_idx % 2 == 0 else 'white'
            for j in range(len(headers)):
                table[row_idx + 1, j].set_facecolor(color)

    plt.tight_layout()
    path = os.path.join(output_dir, 'ablation_summary_table.png')
    plt.savefig(path, dpi=200, bbox_inches='tight', facecolor='white')
    plt.close()
    print(f"   📊 Saved: {path}")


# ============================================================
# Main
# ============================================================
def main():
    print("=" * 60)
    print("  ABLATION STUDY: TTA & Multi-Seed Ensemble Justification")
    print("=" * 60)

    # ---- Load test set ----
    print("\n📂 Step 1: Loading test set...")
    X_test, y_test, test_filenames = load_test_set()
    n_test = len(X_test)
    print(f"   Total test images: {n_test}")
    assert n_test == 159, f"Expected 159 test images, got {n_test}"

    # ---- Load models ----
    print("\n🧠 Step 2: Loading SWA models...")
    models = {}
    for seed in SEEDS:
        swa_path = os.path.join(MODEL_DIR, f"efficientnetb0_v4robust_seed{seed}_swa.weights.h5")
        if not os.path.exists(swa_path):
            # Try .h5 full model format
            swa_path = os.path.join(MODEL_DIR, f"efficientnetb0_v4robust_seed{seed}_swa.h5")
        if not os.path.exists(swa_path):
            print(f"   ❌ SWA model not found for seed {seed}")
            continue

        model = build_model()
        model.load_weights(swa_path)
        models[seed] = model
        print(f"   ✅ Loaded seed {seed} from {os.path.basename(swa_path)}")

    if len(models) < 5:
        print(f"   ⚠️ Only {len(models)}/5 models loaded. Results may be incomplete.")

    # ---- Pre-compute predictions ----
    print("\n⚡ Step 3: Pre-computing predictions (this takes a few minutes)...")

    # No-TTA predictions per model
    print("   Computing No-TTA predictions...")
    preds_no_tta = {}
    for seed, model in models.items():
        print(f"      Seed {seed} (no TTA)...")
        preds_no_tta[seed] = predict_no_tta(model, X_test)

    # TTA predictions per model
    print("   Computing TTA predictions...")
    preds_tta = {}
    for seed, model in models.items():
        print(f"      Seed {seed} (TTA — {len(X_test)} images × {len(TTA_SCALES)} scales × 2 views)...")
        preds_tta[seed] = predict_with_tta_single_model(model, X_test)

    # ---- Compute 5-seed no-TTA reference (Config G) for stability metric ----
    ref_probs_5seed = np.mean([preds_no_tta[s] for s in SEEDS if s in preds_no_tta], axis=0)
    ref_preds_5seed = np.argmax(ref_probs_5seed, axis=1)

    # ---- Evaluate all 8 configurations ----
    print("\n📊 Step 4: Evaluating 8 configurations...")
    all_results = []

    for cfg in CONFIGS:
        print(f"\n   Config {cfg['name']}: {cfg['desc']}")

        # Select prediction source per seed
        seed_preds = []
        for seed in cfg['seeds']:
            if seed not in models:
                print(f"      ⚠️ Seed {seed} not available, skipping")
                continue
            if cfg['tta']:
                seed_preds.append(preds_tta[seed])
            else:
                seed_preds.append(preds_no_tta[seed])

        if not seed_preds:
            print(f"      ❌ No predictions available, skipping config")
            continue

        # Ensemble by averaging probabilities
        ensemble_probs = np.mean(seed_preds, axis=0)
        ensemble_preds = np.argmax(ensemble_probs, axis=1)

        # Compute metrics
        metrics = compute_metrics(
            y_test, ensemble_preds, ensemble_probs,
            cfg['name'], ref_preds_5seed
        )
        metrics['description'] = cfg['desc']
        metrics['num_seeds'] = len(cfg['seeds'])
        metrics['tta'] = cfg['tta']
        all_results.append(metrics)

        print(f"      Accuracy: {metrics['accuracy']}% | Errors: {metrics['total_errors']} | "
              f"Macro F1: {metrics['macro_f1']} | Flips: {metrics['stability_flips_vs_5seed']}")

    # ---- Verification: Config G must match stored results ----
    print("\n" + "=" * 60)
    config_g = [r for r in all_results if r['config'] == 'G']
    if config_g:
        g = config_g[0]
        if abs(g['accuracy'] - 98.11) < 0.1 and g['total_errors'] == 3:
            print(f"✅ VERIFICATION PASSED: Config G = {g['accuracy']}% ({g['total_errors']} errors)")
        else:
            print(f"⚠️  VERIFICATION WARNING: Config G = {g['accuracy']}% ({g['total_errors']} errors)")
            print(f"   Expected: 98.11% (3 errors)")

    # ---- Save results ----
    print("\n💾 Step 5: Saving results...")

    # CSV
    csv_path = os.path.join(OUTPUT_DIR, 'ablation_results.csv')
    import csv
    csv_headers = [
        'Config', 'Description', 'Seeds', 'TTA', 'Accuracy (%)', 'Errors',
        'Macro F1', 'Conf Correct (%)', 'Conf Wrong (%)', 'Confidence Gap (%)',
        'Flips vs 5-seed',
    ]
    # Add per-class headers
    for cls in CLASS_NAMES:
        csv_headers.extend([f'{cls} Precision', f'{cls} Recall', f'{cls} F1', f'{cls} Support'])

    with open(csv_path, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(csv_headers)
        for r in all_results:
            row = [
                r['config'], r['description'], r['num_seeds'],
                'Yes' if r['tta'] else 'No',
                r['accuracy'], r['total_errors'], r['macro_f1'],
                r['mean_conf_correct'], r['mean_conf_wrong'],
                r['confidence_gap'], r['stability_flips_vs_5seed'],
            ]
            for cls in CLASS_NAMES:
                pc = r['per_class'][cls]
                row.extend([pc['precision'], pc['recall'], pc['f1'], pc['support']])
            writer.writerow(row)
    print(f"   📝 Saved: {csv_path}")

    # JSON
    json_path = os.path.join(OUTPUT_DIR, 'ablation_results.json')
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump({
            'protocol': 'Ablation Study — TTA & Multi-Seed Ensemble',
            'test_set_size': n_test,
            'class_distribution': {cls: int(np.sum(y_test == i)) for i, cls in enumerate(CLASS_NAMES)},
            'tta_scales': TTA_SCALES,
            'seeds': SEEDS,
            'results': all_results,
        }, f, indent=2, ensure_ascii=False)
    print(f"   📝 Saved: {json_path}")

    # Summary table image
    generate_summary_table(all_results, OUTPUT_DIR)

    print("\n" + "=" * 60)
    print("  ✅ ABLATION STUDY COMPLETE")
    print(f"  📁 All outputs in: {OUTPUT_DIR}")
    print("=" * 60)


if __name__ == '__main__':
    main()
