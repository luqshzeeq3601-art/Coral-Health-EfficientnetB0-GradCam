# FYP2 Weekly Progress Plan
## Coral Reef Health Assessment via Convolutional Neural Network-based Image Analysis

**Student:** [Your Name]  
**Supervisor:** Assoc. Prof. Ts. Dr. Yasmin Yacob  
**Semester:** FYP 2 (March 2026 – July 2026)

---

## Project Goal

To develop and deploy a **production-ready CNN-based system** (EfficientNetB0 + SWA + TTA) that classifies coral reef images into **Healthy**, **Bleached**, and **Dead** categories with **≥98% accuracy**, complete with a web application featuring Grad-CAM explainability.

---

## Phase Overview

| Phase | Weeks | Focus Area |
|-------|-------|------------|
| **Phase 1** — Foundation & Review | Week 1–2 | Briefing, FYP1 review, environment setup |
| **Phase 2** — Model Development | Week 3–6 | Data pipeline, model training, optimization |
| **Phase 3** — Model Evaluation & XAI | Week 7–10 | Testing, Grad-CAM, performance analysis |
| **Phase 4** — Web Application & Integration | Week 10–13 | Flask app, UI/UX, deployment |
| **Phase 5** — Report Writing & Submission | Week 13–17 | Documentation, viva preparation, final submission |

---

## Week-by-Week Breakdown

### 📅 WEEK 1 — 16–22 March 2026
**Theme: FYP2 Briefing & Project Re-orientation**

| Item | Details |
|------|---------|
| **Activities** | • Attend FYP2 briefing session |
|                | • Review FYP1 proposal & supervisor feedback |
|                | • Re-familiarize with project scope and objectives |
|                | • Set up development environment (Python 3.x, TensorFlow/Keras, CUDA) |
| **Deliverables** | ✅ Updated project plan and timeline |
|                  | ✅ Environment setup confirmed (GPU, dependencies) |
| **Status** | 🟢 Completed |

---

### 📅 WEEK 2 — 23–29 March 2026
**Theme: Dataset Preparation & Baseline Analysis**

| Item | Details |
|------|---------|
| **Activities** | • Audit coral reef dataset (Healthy / Bleached / Dead categories) |
|                | • Review class distribution & identify imbalance issues |
|                | • Define train/validation/test splits (deterministic, reproducible) |
|                | • Perform EDA — visualize sample images per class |
| **Deliverables** | ✅ `split_info_v3.json` — fixed dataset split file |
|                  | ✅ EDA notebook with class distribution charts |
|                  | ✅ Data quality assessment report |
| **Status** | 🟢 Completed |

---

### 📅 WEEK 3 — 30 March – 05 April 2026
**Theme: Data Augmentation Pipeline & Preprocessing**

| Item | Details |
|------|---------|
| **Activities** | • Implement OpenCV preprocessing pipeline (resize to 224×224, BGR→RGB) |
|                | • Design augmentation strategy (rotation, flip, brightness, contrast) |
|                | • Implement hard-example oversampling (×20) for Bleached/Dead images |
|                | • Validate preprocessing consistency across training & inference |
| **Deliverables** | ✅ Standardized preprocessing pipeline |
|                  | ✅ Augmentation configuration documented |
|                  | ✅ Augmented training samples verified |
| **Status** | 🟢 Completed |

---

### 📅 WEEK 4 — 06–12 April 2026
**Theme: Base Model Architecture & Initial Training**
> 🎤 **Talk 1: Introduction & Plagiarism**

| Item | Details |
|------|---------|
| **Activities** | • Select EfficientNetB0 as backbone (transfer learning from ImageNet) |
|                | • Design model head: GlobalAveragePooling → Dense → Softmax (3 classes) |
|                | • Train initial baseline model (single seed) |
|                | • Evaluate baseline accuracy on validation set |
|                | • Attend Talk 1: Introduction & Plagiarism |
| **Deliverables** | ✅ Baseline model trained with initial accuracy metrics |
|                  | ✅ Training history plots (loss & accuracy curves) |
|                  | ✅ Understanding of plagiarism guidelines |
| **Status** | 🟢 Completed |

---

### 📅 WEEK 5 — 20–26 April 2026
**Theme: Model Optimization — SWA & Multi-Seed Training**
> 🎤 **Talk 2: Analysis of Result & Discussion**

| Item | Details |
|------|---------|
| **Activities** | • Implement Stochastic Weight Averaging (SWA) for better generalization |
|                | • Train 5-seed ensemble (seeds 42–46) with SWA |
|                | • Compare SWA vs. standard training results |
|                | • Begin results analysis and discussion framework |
|                | • Attend Talk 2: Analysis of Result & Discussion |
| **Deliverables** | ✅ 5 trained SWA model weight files (`.h5`) |
|                  | ✅ Comparative analysis: SWA vs. non-SWA performance |
|                  | ✅ Training script: `train_v4_robust.py` |
| **Status** | 🟢 Completed |

