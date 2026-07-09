# Chapter 3: Methodology

Introduction

This chapter describes the methodology adopted for the development of the coral reef health assessment system, detailing the design decisions, processing stages, and evaluation strategies that collectively form the research workflow. The chapter is organised to follow the ten-stage pipeline established in the design framework presented in Section 3.2, progressing through three logical phases: data preparation, model development and optimisation, and model analysis and output. Section 3.3 introduces the BHD Coral Dataset, including its class composition and the class imbalance characteristics that inform subsequent processing decisions. Section 3.4 defines the performance evaluation metrics employed to assess model performance from both classification and deployment perspectives. Sections 3.5 through 3.7 provide detailed descriptions of each pipeline stage, encompassing data pre-processing, stratified splitting, augmentation, EfficientNet-B0 model construction, five-seed Stochastic Weight Averaging ensemble training, hyperparameter tuning, model saving, Grad-CAM interpretability analysis, and Multi-Scale Test-Time Augmentation evaluation. Section 3.8 documents the development environment, and Section 3.9 summarises the chapter. Together, these sections establish a reproducible and systematically validated methodology that addresses all three research objectives of this project.

Design Framework

Figure 3.  1 Illustrates the methodological framework adopted in this study for coral reef health classification.

The first row begins with Data Acquisition, where the BHD Coral Dataset is sourced from Kaggle as the primary input. The images then undergo Data Pre-processing to standardise resolution and pixel normalisation before being partitioned into training, validation, and test subsets during the Data Splitting stage. Multiple CNN architectures are subsequently trained and benchmarked in the Model Development and Comparison stage, from which the EfficientNetB0 5-Seed SWA Ensemble is selected as the final model based on superior classification performance.

The second row begins with Final Model Evaluation, where the selected ensemble is assessed against the test set. At this stage, Multi-Scale Test-Time Augmentation (TTA) is applied during inference, generating predictions across two resolutions  224×224 and 256×256 with horizontal flip  and averaging the outputs to produce robust final predictions. The evaluated model then proceeds to Grad-CAM, where Gradient-weighted Class Activation Mapping generates spatial heatmaps to support interpretability of the classification decisions. The pipeline concludes at the Output Results and Deployment stage, where predictions and Grad-CAM visualisations are served through a Flask web application.

Dataset

BHD Coral Kaggle

This study uses the BHD Coral Dataset, publicly available on Kaggle, as the primary data source for training and evaluating the deep learning model (Jamil, 2021). The dataset was specifically curated for coral reef health classification tasks and contains a total of 1,582 colour images in JPEG and PNG formats. All images are in RGB format and were captured underwater, covering varying resolutions and aspect ratios. The dataset is selected for this study due to its relevance to the classification task, its public accessibility, and its suitability for reproducible research.

Figure 3.  2 Sample Images from the BHD Coral Dataset Representing Healthy, Bleached, and Dead Classes.

As shown in Figure 3.2, the dataset contains three visually distinct coral health categories. Healthy corals display vibrant and varied colouration, reflecting the presence of symbiotic algae. Bleached corals appear white or pale, indicating that thermal stress has caused the expulsion of algae from the coral tissue. Dead corals are characterised by dark colouration due to coverage by turf algae or sediment. These visual differences across the three classes provide the discriminative features that the model is trained to recognise.

The dataset contains images with varying resolutions and aspect ratios. To ensure consistency and compatibility with the EfficientNet-B0 input requirements, all images are resized to 224 x 224 pixels during pre-processing. This standardisation reduces variability introduced by inconsistent image dimensions and supports stable model training. The dataset was divided into training, validation, and testing subsets using a stratified 80:10:10 ratio to preserve class distribution across all subsets.

Table 3. 1 Distribution of BHD Coral Dataset

