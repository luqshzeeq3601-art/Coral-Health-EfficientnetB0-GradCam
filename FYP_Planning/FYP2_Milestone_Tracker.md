# FYP2 Milestone Tracker
## Coral Reef Health Assessment via CNN-based Image Analysis

---

## 🎯 Project Objective

Develop and deploy a **production-ready deep learning system** for automated coral reef health classification (Healthy / Bleached / Dead) achieving **≥98% accuracy** with explainable AI (Grad-CAM).

---

## 📊 Model Journey — From Scratch to 98.11%

### Stage 1: Data Foundation
```
📁 Dataset: 795 coral reef images
├── Healthy:  ~45% (majority class)
├── Bleached: ~45% (minority class)
└── Dead:     ~10% (rare class — critical for oversampling)

🔧 Preprocessing: OpenCV → BGR→RGB → Resize 224×224
📊 Split: Deterministic (split_info_v3.json)
   ├── Train: ~508 images
   ├── Validation: ~128 images
   └── Test: 159 images (held-out)
```

### Stage 2: Model Architecture Selection
```
🧠 Selected: EfficientNetB0 (ImageNet pretrained)
   ├── Reason: Best accuracy/parameter efficiency trade-off
   ├── Parameters: ~5.3M (compact for embedded deployment)
   └── Input: 224×224×3 RGB images

🏗️ Model Head:
   GlobalAveragePooling2D → Dense(3, softmax)
```

### Stage 3: Training Optimization
```
⚡ Technique Stack:
   ├── Transfer Learning (ImageNet → Coral domain)
   ├── Hard-Example Oversampling (×20 for Bleached/Dead)
   ├── Stochastic Weight Averaging (SWA)
   │   └── 5-seed ensemble (seeds 42, 43, 44, 45, 46)
   ├── Multi-Scale TTA (224 + 256, original + H-flip)
   └── Temperature Scaling (T = 0.441)
```

### Stage 4: Results Achieved
```
🏆 FINAL RESULTS (V4 Robust — SWA + TTA Ensemble):

              Precision    Recall    F1-Score    Support
   Healthy       0.97       1.00       0.99        72
   Bleached      0.99       0.97       0.98        72
   Dead          1.00       0.93       0.97        15

   ══════════════════════════════════════════════════════
   Overall Accuracy:     98.11%  (156/159 correct)
   Macro Average:        0.99 P / 0.97 R / 0.98 F1
   Weighted Average:     0.98 P / 0.98 R / 0.98 F1
```

### Stage 5: Explainability (XAI)
```
🔍 Grad-CAM Visualization:
   ├── Method: Gradient-weighted Class Activation Mapping
   ├── Colormap: JET (Blue → Green → Yellow → Red)
   ├── Blue = Low attention | Red = High attention
   └── Validates model focuses on biologically relevant features
```

### Stage 6: Web Deployment
```
🌐 Coral Health AI Web Application:
   ├── Backend: Flask (Python)
   ├── Frontend: HTML/CSS/JS (design8.html)
   ├── Features:
   │   ├── Drag-and-drop image upload
   │   ├── Real-time classification (Healthy/Bleached/Dead)
   │   ├── Confidence score with temperature calibration
   │   └── Grad-CAM overlay visualization
   └── Launcher: run_coral_ai.bat (one-click start)
```

---

## 📅 FYP2 Important Dates

| Week | Date Range | Event | Status |
|------|-----------|-------|--------|
| W1 | 16–22 Mar 2026 | FYP2 Briefing | ✅ Done |
| W2 | 23–29 Mar 2026 | Dataset & Environment Setup | ✅ Done |
| W4 | 06–12 Apr 2026 | Talk 1: Introduction & Plagiarism | ✅ Done |
| W5 | 20–26 Apr 2026 | Talk 2: Analysis of Result & Discussion | ✅ Done |
| W6 | 27 Apr–03 May 2026 | Talk 3: ChatGPT & AI Tools | ✅ Done |
| **W7** | **04–10 May 2026** | **Progress Report 1 Submission** | ✅ Done |
| W11 | 25–31 May 2026 | Semester Break | ✅ Done |
| **W12** | **08–14 Jun 2026** | **Progress Report 2 Submission** / Talk 4 | ✅ Done |
| **W14** | **22–28 Jun 2026** | **Full Report Deadline (26 Jun)** | 🟡 In Progress |
| **W15** | **29 Jun–05 Jul 2026** | **🎓 Viva Presentation** | ⬜ Upcoming |
| **W16** | **06–12 Jul 2026** | **Final Report & TOC Deadline (12 Jul)** | ⬜ Upcoming |

---

## 🛠️ Technical Stack

| Component | Technology |
|-----------|-----------|
| Language | Python 3.x |
| Deep Learning | TensorFlow / Keras |
| Model | EfficientNetB0 (ImageNet) |
| Ensemble | 5-seed SWA |
| Inference | Multi-Scale TTA |
| Calibration | Temperature Scaling |
| XAI | Grad-CAM (JET colormap) |
| Backend | Flask |
| Frontend | HTML/CSS/JavaScript |
| Preprocessing | OpenCV |

---

*Project: Coral Reef Health Assessment via Convolutional Neural Network-based Image Analysis*  
*Supervisor: Assoc. Prof. Ts. Dr. Yasmin Yacob*  
*Last Updated: 24 June 2026*
