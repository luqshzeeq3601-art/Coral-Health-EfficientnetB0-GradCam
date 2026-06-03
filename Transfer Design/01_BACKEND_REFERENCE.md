# Backend Reference — `app.py`

Single-file Flask application (~1670 lines). Loads a 5-model EfficientNet-B0 ensemble
at startup, serves the compiled React SPA and JSON APIs. Binds to `0.0.0.0:5000`.

---

## 1. Startup Sequence

When `app.py` is executed (via `python app.py` or the `.bat` scripts), this happens:

```
__main__
  └── load_models()
        ├── For each seed in [42, 43, 44, 45, 46]:
        │     ├── build_model()          → rebuild architecture
        │     └── model.load_weights()   → load .h5 weights
        ├── load_calibration_artifacts()
        │     ├── Load ensemble_weights.npy (optional)
        │     └── Load temperature.txt (optional, default T=1.0)
        ├── check_metrics_consistency()  → warn if stale summary files
        └── load_base_model()            → load standalone baseline
              ├── Try: 05_Baseline_Model/.../efficientnetb0_baseline.weights.h5
              └── Fallback: reuse ensemble seed 42
```

### 1.1 Model Architecture — `build_model()`

```python
base_model = EfficientNetB0(include_top=False, weights=None, input_shape=(224, 224, 3))
base_model.trainable = True
for layer in base_model.layers[:-100]:
    layer.trainable = False

model = Sequential([
    Input(shape=(224, 224, 3)),
    base_model,                    # EfficientNet-B0 backbone
    GlobalAveragePooling2D(),      # Spatial pooling
    Dropout(0.6),                  # Regularization
    Dense(3, activation='softmax', # 3-class output
          kernel_regularizer=l2(0.0001))
])
```

> **Transfer note:** To adapt for a different number of classes, change `Dense(3, ...)` to
> `Dense(N, ...)` and update `CLASS_NAMES`.

### 1.2 Baseline Architecture — `build_baseline_model()`

```python
base_model = EfficientNetB0(include_top=False, weights='imagenet', input_shape=(224, 224, 3))
base_model.trainable = False  # Frozen backbone

model = Sequential([
    Input(shape=(224, 224, 3)),
    base_model,
    GlobalAveragePooling2D(),
    Dense(3, activation='softmax')  # No Dropout, No L2
])
```

### 1.3 Model Weight Files

| Model | Path | Description |
|---|---|---|
| Ensemble seed 42 | `02_Modelling/efficientnetb0_coral/models/efficientnetb0_v4robust_seed42_swa.h5` | SWA checkpoint |
| Ensemble seed 43 | `02_Modelling/efficientnetb0_coral/models/efficientnetb0_v4robust_seed43_swa.h5` | SWA checkpoint |
| Ensemble seed 44 | `02_Modelling/efficientnetb0_coral/models/efficientnetb0_v4robust_seed44_swa.h5` | SWA checkpoint |
| Ensemble seed 45 | `02_Modelling/efficientnetb0_coral/models/efficientnetb0_v4robust_seed45_swa.h5` | SWA checkpoint |
| Ensemble seed 46 | `02_Modelling/efficientnetb0_coral/models/efficientnetb0_v4robust_seed46_swa.h5` | SWA checkpoint |
| Baseline | `05_Baseline_Model/outputs/baseline_model/efficientnetb0_baseline.weights.h5` | Frozen-backbone head |
| Calibration weights | `02_Modelling/efficientnetb0_coral/models/ensemble_weights.npy` | Per-seed averaging weights |
| Temperature | `02_Modelling/efficientnetb0_coral/models/temperature.txt` | Calibration T value |

### 1.4 Calibration

**Temperature Scaling** converts softmax probabilities via `p^(1/T)` then renormalize:

```python
def temperature_scale_from_probs(probs, temperature):
    probs = np.clip(probs, 1e-8, 1.0)
    scaled = np.power(probs, 1.0 / float(temperature))
    return scaled / np.sum(scaled)
```

---

## 2. How Flask Serves the React SPA

