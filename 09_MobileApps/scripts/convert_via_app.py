import os
import sys

# Add web app directory to path
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(os.path.dirname(BASE_DIR))
WEB_APP_DIR = os.path.join(PROJECT_ROOT, "04_Web_Application")
sys.path.append(WEB_APP_DIR)

import app
import tensorflow as tf
from tensorflow.keras.models import Model

OUTPUT_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "Coral Mobile - Codex", "assets", "models")

def make_dual_output_model(model):
    efficientnet = None
    for layer in model.layers:
        if 'efficientnet' in layer.name.lower():
            efficientnet = layer
            break
            
    if not efficientnet:
        raise ValueError("Could not find efficientnet layer")
        
    try:
        top_conv = efficientnet.get_layer('top_conv')
    except:
        for layer in reversed(efficientnet.layers):
            if isinstance(layer, tf.keras.layers.Conv2D):
                top_conv = layer
                break
                
    inputs = tf.keras.Input(shape=(224, 224, 3))
    predictions = model(inputs)
    feature_extractor = Model(inputs=efficientnet.input, outputs=top_conv.output)
    features = feature_extractor(inputs)
    
    dual_model = Model(inputs=inputs, outputs=[predictions, features])
    return dual_model

def convert_to_tflite(keras_model, output_path):
    converter = tf.lite.TFLiteConverter.from_keras_model(keras_model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_types = [tf.float16]
    
    tflite_model = converter.convert()
    
    with open(output_path, 'wb') as f:
        f.write(tflite_model)
    
    print(f"Saved: {output_path} ({len(tflite_model) / 1024 / 1024:.2f} MB)")

def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    print("Loading models via app.py...")
    # This automatically loads all models and puts them in app.MODELS and app.BASE_MODEL
    app.load_models()
    
    for i, model in enumerate(app.MODELS):
        seed = app.FOLDS[i]
        print(f"Converting seed {seed}...")
        try:
            dual_model = make_dual_output_model(model)
            out_path = os.path.join(OUTPUT_DIR, f"coral_ensemble_seed{seed}.tflite")
            convert_to_tflite(dual_model, out_path)
        except Exception as e:
            print(f"Failed to convert seed {seed}: {e}")
            
    if app.BASE_MODEL:
        print("\nConverting Baseline Model...")
        try:
            dual_baseline = make_dual_output_model(app.BASE_MODEL)
            out_path = os.path.join(OUTPUT_DIR, "coral_base.tflite")
            convert_to_tflite(dual_baseline, out_path)
        except Exception as e:
            print(f"Failed to convert baseline model: {e}")
            
    # Copy temperature
    import shutil
    temp_src = os.path.join(app.MODEL_DIR, "temperature.txt")
    temp_dst = os.path.join(OUTPUT_DIR, "temperature.txt")
    if os.path.exists(temp_src):
        shutil.copy(temp_src, temp_dst)
        print("Copied temperature.txt")

    print("All conversions complete!")

if __name__ == "__main__":
    main()
