# Chapter 4: Results

Introduction

This chapter presents the experimental evaluation of the EfficientNetB0 5-seed SWA ensemble for coral reef health classification. Results are reported sequentially across seven subsections: dataset partitioning and class distribution in Section 4.1.1, training and validation learning curves in Section 4.1.2, hyperparameter tuning and final model selection in Section 4.1.3, test set classification performance in Section 4.1.4, baseline-to-final model comparison in Section 4.1.5, ablation study on ensemble size and Multi-Scale TTA in Section 4.1.6, and Grad-CAM explainability results in Section 4.1.7. The subsequent discussion in Section 4.2 interprets each finding in terms of its technical significance, addressing data split reliability, training convergence, classification error profiling, baseline improvement, ablation configuration selection, and Grad-CAM attention quality. The chapter concludes with a summary in Section 4.3 that consolidates the key outcomes against the three research objectives.

Dataset Split and Class Distribution

The dataset comprises 1,582 labelled underwater coral images partitioned into three non-overlapping subsets: training, validation, and test. The split was generated deterministically using a stratified manifest recorded in split_info_v3.json, ensuring that the class proportions observed in the full dataset are preserved across all three subsets. The training set contains 1,265 images, the validation set 158, and the test set 159, as detailed in Table 4.1.

Table 4. 1 Distribution of Training, Validation, and Test Samples Across Coral Health Classes.

The proportion of Dead samples in the dataset is considerably lower than that of the Healthy and Bleached classes, with only 150 images available across all subsets. To reduce the impact of class imbalance and improve learning on difficult samples, targeted hard-example oversampling was applied within the training set. Selected hard examples from the Dead class were duplicated at a higher rate than those from the Healthy and Bleached classes, while the validation and test sets remained unchanged to preserve unbiased model evaluation. This strategy improved minority-class representation without introducing data leakage into the evaluation process.

Training and Validation Learning Curves

Figure 4.1 and Figure 4.2 present the learning curves of both the training and validation partitions across 30 epochs. Accuracy of training shows a consistent increasing trend beginning with the early training periods, up to the last training epoch where it reaches above 98% accuracy. The same pattern of validation accuracy with significantly reduced oscillation, and with a steady level of high performance since about epoch 22. This convergence pattern suggests that the model is effective in generalising to unseen data and not merely by fitting the training distribution.

[03_Model_Evaluation/Efficientnet base vs Ensemble/01_training_validation_accuracy.png](../../03_Model_Evaluation/Efficientnet%20base%20vs%20Ensemble/01_training_validation_accuracy.png)

The loss curves in Figure 4.2 corroborate this observation. Training loss decreases gradually across all 30 epochs, reflecting steady weight updates under the Cosine Decay schedule. Validation loss, by contrast, drops sharply during the early epochs and stabilises at a markedly lower value than the training loss by the later stages of training. This persistent gap  where validation loss remains below training loss throughout arises from Hard-Example Oversampling applied exclusively to the training partition, which increases the average difficulty of training batches relative to the clean validation set. The pattern therefore does not indicate underfitting; rather, it reflects the intended asymmetry introduced by the oversampling strategy. The absence of any upward divergence in the validation loss confirms that the model does not overfit the training distribution. The magnitude and trajectory of this gap across all epochs are interpreted further in the generalisation analysis presented in Section 4.2.2.

[03_Model_Evaluation/Efficientnet base vs Ensemble/02_training_validation_loss.png](../../03_Model_Evaluation/Efficientnet%20base%20vs%20Ensemble/02_training_validation_loss.png)

Figure 4. 1 Training and validation accuracy over 30 epochs for the EfficientNetB0 5-seed SWA ensemble.

Figure 4. 2 Training and validation loss over 30 epochs for the EfficientNetB0 5-seed SWA ensemble.

Hyperparameter Tuning and Final Model Selection

Model selection followed an iterative tuning process in which hyperparameter configurations were evaluated against training and validation performance across the full training cycle. Configurations that failed to satisfy acceptable thresholds across all three evaluation criteria validation accuracy, validation loss, and macro F1-score were rejected and training was reinitiated with revised settings, consistent with the decision gate depicted in the system flowchart. The process converged upon the final configuration once the validation metrics satisfied the prescribed exit criterion, at which point the five SWA-averaged checkpoints, one per training seed, were preserved for ensemble construction. Table 4.2 summarises the finalised hyperparameter values adopted for the EfficientNetB0 ensemble model.

Table 4. 2 Finalised hyperparameter configuration for the EfficientNetB0 5-seed SWA ensemble.

