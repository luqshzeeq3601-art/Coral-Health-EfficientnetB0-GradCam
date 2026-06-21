# Chapter 5: Conclusion and Recommendations

## 5.1 Conclusion

This chapter summarises the outcomes of the project in relation to the three research objectives defined in Chapter 1.

### 5.1.1 Objective 1 — Model Development

The first objective was to develop a deep learning model based on a pretrained EfficientNetB0 architecture with Stochastic Weight Averaging (SWA) and a multi-seed ensemble strategy for coral reef health classification. This objective has been successfully achieved. The final model consists of five independently seeded EfficientNetB0 models (seeds 42–46), each trained with transfer learning, staged fine-tuning, and SWA optimisation. The ensemble predictions are combined via averaging to produce a single robust classification output. On the held-out test set of 159 images, the model achieved a test accuracy of 98.11% with only 3 misclassifications, representing an improvement of 13.20 percentage points over the frozen-backbone baseline model (84.91%). This confirms that the combination of ensemble diversity, SWA weight averaging, and targeted training strategies (including hard-example oversampling and Mixup regularisation) effectively addresses the challenges of coral reef image classification on a small, imbalanced dataset.

### 5.1.2 Objective 2 — Explainability via Grad-CAM

The second objective was to apply Gradient-weighted Class Activation Mapping (Grad-CAM) as a visual explanation method to support the interpretation and validation of the model's classification decisions. This objective has been successfully achieved. Grad-CAM heatmaps were generated for each prediction by extracting gradient information from the final convolutional layer of the EfficientNetB0 backbone. The resulting heatmaps highlight the spatial regions in the input image that contributed most to the predicted class, providing a visual explanation of the model's decision-making process. Qualitative analysis of the Grad-CAM outputs confirmed that the model focuses on ecologically meaningful coral features: healthy tissue regions for Healthy predictions, pale or whitened surface areas for Bleached predictions, and algae-covered or structurally degraded regions for Dead predictions. For the three misclassified test images, Grad-CAM panels revealed ambiguous attention patterns in transitional bleaching zones, offering a plausible explanation for the errors. This integration of explainability enhances trust and transparency, which is essential for adoption by marine biologists and reef monitoring practitioners.

### 5.1.3 Objective 3 — Performance Evaluation

The third objective was to evaluate the model's performance using standard classification metrics, including accuracy, precision, recall, and F1-score, on a held-out test set. This objective has been successfully achieved. The final ensemble model was evaluated on 159 unseen test images drawn from the BHD Coral Dataset, with class distribution preserved via stratified splitting (72 Healthy, 72 Bleached, 15 Dead). The evaluation results are summarised as follows:

| Metric | Value |
|--------|------:|
| Test Accuracy | 98.11% |
| Macro F1-Score | 0.9769 |
| Weighted F1-Score | 0.9810 |
| Healthy F1-Score | 0.9863 |
| Bleached F1-Score | 0.9790 |
| Dead F1-Score | 0.9655 |
| Total Errors | 3 / 159 |

The model achieves balanced performance across all three classes, including the minority Dead class (support = 15), which recorded perfect precision (1.00) and a recall of 93.33%. The error profile is directional: two Bleached images were misclassified as Healthy and one Dead image was misclassified as Bleached, consistent with visual overlap in intermediate bleaching stages. A 95% Wilson confidence interval for the overall accuracy is [94.60%, 99.36%], reflecting the uncertainty associated with the limited test set size. These results confirm that the model meets the performance standards required for practical coral reef health assessment.

---

## 5.2 Recommendations for Future Work

Based on the findings and limitations identified in this project, the following recommendations are proposed for future research and development:

### 5.2.1 Model Compression for Edge Deployment

The current inference pipeline relies on a five-model ensemble, which increases computational cost and memory requirements. Future work should explore knowledge distillation or post-training quantisation (FP16 or INT8) to compress the ensemble into a single lightweight model. This would enable direct deployment on resource-constrained edge devices such as underwater remotely operated vehicles (ROVs), autonomous underwater vehicles (AUVs), and portable diver cameras, facilitating real-time coral health monitoring in the field.

### 5.2.2 Active Learning Pipeline

The model's confidence threshold mechanism (set at 75.0%) already flags uncertain predictions for manual review. This can be extended into a formal active learning pipeline, where low-confidence predictions are systematically routed to marine biology experts for annotation. The newly labelled samples would then be incorporated into retraining cycles, enabling the model to progressively improve on edge cases and ambiguous coral conditions without requiring large-scale manual data collection.

### 5.2.3 Domain Adaptation for New Reef Sites

The current model was trained and evaluated exclusively on the BHD Coral Dataset, which represents a specific set of underwater imaging conditions. To ensure generalisability, future work should validate the model on coral images captured from different reef sites, geographic regions, camera systems, and environmental conditions (varying water turbidity, depth, and illumination). Domain adaptation techniques such as domain adversarial training or style transfer may be employed to bridge the visual gap between training and deployment environments.

### 5.2.4 Extension to Real-Time Video Classification

The current system processes individual static images. A natural extension is to support real-time frame-by-frame analysis of underwater video feeds. This would require optimisation of the inference pipeline for continuous processing and the addition of temporal smoothing to produce stable classifications across consecutive video frames, enabling live reef health surveys during dive operations.

---

*Last Updated: 12 June 2026*
