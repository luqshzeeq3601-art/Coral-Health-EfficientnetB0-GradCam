# Transfer Guide — Port This Template to a New Project

Step-by-step guide to reuse the Coral AI React SPA + Flask backend for a
**different EfficientNet image classification project**.

---

## Step 1: Copy the Core Files

From this `Transfer Design/` folder, copy:

| Source (in this folder) | Destination (your new project) |
|---|---|
| `frontend/` (entire directory) | `your_project/web_app/frontend/` |
| `backend/app.py` | `your_project/web_app/app.py` |
| `backend/requirements.txt` | `your_project/web_app/requirements.txt` |
| `launch_scripts/run_coral_ai.bat` | `your_project/run_app.bat` |

---

## Step 2: Update Class Names

### In `app.py` (backend)

Find (around line 186):
```python
CLASS_NAMES = ['Healthy', 'Bleached', 'Dead']
```
Replace with your classes:
```python
CLASS_NAMES = ['ClassA', 'ClassB', 'ClassC', ...]
```

### In the React source (`src/lib/api.ts`):
```typescript
export const CLASS_NAMES = ["ClassA", "ClassB", "ClassC"] as const;
```

### Update Dense layer count:
```python
# In build_model() and build_baseline_model()
Dense(3, activation='softmax', ...)   # ← Change 3 to your class count
```

---

## Step 3: Update Model Paths

### In `app.py`, find (around line 187):
```python
FOLDS = [42, 43, 44, 45, 46]
```

Replace with your seed numbers (or fewer/more models):
```python
FOLDS = [0, 1, 2, 3, 4]
```

### Update model loading directory (~line 196):
```python
PROJECT_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, '..'))
MODEL_DIR = os.path.join(PROJECT_ROOT, '02_Modelling', 'efficientnetb0_coral', 'models')
```
Change to your model directory:
```python
MODEL_DIR = os.path.join(PROJECT_ROOT, 'models', 'weights')
```

### Update model filename pattern (~line 201):
```python
model_path = os.path.join(MODEL_DIR, f'efficientnetb0_v4robust_seed{fold}_swa.h5')
```
Change to match your weight files:
```python
model_path = os.path.join(MODEL_DIR, f'my_model_seed{fold}.h5')
```

---

## Step 4: Update Status Definitions

In `app.py`, find the status mapping (~line 1366) and update for your classes:

```python
# Current:
if predicted_class == 'Healthy':
    status = {'severity': 'Good', 'icon': '🟢', 'description': '...'}
elif predicted_class == 'Bleached':
    status = {'severity': 'Warning', 'icon': '🟡', 'description': '...'}
elif predicted_class == 'Dead':
    status = {'severity': 'Critical', 'icon': '🔴', 'description': '...'}

# Change to your classes:
if predicted_class == 'ClassA':
    status = {'severity': 'Good', 'icon': '🟢', 'description': 'Your description...'}
...
```

---

## Step 5: Update the Frontend (React Source)

If you want to change text, branding, or layout, you need to rebuild:

### 5.1 Install Node.js Dependencies
```bash
cd "Landing Page Ideas/Coral Improve Design Landing Page/Coral AI Landing Page"
npm install
```

### 5.2 Files to Modify

| File | What to Change |
|---|---|
| `src/components/Hero.tsx` | Headlines, stats, video paths, project name |
| `src/components/Mission.tsx` | Project description text |
| `src/components/TechnologyStack.tsx` | Feature descriptions |
| `src/components/Validation.tsx` | Benchmark display (may need new tab logic) |
| `src/components/TryModel.tsx` | Upload instructions, result display labels |
| `src/components/ChatBot.tsx` | System prompt, quick prompts, branding |
| `src/components/Header.tsx` | Logo, navigation links |
| `src/components/Footer.tsx` | Credits, links |
| `src/lib/api.ts` | Class names, types |
| `src/index.css` | Colors, fonts |
| `public/` | Logos, favicons |

### 5.3 Rebuild
```bash
npm run build
xcopy /E /Y dist\* path\to\web_app\frontend\
```

---

## Step 6: Update Metrics Data Sources

The `/api/metrics` endpoint reads from these files. Create equivalents for your project:

| Data | Current Path | Description |
|---|---|---|
| Ensemble audit | `03_Model_Evaluation/Validation_Data/02_Deployment_Phase/robust_v4_audit_results.csv` | CSV with columns: `true_label`, `predicted_label`, `confidence`, `correct` |
| Baseline summary | `05_Baseline_Model/outputs/baseline_model/eval_summary.json` | JSON with accuracy, classification report |
| Architecture comparison | `03_Model_Evaluation/02_Architecture_Comparison/architecture_comparison_summary.json` | JSON comparison data |

Or simply remove the `/api/metrics` endpoint and Validation section if not needed.

---

## Step 7: Update the Launch Script

In `run_app.bat`, update these paths:

```batch
:: Model directory check
set "MODEL_PATH=models\weights"

:: Frontend check
if not exist "web_app\frontend\index.html" (...)

:: Launch command
"%PYTHON_EXEC%" "web_app\app.py"
```

---

## Step 8: Update Grad-CAM Layer Name

If you change the model architecture, update the target layer:

```python
# In compute_gradcam()
def compute_gradcam(model, img_array, class_idx, layer_name='top_conv', ...):
    # 'top_conv' is the last conv layer in EfficientNet-B0
    # For other architectures, change to the appropriate layer name
    # e.g., ResNet50: 'conv5_block3_3_conv'
    # e.g., VGG16: 'block5_conv3'
```

---

## Step 9: Update the Chatbot System Prompt

In `app.py`, find the chat system prompt (~line 1450):

```python
system_instruction = f"""
You are **ReefGuide**, the AI assistant for the **CoralAI** coral health
classification platform. ...
"""
```

Replace with a prompt appropriate for your domain.

---

## Step 10: Test Everything

```bash
# 1. Verify models load
python web_app/app.py
# Should see: "Total models loaded: N/N"

# 2. Test health endpoint
curl http://localhost:5000/api/health

# 3. Test prediction
curl -X POST http://localhost:5000/api/predict \
  -F "file=@test_image.jpg" \
  -F "model_type=ensemble" \
  -F "gradcam_enabled=true"

# 4. Open browser
# http://localhost:5000/
```

---

## Quick Checklist

- [ ] Copy `frontend/`, `app.py`, `requirements.txt`, `.bat` scripts
- [ ] Update `CLASS_NAMES` in `app.py` and `api.ts`
- [ ] Update `Dense(N, ...)` layer count
- [ ] Update model directory path and filename pattern
- [ ] Update model `FOLDS` list
- [ ] Update status definitions (severity, icon, description)
- [ ] Update chatbot system prompt
- [ ] Update Grad-CAM layer name (if not EfficientNet-B0)
- [ ] Update launch script paths
- [ ] Create metrics data files (or remove `/api/metrics`)
- [ ] Update React source text/branding and rebuild
- [ ] Test all endpoints
- [ ] Verify frontend loads and theme toggle works
