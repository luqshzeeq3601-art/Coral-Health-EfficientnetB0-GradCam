import os
import tensorflow as tf
from tensorflow.keras.models import Sequential, Model
from tensorflow.keras.applications import EfficientNetB0
from tensorflow.keras.layers import GlobalAveragePooling2D, Dropout, Dense, Input

IMG_SIZE = 224
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJECT_ROOT = os.path.dirname(BASE_DIR)

ENSEMBLE_DIR = os.path.join(PROJECT_ROOT, "02_Modelling", "efficientnetb0_coral", "models")
BASELINE_DIR = os.path.join(PROJECT_ROOT, "05_Baseline_Model", "models")
OUTPUT_DIR = os.path.join(BASE_DIR, "Coral Mobile - Codex", "assets", "models")

SEEDS = [42, 43, 44, 45, 46]

def build_ensemble_model():
    base_model = EfficientNetB0(include_top=False, weights='imagenet', input_shape=(IMG_SIZE, IMG_SIZE, 3))
    model = Sequential([
        Input(shape=(IMG_SIZE, IMG_SIZE, 3)),
        base_model,
        GlobalAveragePooling2D(),
        Dropout(0.4),
        Dense(3, activation='softmax', kernel_regularizer=tf.keras.regularizers.l2(0.0002))
    ])
    return model

def build_baseline_model():
    base_model = EfficientNetB0(include_top=False, weights='imagenet', input_shape=(IMG_SIZE, IMG_SIZE, 3))
    model = Sequential([
        Input(shape=(IMG_SIZE, IMG_SIZE, 3)),
        base_model,
        GlobalAveragePooling2D(),
        Dense(3, activation='softmax')
    ])
    return model

def make_dual_output_model(model):
    # Find the efficientnet base model
    efficientnet = None
    for layer in model.layers:
        if 'efficientnet' in layer.name.lower():
            efficientnet = layer
            break
            
    if not efficientnet:
        raise ValueError("Could not find efficientnet layer")
        
    # Get the last conv layer (top_conv)
    try:
        top_conv = efficientnet.get_layer('top_conv')
    except:
        # Fallback if layer name changed
        for layer in reversed(efficientnet.layers):
            if isinstance(layer, tf.keras.layers.Conv2D):
                top_conv = layer
                break
                
    # Create a new model with two outputs: predictions and top_conv activations
    # We must trace from the very input of the Sequential model
    
    # We can reconstruct it or simply use functional API to extract what we need.
    inputs = tf.keras.Input(shape=(IMG_SIZE, IMG_SIZE, 3))
    
    # Run through the sequential model manually
    x = inputs
    
    # We need the output of the sequential model, AND the output of the top_conv inside the efficientnet.
    # To do this cleanly, we can use the Model class.
    
    # First output is the normal prediction
    predictions = model(inputs)
    
    # For the second output, we create a sub-model that extracts top_conv
    feature_extractor = Model(inputs=efficientnet.input, outputs=top_conv.output)
    
    # Since the first layer of sequential is the efficientnet, we can just pass the inputs to it
    # Wait, in the Sequential model, the first layer is the base_model.
    # So we can pass inputs to the feature_extractor
    features = feature_extractor(inputs)
    
    # Return dual output model
    dual_model = Model(inputs=inputs, outputs=[predictions, features])
    return dual_model

def convert_to_tflite(keras_model, output_path):
    converter = tf.lite.TFLiteConverter.from_keras_model(keras_model)
    # Float16 quantization
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_types = [tf.float16]
    
    tflite_model = converter.convert()
    
    with open(output_path, 'wb') as f:
        f.write(tflite_model)
    
    print(f"Saved: {output_path} ({len(tflite_model) / 1024 / 1024:.2f} MB)")

def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    print("Converting Ensemble Models...")
    for seed in SEEDS:
        print(f"Processing seed {seed}...")
        
        # Load the full model directly
        model_path = os.path.join(ENSEMBLE_DIR, f"efficientnetb0_v4robust_seed{seed}_swa.h5")
        if not os.path.exists(model_path):
            print(f"Warning: {model_path} not found. Skipping...")
            continue
            
        try:
            model = tf.keras.models.load_model(model_path, compile=False)
            
            # Create dual output
            dual_model = make_dual_output_model(model)
            
            # Convert to TFLite
            out_path = os.path.join(OUTPUT_DIR, f"coral_ensemble_seed{seed}.tflite")
            convert_to_tflite(dual_model, out_path)
        except Exception as e:
            print(f"Failed to convert seed {seed}: {e}")
        
    print("\nConverting Baseline Model...")
    # Baseline is a bit different as it might only have .weights.h5, but we can try building it like app.py
    baseline_weights = os.path.join(BASELINE_DIR, "efficientnetb0_baseline.weights.h5")
    
    if os.path.exists(baseline_weights):
        try:
            # Replicate app.py baseline loading logic via h5py
            import h5py
            baseline_model = EfficientNetB0(include_top=False, weights='imagenet', input_shape=(IMG_SIZE, IMG_SIZE, 3))
            baseline_model.trainable = False
            model = Sequential([
                Input(shape=(IMG_SIZE, IMG_SIZE, 3)),
                baseline_model,
                GlobalAveragePooling2D(),
                Dense(3, activation='softmax')
            ])
            with h5py.File(baseline_weights, 'r') as f:
                kernel = np.array(f['dense']['dense']['kernel:0'])
                bias = np.array(f['dense']['dense']['bias:0'])
            model.layers[-1].set_weights([kernel, bias])
            
            dual_baseline = make_dual_output_model(model)
            out_path = os.path.join(OUTPUT_DIR, "coral_base.tflite")
            convert_to_tflite(dual_baseline, out_path)
        except Exception as e:
            print(f"Failed to convert baseline model: {e}")
    else:
        print(f"Warning: Baseline weights {baseline_weights} not found.")

    # Copy temperature.txt
    import shutil
    temp_src = os.path.join(ENSEMBLE_DIR, "temperature.txt")
    temp_dst = os.path.join(OUTPUT_DIR, "temperature.txt")
    if os.path.exists(temp_src):
        shutil.copy(temp_src, temp_dst)
        print("Copied temperature.txt")
        
    print("All conversions complete!")

if __name__ == "__main__":
    main()
