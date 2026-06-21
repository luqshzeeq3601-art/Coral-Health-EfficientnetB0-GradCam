# Coral Health AI — Mobile Screen Content Specifications

This file defines the exact UI components, data structures, and user actions required for each individual screen of the mobile application.

---

## 🏠 Tab 1: Home Dashboard

### 1.1 Dashboard Root Screen
*   **Purpose:** Establishes trust, displays high-level accuracy tracking metrics, and gives immediate access to the primary upload flow[cite: 2].
*   **UI Components:**
    1. **Top Branding Bar:** Displays the custom system logo, the title text "Coral Health AI", and an active database cloud-sync check icon[cite: 2].
    2. **Hero Accuracy Box:** A prominent, full-width Bento card featuring a bold "98.11% Accuracy" readout using Rethink Sans typography[cite: 2].
    3. **Primary Action Launcher:** A large, pill-shaped cobalt blue button (#0057e6) labeled "New Health Assessment" that deep-links directly to the Assess tab[cite: 2].
    4. **Recent Assessments Slider:** A horizontal row of 24px rounded mini-cards showing a small preview thumbnail, relative time indicator, and a soft pastel classification badge (e.g., green fill for Healthy, amber fill for Bleached)[cite: 2].
    5. **Mission Reference Block:** A collapsible text container providing a brief summary of the CNN monitoring pipeline for field researchers[cite: 2].

---

## 🔬 Tab 2: Assess (Multi-Step Inference Flow)

### 2.1 Step 1: Upload Image Screen
*   **Purpose:** Securely grabs the target underwater coral photograph from the local device filesystem[cite: 2].
*   **UI Components:**
    1. **Linear Progress Stepper:** A top indicator row tracing: [● Upload] → [Configure] → [Analyze] → [Result][cite: 2].
    2. **Drop/Tap Upload Zone:** A large square target container featuring a soft baby-blue pastel background tint and a centralized cloud-upload icon[cite: 2].
    3. **Dynamic File Tracker:** Appears post-selection to show the raw filename, file size indicator, and a trailing remove icon button[cite: 2].
    4. **Navigation Trigger:** A bottom pill button labeled "Continue" that remains disabled until a valid file is loaded[cite: 2].

### 2.2 Step 2: Configure Settings Screen
*   **Purpose:** Allows field operators to adjust model parameters before initializing the forward pass[cite: 2].
*   **UI Components:**
    1. **Linear Progress Stepper:** Top status steps advanced to: [✓ Upload] → [● Configure] → [Analyze] → [Result][cite: 2].
    2. **Model Selection Segment:** A side-by-side card switch layout allowing selection between "Ensemble (5-Seed SWA)" and "Base (Single EfficientNet-B0)"[cite: 2].
    3. **Explainability Switch:** An oversized toggle row labeled "Enable Grad-CAM Attention Map Generation"[cite: 2].
    4. **Execution Action:** A solid cobalt blue pill button at the bottom labeled "Run Assessment"[cite: 2].

### 2.3 Step 3: Analysis Loading Screen
*   **Purpose:** Provides a passive waiting state that explains the internal math layers to the user while processing[cite: 2].
*   **UI Components:**
    1. **Linear Progress Stepper:** Top status steps advanced to: [✓ Upload] → [✓ Configure] → [● Analyze] → [Result][cite: 2].
    2. **Central Processing Spinner:** A smooth looping micro-animation showing active computation.
    3. **Pipeline Check List:** Four sequential text rows that automatically light up with green checkmarks:
        * Preprocessing (Image Resizing & Normalization)[cite: 2].
        * Feature Extraction (EfficientNet-B0 Backbone Pass)[cite: 2].
        * Attention Matrix (Grad-CAM Calculation)[cite: 2].
        * Final Resolution (Class Output Verification)[cite: 2].

### 2.4 Step 4: Analysis Results Screen
*   **Purpose:** The main diagnostic view displaying the deep learning model output, probability spreads, and attention maps[cite: 2].
*   **UI Components:**
    1. **Linear Progress Stepper:** Finalized to: [✓ Upload] → [✓ Configure] → [✓ Analyze] → [● Result][cite: 2].
    2. **Primary Classification Panel:** Large color-coded text block displaying the outcome ("Healthy" in green, "Bleached" in amber, or "Dead" in red) paired with a thick circular confidence gauge[cite: 2].
    3. **Probability Spread Bars:** A vertical block of three horizontal bars illustrating exactly how the score split across the three target classes[cite: 2].
    4. **Grad-CAM Comparison Window:** A bento element grouping the Original Photo and the generated Heatmap Overlay side-by-side, completed with a color spectrum legend bar (Blue to Red)[cite: 2].
    5. **Bottom Interface Actions:** Three explicit pill buttons grouped closely together:
        * "Ask ReefGuide" (Launches the contextual chatbot)[cite: 2].
        * "Run Again" (Resets back to the upload screen)[cite: 2].
        * "Done" (Saves and routes back to Dashboard)[cite: 2].

---

## 📋 Tab 3: History (Logs & Database Records)

### 3.1 Historical Assessment List Screen
*   **Purpose:** Let researchers browse, search, and filter previous records[cite: 2].
*   **UI Components:**
    1. **Search & Filter Row:** A rounded pill-shaped search input alongside horizontal pastel chips for filtering by category (All, Healthy, Bleached, Dead)[cite: 2].
    2. **Vertical Logs Roll:** A scrolling feed of 24px white cards[cite: 2]. Each log item embeds:
        * A tiny thumbnail photo box[cite: 2].
        * Class label text with matching semantic color tints[cite: 2].
        * Timestamp date labels (e.g., "May 31, 2026")[cite: 2].
        * Small sub-labels indicating the model type used (Ensemble/Base)[cite: 2].

### 3.2 Historical Record Detail Screen
*   **Purpose:** A read-only archival twin of the primary Results Screen for historical comparison[cite: 2].
*   **UI Components:**
    1. **Top Back-Navigation Bar:** Return arrow header displaying the log entry's unique ID and save date[cite: 2].
    2. **Archived Analysis Payload:** Direct layout copy of Screen 2.4 (Classification block, probability trackers, and Grad-CAM layers)[cite: 2].
    3. **Management Row:** A twin action split button: "Ask ReefGuide" and "Delete Log Entry" (triggers confirmation popup)[cite: 2].

---

## 📊 Tab 4: Performance (Model Metrics Validation)

### 4.1 View A: Base vs Ensemble Validator Screen
*   **Purpose:** Displays cross-validation accuracy metrics proving system optimization[cite: 2].
*   **UI Components:**
    1. **Top Segment Controls:** A clean selector switch to toggle the graphs below between "Base" and "Ensemble" modes[cite: 2].
    2. **Primary Performance Grid:** A 2x2 grid of bento cards displaying isolated stats: Accuracy, Precision, Recall, and Macro F1[cite: 2].
    3. **Confusion Matrix Card:** An interactive 3x3 data block showing true vs predicted classes, using varying color opacities[cite: 2].
    4. **History Loss Graphs:** Line charts visualizing epoch training/validation loss changes without harsh grid lines[cite: 2].

### 4.2 View B: Cross-Architecture Benchmark Screen
*   **Purpose:** Proves EfficientNet-B0 parameter efficiency against larger networks (ResNet50, ConvNeXt)[cite: 2].
*   **UI Components:**
    1. **Winning Highlight Tiles:** Three high-contrast summary widgets identifying the model that achieved the best accuracy and lowest footprint[cite: 2].
    2. **Efficiency Scatter Plot:** A scatter graph plotting Model Parameter Size (X-axis) against Test Accuracy (Y-axis)[cite: 2].
    3. **Architecture Comparative Grid:** A database data table itemizing parameters, precision scores, and processing latencies side-by-side[cite: 2].

---

## 📚 Tab 5: Learn (Educational Center)

### 5.0 Educational Hub Home Screen
*   **Purpose:** Gateway to the application's underlying technology features and project context[cite: 2].
*   **UI Components:**
    1. **Navigational Bento Cards:** A staggered layout of four highly rounded cards using soft pastel backgrounds to link out to deeper topics[cite: 2]:
        * "How the AI Model Works" (Routes to 5.1)[cite: 2].
        * "Core Technology Pillars" (Routes to 5.2)[cite: 2].
        * "Interactive 3D Attention Viewer" (Routes to 5.3)[cite: 2].
        * "About Project & Mission" (Routes to 5.4)[cite: 2].

### 5.1 Pipeline Walkthrough Screen
*   **Purpose:** Step-by-step documentation detailing image ingestion down to output scores[cite: 2].
*   **UI Components:**
    1. **Sequential Flowchart Block:** A clean, connected horizontal diagram breaking down the 5 stages of the processing flow[cite: 2].
    2. **Deep Process Cards:** Four expandable text rows explaining Tensor Preprocessing, Forward Pass feature maps, Backpropagation, and Heatmap extraction[cite: 2].

### 5.2 Core Technology Pillars Screen
*   **Purpose:** Summarizes the engineering elements that ensure field reliability[cite: 2].
*   **UI Components:**
    1. **Feature Definition Widgets:** Three standalone descriptive layout cards mapping out:
        * EfficientNet-B0 Feature Extractor properties[cite: 2].
        * 5-Seed SWA Ensemble logic[cite: 2].
        * Grad-CAM validation protocols[cite: 2].

### 5.3 Interactive 3D Attention Viewer Screen
*   **Purpose:** An immersive educational component detailing spatial importance mapping[cite: 2].
*   **UI Components:**
    1. **3D Viewport Area:** An interactive viewport workspace supporting multi-touch drag/rotation to inspect layered neural processing steps[cite: 2].
    2. **Step Control Controls:** Play, pause, forward, and backward navigation button rows to step through code layers[cite: 2].
    3. **Mathematical Toggle Switch:** A button labeled "Show Math Formulas" that flips plain-text descriptions into formal LaTeX gradient equations[cite: 2].

### 5.4 About & Mission Screen
*   **Purpose:** Connects software performance back to marine biology and ecological restoration goals[cite: 2].
*   **UI Components:**
    1. **Narrative Text Blocks:** Multi-column text fields explaining the limitations of manual reef tracking methods[cite: 2].
    2. **Video Playback Window:** An embedded media player container loaded with a drone reef monitoring clip[cite: 2].
    3. **Scientific Disclaimer Badge:** A highly visible information card stating the tool operates purely as decision support[cite: 2].

---

## 💬 Contextual Overlay Components

### 6.0 ReefGuide Chatbot Overlay Sheet
*   **Purpose:** Provides contextual help following a prediction from results screens, avoiding the need for a dedicated navigation tab[cite: 2].
*   **UI Components:**
    1. **Highly Curved Overlay Drawer:** A bottom sheet container using a 32px top radius and a thick centered grab-handle pill[cite: 2, 4].
    2. **Context Snapshot Chip:** A mini summary banner displaying the thumbnail and classification score passed from the underlying result screen[cite: 2].
    3. **Scrollable Chat Feed:** Alternating chat bubble cards (user entries display in soft blue pastel fields; AI returns clear white boxes)[cite: 2, 4].
    4. **Quick Prompt Pill Suggestions:** A horizontal line of clickable pill text options like "Explain Grad-CAM Map" or "What does this confidence level mean?"[cite: 2].