---

### 📅 WEEK 6 — 27 April – 03 May 2026
**Theme: Inference Optimization — Test-Time Augmentation (TTA)**
> 🎤 **Talk 3: ChatGPT & AI Tools**

| Item | Details |
|------|---------|
| **Activities** | • Implement Multi-Scale TTA (224 + 256, original + horizontal flip) |
|                | • Ensemble: average predictions across 5 seeds × TTA variants |
|                | • Implement temperature scaling calibration (T=0.441) |
|                | • Validate ensemble accuracy on held-out test set |
|                | • Attend Talk 3: ChatGPT & AI Tools |
| **Deliverables** | ✅ TTA inference pipeline |
|                  | ✅ Temperature calibration file: `temperature.txt` |
|                  | ✅ **Ensemble Test Accuracy: 98.11%** (159 images) |
| **Status** | 🟢 Completed |

---

### 📅 WEEK 7 — 04–10 May 2026
**Theme: Model Evaluation & Progress Report 1 Submission**
> 📝 **Progress Report 1 Submission**

| Item | Details |
|------|---------|
| **Activities** | • Generate confusion matrix & classification report heatmap |
|                | • Compute per-class precision, recall, F1-score |
|                | • Per-image audit to verify predictions vs. ground truth |
|                | • Compile Progress Report 1 |
| **Deliverables** | ✅ Confusion matrix visualization |
|                  | ✅ Classification report (Healthy: 0.99, Bleached: 0.98, Dead: 0.97) |
|                  | ✅ **Progress Report 1 submitted** |
| **Key Metrics** | Precision (macro): 0.99 · Recall (macro): 0.97 · F1 (macro): 0.98 |
| **Status** | 🟢 Completed |

---

### 📅 WEEK 8 — 11–17 May 2026
**Theme: Explainable AI — Grad-CAM Implementation**

| Item | Details |
|------|---------|
| **Activities** | • Implement Grad-CAM for CNN explainability |
|                | • Apply JET colormap (Blue→Red) for visualization |
|                | • Overlay heatmaps on original coral reef images |
|                | • Validate Grad-CAM activations match domain knowledge |
| **Deliverables** | ✅ Grad-CAM generation pipeline |
|                  | ✅ Sample Grad-CAM visualizations for each class |
|                  | ✅ Grad-CAM analysis documentation |
| **Status** | 🟢 Completed |

---

### 📅 WEEK 9 — 18–24 May 2026
**Theme: Web Application Development — Backend (Flask)**

| Item | Details |
|------|---------|
| **Activities** | • Design Flask backend architecture (`app.py`) |
|                | • Implement model loading & inference API endpoints |
|                | • Integrate ensemble prediction (5 seeds + TTA + temperature scaling) |
|                | • Add Grad-CAM generation endpoint |
|                | • Build REST API for image upload & classification |
| **Deliverables** | ✅ Flask backend with inference endpoints |
|                  | ✅ API: `/predict` → returns class, confidence, Grad-CAM |
|                  | ✅ Backend tested with sample images |
| **Status** | 🟢 Completed |

---

### 📅 WEEK 10 — 25–31 May 2026
**Theme: Web Application Development — Frontend (UI/UX)**
> 🏖️ **Semester Break begins**

| Item | Details |
|------|---------|
| **Activities** | • Design professional landing page (`design8.html`) |
|                | • Implement "Try Model" section with drag-and-drop upload |
|                | • Display confidence scores & Grad-CAM visualization in UI |
|                | • Add color legend for Grad-CAM heatmap interpretation |
|                | • Responsive design for desktop/mobile |
| **Deliverables** | ✅ Complete web frontend with modern UI |
|                  | ✅ Interactive image classification demo |
|                  | ✅ Grad-CAM overlay display in browser |
| **Status** | 🟢 Completed |

---

### 📅 WEEK 11 — 01–07 June 2026
**Theme: System Integration & End-to-End Testing**

| Item | Details |
|------|---------|
| **Activities** | • Integrate frontend + backend end-to-end |
|                | • Test full workflow: Upload → Predict → Display results + Grad-CAM |
|                | • Cross-browser testing (Chrome, Firefox, Edge) |
|                | • Performance optimization (inference speed, image processing) |
|                | • Create `run_coral_ai.bat` launcher script |
| **Deliverables** | ✅ Fully functional Coral Health AI web application |
|                  | ✅ One-click launcher script |
|                  | ✅ Test report with edge cases |
| **Status** | 🟢 Completed |

---

### 📅 WEEK 12 — 08–14 June 2026
**Theme: Progress Report 2 & Presentation Skills**
> 📝 **Progress Report 2 Submission**  
> 🎤 **Talk 4: Presentation Skills**

| Item | Details |
|------|---------|
| **Activities** | • Compile comprehensive Progress Report 2 |
|                | • Include model results, web app screenshots, Grad-CAM samples |
|                | • Attend Talk 4: Presentation Skills |
|                | • Begin preparing viva presentation slides |
| **Deliverables** | ✅ **Progress Report 2 submitted** |
|                  | ✅ Presentation outline drafted |
| **Status** | 🟢 Completed |

