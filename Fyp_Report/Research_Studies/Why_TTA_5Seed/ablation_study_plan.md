# Ablation Study: Justifying TTA and Multi-Seed (5) Ensemble Choices

Empirically measure the contribution of TTA (Test-Time Augmentation) and the number of ensemble seeds (1 → 2 → 3 → 5) so you can present data-backed justification in Chapter 4 of the FYP report.

## Background

Your final model uses **5 seeds × SWA + Multi-Scale TTA** and achieves **98.11% accuracy** (3 errors / 159 test images). The question is: *why 5 seeds and not 2 or 3? Why TTA?* We need measurable ablation evidence.

## Proposed Experiment Design

The script will evaluate every combination on the **same frozen 159-image test set** using the **same saved SWA weights** (no retraining). This produces a clean comparison table.

### Ablation Matrix (8 configurations)

| Config | Seeds Used | TTA | Description |
|---|---|---|---|
| A | 1 (seed 42 only) | ❌ No | Single model, no TTA |
| B | 1 (seed 42 only) | ✅ Yes | Single model + TTA |
| C | 2 (seeds 42, 43) | ❌ No | 2-seed ensemble, no TTA |
| D | 2 (seeds 42, 43) | ✅ Yes | 2-seed ensemble + TTA |
| E | 3 (seeds 42, 43, 44) | ❌ No | 3-seed ensemble, no TTA |
| F | 3 (seeds 42, 43, 44) | ✅ Yes | 3-seed ensemble + TTA |
| G | 5 (all seeds) | ❌ No | 5-seed ensemble, no TTA (canonical benchmark) |
| H | 5 (all seeds) | ✅ Yes | 5-seed ensemble + TTA (full pipeline) |

### Metrics Collected per Configuration

1. **Accuracy** (% correct out of 159)
2. **Total errors** (count of misclassifications)
3. **Per-class precision, recall, F1-score**
4. **Macro F1-score** (most important for imbalanced classes — Dead has only 15 test images)
5. **Mean confidence on correct predictions** (measures calibration / decision certainty)
6. **Mean confidence on wrong predictions** (lower = more uncertain, which is desirable)
7. **Prediction agreement stability** — for seed subsets, measure how many images change prediction vs the full 5-seed ensemble (measures whether adding seeds resolves borderline cases)

## Proposed Changes

### Ablation Script

#### [NEW] [run_ablation_study.py](file:///c:/Users/luqma/OneDrive/Desktop/CHI/BASEPROJECT/03_Model_Evaluation/run_ablation_study.py)

A standalone Python script that:

1. Loads the 5 SWA model weights from [models/](file:///c:/Users/luqma/OneDrive/Desktop/CHI/BASEPROJECT/02_Modelling/efficientnetb0_coral/models)
2. Loads the test split from `split_info_v3.json`
3. Pre-computes per-model raw predictions (no TTA) and per-model TTA predictions for all 159 test images — caches these to avoid redundant GPU work
4. For each of the 8 configurations above, combines the relevant predictions and computes all metrics
5. Outputs:
   - `ablation_results.csv` — Full table of all 8 configs × all metrics
   - `ablation_results.json` — Machine-readable results
   - `ablation_accuracy_by_seeds.png` — Line chart: accuracy vs number of seeds (with/without TTA)
   - `ablation_f1_by_seeds.png` — Line chart: macro F1 vs number of seeds (with/without TTA)
   - `ablation_errors_by_seeds.png` — Bar chart: error count comparison
   - `ablation_confidence_gap.png` — Chart showing correct vs wrong prediction confidence gap per config
   - `ablation_prediction_stability.png` — Shows how many predictions flip/stabilise as seeds increase
   - `ablation_summary_table.png` — Publication-ready table image for the report

All outputs go to `03_Model_Evaluation/Ablation_TTA_MultiSeed/`.

---

### Report Figure Generation

#### [NEW] [generate_ablation_figures.py](file:///c:/Users/luqma/OneDrive/Desktop/CHI/BASEPROJECT/03_Model_Evaluation/generate_ablation_figures.py)

 A secondary script (no GPU needed) that reads the ablation JSON and regenerates clean, report-ready figures. This lets you tweak styling without re-running inference.

## Open Questions

> [!IMPORTANT]
> **Dataset path**: Your training script references `c:\Users\ZeeqRyz\Desktop\BASEPROJECT\Dataset` but the actual workspace has `Dataset\BHD Kaggle\{Healthy,Bleached,Dead}`. Which path should the ablation script use? I'll default to the workspace path with `BHD Kaggle` subfolder.

> [!IMPORTANT]
> **split_info_v3.json location**: The split file is referenced in the training script but may not exist at the expected path. Does it exist at [efficientnetb0_coral/split_info_v3.json](file:///c:/Users/luqma/OneDrive/Desktop/CHI/BASEPROJECT/02_Modelling/efficientnetb0_coral/split_info_v3.json)? If not, we'll need the test file list from another source (the audit CSV already has the 159 test filenames).

> [!NOTE]
> **GPU requirement**: The ablation script needs TensorFlow GPU access to run inference. Each of the 5 models needs ~16MB of weights. Total inference is ~159 images × 5 models × 2 (with/without TTA) — estimated 10–15 minutes on a single GPU.

## Verification Plan

### Automated Tests
- Config G (5-seed, no TTA) must reproduce **98.11% accuracy** and **3 errors** matching the stored confusion matrix
- All configs must evaluate exactly **159 test images**
- The sum of per-class support in every config must equal 159

### Manual Verification
- Review the generated figures for visual clarity and correctness
- Verify that the ablation table shows a clear trend: more seeds → better accuracy / F1, and TTA provides additional lift
- Copy final figures to `Fyp_Report/` for Chapter 4 inclusion
