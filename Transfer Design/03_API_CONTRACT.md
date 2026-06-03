# API Contract — Frontend ↔ Backend JSON Schemas

Every endpoint's exact request and response schema. The frontend and backend must
agree on these shapes. **All image data crosses the wire as raw base64 PNG strings**
(no `data:` prefix; the frontend adds it).

---

## `GET /api/health`

**Purpose:** Server readiness check used by `run_coral_ai.bat` polling loop.

**Response:**
```json
{
  "status": "running",
  "models_loaded": 5,
  "folds_requested": [42, 43, 44, 45, 46],
  "folds_loaded": [42, 43, 44, 45, 46],
  "temperature": 1.0,
  "has_ensemble_weights": true
}
```

---

## `POST /api/predict`

**Purpose:** Core inference endpoint. Upload a coral image, get prediction + Grad-CAM.

### Request (multipart/form-data)

| Field | Type | Required | Values |
|---|---|---|---|
| `file` (or `image`) | File | ✅ | JPG/PNG image |
| `model_type` | String | ❌ | `"ensemble"` (default) or `"base"` |
| `gradcam_enabled` | String | ❌ | `"true"` (default) or `"false"` |

### Response (200 OK)

```json
{
  "prediction": "Healthy | Bleached | Dead",
  "confidence": 98.73,
  "probabilities": {
    "Healthy": 98.73,
    "Bleached": 0.82,
    "Dead": 0.45
  },
  "individual_models": [
    {
      "fold": 42,
      "prediction": "Healthy",
      "confidence": 99.12,
      "probabilities": {"Healthy": 99.12, "Bleached": 0.55, "Dead": 0.33}
    }
  ],
  "gradcam": {
    "heatmap": "<raw base64 PNG>",
    "overlay": "<raw base64 PNG>"
  },
  "original_image": "<raw base64 PNG>",
  "status": {
    "severity": "Good | Warning | Critical | Uncertain",
    "icon": "🟢 | 🟡 | 🔴",
    "description": "Human-readable explanation",
    "recommendation": "Human-readable next step"
  },
  "uncertainty": false,
  "notes": ["Model disagreement detected: [...]"],
  "model_used": "EfficientNetB0 SWA Ensemble (5-seed)",
  "debug_preprocessing": [{"fold": 42, "prediction": "Healthy", "confidence": 99.1}]
}
```

### Response (Error)

```json
{"error": "No file uploaded"}           // 400
{"error": "No models loaded..."}        // 500
{"error": "Could not decode image"}     // 400
```

### Field Notes

| Field | Type | Notes |
|---|---|---|
| `prediction` | String | One of: `"Healthy"`, `"Bleached"`, `"Dead"` |
| `confidence` | Float | Percent (0-100), highest class probability |
| `probabilities` | Object | All 3 classes as percent (0-100), sum ≈ 100 |
| `individual_models` | Array | Only populated for ensemble mode |
| `gradcam` | Object\|null | null if `gradcam_enabled=false`; may contain `error` string |
| `original_image` | String | Base64 PNG of the preprocessed 224×224 input |
| `uncertainty` | Boolean | true if confidence < 75.0% |
| `notes` | Array | Warning strings (low confidence, model disagreement) |
| `model_used` | String | Human-readable model description |

---

## `GET /api/metrics`

**Purpose:** Benchmark data for the Validation section's tabbed UI.

### Response (200 OK)

