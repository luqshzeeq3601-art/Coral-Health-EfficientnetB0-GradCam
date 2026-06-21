# Judge Questions & Answers for UPEX 2026 Poster

This document outlines potential questions a judge might ask based on your "Coral Reef Health Assessment" poster, along with structured, concise bullet points on how to answer them effectively.

## 1. Project Overview & Architecture

### Q: Can you briefly explain your project and the main problem it solves?
**How to answer:**
*   Start with the **core problem**: Traditional coral monitoring requires expensive, time-consuming dives by experts. Also, existing AI solutions often lack transparency (the "black-box" problem).
*   State your **solution**: A web-based platform using Convolutional Neural Networks (CNN) to automatically classify coral health into Healthy, Bleached, and Dead categories.
*   Highlight the **innovation**: Integration of Explainable AI (Grad-CAM) to show *why* the AI made its decision, increasing trust for marine researchers.

### Q: Why did you choose EfficientNetB0 over other CNN architectures (like ResNet or VGG)?
**How to answer:**
*   Mention **Efficiency**: EfficientNetB0 provides an optimal balance between high accuracy and computational efficiency.
*   Mention **Deployment**: It is lightweight, making it highly suitable for web-based deployment where faster inference times are necessary.
*   Mention **Resource constraints**: It requires fewer parameters compared to heavy models like VGG or ResNet, reducing training time and memory usage.

## 2. Methodology & Technical Details

### Q: You used "Hard-Example Oversampling" and "Class Weighting." Why was this necessary?
**How to answer:**
*   Explain the **imbalance issue**: Datasets in nature are rarely perfectly balanced. The "Dead" or "Bleached" classes might have had fewer or more difficult samples to learn from compared to the "Healthy" class.
*   Explain the **solution**: Hard-example oversampling duplicates the difficult-to-predict samples, while class weighting heavily penalizes the model for misclassifying minority classes (like Dead corals).
*   **Result**: This ensures the model doesn't just bias toward the majority class and learns the distinguishing features of the critical classes.

### Q: Can you explain Stochastic Weight Averaging (SWA) and why you applied it?
**How to answer:**
*   **Definition**: SWA is an optimization technique that averages the weights of the neural network during the final stages of training.
*   **Benefit**: Instead of just taking the weights from the very last epoch (which might be stuck in a sharp local minimum), SWA finds a broader, flatter minimum.
*   **Outcome**: This leads to better generalization on unseen data (test set) and makes the model more robust against overfitting.

### Q: Why did you train an ensemble of five models with different seeds (42-46)?
**How to answer:**
*   Explain **variance reduction**: A single model can have slight biases based on its initial random weight initialization.
*   Explain **ensemble benefits**: By combining predictions from 5 slightly different models, the final prediction becomes much more stable and reliable.
*   **Confidence**: It improves the overall accuracy and the reliability of the confidence scores presented to the user.

## 3. Explainable AI (XAI) & Results

### Q: How does your system address the "AI Black-Box Problem"?
**How to answer:**
*   Mention **Grad-CAM**: Gradient-weighted Class Activation Mapping (Grad-CAM) is used to generate a heat map over the uploaded image.
*   Explain **visual proof**: Instead of just saying "95% Bleached," it highlights the specific pale regions of the coral that led the CNN to that conclusion.
*   **Trust**: This allows domain experts (like marine biologists) to verify that the AI is looking at the actual coral texture and not just background noise (like water or fish).

### Q: Did your model struggle with any specific classifications? (e.g., distinguishing Bleached vs. Dead)
**How to answer:**
*   **Acknowledge realistic challenges**: Yes, the transition between severely bleached and newly dead coral can be visually subtle even for humans.
*   **Point to solutions used**: Mention that this exact difficulty is why you implemented *Hard-Example Oversampling* and *Ensemble Modeling*—to specifically force the model to focus on the nuanced differences.
*   *(Note: Refer to your confusion matrix if they ask for specific numbers).*

## 4. Commercialization & Future Work

### Q: How would environmental agencies actually use this platform in the field?
**How to answer:**
*   **Workflow**: Divers or underwater drones capture images of the reef.
*   **Platform usage**: They upload these images to the web platform (Coral Health AI Platform).
*   **Instant Analysis**: The system provides an immediate classification, a confidence score, and a Grad-CAM visual explanation.
*   **Impact**: It acts as a "ReefGuide Support" to assist non-experts or speed up the analysis process for experts, leading to faster data-driven conservation efforts.

### Q: What are the limitations of your current system, and what would you improve in the future?
**How to answer:**
*   **Current limitation**: It currently processes 2D static images, which requires manual upload.
*   **Future improvement 1 (Video)**: Implement real-time video stream processing for live monitoring via underwater drones.
*   **Future improvement 2 (More classes)**: Expand classification to include specific coral diseases (e.g., White Syndrome, Black Band Disease) rather than just Healthy/Bleached/Dead.
