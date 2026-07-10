<p align="center">
  <img src="04_Web_Application/frontend/corallogo.png" alt="Coral Health AI Logo" width="120"/>
</p>

<h1 align="center">🪸 Coral Reef Health Assessment via CNN-Based Image Analysis</h1>

<p align="center">
  <strong>EfficientNet-B0 Ensemble · Grad-CAM Explainability · Flask Web App · Flutter Mobile App</strong>
</p>

<p align="center">
  <a href="#-quick-start"><img src="https://img.shields.io/badge/Quick_Start-blue?style=for-the-badge" alt="Quick Start"/></a>
  <a href="#-project-structure"><img src="https://img.shields.io/badge/Project_Structure-green?style=for-the-badge" alt="Project Structure"/></a>
  <a href="#-tech-stack"><img src="https://img.shields.io/badge/Tech_Stack-orange?style=for-the-badge" alt="Tech Stack"/></a>
  <a href="#-model-performance"><img src="https://img.shields.io/badge/Model_Performance-red?style=for-the-badge" alt="Model Performance"/></a>
</p>

---

## 📖 About

This is a **Final Year Project (FYP)** that uses deep learning to classify coral reef health conditions from underwater images. The system classifies coral images into three categories:

| Class | Description |
|---|---|
| 🟢 **Healthy** | Living coral with natural coloration |
| 🟡 **Bleached** | Coral undergoing bleaching stress |
| 🔴 **Dead** | Dead coral covered in algae or sediment |

The project provides **Explainable AI (XAI)** through Grad-CAM heatmap overlays, allowing users to visualize *why* the model made its prediction — making it trustworthy and interpretable for marine researchers.

---

## ✨ Key Features

- **5-Seed EfficientNet-B0 Ensemble** — Robust predictions using Stochastic Weight Averaging (SWA) across 5 model seeds
- **Test-Time Augmentation (TTA)** — 2 scales × 2 flips = 4 inference views per model for improved accuracy
- **Grad-CAM Heatmaps** — Visual explanations highlighting which image regions influenced the prediction
- **Temperature Calibration** — Calibrated confidence scores for reliable probability estimates
- **Web Application** — React SPA served via Flask with real-time prediction and chatbot assistant
- **Mobile Application** — Flutter-based cross-platform app for on-field coral assessment
- **ReefGuide Chatbot** — AI assistant powered by Ollama (Qwen2.5:3b) with a rule-based fallback for coral health guidance

---

## 🚀 Quick Start

### Prerequisites