```json
{
  "baseline": {
    "model_info": {
      "accuracy": "84.91%",
      "total_errors": 24,
      "total_samples": 159,
      "total_models": 1,
      "inference_time_ms": 9.63,
      "total_params_display": "4.05M"
    },
    "classification_report": [
      {"Class": "Healthy", "precision": 0.93, "recall": 0.93, "f1-score": 0.93, "support": 72},
      {"Class": "Bleached", "precision": 0.78, "recall": 0.78, "f1-score": 0.78, "support": 72},
      {"Class": "Dead", "precision": 0.80, "recall": 0.80, "f1-score": 0.80, "support": 15},
      {"Class": "macro avg", "precision": 0.84, "recall": 0.84, "f1-score": 0.84, "support": 159}
    ],
    "confusion_matrix_data": [[67,1,4],[8,56,8],[1,2,12]],
    "training_history_data": [
      {"epoch": 1, "train_acc": 0.5, "val_acc": 0.4, "train_loss": 1.2, "val_loss": 1.5}
    ],
    "confusion_matrix": "<base64 PNG image>"
  },
  "ensemble": {
    "model_info": {
      "accuracy": "98.11%",
      "total_errors": 3,
      "total_samples": 159,
      "total_models": 5,
      "inference_time_ms": 10.38,
      "total_params_display": "20.27M"
    },
    "classification_report": [
      {"Class": "Healthy", "precision": 0.9861, "recall": 1.0, "f1-score": 0.993, "support": 72}
    ],
    "confusion_matrix_data": [[72,0,0],[2,70,0],[0,1,14]],
    "training_history_data": [],
    "confusion_matrix": "<base64 PNG image>",
    "report_heatmap": "<base64 PNG image>",
    "training_history": "<base64 PNG image>",
    "summary_text": "Deployment Audit (Robust-V4)\nAccuracy: 98.11%\n..."
  },
  "architecture_comparison": {
    "summary": {
      "models": [
        {"model": "EfficientNetB0", "model_type": "Ensemble", "parameters_m": 20.27, "accuracy": 0.9811, "macro_f1": 0.98, "total_errors": 3}
      ]
    },
    "accuracy_vs_parameters": "<base64 PNG>",
    "per_class_f1": "<base64 PNG>",
    "confusion_matrix_three_models": "<base64 PNG>"
  },
  "research": { "...same shape as baseline/ensemble..." },
  "deployment": { "...same shape..." }
}
```

### Important: Precision/Recall/F1 Value Ranges

> **Backend returns `precision`, `recall`, `f1-score` as fractions (0.0 – 1.0).**
> The frontend multiplies by 100 when displaying if `value <= 1`.

---

## `POST /api/chat`

**Purpose:** ReefGuide chatbot assistant.

### Request (JSON)

```json
{
  "message": "What does bleaching mean?",
  "history": [
    {"role": "user", "content": "..."},
    {"role": "assistant", "content": "..."}
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

### Response (200 OK)

```json
{
  "reply": "Bleaching occurs when coral expels its symbiotic algae...",
  "source": "gemini"
}
```

| Field | Values |
|---|---|
| `source` | `"gemini"` (API key present) or `"fallback"` (keyword matching) |

### Server-Side Sanitization

- `message`: trimmed to 1200 chars.
- `history`: last 6 items, each content trimmed to 600 chars.
- `predictionContext`: only `prediction`, `confidence`, `probabilities`, `uncertainty`, `notes` kept.

---

## `GET /api/simulation_samples`

**Purpose:** Provide dataset sample thumbnails for the Attention Explorer.

### Response

```json
{
  "samples": [
    {
      "id": "healthy_sample_1",
      "path": "Dataset/Healthy/1.png",
      "class": "Healthy",
      "name": "Healthy Coral Sample #1",
      "filename": "1.png",
      "thumbnail_b64": "<base64 PNG 120px>"
    }
  ]
}
```

---

## `POST /api/simulation_inference`

**Purpose:** Run real inference on a dataset image and extract conv channel activations.

### Request (JSON)

```json
{"path": "Dataset/Healthy/1.png"}
```

### Response

```json
{
  "path": "Dataset/Healthy/1.png",
  "prediction": "Healthy",
  "confidence": 99.5,
  "probabilities": {"Healthy": 99.5, "Bleached": 0.3, "Dead": 0.2},
  "inference_time_ms": 45.2,
  "input_image_b64": "<base64 PNG>",
  "heatmap_base64": "<base64 PNG>",
  "overlay_base64": "<base64 PNG>",
  "channels": [
    {
      "channel_index": 1024,
      "rank": 1,
      "activation_mean": 3.47,
      "alpha_k": 0.82,
      "texture_base64": "<base64 PNG 224×224 grayscale>"
    }
  ]
}
```
