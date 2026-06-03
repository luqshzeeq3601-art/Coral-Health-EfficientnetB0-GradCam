# Deployment Reference — Launch Scripts & Environment

---

## 1. Environment Requirements

### Python Virtual Environment

| Path | Priority |
|---|---|
| `%USERPROFILE%\v-coral\Scripts\python.exe` | 1st (named venv) |
| `<project_root>\.venv\Scripts\python.exe` | 2nd (local venv) |

### Python Dependencies (`requirements.txt`)

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
```

Install: `pip install -r 04_Web_Application/requirements.txt`

### Optional Environment Variables

| Variable | Purpose | Default |
|---|---|---|
| `GEMINI_API_KEY` | Enables Gemini-powered chatbot | Falls back to keyword matching |
| `GEMINI_MODEL` | Override Gemini model name | `gemini-2.5-flash` |

---

## 2. `run_coral_ai.bat` — Local Demo Launch

**Location:** Project root.

### Complete Flow

```
1. cd to project root (where the .bat lives)

2. PRE-FLIGHT CHECKS:
   ├── Find Python venv (v-coral or .venv)
   ├── Check model directory exists:
   │   02_Modelling\efficientnetb0_coral\models\
   ├── Check compiled frontend exists:
   │   04_Web_Application\frontend\index.html
   └── Check curl.exe is on PATH

3. LAUNCH:
   ├── Create temporary polling script at %TEMP%\coral_poll.bat
   │   └── Polls GET http://localhost:5000/api/health every 1s
   │       └── On success (or after 90 tries) → opens browser to http://localhost:5000/
   ├── Start polling script in background
   └── Run Flask app in FOREGROUND:
       python "04_Web_Application\app.py"
       └── This blocks; the console stays open as the server

4. ON EXIT:
   └── Clean up %TEMP%\coral_poll.bat
```

### Key Details

- **Server runs in foreground** — closing the window stops it.
- **Browser opens automatically** when `/api/health` responds (not on a fixed timer).
- **Maximum wait:** 90 seconds before force-opening browser anyway.
- Flask binds to `0.0.0.0:5000` (accessible on LAN).
- `debug=False`, `use_reloader=False` — prevents double model loading.
- `threaded=True` — allows concurrent asset requests.

### What Happens at Startup (Inside `app.py`)

```
Loading V4 Robust ensemble models...
  [OK] Loaded efficientnetb0_v4robust_seed42_swa.h5
  [OK] Loaded efficientnetb0_v4robust_seed43_swa.h5
  [OK] Loaded efficientnetb0_v4robust_seed44_swa.h5
  [OK] Loaded efficientnetb0_v4robust_seed45_swa.h5
  [OK] Loaded efficientnetb0_v4robust_seed46_swa.h5
  Total models loaded: 5/5
  [OK] Loaded ensemble weights
  [OK] Loaded temperature scaling T=1.0000
  [OK] Base model loaded: standalone baseline

=======================================================
   Coral Health AI - Web Application Server
=======================================================
   Server starting at http://localhost:5000
```

---

## 3. `start_coral_app.bat` — Public Deployment (Cloudflare Tunnel)

**Location:** Project root.

### Flow

```
1. Detect Python venv (same as run_coral_ai.bat)

2. Check frontend exists:
   04_Web_Application\frontend\index.html

3. LAUNCH TWO WINDOWS:
   Window 1 "Coral App":
     cd /d "04_Web_Application"
     python app.py

   Window 2 "Coral Tunnel":
     cloudflared.exe tunnel --protocol http2 --url http://localhost:5000 run coralapp
```

### Cloudflare Tunnel Requirements

- `cloudflared.exe` installed at `C:\Program Files (x86)\cloudflared\`.
- A named tunnel `coralapp` pre-configured (via `cloudflared tunnel create coralapp`).
- DNS route configured in Cloudflare dashboard mapping hostname → tunnel.
- Protocol: HTTP/2.

---

## 4. Building the React Frontend

### When You Need to Rebuild

You only need to rebuild if you've modified the React source code.

### Steps

```bash
# 1. Navigate to React source
cd "Landing Page Ideas\Coral Improve Design Landing Page\Coral AI Landing Page"

# 2. Install dependencies (first time only)
npm install

# 3. Build production bundle
npm run build
# Output: dist/

# 4. Copy build output to Flask's frontend directory
xcopy /E /Y dist\* ..\..\..\04_Web_Application\frontend\
```

### Development Mode

```bash
# Start Vite dev server (hot reload)
npm run dev
# → Runs on http://localhost:5173
# → Proxies /api/* to http://localhost:5000 (Flask must be running)
```

---

## 5. Directory Structure Required by the Server

```
<project_root>/
├── 02_Modelling/
│   └── efficientnetb0_coral/
│       ├── models/
│       │   ├── efficientnetb0_v4robust_seed42_swa.h5
│       │   ├── efficientnetb0_v4robust_seed43_swa.h5
│       │   ├── efficientnetb0_v4robust_seed44_swa.h5
│       │   ├── efficientnetb0_v4robust_seed45_swa.h5
│       │   ├── efficientnetb0_v4robust_seed46_swa.h5
│       │   ├── ensemble_weights.npy  (optional)
│       │   └── temperature.txt       (optional)
│       └── outputs/
│           └── training_history_ensemble.png (optional)
│
├── 03_Model_Evaluation/
│   └── Validation_Data/
│       └── 02_Deployment_Phase/
│           └── robust_v4_audit_results.csv  (deployment metrics source)
│
├── 04_Web_Application/
│   ├── app.py
│   ├── requirements.txt
│   ├── frontend/          ← Compiled React SPA
│   │   ├── index.html
│   │   ├── assets/
│   │   ├── corallogo.png
│   │   └── static/video/
│   ├── static/            ← Flask static dir (used by legacy templates)
│   │   ├── css/style.css
│   │   ├── js/app.js
│   │   ├── img/
│   │   └── video/
│   └── templates/         ← Jinja HTML templates (legacy)
│
├── 05_Baseline_Model/
│   └── outputs/baseline_model/
│       ├── efficientnetb0_baseline.weights.h5
│       ├── eval_summary.json
│       └── training_history.json
│
├── Dataset/               ← Used by simulation endpoints
│   ├── Healthy/
│   ├── Bleached/
│   └── Dead/
│
├── run_coral_ai.bat
└── start_coral_app.bat
```