As shown in Table 3.1, the dataset contains 1,582 coral images distributed across three health categories. Before augmentation, the dataset was partitioned into training, validation, and testing subsets using stratified sampling. Although the Healthy and Bleached classes contain similar numbers of samples, the Dead class is considerably smaller, indicating a class imbalance that may affect model training performance. The effect of targeted oversampling and augmentation on the training subset size for each class is presented in Table 3.4 in Section 3.5.4.

Performance Evaluation Metrics

A series of metrics is used to assess the performance of the proposed coral reef health classification system to ensure the evaluation is comprehensive, robust, and tailored to the three-class classification problem. Using overall accuracy alone may not be adequate in this case, as the BHD Coral Dataset is highly imbalanced with the Dead class having significantly fewer samples than the Healthy and Bleached classes. This means that a high overall accuracy could conceal issues with the minority classes. To overcome this issue, the evaluation metrics include classification accuracy, precision, recall, F1-score, macro-averaged and weighted-average aggregate measures and confusion matrix. This suite of metrics offers a comprehensive assessment of model performance in terms of classification accuracy and class-specific predictive performance, both of which are critical for assessing the system's suitability for real-world coral reef health monitoring.

Classification Accuracy

Classification accuracy measures the proportion of correctly classified images out of the total number of test samples, as shown in Equation (2.1). It provides a general indication of how well the model performs across all three coral health classes.

While accuracy offers a straightforward overview of overall model performance, it is sensitive to class distribution. In datasets where class sizes differ significantly, as is the case with the BHD Coral Dataset, a model that predominantly predicts the majority class can still achieve high accuracy while performing poorly on the minority class. For this reason, accuracy is used alongside other class-level metrics rather than as a standalone measure.

Precision

Precision measures the proportion of positive predictions for a given class that are genuinely correct, as shown in Equation (2.2), reflecting the model's ability to avoid false positives.

In the context of coral health classification, a low precision for the Dead class would indicate that the model frequently misclassifies Healthy or Bleached coral as Dead, which could lead to unnecessary conservation interventions based on incorrect assessments. Precision is therefore particularly important for ensuring the reliability of each predicted class label.

Recall

Recall measures the proportion of actual positive samples for a given class that the model correctly identifies, as shown in Equation (2.3), reflecting the model's sensitivity to true positives.

In coral reef monitoring, a low recall for the Dead class is especially critical, as it implies that genuinely degraded coral reefs are being overlooked and misclassified as Healthy or Bleached. Missing such cases in a real-world monitoring scenario could delay conservation responses. Recall therefore captures the model's ability to detect all instances of a given health condition, making it an essential complement to precision.

F1-Score

The F1-Score is the harmonic mean of precision and recall, as shown in Equation (2.4), providing a single balanced metric that accounts for both false positives and false negatives simultaneously.

Unlike arithmetic averaging, the harmonic mean penalises extreme differences between precision and recall, ensuring that a high F1-Score can only be achieved when both metrics are satisfactory. This property makes the F1-Score particularly suited for evaluating performance on imbalanced datasets such as the BHD Coral Dataset, where the Dead class is underrepresented relative to the Healthy and Bleached classes.

Macro Average and Weighted Average

To provide a system-level summary of classification performance across all three coral health classes, two aggregate metrics are computed. The macro average calculates the arithmetic mean of precision, recall, and F1-Score across all classes without accounting for class size, assigning equal weight to each class regardless of the number of samples it contains. The weighted average, in contrast, computes a support-weighted mean, where each class contributes proportionally to its sample count in the test set. In this study, the test set comprises 72 Healthy, 72 Bleached, and 15 Dead images, reflecting the same imbalance present in the full dataset. The macro average is the primary reported aggregate because it treats the minority Dead class with equal importance as the majority classes, directly penalising any degradation in Dead class performance. The weighted average is reported alongside it to reflect overall system performance as experienced across the realistic distribution of test samples.

Confusion Matrix