```python
FRONTEND_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'frontend')

@app.route('/')
def home():
    return send_from_directory(FRONTEND_DIR, 'index.html')

@app.route('/coral_health')
def coral_health():
    return send_from_directory(FRONTEND_DIR, 'index.html')

@app.route('/<path:filename>')
def frontend_assets(filename):
    # Serves JS, CSS, images, videos from frontend/
    if filename.startswith('api/'):
        return jsonify({'error': 'Not found'}), 404
    full_path = os.path.join(FRONTEND_DIR, filename)
    if os.path.isfile(full_path):
        return send_from_directory(FRONTEND_DIR, filename)
    return jsonify({'error': 'Not found'}), 404
```

> **Key insight:** Flask serves the compiled React build directly from the `frontend/`
> directory. All paths `/assets/*`, `/corallogo.png`, etc. are caught by the wildcard route.
> API routes (`/api/*`) are registered before the wildcard and take priority.

---

## 3. Prediction Pipeline — `POST /api/predict`

### 3.1 Input (multipart/form-data)

| Field | Type | Values | Default |
|---|---|---|---|
| `file` or `image` | File | Image (JPG, PNG) | Required |
| `model_type` | String | `"ensemble"` or `"base"` | `"ensemble"` |
| `gradcam_enabled` | String | `"true"` or `"false"` | `"true"` |

### 3.2 Processing Pipeline

```
Image Upload
  │
  ├── OpenCV decode: imdecode(file_bytes, IMREAD_COLOR)
  ├── BGR → RGB conversion
  ├── Resize to 224×224 (uint8)
  │
  ├── [ENSEMBLE PATH]
  │     ├── TTA: 2 scales [224, 256] × 2 flips [original, h-flip] = 4 views
  │     ├── Each of 5 models predicts on all 4 views (20 total predictions)
  │     ├── Average ALL 20 predictions (flat mean)
  │     └── Apply temperature calibration
  │
  ├── [BASE PATH]
  │     ├── Single forward pass on 224×224 (no TTA)
  │     └── Raw softmax output (no temperature scaling)
  │
  ├── Confidence threshold check (75.0%)
  │     └── Below → uncertainty: true, severity: "Uncertain"
  │
  ├── [GRAD-CAM] (if enabled)
  │     ├── For each model: compute_gradcam(model, img, class_idx)
  │     │     ├── Forward pass to top_conv layer
  │     │     ├── GradientTape: compute gradients of class score w.r.t. conv outputs
  │     │     ├── Global Average Pooling of gradients → channel weights
  │     │     └── Weighted sum + ReLU → heatmap
  │     ├── Average all heatmaps across models
  │     ├── Normalize to [0, 1]
  │     ├── Create JET colormap overlay
  │     └── Encode as base64 PNG
  │
  └── Return JSON response
```

### 3.3 Output JSON

```json
{
  "prediction": "Healthy",
  "confidence": 98.7,
  "probabilities": {"Healthy": 98.7, "Bleached": 0.8, "Dead": 0.5},
  "individual_models": [
    {"fold": 42, "prediction": "Healthy", "confidence": 99.1, "probabilities": {...}},
    {"fold": 43, "prediction": "Healthy", "confidence": 98.3, "probabilities": {...}}
  ],
  "gradcam": {"heatmap": "<base64>", "overlay": "<base64>"},
  "original_image": "<base64 png>",
  "status": {
    "severity": "Good",
    "icon": "🟢",
    "description": "Coral appears healthy with normal coloration and structure.",
    "recommendation": "Maintain monitoring schedule."
  },
  "uncertainty": false,
  "notes": [],
  "model_used": "EfficientNetB0 SWA Ensemble (5-seed)"
}
```

### 3.4 Status Definitions (Hardcoded)

| Class | Severity | Icon | Description |
|---|---|---|---|
| Healthy | Good | 🟢 | Coral appears healthy with normal coloration and structure. |
| Bleached | Warning | 🟡 | Signs of bleaching detected (loss of color). Stress response indicated. |
| Dead | Critical | 🔴 | Coral appears dead (algae cover, structural collapse). |
| Any (low conf) | Uncertain | ⚠️ | Prefixed: "UNCERTAIN PREDICTION (X% < 75.0%)" |

---

## 4. Metrics Endpoint — `GET /api/metrics`