- **Python 3.10+** with pip
- **Ollama** (optional, for local AI chatbot support)
  - Install Ollama from [ollama.com](https://ollama.com) and run: `ollama pull qwen2.5:3b`
- **Node.js 18+** (optional, only if rebuilding the React frontend from external source)

### Installation & Launch

```bash
# 1. Clone the repository
git clone https://github.com/luqshzeeq3601-art/Coral-Health-EfficientnetB0-GradCam.git
cd Coral-Health-EfficientnetB0-GradCam

# 2. Create a virtual environment
python -m venv .venv

# 3. Activate the virtual environment
# Windows:
.venv\Scripts\activate
# macOS/Linux:
source .venv/bin/activate

# 4. Install dependencies
pip install -r 04_Web_Application/requirements.txt

# 5. (Optional) Start Ollama for Chatbot
# Ensure Ollama is running and has downloaded the model:
# ollama run qwen2.5:3b

# 6. Launch the web application
python 04_Web_Application/app.py
# → Opens at http://localhost:5000
```

**Windows shortcut:** Double-click `run_coral_ai.bat` in the project root — it auto-detects Python, checks for the built frontend, starts the Flask server, and automatically opens your browser.

> [!NOTE]
> The React frontend is pre-built and served directly from `04_Web_Application/frontend/`. You do **not** need to install Node.js or rebuild the frontend to run the application.

### Public Deployment via Cloudflare Tunnel
For staging or public sharing, the repository includes configuration files for a Cloudflare Tunnel:
1. Ensure `cloudflared` is installed on your system.
2. Configure your domain mappings in [cloudflared-coral.yml](file:///c:/Users/ZeeqRyz/Desktop/Coral%20Health%20AI/BASEPROJECT/cloudflared-coral.yml).
3. Double-click [start_coral_app.bat](file:///c:/Users/ZeeqRyz/Desktop/Coral%20Health%20AI/BASEPROJECT/start_coral_app.bat) to launch the Flask app and the tunnel concurrently.

---

## 📁 Project Structure

```
Coral-Health-EfficientnetB0-GradCam/
│
├── 02_Modelling/                    # Model training scripts & weights
│   ├── efficientnetb0_coral/        #   Production model (V4 Robust Ensemble)
│   ├── convnexttiny_coral/          #   Architecture comparison model
│   └── resnet50_coral/              #   Architecture comparison model
│
├── 03_Model_Evaluation/             # Evaluation & benchmarking
│   ├── 01_EfficientNetB0_Evaluation/
│   ├── 02_Architecture_Comparison/
│   ├── Ablation_TTA_MultiSeed/      #   Ablation study results
│   └── Efficientnet base vs Ensemble/
│
├── 04_Web_Application/              # Flask backend + React frontend
│   ├── app.py                       #   Main Flask server (inference + API)
│   ├── frontend/                    #   Compiled React SPA
│   ├── requirements.txt             #   Python dependencies
│   └── static/                      #   Legacy static assets
│
├── 05_Baseline_Model/               # Single-model baseline for comparison
│
├── 06_XAI_Decision_Comparison/      # Explainable AI analysis tools
│
├── 08_Upex_Coral/                   # UPEX poster & presentation materials
│
├── 09_MobileApps/                   # Flutter mobile application
│   └── Coral Mobile - Codex/       #   Flutter project source
│
├── FYP_Planning/                    # Gantt charts & milestone tracking
├── Fyp_Report/                      # Report chapters & viva materials
│
├── run_coral_ai.bat                 # One-click local launcher (Windows)
├── start_coral_app.bat              # Public deployment via Cloudflare Tunnel
└── README.md                        # This file
```

---

## 🛠 Tech Stack

### Machine Learning & AI

| Technology | Purpose |
|---|---|
| TensorFlow / Keras | Deep learning framework |
| EfficientNet-B0 | CNN backbone architecture |
| Stochastic Weight Averaging (SWA) | Model weight stabilization |
| Grad-CAM | Explainable AI heatmaps |
| Ollama / Qwen2.5:3b | AI chatbot (ReefGuide) with Python fallback |

### Web Application

| Technology | Purpose |
|---|---|
| Flask | Python backend server |
| React 19 + TypeScript | Frontend SPA |
| Vite | Build tool |
| Tailwind CSS v4 | Styling |
| GSAP + Framer Motion | Animations |

### Mobile Application

| Technology | Purpose |
|---|---|
| Flutter / Dart | Cross-platform mobile framework |
| TFLite | On-device inference |

---

## 📊 Model Performance

| Metric | Value |
|---|---|
| **Architecture** | EfficientNet-B0 (5-seed SWA ensemble) |
| **Test Accuracy** | **98.11%** (224×224, single-scale ensemble) |
| **Input Size** | 224 × 224 pixels |
| **Classes** | Healthy, Bleached, Dead |
| **Ensemble Seeds** | 42, 43, 44, 45, 46 |
| **TTA Protocol** | 2 scales (224, 256) × 2 flips = 4 views/model |
| **Temperature Calibration** | T = 0.441 |

---

## 🌐 API Endpoints

The Flask backend exposes the following REST API:

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/predict` | Upload an image for classification + Grad-CAM |
| `GET` | `/api/metrics` | Retrieve benchmark data for the Validation section |
| `POST` | `/api/chat` | Send a message to the ReefGuide chatbot |
| `GET` | `/api/health` | Server health check |
| `GET` | `/api/simulation_samples` | Dataset sample thumbnails |
| `POST` | `/api/simulation_inference` | 3D simulation channel extraction |

---

## 🏗 Architecture

```
┌──────────────────────────────────────────┐
│          User's Web Browser              │
│  ┌────────────────────────────────────┐  │
│  │     React SPA (frontend/)          │  │
│  │  ├── Hero + Animated Stats         │  │
│  │  ├── Model Workflow Visualization  │  │
│  │  ├── Validation Benchmarks         │  │
│  │  ├── Try Model (Upload → Predict)  │  │
│  │  ├── ReefGuide Chatbot             │  │
│  │  └── Mobile App Showcase           │  │
│  └──────────────┬─────────────────────┘  │
│                 │ fetch("/api/*")         │
└─────────────────┼────────────────────────┘
                  ▼
┌──────────────────────────────────────────┐
│      Flask Backend (app.py:5000)         │
│                                          │
│  5× EfficientNet-B0 SWA Ensemble        │
│  TTA: 2 scales × 2 flips = 4 views      │
│  Grad-CAM via GradientTape              │
│  Temperature Calibration (T=0.441)       │
└──────────────────────────────────────────┘
```

---

## 👤 Author

**Muhammad Luqman Haziq Bin Mohamad Lofi**
- 🎓 Student, Computer Engineering — UniMAP
- 📧 s221022249@studentmail.unimap.edu.my
- 🔗 [GitHub Profile](https://github.com/luqshzeeq3601-art)

---

## 📝 License

This project is developed as part of a Final Year Project (FYP) at Universiti Malaysia Perlis (UniMAP). All rights reserved.