Reproducibility across all five training seeds was confirmed by verifying that the saved checkpoints produced consistent evaluation outputs upon reloading. The finalised configuration was subsequently applied to the held-out test set, and the resulting performance metrics are presented in Section 4.1.4.

Final Classification Performance on the Test Set

The finalised EfficientNetB0 5-seed SWA ensemble was evaluated against the held-out test set comprising 159 images, none of which participated in any stage of training or hyperparameter selection. The model correctly classified 156 of the 159 samples, yielding an overall test accuracy of 98.11 percent. Macro-averaged and weighted F1-scores of 0.9769 and 0.9810 respectively confirm that this performance is consistent across all three coral health classes rather than concentrated within the numerically dominant categories. The confusion matrix is presented in Figure 4.3, with the complete per-class classification metrics shown in Figure 4.4.

[03_Model_Evaluation/Efficientnet base vs Ensemble/03_accuracy_gap_per_epoch.png](../../03_Model_Evaluation/Efficientnet%20base%20vs%20Ensemble/03_accuracy_gap_per_epoch.png)

Examining the per-class results, the Healthy class achieved a precision of 0.9730 and a recall of 1.0000, producing an F1-score of 0.9863 across 72 test samples. The Bleached class returned a precision of 0.9859 and a recall of 0.9722, yielding an F1-score of 0.9790 across its 72 samples. The Dead class, evaluated against 15 test samples, attained a precision of 1.0000 and a recall of 0.9333, with an F1-score of 0.9655. The perfect Dead class precision is particularly significant from a deployment standpoint, as it indicates the model produced no false positive Dead predictions throughout the entire test evaluation.

The confusion matrix reveals the class-level distribution of the three misclassifications. Both errors originating from the Bleached class resulted in Healthy predictions, while the single Dead class error was assigned to the Bleached category. No misclassifications occurred in the Healthy class, and no sample was incorrectly predicted as Dead. This directional error pattern, concentrated at the visual boundary between adjacent health states, is examined in greater depth in Section 4.2.3.

Figure 4. 3 Confusion matrix of the EfficientNetB0 5-seed SWA ensemble evaluated on 159 test images across three coral health classes.

Figure 4. 4 Per-class classification report metrics.

Baseline vs Final Model Comparison

The baseline EfficientNetB0 model served as the reference point against which the effectiveness of the final framework was evaluated. The baseline configuration consisted of a single EfficientNetB0 model trained with standard image preprocessing, without hard-example oversampling, class weighting, cosine decay learning rate scheduling, Stochastic Weight Averaging, or Multi-Scale Test-Time Augmentation.

As summarised in Table 4.3, the final model achieved a test accuracy of 98.11% against 84.91% for the baseline, representing an improvement of 13.20 percentage points. The macro F1-score increased from 79.19% to 97.69%, and the total number of misclassified samples fell from 24 to 3. These gains confirm that the combined optimisation strategies substantially improved classification reliability across all three coral health categories.

The enhancements introduced in the final model five-seed SWA ensemble training, hard-example oversampling at 30× for the Dead class, class weighting, cosine decay learning rate scheduling, and Multi-Scale TTA at 224×224 and 256×256 resolutions each addressed a specific limitation of the baseline configuration. Grad-CAM was additionally integrated to provide class-discriminative visual explanations of model predictions.

Table 4. 3 Comparison table of accuracy, macro F1-score, and total errors between the baseline EfficientNetB0 single model and the final 5-seed SWA ensemble.

Ensemble Size and Multi-Scale TTA

An ablation study spanning eight configurations was conducted to empirically justify the final inference settings of ensemble size and Multi-Scale Test-Time Augmentation (TTA). Four ensemble sizes one, two, three, and five seeds were each evaluated with and without TTA, producing Configurations A through H. The complete metric set is reported in Table 4.X.Table 4.1 Ablation Study Results Across Eight Configurations.

Table 4.2 Ablation study results across eight configurations, reporting test accuracy, misclassification count, macro F1-score, prediction confidence, and prediction stability for one-, two-, three-, and five-seed ensembles evaluated with and without Multi-Scale.

Ensemble size was the dominant performance driver. A single-seed model (Config A) achieved 96.23% accuracy with six misclassifications and a macro F1-score of 0.9339. Expanding the ensemble to three seeds (Config E) halved the error count to three and raised macro F1 to 0.9769, with no further accuracy gain observed between three and five seeds. The accuracy progression across ensemble sizes is shown in Figure 4.X.

Figure 4.1.1 Test accuracy versus ensemble size for configurations with and without Multi-Scale TTA.

