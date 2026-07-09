# Chapter 1: Introduction

Project Background

Coral reefs are among the most ecologically significant ecosystems on Earth. Although they occupy less than one percent of the ocean floor, they support approximately 25 percent of all known marine species and deliver essential services including coastal protection, fisheries habitat, and tourism revenue (Moberg & Folke, 1999). These functions sustain the livelihoods of hundreds of millions of people across tropical coastal regions, and the economic value attributed to reef services reaches hundreds of billions of dollars annually (Burke et al., 2011). The health of coral reef ecosystems is therefore fundamental to both marine biodiversity and the coastal communities that depend on them.

Coral reefs face accelerating threat from rising sea surface temperatures driven by climate change. The primary symptom of thermal stress is coral bleaching, a condition in which corals expel the symbiotic zooxanthellae algae residing within their tissues. These algae supply up to 90 percent of a coral's energy requirements through photosynthesis, and their loss causes the coral to lose its natural coloration and appear white or pale. If stressful conditions persist, bleached corals become increasingly energy-deficient and may eventually die, resulting in widespread reef mortality and the collapse of the biodiversity they support (Hughes et al., 2018). The progression from a healthy, pigmented reef to a bleached or dead state represents a visually detectable change in coral tissue condition that can be captured in underwater photography.

Monitoring this progression at scale remains a significant challenge. Traditional underwater surveys conducted by trained divers are time-consuming, expensive, and limited in spatial coverage (González-Rivero et al., 2020). The growing volume of reef imagery now exceeds the capacity of human analysts to review consistently. Convolutional neural network (CNN)-based image analysis offers a scalable alternative, enabling automated classification of coral health conditions from digital photographs and reducing dependence on manual ecological assessment.

Problem Statement

Manual analysis is insufficient for the volume of ecological imagery produced by modern underwater monitoring platforms. Cameras mounted on remotely operated vehicles and autonomous underwater vehicles generate data far exceeding human review capacity (González-Rivero et al., 2020). Manual examination is labour-intensive and susceptible to error from observer fatigue and inter-observer subjectivity (Mahmood et al., 2016), necessitating automated classification of coral health imagery at scale (Beijbom et al., 2012).

Deep learning models used in coral health classification frequently operate as black boxes, producing predictions without identifying the image regions that influenced the decision. In underwater imagery, this can cause a model to attend to irrelevant background elements, such as water colour or sediment, rather than biologically meaningful indicators like tissue discolouration or bleaching patterns (Borjali et al., 2020). High accuracy offers no guarantee that predictions reflect valid coral health features, making visual explanation methods essential for scientific credibility (Selvaraju et al., 2020).

Reliance on a single performance measure, typically overall accuracy, can produce misleading assessments of model reliability. In datasets with uneven class distribution, a model may achieve high accuracy by defaulting to majority classes while consistently misclassifying underrepresented categories such as dead coral (Borjali et al., 2020). Under these conditions, reported accuracy overstates true model effectiveness. Evaluation across multiple metrics, including precision, recall, and F1-score for each health class, is therefore necessary to provide a trustworthy assessment.

This work is primarily focused on developing a Convolutional Neural Network (CNN) framework for automated image analysis to assess coral reef health conditions.

Objectives

The overarching aim of this study is to develop and evaluate a convolutional neural network-based image classification system capable of distinguishing between three coral reef health conditions which is Healthy, Bleached, and Dead. Three specific research objectives were established to structure the investigation:

This main aim will be met with three clear goals:

To create a deep learning model for coral reef health classification based on image data.

To apply a visual explanation method to support the interpretation and validation of the model's classification decisions.

To evaluate the model's classification performance using multiple standard metrics across all coral health categories.

Scope

This study employs the BHD Coral Dataset, comprising 1,582 labelled underwater coral images sourced from Kaggle, to train and evaluate a three-class coral reef health classification system. The dataset spans three health categories Healthy, Bleached, and Dead and serves as the sole data source, with classification restricted to these categories without extension to species identification or disease diagnosis.

EfficientNetB0, pretrained on ImageNet, serves as the feature extraction backbone. To address class imbalance, Hard-Example Oversampling is applied during training, and five independently seeded model instances are combined through Stochastic Weight Averaging to stabilise predictions. Multi-Scale Test-Time Augmentation is applied at inference to further improve classification robustness.

Grad-CAM visualisations are integrated to identify image regions most influential to each classification decision, supporting model interpretability. The trained ensemble is deployed as a locally hosted Flask web application, enabling real-time classification with confidence scoring and heatmap overlays. The software stack comprises Python, TensorFlow, Keras, OpenCV, and Scikit-learn, with training conducted on an NVIDIA RTX 3070 GPU.

Several limitations bound the scope of this study. The BHD Coral Dataset originates from a constrained geographic and environmental context, and the model's capacity to generalise across imagery from ecologically distinct reef regions, varying water turbidity levels, or different imaging devices is not evaluated. Classification is restricted to three broad health categories, with no extension to species-level identification, sub-category staging of bleaching severity, or disease diagnosis. The framework processes individual static images and does not support temporal or sequential analysis of reef degradation trends over time. The web application is limited to local hosting on a single workstation and lacks the server infrastructure required for multi-user access or cloud-scale deployment. These constraints define the operational boundary of the current study and are addressed as directions for future work in Chapter 5.

Summary

This chapter introduced the background, motivation, and scope of the study. Coral reefs are ecologically and economically vital ecosystems that are increasingly threatened by bleaching and degradation. Monitoring their health condition at scale is difficult using conventional survey methods, which are costly, time-consuming, and difficult to apply broadly. This gap motivates the use of image-based automated approaches that can assess coral health conditions more efficiently and consistently.

The study aims to develop an automated image classification system capable of distinguishing between healthy, bleached, and dead coral reef conditions. Three research objectives were established: to build an image classification model, to incorporate a visual explanation method so that the model's decisions can be interpreted, and to assess the system's performance across all health categories using recognised evaluation measures. The scope of the study, including the dataset used and the boundaries of the analysis, was also defined to ensure a focused and manageable investigation. The subsequent chapters present the literature review, methodology, results, and conclusion that collectively address these objectives.