The confusion matrix offers a visual, tabular representation of the classification results, comparing predicted labels to true labels in an N×N matrix, with N being the number of classes. Here, N is three, representing the Healthy, Bleached, and Dead coral classes. The cells of the matrix contain the count of each prediction outcome, comprising the four basic terms detailed in Table 3.2: True Positive (TP), True Negative (TN), False Positive (FP), and False Negative (FN). The confusion matrix provides valuable class-specific information on misclassification not otherwise revealed by aggregate metrics, such as the model's propensity to confuse visually similar classes. Due to the visual similarity between Bleached and Dead coral, the confusion matrix is especially useful to determine if the confusion is focused at this class border, which in turn can inform model development.

Table 3. 2 Confusion Matrix Terms and Definitions.

Data Preparation

This section describes the first four stages of the methodology pipeline, covering the acquisition, pre-processing, splitting, and augmentation of the BHD Coral Dataset. These stages collectively transform raw underwater coral images into a standardised and balanced training-ready input for the EfficientNet-B0 model.

Figure 3.  3 Coral Reef Assessment Flowchart.

Figure 3.3 presents the complete execution pipeline of the proposed coral reef health classification system. The workflow begins with Data Acquisition, followed by Data Pre-processing and Data Splitting, where the dataset is partitioned into three mutually exclusive subsets: Training Set, Validation Set, and Test Set. The Test Set is immediately isolated and reserved for final evaluation only. Data Augmentation is applied exclusively to the Training Set before proceeding to Model Development and Model Training. A decision node following Hyperparameter Tuning assesses whether validation accuracy, loss, and F1-score meet the satisfactory threshold; if not, the process returns to Model Training for further optimisation. Once the criteria are satisfied, the trained model artefacts are exported for evaluation and deployment.

The second phase, as shown in Figure 3.3, covers model analysis and output generation. Multi-Scale TTA is applied during the evaluation stage, generating predictions across two resolutions 224×224 and 256×256 with horizontal flip and averaging the outputs to produce robust final predictions. The evaluated model is assessed against the held-out subsets, producing accuracy, precision, recall, F1-score, and confusion matrix results. Grad-CAM is then applied to generate spatial attention heatmaps, providing visual interpretability of the model's classification decisions across the Healthy, Bleached, and Dead coral classes. The pipeline concludes at the Output Results stage, consolidating all evaluation artefacts as the final system output.

Data acquisition

The BHD Coral Dataset was obtained from Kaggle and serves as the primary data source for this study (Jamil, 2021). The dataset comprises 1,582 labelled underwater coral images stored in JPEG and PNG formats, categorised into three health classes: Healthy (712 images), Bleached (720 images), and Dead (150 images). The images were captured under varying underwater conditions, resulting in differences in resolution, aspect ratio, lighting, and colour cast across samples. These characteristics make the dataset representative of real-world coral reef monitoring scenarios while also introducing pre-processing requirements that are addressed in the subsequent stage.

Data pre-processing

All images undergo a standardised pre-processing pipeline before entering the training process. Images loaded using OpenCV are first converted from BGR to RGB colour space to match the input format expected by EfficientNet-B0. Each image is then resized to 224 × 224 pixels using bilinear interpolation to satisfy the fixed input dimension of the architecture. Pixel values are subsequently normalised from the range of 0 to 255 to a standardised range of 0 to 1 by dividing by 255 and cast to 32-bit floating-point representation to ensure numerical precision during gradient computation. Class labels are encoded as integer indices and converted to one-hot encoded vectors using the Keras to categorical function, as required by the categorical cross-entropy loss function used during training.

Figure 3.  4 Example of Image Resizing Process.

Data Splitting

The pre-processed dataset is partitioned into three mutually exclusive subsets using stratified random splitting with a fixed seed of 42 to ensure reproducibility. The training set comprises 80 percent of the data, the validation set 10 percent, and the test set the remaining 10 percent, yielding 159 test images. Stratified splitting is applied to preserve the proportional class distribution of Healthy, Bleached, and Dead samples within each subset, which is particularly important given the underrepresentation of the Dead class. Critically, data splitting is performed before augmentation to prevent data leakage, which would occur if augmented variants of training images were to appear in the validation or test sets, artificially inflating evaluation metrics.

