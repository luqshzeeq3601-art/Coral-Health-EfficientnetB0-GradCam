# Methodology Flowchart Redraw Guide

## Final Usage

The final report uses:

- one simple **block diagram** for the overall methodology
- one detailed **flowchart** for the training and evaluation logic

## Block Diagram Layout

Use a two-row layout with a downward connector from the last block in the top row.

Top row from left to right:

1. `Data Acquisition`
2. `Data Pre-processing`
3. `Data Splitting (Train / Validation / Test)`
4. `Model Development and Comparison`
5. `Final Model Selection: EfficientNetB0 5-Seed SWA Ensemble`

Bottom row from right to left:

1. `Final Model Evaluation`
2. `Grad-CAM / XAI Analysis`
3. `Output Results and Deployment`

## Detailed Flowchart Layout

Use a top-to-bottom flow with one decision branch and three split outputs from `Data Splitting`.

Recommended order:

1. `Start`
2. `Data Acquisition`
3. `Data Pre-processing`
4. `Data Splitting`
5. Three outputs:
   - `Test Set`
   - `Validation Set`
   - `Training Set`
6. Continue the main training flow from `Training Set`:
   - `Data Augmentation (Training Only)`
   - `Model Development`
   - `Model Training`
   - `Hyperparameter Tuning`
   - `Validation Accuracy, Loss, and F1-Score Satisfactory?`
7. Decision branch:
   - `No` -> return to `Model Training`
   - `Yes` -> `Save Best Model`
8. Merge `Save Best Model` with `Test Set` into:
   - `Model Evaluation`
9. Continue downward:
   - `Grad-CAM`
   - `Output Results`
   - `End`

## Recommended Shape Types

- Terminator: `Start`, `End`
- Process: `Data Pre-processing`, `Data Augmentation (Training Only)`, `Model Development`, `Model Training`, `Hyperparameter Tuning`, `Save Best Model`, `Model Evaluation`, `Grad-CAM`
- Data/Input shape: `Data Acquisition`, `Output Results`
- Stored data shape: `Training Set`, `Validation Set`, `Test Set`
- Decision diamond: `Validation Accuracy, Loss, and F1-Score Satisfactory?`

## Recommended Text Formatting

- Use short labels with title case.
- Keep font consistent across all nodes.
- Use bold only if your report template requires it.
- Avoid long sentences inside shapes.
- Use `Training Only` in brackets to make the augmentation constraint explicit.
- Use `Output Results and Deployment` only in the simple block diagram.

## Suggested Final Flowchart Structure

```text
                         Start
                           |
                   Data Acquisition
                           |
                  Data Pre-processing
                           |
                     Data Splitting
              _____________|_____________
             |             |             |
       Training Set   Validation Set   Test Set
             |
Data Augmentation (Training Only)
             |
     Model Development
             |
       Model Training
             |
   Hyperparameter Tuning
             |
Validation Accuracy, Loss, and F1-Score Satisfactory?
          | Yes                 | No
          |                     |
    Save Best Model            |
          |                    |
          |____________________|
                     |
            Model Evaluation
                     |
                 Grad-CAM
                     |
            Output Results
                     |
                    End
```

## Practical Redrawing Tips

- Keep `Validation Set` and `Test Set` at the same horizontal level as `Training Set`.
- Connect `Validation Set` to the tuning stage, not directly to the final output stage.
- Connect `Test Set` only to the `Model Evaluation` stage.
- Keep the `No` branch looping back to `Model Training`.
- Use the simple block diagram when you want a compact methodology summary.
