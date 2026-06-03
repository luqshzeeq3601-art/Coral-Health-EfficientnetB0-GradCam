# Transfer Design — Coral AI React Landing Page

> **Purpose:** This folder is a self-contained transfer kit for porting the production
> Coral AI React SPA template to **any other EfficientNet-based image classification project**.
> It documents the full stack (frontend → backend → model loading → deployment) and
> includes copies of every file needed for the web interface.

## What This Template Is

The **primary production template** is a fully compiled React Single Page Application (SPA)
built with **Vite + React 19 + TypeScript + Tailwind CSS v4**. It is served by a Python
Flask backend and communicates with a TensorFlow/Keras inference engine.

| Attribute | Value |
|---|---|
| **Framework** | React 19 (compiled via Vite) |
| **Styling** | Tailwind CSS v4 + custom CSS variables |
| **Animations** | GSAP + Framer Motion |
| **Icons** | Lucide React |
| **Theme** | Dark/Light mode saved in `localStorage` |
| **Backend** | Python Flask (single `app.py`) |
| **ML Engine** | TensorFlow/Keras EfficientNet-B0 ensemble |
| **Explainability** | Grad-CAM heatmap overlays (computed server-side) |
| **Chatbot** | ReefGuide — Gemini 2.5 Flash API (with keyword fallback) |

## What's in This Folder

| File / Folder | Description |
|---|---|
| `00_TRANSFER_OVERVIEW.md` | This file — high-level summary |
| `01_BACKEND_REFERENCE.md` | Complete backend documentation: model loading, API endpoints, XAI |
| `02_FRONTEND_REFERENCE.md` | React component tree, page sections, API integration |
| `03_API_CONTRACT.md` | Exact JSON schemas for every endpoint (frontend ↔ backend) |
| `04_DEPLOYMENT.md` | Launch scripts, environment setup, Cloudflare tunnel |
| `05_TRANSFER_GUIDE.md` | **Step-by-step guide** to port this template to another project |
| `frontend/` | Complete copy of the compiled React SPA (ready to serve) |
| `backend/` | Copy of `app.py`, `requirements.txt` |
| `launch_scripts/` | Copy of `run_coral_ai.bat` and `start_coral_app.bat` |

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     User's Web Browser                          │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  React SPA (frontend/index.html)                          │  │
│  │  ├── Hero Section (animated coral video + stats)          │  │
│  │  ├── Mission Section (about the project)                  │  │
│  │  ├── Technology Stack (EfficientNet features)             │  │
│  │  ├── Model Workflow (Grad-CAM pipeline visualization)     │  │
│  │  ├── Validation (tabbed benchmarks: Basic/Ensemble/Arch)  │  │
│  │  ├── Attention Explorer (3D Grad-CAM simulation)          │  │
│  │  ├── Try Model (upload image → get prediction + heatmap)  │  │
│  │  ├── ChatBot (ReefGuide assistant)                        │  │
│  │  └── Footer                                               │  │
│  └──────────────────────┬─────────────────────────────────────┘  │
│                         │ fetch("/api/*")                        │
└─────────────────────────┼───────────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│               Flask Backend (app.py, port 5000)                 │
│                                                                 │
│  Routes:                                                        │
│    / , /coral_health  → serve frontend/index.html               │
│    /<path:filename>   → serve frontend/ assets (JS, CSS, imgs)  │
│                                                                 │
│  API Endpoints:                                                 │
│    POST /api/predict  → ML inference + Grad-CAM                 │
│    GET  /api/metrics  → benchmark data for Validation section   │
│    POST /api/chat     → Gemini chatbot / keyword fallback       │
│    GET  /api/health   → server status                           │
│    GET  /api/simulation_samples  → dataset thumbnails           │
│    POST /api/simulation_inference → 3D sim channel extraction   │
│                                                                 │
│  ML Engine:                                                     │
│    5× EfficientNet-B0 SWA models (seeds 42-46)                  │
│    Test-Time Augmentation: 2 scales × 2 flips = 4 views/model   │
│    Temperature calibration from ensemble_weights.npy             │
│    Grad-CAM via GradientTape on top_conv layer                  │
└─────────────────────────────────────────────────────────────────┘
```

## Quick Start (For This Existing Project)

```bash
# 1. Ensure Python virtualenv exists with dependencies
pip install -r 04_Web_Application/requirements.txt

# 2. Ensure model weights exist at:
#    02_Modelling/efficientnetb0_coral/models/efficientnetb0_v4robust_seed{42-46}_swa.h5

# 3. Run the application
run_coral_ai.bat
#    → Starts Flask on port 5000
#    → Polls /api/health until ready
#    → Auto-opens browser to http://localhost:5000/
```

## Key Constants (Hardcoded Across Frontend & Backend)

| Constant | Value | Location |
|---|---|---|
| `CLASS_NAMES` | `['Healthy', 'Bleached', 'Dead']` | `app.py` line 186, `api.ts` line 11 |
| `IMG_SIZE` | `224` | `app.py` line 185 |
| `CONFIDENCE_THRESHOLD` | `75.0%` | `app.py` line 1366 |
| `FOLDS` (ensemble seeds) | `[42, 43, 44, 45, 46]` | `app.py` line 187 |
| `TTA_SCALES` | `[224, 256]` | `app.py` line 1220 |
| `TEMPERATURE` default | `1.0` | `app.py` line 215 |
| Flask port | `5000` | `app.py` line 1670 |