Data Augmentation

Prior to data augmentation, the dataset was divided into training, validation, and testing subsets using a stratified 80:10:10 ratio. As shown in Table 3.3, the Dead class contained only 120 training samples prior to augmentation, substantially fewer than the Healthy and Bleached classes, resulting in a class imbalance that could negatively affect model learning. To improve minority-class representation, targeted oversampling and augmentation strategies were applied to the training set. Following augmentation, the number of training samples increased while the validation and testing subsets remained unchanged to ensure unbiased model evaluation.

Table 3. 3 Class Distribution Before and After Augmentation.

Data augmentation is applied exclusively to the training set using the Keras ImageDataGenerator, which introduces stochastic geometric and photometric transformations on-the-fly at each training epoch, ensuring that the validation and test sets retain only original unmodified images. Three core transformations are employed. Random rotation within ±20 degrees simulates variations in underwater camera orientation during image capture, as illustrated in Figure 3.5.

Figure 3.  5 Random Rotation Augmentation.

Horizontal flipping produces a mirror image of each coral sample, which is ecologically valid given the bilateral symmetry of coral structures, as shown in Figure 3.6.

Figure 3.  6 Horizontal Flipping Augmentation.

Zoom variation within a range of 90 to 110 percent of the original image size replicates differences in capture distance between the camera and the reef surface, as shown in Figure 3.7. Width and height shifts of up to 15 percent and brightness jitter between 0.8 and 1.2 further account for positional variation and inconsistent underwater illumination respectively. Vertical flipping is deliberately excluded as inverted coral images carry no ecological validity.

Figure 3.  7 Random Zoom Augmentation.

To address class imbalance and difficult classification cases, a targeted oversampling strategy was implemented according to the augmentation priorities shown in Table 3.4. Hard examples from the Dead class were oversampled by a factor of 30×, while selected hard examples from the Healthy and Bleached classes were oversampled by a factor of 20×. In addition, class weights were computed using the inverse class frequency method, with the Dead class receiving an additional weight multiplier of 1.3× during training. This combination of augmentation, targeted oversampling, and class weighting improves minority-class representation and enhances the model's ability to learn challenging coral health patterns.

Table 3. 4 Augmentation Focus Strategy.

Model Development and Optimisation

This section describes the three central stages of the methodology pipeline corresponding to Sections 3.6.1 through 3.6.3 of the design framework: model training, hyperparameter tuning, and model saving. These stages transform the prepared and augmented training data into a finalised, optimised, and deployable model artifact.

Model Training – EfficientNetB0 Architecture and Five-Seed SWA Ensemble Training

EfficientNet-B0 was selected as the backbone architecture on account of its compound scaling strategy, which simultaneously adjusts network depth, width, and input resolution using a single compound coefficient. This design achieves strong classification accuracy without the parameter overhead associated with deeper architectures such as ResNet or VGG, making it well-suited to the relatively small BHD Coral Dataset. The model was initialised with ImageNet pretrained weights to leverage transferable low-level and mid-level visual representations, substantially reducing the labelled training data required for convergence.

The original 1,000-class EfficientNet-B0 classification head was replaced with a custom three-class head detailed in Table 3.5. A Global Average Pooling layer reduces the backbone's spatial feature maps to a compact 1,280-dimensional vector, followed by a Dropout layer with a rate of 0.4 to mitigate overfitting during fine-tuning, and a Dense output layer with three neurons governed by a Softmax activation function. L2 regularisation with a weight decay coefficient of  λ = 0.0002 is applied to the output layer to constrain model complexity. The final 100 layers of the EfficientNet-B0 backbone are unfrozen for fine-tuning, while the remaining layers retain their pretrained weights, allowing higher-level features to adapt to coral-specific visual patterns without disrupting generalised low-level representations.

Table 3. 5 Modified EfficientNet-B0 Architecture.

