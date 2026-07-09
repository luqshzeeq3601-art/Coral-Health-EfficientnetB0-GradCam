# Final Methodology Diagram Decision

## Final Decision

The report will use two methodology diagrams:

1. A simple **block diagram** for the high-level methodology summary.
2. A detailed **flowchart** for the training, validation, and evaluation process.

## Final Block Diagram Content

The final block diagram uses this sequence:

- `Data Acquisition`
- `Data Pre-processing`
- `Data Splitting (Train / Validation / Test)`
- `Model Development and Comparison`
- `Final Model Selection: EfficientNetB0 5-Seed SWA Ensemble`
- `Final Model Evaluation`
- `Grad-CAM / XAI Analysis`
- `Output Results and Deployment`

This block diagram is intended to give a concise overview of the full methodology. It summarizes the dataset pipeline, model comparison stage, final model selection, evaluation, interpretability analysis, and final output/deployment stage.

## Final Detailed Flowchart Content

The final detailed flowchart uses this sequence:

1. Start
2. Data Acquisition
3. Data Pre-processing
4. Data Splitting
5. Split into `Training Set`, `Validation Set`, and `Test Set`
6. Apply `Data Augmentation (Training Only)`
7. Model Development
8. Model Training
9. Hyperparameter Tuning
10. Check `Validation Accuracy, Loss, and F1-Score Satisfactory?`
11. If `No`, repeat training
12. If `Yes`, save best model
13. Perform final model evaluation using the test set
14. Apply Grad-CAM
15. Output Results
16. End

## Report-Ready Description

Figure X.X and Figure X.Y present the final methodological diagrams used in this project. The block diagram gives a high-level overview of the complete methodology, beginning with data acquisition and pre-processing, followed by dataset splitting, model development and comparison, final model selection, evaluation, interpretability analysis, and output/deployment.

The detailed flowchart expands the training pipeline by showing the separation of training, validation, and test sets, the application of data augmentation only to the training data, the iterative training and hyperparameter-tuning loop, and the use of validation accuracy, loss, and F1-score as the decision criteria before saving the best model. After the best model is saved, final evaluation is carried out on the held-out test set, followed by Grad-CAM analysis and final reporting of results.

## Text Layout for the Final Flowchart

```text
START
  |
Data Acquisition
  |
Data Pre-processing
  |
Data Splitting
  |-------------------------------|-------------------------------|
  |                               |                               |
Training Set                  Validation Set                  Test Set
  |
Data Augmentation
  |
Model Development
  |
Model Training
  |
Hyperparameter Tuning
  |
Validation Accuracy, Loss, and F1-Score Satisfactory?
  |----------------------|
  | Yes                  | No
  |                      |
Save Best Model          Repeat Training
  |
Final Model Evaluation on Test Set
  |
Grad-CAM
  |
Output Results
  |
END
```

## Suggested Labels

Use these labels to keep the final figures consistent:

- `Start`
- `Data Acquisition`
- `Data Pre-processing`
- `Data Splitting`
- `Training Set`
- `Validation Set`
- `Test Set`
- `Data Augmentation (Training Only)`
- `Model Development`
- `Model Training`
- `Hyperparameter Tuning`
- `Validation Accuracy, Loss, and F1-Score Satisfactory?`
- `Save Best Model`
- `Final Test Set Evaluation`
- `Grad-CAM`
- `Output Results`
- `End`
