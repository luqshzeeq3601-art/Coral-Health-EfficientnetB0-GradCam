# Coral Health Flutter Model Integration Plan

## Summary

The Flutter app will be developed as a separate mobile client for the existing Coral Health AI project. This repo already contains the main ML pipeline, backend API, model artifacts, baseline model work, and Grad-CAM implementation.

The recommended mobile strategy is hybrid:

- Online mode calls the existing Flask/Keras backend for canonical ensemble prediction and true Grad-CAM.
- Offline mode runs exported TFLite models inside Flutter for local prediction.
- Auto mode uses the backend when available and falls back to offline inference when the device has no connection.

## Current Project Understanding

The canonical backend is `04_Web_Application/app.py`.

The production model is a 5-seed EfficientNetB0 SWA ensemble:

- `efficientnetb0_v4robust_seed42_swa.h5`
- `efficientnetb0_v4robust_seed43_swa.h5`
- `efficientnetb0_v4robust_seed44_swa.h5`
- `efficientnetb0_v4robust_seed45_swa.h5`
- `efficientnetb0_v4robust_seed46_swa.h5`

These files are stored in:

```text
02_Modelling/efficientnetb0_coral/models/
```

The model constants are:

- Image size: `224x224`
- Input color order: RGB
- Input dtype/range: `float32`, `0-255`
- Classes: `Healthy`, `Bleached`, `Dead`
- Ensemble seeds: `42, 43, 44, 45, 46`
- Confidence threshold: `75.0%`
- Temperature scaling file: `temperature.txt`

The current backend uses uniform ensemble averaging unless `ensemble_weights.npy` is added later.

## Online Flutter Integration

Flutter should call the backend endpoint:

```text
POST /api/predict
```

Request format:

```text
multipart/form-data
file=<image>
model_type=ensemble|base
gradcam_enabled=true|false
```

Response fields to map into Flutter:

- `prediction`
- `confidence`
- `probabilities`
- `individual_models`
- `gradcam.heatmap`
- `gradcam.overlay`
- `original_image`
- `status`
- `uncertainty`
- `notes`
- `model_used`

Online mode is the source of truth because it preserves:

- 5-model ensemble loading
- test-time augmentation
- temperature scaling
- model disagreement notes
- true Grad-CAM using Keras `GradientTape`

## Offline Flutter Integration

Offline mode should use TFLite exports generated from the existing Keras models.

Minimum offline option:

- Package only seed42 TFLite for a smaller app and faster inference.
- Label result as offline/local prediction.

Full offline option:

- Package all five seed TFLite models.
- Run each model locally.
- Average probabilities.
- Apply the same temperature scaling value from `temperature.txt`.

Offline preprocessing must match the backend:

1. Decode camera/gallery image.
2. Convert to RGB.
3. Resize to `224x224`.
4. Convert to `float32`.
5. Keep pixel range as `0-255`.
6. Feed tensor shape `[1, 224, 224, 3]`.

Offline base model support should wait until the baseline weight path is standardized. The backend expects:

```text
05_Baseline_Model/outputs/baseline_model/efficientnetb0_baseline.weights.h5
```

but the available baseline weights were found under:

```text
05_Baseline_Model/models/efficientnetb0_baseline.weights.h5
```

## Grad-CAM Strategy

Online Grad-CAM:

- Use backend `gradcam.overlay` and `gradcam.heatmap`.
- Treat this as the canonical explanation.

Offline explanation:

- Do not claim full Grad-CAM parity unless gradients are available.
- Flutter/TFLite does not naturally support Keras `GradientTape`.
- If offline heatmaps are required, export a companion activation-output TFLite model and generate an approximate CAM-style heatmap.
- Label this clearly as `Offline Heatmap` or `Approximate CAM`.

Recommended behavior:

- Online: show `Grad-CAM`.
- Offline: show prediction only for v1.
- Future offline v2: add approximate heatmap after TFLite activation export is validated.

## Flutter Architecture To Add Later

Suggested Dart layers:

- `PredictionRepository`
- `OnlinePredictionService`
- `OfflinePredictionService`
- `ModelAssetManager`
- `ImagePreprocessor`
- `PredictionResult`
- `ModelRuntimeMode`
- `ModelType`

Suggested runtime modes:

```dart
enum ModelRuntimeMode { online, offline, auto }
enum ModelType { ensemble, base }
```

Suggested result shape:

```dart
class PredictionResult {
  final String prediction;
  final double confidence;
  final Map<String, double> probabilities;
  final String modelUsed;
  final bool uncertainty;
  final List<String> notes;
  final String? heatmapBase64;
  final String? overlayBase64;
  final bool isOffline;
}
```

## Android And iOS Notes

Android:

- Use `tflite_flutter`.
- Store models in Flutter assets.
- Add camera and gallery permissions.
- Test on a real device because camera and TFLite behavior may differ from emulator.

iOS:

- Use the same Flutter TFLite package if supported by the chosen plugin version.
- Add camera/photo permissions to `Info.plist`.
- Verify model asset loading and memory usage on-device.

## Test Plan

Backend tests:

- Upload one sample image per class.
- Test `model_type=ensemble`.
- Test `model_type=base` after baseline path is fixed.
- Test `gradcam_enabled=true`.
- Test `gradcam_enabled=false`.

Flutter online tests:

- Successful prediction.
- Backend unavailable.
- Timeout.
- Invalid image.
- Grad-CAM unavailable.

Flutter offline tests:

- TFLite model loads on Android.
- TFLite model loads on iOS.
- Preprocessing output matches Python assumptions.
- Offline class prediction matches Keras for known samples.
- Offline ensemble probability averaging matches Python within tolerance.

Hybrid tests:

- Auto mode uses online when backend is reachable.
- Auto mode falls back to offline when backend is unreachable.
- App can refresh an offline result with online Grad-CAM when the network returns.

## Implementation Order

1. Bring the real Flutter project folder into or beside `09_MobileApps`.
2. Standardize model artifact paths, especially the baseline model path.
3. Keep the existing Flask backend as the online source of truth.
4. Add Flutter online prediction service using `/api/predict`.
5. Export seed42 TFLite and validate local prediction.
6. Add offline prediction UI state.
7. Optionally package all five TFLite seed models for offline ensemble.
8. Add approximate offline heatmap only after prediction parity is proven.

## Assumptions

- The Flutter project currently lives outside this repo folder.
- The mobile app targets Android and iOS.
- Online backend inference is preferred for final/demo-quality results.
- Offline mode is primarily for availability, not exact Grad-CAM parity.
- True Grad-CAM remains a backend feature unless a separate mobile explanation pipeline is validated.