The training configuration is presented in Table 3.6. The Adam optimiser is employed with an initial learning rate of 8 × 10⁻⁵, governed by a Cosine Decay schedule over 30 epochs with a batch size of 16. Categorical cross-entropy with label smoothing of ε = 0.05 is used as the loss function, softening the target probability distribution to prevent overconfidence on noisy training samples.

Table 3. 6 Training Configuration.

To improve generalisation, Stochastic Weight Averaging (SWA) is applied during the final five epochs of each training run. The SWA callback accumulates model weights from epochs 26 to 30 and computes their running arithmetic mean, yielding a consolidated checkpoint that resides in a wider, flatter region of the loss landscape compared to any single-epoch solution. Models residing in flatter loss regions have been shown to generalise more robustly to unseen data.

Five independent models are trained using random seeds 42 to 46, each producing a distinct SWA-averaged checkpoint, with ensemble predictions combined via probability vector averaging. The selection of five seeds as the final ensemble size, alongside Multi-Scale TTA as the inference strategy, was validated through a systematic ablation study across eight configurations; the results and rationale are presented in Section 4.1.6.

Hyperparameter Tuning

Hyperparameter tuning was conducted through systematic experimentation to identify a configuration that maximises classification performance while maintaining stable model convergence. Key parameters, including dropout rate, L2 regularisation coefficient, label smoothing factor, initial learning rate, the number of fine-tuned backbone layers, augmentation intensity, class oversampling multipliers, and class weight scaling factors, were evaluated across a range of candidate values. Multi-Scale Test-Time Augmentation (TTA) was applied only during evaluation and inference and was therefore excluded from the tuning process.

A model configuration was considered satisfactory when the training and validation curves demonstrated stable convergence with minimal signs of overfitting. Configurations that failed to meet these conditions were revised and retrained iteratively until an optimal balance between learning effectiveness and generalisation was achieved. The final optimised hyperparameter values are presented in Table 3.7 together with their baseline counterparts and the rationale for each modification.

Table 3. 7 Hyperparameters Tuning Summary.

Model Export

Once the final model configuration has been selected, the trained model artefacts are preserved for evaluation, reproducibility, and deployment purposes. The SWA-averaged model weights and supporting configuration files are exported and stored to ensure consistent inference behaviour during subsequent testing and deployment stages. For each of the five training seeds, the SWA-averaged weight checkpoint is saved in HDF5 format as the primary inference model, while the best single-epoch checkpoint is retained through the Model Checkpoint callback as a validation-based backup. The exported model artefacts are subsequently integrated into the Flask-based deployment framework to support real-time coral reef health classification without additional retraining.

Model Analysis and Output

This section covers the final three stages of the methodology pipeline: model interpretability using Grad-CAM, model evaluation on the held-out test set, and the generation of output results. These stages collectively validate the classification performance of the trained ensemble model and provide visual evidence of its decision-making process.

Model Evaluation with Multi-Scale TTA

The final ensemble model is evaluated using the 159-image test set, which was not used during training or hyperparameter tuning to ensure a fair assessment of model performance. To improve prediction reliability, Multi-Scale Test-Time Augmentation (TTA) is applied during testing. Each test image is processed at two image sizes: 224 × 224 pixels and 256 × 256 pixels, with the larger image centre-cropped to 224 × 224 pixels. For each size, both the original image and its horizontally flipped version are evaluated, resulting in four prediction views per image. The prediction probabilities from all five SWA ensemble models across the four TTA views are then averaged to produce the final class prediction.

Multi-Scale TTA was adopted for three reasons. First, the 159-image test set introduces sampling uncertainty, particularly for the Dead class with only 15 test samples; aggregating predictions across multiple views reduces the influence of any single stochastic outcome on the final classification result. Second, processing each image at two resolutions (224 × 224 and 256 × 256 with centre-crop) enables the model to evaluate coral features at different spatial scales, capturing both fine-grained texture patterns and broader structural context within a single inference pass. Third, horizontal flip was selected as the sole geometric transformation because underwater coral images may appear in any horizontal orientation depending on camera angle, whereas vertical flipping produces ecologically invalid orientations inconsistent with natural coral imaging conditions, mirroring the exclusion of vertical flip during training augmentation. The four prediction views per image therefore represent a practical balance between inference coverage and computational cost, consistent with the average voting aggregation strategy identified by Kandel and Castelli (2021) as the most reliable TTA configuration across multiple CNN architectures.

