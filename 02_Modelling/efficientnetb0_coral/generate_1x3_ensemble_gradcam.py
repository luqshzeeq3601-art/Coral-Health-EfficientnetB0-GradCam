import os
import sys
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import tensorflow as tf

# Add current directory to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from replot_evaluation import (
    load_test_split,
    load_models,
    predict_single_scale_ensemble,
    make_gradcam_heatmap_smooth,
    CLASS_NAMES
)

def main():
    print("Loading test split...")
    x_test, y_true, test_paths = load_test_split()
    
    print("Loading models...")
    models = load_models()
    
    print("Predicting ensemble probabilities...")
    avg_probs = predict_single_scale_ensemble(models, x_test)
    y_pred = np.argmax(avg_probs, axis=1)
    
    print("Selecting best correctly classified samples for each class...")
    samples_ensemble = []
    gradcam_model = models[0]  # Seed 42 SWA model for CAM
    
    for cls_idx, cls_name in enumerate(CLASS_NAMES):
        idxs = np.where(y_true == cls_idx)[0]
        correct_idxs = [j for j in idxs if y_pred[j] == cls_idx]
        sorted_idxs = sorted(correct_idxs, key=lambda j: avg_probs[j][cls_idx], reverse=True)
        # Select the single best sample for each class
        if sorted_idxs:
            best_idx = sorted_idxs[0]
            conf = avg_probs[best_idx][cls_idx]
            samples_ensemble.append((x_test[best_idx], cls_idx, y_pred[best_idx], conf))
            print(f"  Class {cls_name}: Selected index {best_idx} with confidence {conf*100:.2f}%")
        else:
            print(f"  Warning: No correct predictions for class {cls_name}")
            
    if len(samples_ensemble) < 3:
        print("Error: Could not find correct predictions for all three classes.")
        return
        
    print("Generating 1x3 Ensemble Grad-CAM Grid...")
    fig, axes = plt.subplots(1, 3, figsize=(15, 6), facecolor="white")
    plt.subplots_adjust(top=0.85, wspace=0.15) # Proper gap at the top
    
    for idx, (img, true_lbl, pred_lbl, conf) in enumerate(samples_ensemble):
        ax = axes[idx]
        img_array = np.expand_dims(img, axis=0)
        # aug + eigen smooth CAM
        heatmap = make_gradcam_heatmap_smooth(img_array, gradcam_model, aug_smooth=True, eigen_smooth=True)
        ax.imshow(img.astype(np.uint8))
        if heatmap.max() > 0:
            ax.imshow(heatmap, cmap='jet', alpha=0.4)
        ax.axis('off')
        label_text = f"True: {CLASS_NAMES[true_lbl]}\nPred: {CLASS_NAMES[pred_lbl]} ({conf*100:.1f}%)"
        ax.set_title(label_text, fontsize=13, color='black', fontweight='normal', pad=10)
        
    plt.suptitle("Grad-CAM EfficientnetB0", fontsize=22, fontweight="bold", y=0.96)
    
    # Save directory
    figures_dir = r"C:\Users\ZeeqRyz\Desktop\CHI\BASEPROJECT\Fyp_Report\Figures"
    os.makedirs(figures_dir, exist_ok=True)
    
    path_1 = os.path.join(figures_dir, "gradcamensemble_outputs_1x3.png")
    path_2 = os.path.join(figures_dir, "gradcam_ensemble_1x3.png")
    
    fig.savefig(path_1, dpi=300, bbox_inches="tight")
    fig.savefig(path_2, dpi=300, bbox_inches="tight")
    plt.close(fig)
    
    print(f"Successfully generated and saved 1x3 Grad-CAM grid to:")
    print(f"  - {path_1}")
    print(f"  - {path_2}")

if __name__ == "__main__":
    main()
