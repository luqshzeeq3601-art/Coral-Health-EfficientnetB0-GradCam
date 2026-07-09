# Methodology Flowchart Mermaid

This file stores the final detailed methodology flowchart selected for the report.

```mermaid
%%{init: {"flowchart": {"curve": "linear", "htmlLabels": false}} }%%
flowchart TB
    A(["Start"]) --> B[/Data Acquisition/]
    B --> C["Data Pre-processing"]
    C --> D["Data Splitting"]

    D --> E[("Test Set")]
    D --> F[("Validation Set")]
    D --> G[("Training Set")]

    G --> H["Data Augmentation<br/>(Training Only)"]
    H --> I["Model Development"]
    I --> J["Model Training"]
    F --> K["Hyperparameter Tuning"]
    J --> K
    K --> L{"Validation Accuracy,<br/>Loss, and F1-Score<br/>Satisfactory?"}

    L -->|No| J
    L -->|Yes| M["Save Best Model"]

    M --> N["Model Evaluation<br/>(Accuracy, Precision,<br/>Recall, F1-Score,<br/>Confusion Matrix)"]
    E --> N
    N --> O["Grad-CAM"]
    O --> P[/Output Results/]
    P --> Q(["End"])
```

## Notes

- This is the final chosen detailed flowchart for the report.
- The separate simple block diagram is used as the summary diagram, while this flowchart shows the training, validation, tuning, and evaluation logic in more detail.
- `Data Augmentation` is applied only to the training set after splitting.
- `Validation Set` is used for hyperparameter tuning and for checking validation accuracy, loss, and F1-score.
- `Test Set` is reserved for the final evaluation stage.