Model performance is evaluated using the metrics described in Section 3.4, including accuracy, precision, recall, F1-score, macro and weighted averages and confusion matrix analysis. The complete results are presented in Chapter 4.

Model Interpretability - Grad-CAM

Convolutional neural networks are inherently opaque in their decision-making process, which limits their trustworthiness in critical domains such as marine ecosystem monitoring. To address this limitation, Gradient-weighted Class Activation Mapping (Grad-CAM) is integrated into the proposed system to provide class-discriminative visual explanations for each classification decision. Grad-CAM operates by computing the gradient of the predicted class score with respect to the feature map activations of the final convolutional layer of EfficientNet-B0, identified as the top_conv layer, and using those gradients to localise the image regions that most influenced the prediction. Grad-CAM was selected over alternative explainability methods on the basis of its native compatibility with convolutional architectures, producing spatially localised heatmaps directly from feature map gradients without requiring proxy models or perturbation-based sampling. In domains where classification decisions carry ecological significance, the ability to generate interpretable visual evidence without additional computational overhead or post-processing steps makes Grad-CAM a more practical choice than perturbation-based alternatives.

The mathematical formulation proceeds in two stages. First, channel-wise importance weights are derived by globally average-pooling the backpropagated gradients across the spatial dimensions of the target feature map.

Where is the class score for target class , is the activation at spatial location of the -th feature map, and is the total number of spatial positions. Second, the final heatmap is produced by computing a weighted linear combination of the feature maps and applying a ReLU activation to retain only regions that positively contribute to the predicted class.

The resulting heatmap is upsampled to the original 224 × 224 input resolution using bilinear interpolation and overlaid onto the coral image using the JET colourmap, which encodes activation intensity from low to high as blue, green, yellow, and red respectively. The Grad-CAM setup configuration is summarised in Table 3.8.

Table 3. 8 Grad-CAM Setup Configuration.

The expected Grad-CAM focal regions for each coral health class, derived from established biological indicators of reef condition, are summarised in Table 3.9.

Table 3. 9 Expected Grad-CAM Attention Regions per Class.

Output Results

The system produces two categories of output upon completing the evaluation and interpretability analysis. The quantitative outputs comprise the classification report detailing per-class precision, recall, and F1-score, and the confusion matrix. The visual outputs comprise Grad-CAM heatmap panels generated for representative samples from each of the three coral health classes, illustrating the spatial regions that the model associates with each health condition. In the context of the Flask web application, both the predicted class label with its associated confidence score and the corresponding Grad-CAM overlay are presented to the user in real time, fulfilling the deployment and interpretability objectives of this project.

Development Environment

The proposed coral reef health assessment system was developed and trained within a locally configured Python-based environment, supported by specialised deep learning frameworks and hardware acceleration. All software components were selected on the basis of their compatibility, community support, and suitability for the specific computational demands of the project.

Python Programming Language

Python serves as the primary programming language throughout the entire development pipeline, encompassing data pre-processing, model construction, training, evaluation, and web application deployment. Its extensive ecosystem of scientific and deep learning libraries, combined with concise and readable syntax, makes it the de facto standard for machine learning research and development. In this project, all pipeline components from the Keras model definition to the Flask inference server  are implemented within a unified Python environment, ensuring consistency, modularity, and reproducibility across all experimental stages.

Figure 3.  8 Python programming environment used for model development.

TensorFlow & Keras Framework

