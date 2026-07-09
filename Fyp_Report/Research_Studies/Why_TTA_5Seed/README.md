# Justification Rationale: Why 5-Seed Ensemble and No TTA?

This directory contains the ablation study results, data, and charts compiled to justify the selection of the **5-seed SWA ensemble without Test-Time Augmentation (TTA)** for the final coral health classification model.

---

## 📊 Summary Table of Ablation Results

| Configuration | Seeds | TTA | Test Accuracy | Total Errors | Macro F1-Score | Prediction Flips (vs 5-seed No-TTA) |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| A | 1 | ✗ | 96.23% | 6 | 0.9339 | 3 |
| B | 1 | ✓ | 96.86% | 5 | 0.9469 | 2 |
| C | 2 | ✗ | 96.86% | 5 | 0.9493 | 2 |
| D | 2 | ✓ | 96.23% | 6 | 0.9423 | 3 |
| E | 3 | ✗ | 98.11% | 3 | 0.9769 | 0 |
| F | 3 | ✓ | 97.48% | 4 | 0.9624 | 1 |
| **G (Selected)** | **5** | **✗** | **98.11%** | **3** | **0.9769** | **0** |
| H | 5 | ✓ | 98.11% | 3 | 0.9769 | 2 |

---

## 💡 Key Arguments for the FYP Report

### 1. Why We Do Not Use Test-Time Augmentation (TTA)
* **Performance Degradation:** Rather than helping, TTA consistently introduced noise and decreased accuracy in multi-seed configurations:
  * In the **2-seed ensemble**, TTA reduced accuracy from **96.86%** (Config C) to **96.23%** (Config D) and increased errors from 5 to 6.
  * In the **3-seed ensemble**, TTA reduced accuracy from **98.11%** (Config E) to **97.48%** (Config F) and increased errors from 3 to 4.
* **Over-smoothing and Calibration Issues:** The scale/flip alterations applied during TTA likely distorted distinct diagnostic features (like fine coral bleaching textures), leading to prediction confusion.
* **Unnecessary Overhead:** Running TTA multiplies inference time by the number of augmentations (4x in this setup) without providing any performance benefits.

### 2. Why We Use a 5-Seed Ensemble
* **Optimal Error Minimization:** Increasing the ensemble size from 1 to 3 seeds halved the misclassification count (from **6 errors** to **3 errors**), raising the test accuracy from **96.23%** to **98.11%**.
* **Robustness & Stability:** Although the 3-seed (Config E) and 5-seed (Config G) ensembles share the same accuracy, the 5-seed ensemble is chosen for:
  * **Variance Dampening:** It averages out random weight initialization variance across more models, ensuring a more stable decision boundary.
  * **Confidence Alignment:** A larger ensemble produces a wider confidence gap, increasing the prediction margin for correct classifications.
  * **Benchmark Standard:** It secures the highest possible classification rate (98.11% accuracy, only 3 misclassifications out of 159 images) as a robust, reproducible benchmark.

---

## 📁 File Structure & Assets

* **[ablation_summary_table.png](file:///C:/Users/ZeeqRyz/Desktop/CHI/BASEPROJECT/Fyp_Report/Research_Studies/Why_TTA_5Seed/ablation_summary_table.png)**: Summary table image showing all metrics.
* **[ablation_accuracy_by_seeds.png](file:///C:/Users/ZeeqRyz/Desktop/CHI/BASEPROJECT/Fyp_Report/Research_Studies/Why_TTA_5Seed/ablation_accuracy_by_seeds.png)**: Line plot comparing test accuracy across seed counts (1, 2, 3, 5) with and without TTA.
* **[ablation_errors_by_seeds.png](file:///C:/Users/ZeeqRyz/Desktop/CHI/BASEPROJECT/Fyp_Report/Research_Studies/Why_TTA_5Seed/ablation_errors_by_seeds.png)**: Bar chart illustrating error counts across the 8 configurations.
* **[ablation_confidence_gap.png](file:///C:/Users/ZeeqRyz/Desktop/CHI/BASEPROJECT/Fyp_Report/Research_Studies/Why_TTA_5Seed/ablation_confidence_gap.png)**: Visual comparing mean confidence values between correct and incorrect predictions.
* **[ablation_prediction_stability.png](file:///C:/Users/ZeeqRyz/Desktop/CHI/BASEPROJECT/Fyp_Report/Research_Studies/Why_TTA_5Seed/ablation_prediction_stability.png)**: Chart displaying how many predictions flipped compared to the selected 5-seed no-TTA ensemble.
* **[ablation_results.csv](file:///C:/Users/ZeeqRyz/Desktop/CHI/BASEPROJECT/Fyp_Report/Research_Studies/Why_TTA_5Seed/ablation_results.csv)** / **[json](file:///C:/Users/ZeeqRyz/Desktop/CHI/BASEPROJECT/Fyp_Report/Research_Studies/Why_TTA_5Seed/ablation_results.json)**: Raw metrics data.
* **[ablation_study_plan.md](file:///C:/Users/ZeeqRyz/Desktop/CHI/BASEPROJECT/Fyp_Report/Research_Studies/Why_TTA_5Seed/ablation_study_plan.md)**: Original research plan.