---

### 📅 WEEK 13 — 15–21 June 2026
**Theme: Report Writing — Full Report Draft**

| Item | Details |
|------|---------|
| **Activities** | • Write Chapter 1: Introduction (problem statement, objectives, scope) |
|                | • Write Chapter 2: Literature Review (CNN, transfer learning, coral health) |
|                | • Write Chapter 3: Methodology (EfficientNetB0, SWA, TTA, Grad-CAM) |
|                | • Write Chapter 4: Results & Discussion (accuracy, confusion matrix, XAI) |
|                | • Write Chapter 5: Conclusion & Future Work |
| **Deliverables** | ✅ Full report first draft (all chapters) |
|                  | ✅ Properly formatted tables, figures, references |
| **Status** | 🟢 Completed |

---

### 📅 WEEK 14 — 22–28 June 2026
**Theme: Full Report Submission**
> 📝 **Full Report Submission Deadline: 26 June 2026**

| Item | Details |
|------|---------|
| **Activities** | • Proofread and finalize full report |
|                | • Ensure APA citation format |
|                | • Format appendices (code listings, extra visualizations) |
|                | • Submit full report by deadline |
| **Deliverables** | ✅ **Full Report submitted (26 June 2026)** |
| **Status** | 🟡 In Progress |

---

### 📅 WEEK 15 — 29 June – 05 July 2026
**Theme: Viva Presentation**
> 🎓 **Viva Voce Presentation**

| Item | Details |
|------|---------|
| **Activities** | • Finalize presentation slides (15–20 slides) |
|                | • Rehearse presentation (15 min presentation + Q&A) |
|                | • Prepare live demo of web application |
|                | • **Present at Viva** |
| **Deliverables** | ✅ Presentation slides |
|                  | ✅ Live demo ready |
|                  | ✅ **Viva completed** |
| **Status** | ⬜ Pending |

---

### 📅 WEEK 16 — 06–12 July 2026
**Theme: Final Report & Table of Contents Submission**
> 📝 **Final Report & TOC Submission Deadline: 12 July 2026**

| Item | Details |
|------|---------|
| **Activities** | • Incorporate viva feedback into final report |
|                | • Finalize Table of Contents |
|                | • Final formatting check & submission |
| **Deliverables** | ✅ **Final Report & TOC submitted (12 July 2026)** |
| **Status** | ⬜ Pending |

---

### 📅 WEEK 17–18 — 13–19 July 2026
**Theme: Project Wrap-Up & Documentation**

| Item | Details |
|------|---------|
| **Activities** | • Archive all code, models, and documentation |
|                | • Write project README and setup instructions |
|                | • Clean up repository structure |
|                | • Final review and handover |
| **Deliverables** | ✅ Complete project archive |
|                  | ✅ Documentation finalized |
| **Status** | ⬜ Pending |

---

## Key Milestones Summary

| # | Milestone | Target Date | Status |
|---|-----------|-------------|--------|
| M1 | Dataset prepared & splits finalized | Week 2 (29 Mar 2026) | 🟡 |
| M2 | Baseline model trained | Week 4 (12 Apr 2026) | ⬜ |
| M3 | SWA ensemble trained (5 seeds) | Week 5 (26 Apr 2026) | ⬜ |
| M4 | **98.11% accuracy achieved** (TTA + Ensemble) | Week 6 (03 May 2026) | ⬜ |
| M5 | **Progress Report 1 submitted** | Week 7 (10 May 2026) | ⬜ |
| M6 | Grad-CAM XAI implemented | Week 8 (17 May 2026) | ⬜ |
| M7 | Web application completed | Week 11 (07 Jun 2026) | ⬜ |
| M8 | **Progress Report 2 submitted** | Week 12 (14 Jun 2026) | ⬜ |
| M9 | **Full Report submitted** | Week 14 (26 Jun 2026) | ⬜ |
| M10 | **Viva Presentation** | Week 15 (05 Jul 2026) | ⬜ |
| M11 | **Final Report & TOC submitted** | Week 16 (12 Jul 2026) | ⬜ |

---

## Model Achievement Summary

| Metric | Value |
|--------|-------|
| **Architecture** | EfficientNetB0 (Transfer Learning) |
| **Technique** | SWA + Multi-Scale TTA + Temperature Scaling |
| **Ensemble** | 5 seeds (42–46) |
| **Test Set** | 159 images (Healthy: 72, Bleached: 72, Dead: 15) |
| **Ensemble Accuracy** | **98.11%** |
| **Macro F1-Score** | 0.98 |
| **Explainability** | Grad-CAM with JET colormap |
| **Deployment** | Flask web app with live inference |

---

*Last Updated: 24 June 2026*  
*Supervisor: Assoc. Prof. Ts. Dr. Yasmin Yacob*