[03_Model_Evaluation/Efficientnet base vs Ensemble/01_training_validation_accuracy.png](../../03_Model_Evaluation/Efficientnet%20base%20vs%20Ensemble/01_training_validation_accuracy.png)

The macro F1-score followed the same trajectory, confirming that the accuracy gains reflected balanced improvement across all three coral health classes rather than gains concentrated in the majority classes. This trend is presented in Figure 4.Y.

Figure 4.1.2 Macro F1-score versus ensemble size for configurations with and without Multi-Scale TTA.

[03_Model_Evaluation/Efficientnet base vs Ensemble/01_training_validation_accuracy.png](../../03_Model_Evaluation/Efficientnet%20base%20vs%20Ensemble/01_training_validation_accuracy.png)

The misclassification counts across all eight configurations, shown in Figure 4.Z, provide the clearest evidence for the selected pipeline. Error counts fell from six at one seed to three at three and five seeds, with TTA at lower seed counts either failing to reduce errors or increasing them, as observed in the two-seed configuration where TTA raised the count from five (Config C) to six (Config D).

Figure 4.1.3 Misclassification count across the eight ablation configurations.

[03_Model_Evaluation/Efficientnet base vs Ensemble/01_training_validation_accuracy.png](../../03_Model_Evaluation/Efficientnet%20base%20vs%20Ensemble/01_training_validation_accuracy.png)

Configuration H a five-seed SWA ensemble evaluated with Multi-Scale TTA across 224×224 and 256×256 resolutions with horizontal flip was selected as the final inference configuration. The five-seed ensemble was retained over three seeds for its broader averaging of random initialisation variance, which yields a more stable decision boundary, while TTA was preserved because at five seeds it sustained peak accuracy without introducing the prediction instability seen at lower seed counts, contributing robustness against the scale and orientation variation characteristic of real-world underwater imagery.

Grad-CAM Explainability Results

Grad-CAM was applied to the final convolutional layer of both the baseline single model and the EfficientNetB0 5-seed SWA ensemble to generate spatial attention heatmaps, enabling a direct comparison of decision quality between the two configurations. Figure 4.5 presents nine correctly classified ensemble samples three per coral health class with predicted labels and confidence scores. Figure 4.6 presents the corresponding baseline Grad-CAM outputs for one representative sample per class under the same evaluation conditions.

[03_Model_Evaluation/Efficientnet base vs Ensemble/05_final_confusion_matrix.png](../../03_Model_Evaluation/Efficientnet%20base%20vs%20Ensemble/05_final_confusion_matrix.png)

Figure 4. 5 Grad-CAM attention heatmaps for three correctly classified samples per coral health class generated using the EfficientNetB0 5-seed SWA ensemble, with per-sample prediction confidence ranging from 97.3% to 99.4%.

Figure 4. 6 Grad-CAM attention heatmaps generated by the baseline EfficientNetB0 single model for one representative sample per coral health class, with prediction confidence of 75.2% (Healthy), 45.5% (Bleached), and 52.5% (Dead).

Across all three classes, the ensemble produced attention maps concentrated on biologically relevant coral features. Healthy samples, classified at 97.3% to 97.6% confidence, showed activation localised over coral branching and fan structures, with the highest-intensity region anchored to pigmented tissue. Bleached samples at 98.4% to 99.4% confidence produced broader activation distributed across the pale coral surface, reflecting the spatially diffuse nature of tissue whitening. Dead samples at 96.6% to 99.4% confidence drew focused activation over exposed skeletal formations, confirming reliance on structural texture in the absence of chromatic pigmentation cues.

Comparison with the baseline in Figure 4.6 reveals a consistent pattern of unreliable spatial localisation. The most pronounced failure occurred in the Healthy class: the baseline classified the sample at 75.2% confidence, but activation concentrated on a clownfish occupying the image foreground rather than on the coral body, indicating the prediction was driven entirely by incidental reef fauna rather than coral tissue. For the Bleached class, the baseline produced partial activation on the coral surface at 45.5% confidence a value near the three-class chance threshold reflecting substantial decision uncertainty even when localisation was partially correct. For the Dead class, the baseline at 52.5% confidence produced activation that partially overlapped the skeletal coral mass but extended into the upper background, diluting the spatial specificity of the decision. Across all three baseline cases, confidence values ranged from 45.5% to 75.2%, in contrast to the ensemble's 96.6% to 99.4%, confirming that the baseline's weaker classification certainty was accompanied by correspondingly degraded attention quality.

[03_Model_Evaluation/Efficientnet base vs Ensemble/06_final_classification_report_table.png](../../03_Model_Evaluation/Efficientnet%20base%20vs%20Ensemble/06_final_classification_report_table.png)