TensorFlow 2.12, together with its high-level Keras API, constitutes the primary deep learning framework used for constructing, compiling, training, and saving the EfficientNet-B0 model. Keras provides a modular Sequential interface that simplifies the attachment of the custom classification head to the pretrained backbone, while TensorFlow's backend manages automatic differentiation, gradient computation, and GPU memory allocation during training. The framework also supplies the ModelCheckpoint and LearningRateScheduler callbacks used in the training pipeline, and directly supports the SWA weight-averaging procedure implemented through a custom Keras callback. Model weights are serialised and loaded in the TensorFlow HDF5 format, ensuring compatibility between the training environment and the Flask deployment server.

Figure 3.  9 TensorFlow and Keras deep learning framework.

OpenCV Library

OpenCV is employed throughout the pre-processing and visualisation stages of the pipeline. During pre-processing, it handles image loading from disk, BGR to RGB colour space conversion, and bilinear resizing to the target resolution of 224 × 224 pixels. In the Grad-CAM visualisation stage, OpenCV applies the JET colourmap to the normalised heatmap arrays and performs the weighted overlay blending that superimposes the activation heatmap onto the original coral image. Its optimised C++ backend provides computational efficiency for these operations, which are executed at inference time within the Flask web application for every uploaded image.

Figure 3.  10 OpenCV image processing operations.

Supporting Libraries

NumPy underpins all numerical array operations across the pipeline, including pixel normalisation, multi-scale TTA crop generation, and Grad-CAM weight pooling. Matplotlib is used to generate the training and validation accuracy and loss curves reported in Chapter 4, as well as the Grad-CAM heatmap panel figures used in the interpretability analysis. Scikit-learn provides the train_test_split function with stratified sampling for dataset partitioning, and generates the classification report and confusion matrix used in the model evaluation stage. Seaborn is employed alongside Matplotlib to render the confusion matrix as an annotated heatmap for visual presentation. Flask and Flask-CORS form the backend web framework that serves the inference API, handles image uploads, and returns classification predictions together with Grad-CAM overlays to the frontend interface in real time.

Figure 3.  11 NumPy.

Figure 3.  12 Matplotlib.

Figure 3.  13 Scikit Learn.

Figure 3.  14 Seaborn.

Figure 3.  15 Flask.

Hardware - NVIDIA RTX 3070 GPU

All model training and evaluation were conducted on a local workstation equipped with an NVIDIA GeForce RTX 3070 GPU with 8 GB of dedicated VRAM. CUDA 11.8 and cuDNN 8.6 were configured to enable TensorFlow GPU acceleration, allowing parallel matrix computations during forward and backward propagation passes across the five-seed ensemble training runs. Training each seed to completion across 30 epochs required approximately 12 minutes on this hardware configuration, yielding a total training duration of approximately 60 minutes for the full 5-seed ensemble inclusive of GPU cooldown intervals between seeds. The adoption of local GPU hardware rather than cloud-based resources ensured consistent computational conditions and eliminated session timeout limitations that would otherwise interrupt long training runs.

Summary

This chapter presented the complete ten-stage methodological framework for the coral reef health assessment system, progressing through three logical phases. The data preparation phase addressed image standardisation, stratified 80:10:10 splitting of the BHD Coral Dataset, and class-imbalance correction through targeted hard-example oversampling applied exclusively to the training set. The model development phase covered the construction of the modified EfficientNetB0 architecture with a custom three-class head, five-seed SWA ensemble training under a Cosine Decay schedule, and iterative hyperparameter tuning evaluated against convergence and generalisation criteria. The model analysis and output phase integrated Grad-CAM for class-discriminative visualisation, Multi-Scale TTA across two input resolutions with horizontal flip, and comprehensive performance measurement using accuracy, precision, recall, F1-score, and confusion matrix analysis. All pipeline stages were implemented in Python 3.10 using TensorFlow 2.12, Keras, OpenCV, and supporting scientific libraries, with training executed on an NVIDIA GeForce RTX 3070 GPU under CUDA 11.8 and cuDNN 8.6 acceleration. The quantitative results and visual outputs produced through this methodology are presented and discussed in Chapter 4.