Returns a comprehensive JSON object consumed by the Validation section's tabbed benchmarks:

```json
{
  "baseline": {
    "model_info": {"accuracy": "84.91%", "total_errors": 24, "total_samples": 159, ...},
    "classification_report": [{"Class": "Healthy", "precision": 0.93, "recall": 0.93, ...}],
    "confusion_matrix_data": [[67,1,4],[8,56,8],[1,2,12]],
    "training_history_data": [{"epoch": 1, "train_acc": 0.5, "val_acc": 0.4, ...}]
  },
  "ensemble": { /* same shape, from deployment audit CSV */ },
  "architecture_comparison": { "summary": {...}, "accuracy_vs_parameters": "<b64>", ... },
  "research": { /* research phase metrics */ },
  "deployment": { /* deployment phase metrics */ }
}
```

### 4.1 Data Sources

| Block | Primary Source |
|---|---|
| `deployment` / `ensemble` | `03_Model_Evaluation/Validation_Data/02_Deployment_Phase/robust_v4_audit_results.csv` (computed live via sklearn) |
| `baseline` | `05_Baseline_Model/outputs/baseline_model/eval_summary.json` |
| `architecture_comparison` | `03_Model_Evaluation/02_Architecture_Comparison/architecture_comparison_summary.json` |
| `research` | `03_Model_Evaluation/01_Research_Phase/` and `02_Modelling/.../outputs/` |

---

## 5. Chat Endpoint — `POST /api/chat`

### 5.1 Input JSON

```json
{
  "message": "Why is this coral bleached?",
  "history": [
    {"role": "user", "content": "What does the model predict?"},
    {"role": "assistant", "content": "The model predicts Bleached with 87% confidence."}
  ],
  "predictionContext": {
    "prediction": "Bleached",
    "confidence": 87.3,
    "probabilities": {"Healthy": 5.2, "Bleached": 87.3, "Dead": 7.5},
    "uncertainty": false,
    "notes": []
  }
}
```

### 5.2 Processing

1. Sanitize inputs: trim to 1200 chars, last 6 history items, allowlisted context fields.
2. If `GEMINI_API_KEY` env var is set → call Gemini API with system prompt.
3. Otherwise → keyword-based fallback matching (`upload`, `confidence`, `grad`, `healthy`, etc.).

### 5.3 Output

```json
{
  "reply": "Bleaching occurs when coral loses its symbiotic algae...",
  "source": "gemini"
}
```

---

## 6. Simulation Endpoints (3D Grad-CAM)

### `GET /api/simulation_samples`

Returns 6 dataset images (2 per class) with 120px thumbnails for the Attention Explorer UI.

### `POST /api/simulation_inference`

Takes `{"path": "Dataset/Healthy/1.png"}`, runs real inference on BASE_MODEL, extracts
top-6 highest-activated conv channels from `top_conv` with gradient weights (`alpha_k`),
returns each as base64 texture plus the final heatmap/overlay.

---

## 7. Grad-CAM Implementation Details

```python
def compute_gradcam(model, img_array, class_idx, layer_name='top_conv', eigen_smooth=False):
    # 1. Find EfficientNet backbone inside Sequential model
    # 2. Build sub-model: efficientnet.input → target_layer.output
    # 3. Forward pass to get conv_outputs
    # 4. Wrap as tf.Variable (so GradientTape tracks it)
    # 5. Inside GradientTape:
    #      - Complete forward: BN → Activation → GAP → Dropout → Dense
    #      - Compute loss = model_outputs[:, class_idx]
    # 6. Compute gradients of loss w.r.t. conv_outputs
    # 7. Global Average Pool gradients → channel weights
    # 8. Weighted sum of activation maps → heatmap
    # 9. ReLU → normalize → resize to 224×224
```

> **Transfer note:** The two-stage forward pass (inside EfficientNet, then outer Sequential
> layers) is critical. If you change the model architecture, you must update the layer
> traversal logic.

---

## 8. Python Dependencies

```
tensorflow
numpy<2.0.0
pandas
opencv-python<4.10.0
matplotlib
flask
Pillow
flask-cors
google-genai
seaborn (imported from sklearn usage)
```
