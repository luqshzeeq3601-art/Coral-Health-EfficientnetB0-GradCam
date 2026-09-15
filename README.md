<p align="center">
  <img src="04_Web_Application/frontend/corallogo.png" alt="Coral Health AI Logo" width="120"/>
</p>

<h1 align="center">🪸 Coral Reef Health Assessment via CNN-Based Image Analysis</h1>

<p align="center">
  <strong>EfficientNet-B0 Ensemble · Grad-CAM Explainability · Flask Web App</strong>
</p>

<p align="center">
  <a href="#-why-this-matters"><img src="https://img.shields.io/badge/Why_This_Matters-teal?style=for-the-badge" alt="Why This Matters"/></a>
  <a href="#-quick-start"><img src="https://img.shields.io/badge/Quick_Start-blue?style=for-the-badge" alt="Quick Start"/></a>
  <a href="#-model-performance"><img src="https://img.shields.io/badge/Model_Performance-red?style=for-the-badge" alt="Model Performance"/></a>
  <a href="#-tech-stack"><img src="https://img.shields.io/badge/Tech_Stack-orange?style=for-the-badge" alt="Tech Stack"/></a>
</p>

---

## 🌍 Why This Matters

**Coral reefs are dying.** Over 50% of the world's coral reefs have been lost in the last 30 years due to climate change, ocean acidification, and human activity. Monitoring reef health is critical — but traditional methods require marine biologists to manually inspect thousands of underwater images, which is **slow, expensive, and subjective**.

This project solves that by using **AI to automatically classify coral health** from underwater images in seconds — with visual explanations of *why* each decision was made.

### The Problem

| Challenge | Traditional Method | This Solution |
|---|---|---|
| **Speed** | Hours to manually review survey images | Seconds per image, real-time results |
| **Cost** | Requires trained marine biologists on-site | Anyone with a browser can use the web app |
| **Consistency** | Subjective — varies between experts | 98.11% accuracy, reproducible results |
| **Transparency** | Expert says "it's bleached" — no visual proof | Grad-CAM heatmap shows *exactly* what the AI focused on |
| **Scalability** | One expert, one reef at a time | Process entire reef survey datasets at scale |

---

## 🎯 Who Benefits

### 🔬 Marine Researchers & Conservation Organizations
- **Rapid reef health surveys** — process underwater camera footage at scale instead of manual review
- **Standardized assessments** — consistent classification across different survey sites and time periods
- **Visual evidence** — Grad-CAM heatmaps provide auditable proof for conservation reports and funding proposals

### 🏛 Government & Environmental Agencies
- **Policy-driven monitoring** — track reef degradation over time with quantifiable data
- **Early warning system** — detect bleaching events early before they become irreversible
- **Cost reduction** — reduce dependency on expensive field expeditions for routine monitoring

### 🎓 Education & Public Awareness
- **Interactive learning tool** — the web app lets students and the public upload coral images and see AI analysis in real-time
- **ReefGuide Chatbot** — an AI assistant that answers questions about coral health, bleaching causes, and conservation
- **Open research** — methodology and evaluation are fully documented for academic use

### 🏭 Aquaculture & Dive Tourism Industry
- **Reef condition reporting** — dive operators can monitor and report reef health at their sites
- **Sustainable tourism** — data-driven evidence to support marine protected area management

---

## 📖 What This Project Does

An AI-powered system that classifies underwater coral images into three health categories:

| Class | Description | What It Looks Like |
|---|---|---|
| 🟢 **Healthy** | Living coral with natural coloration | Vibrant colors, visible polyps |
| 🟡 **Bleached** | Coral undergoing thermal stress | White/pale appearance, loss of zooxanthellae |
| 🔴 **Dead** | Dead coral structure | Covered in algae, sediment, or eroded skeleton |

The system doesn't just classify — it **explains its reasoning** through Grad-CAM heatmaps, highlighting which regions of the image influenced the prediction. This makes the AI trustworthy and interpretable, not a black box.

---

## ✨ Key Features

- **98.11% Test Accuracy** — 5-seed EfficientNet-B0 ensemble with Stochastic Weight Averaging (SWA)
- **Test-Time Augmentation (TTA)** — 2 scales × 2 flips = 4 inference views per model for robust predictions
- **Grad-CAM Heatmaps** — visual explanations showing *which coral regions* influenced each classification
- **Temperature Calibration** — calibrated confidence scores so probabilities mean what they say
- **Web Application** — upload an image and get results instantly via a modern React + Flask app
- **ReefGuide Chatbot** — AI assistant (Ollama/Qwen2.5:3b) with rule-based fallback for coral health guidance

---

## 🚀 Quick Start

### Prerequisites

- **Python 3.10+** with pip
- **Ollama** (optional, for local AI chatbot support)
  - Install Ollama from [ollama.com](https://ollama.com) and run: `ollama pull qwen2.5:3b`

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

**Windows shortcut:** Double-click `run_coral_ai.bat` in the project root — it auto-detects Python, starts the Flask server, and opens your browser automatically.

> [!NOTE]
> The React frontend is pre-built and served directly from `04_Web_Application/frontend/`. You do **not** need to install Node.js or rebuild the frontend to run the application.

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

### Why These Design Choices?

| Decision | Reasoning |
|---|---|
| **EfficientNet-B0** over larger models | Best accuracy-to-compute ratio — deployable on standard hardware without GPU |
| **5-seed ensemble** | Reduces prediction variance; ablation study confirmed diminishing returns beyond 5 |
| **SWA** | Smoother loss landscape → better generalization than vanilla SGD |
| **Grad-CAM** | Researchers need to *trust* AI decisions — visual explanations enable that |
| **Temperature calibration** | Raw softmax outputs are overconfident; calibration makes "90% confident" actually mean 90% |

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

---

## 🌐 API Endpoints

The Flask backend exposes a REST API that can be integrated into other tools and pipelines:

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
│  │  └── ReefGuide Chatbot             │  │
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
├── FYP_Planning/                    # Gantt charts & milestone tracking
│
├── run_coral_ai.bat                 # One-click local launcher (Windows)
└── README.md                        # This file
```

---

## 🤝 Contributing

Contributions are welcome. If you're working in marine conservation, coral biology, or AI for environmental science, feel free to open an issue or submit a pull request.

Potential areas for contribution:
- Additional coral health categories (e.g., diseased, recovering)
- Support for video/frame-by-frame analysis
- Integration with underwater drone systems
- Multi-species coral identification
- Dataset expansion with new reef survey data

---

## 👤 Author

**Muhammad Luqman Haziq Bin Mohamad Lofi**
- 🎓 Computer Engineering — Universiti Malaysia Perlis (UniMAP)
- 🔗 [GitHub Profile](https://github.com/luqshzeeq3601-art)

---

## 📝 License

This project was developed as academic research at Universiti Malaysia Perlis (UniMAP). All rights reserved.
