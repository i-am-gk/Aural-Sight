import json
try:
    import tensorflow as tf
except ImportError:
    import sys
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "tensorflow", "numpy"])
    import tensorflow as tf

def inspect_model():
    model_path = r"d:\FYP\FYP project\aural_sight\assets\wake_word_model.tflite"
    
    try:
        interpreter = tf.lite.Interpreter(model_path=model_path)
        interpreter.allocate_tensors()
        
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()
        
        print("INPUT:")
        for i in input_details:
            print(f"- Name: {i['name']}")
            print(f"- Shape: {i['shape']}")
            print(f"- Type: {i['dtype']}")
            if 'quantization' in i:
                print(f"- Quantization: {i['quantization']}")
                
        print("\nOUTPUT:")
        for o in output_details:
            print(f"- Name: {o['name']}")
            print(f"- Shape: {o['shape']}")
            print(f"- Type: {o['dtype']}")
            if 'quantization' in o:
                print(f"- Quantization: {o['quantization']}")
                
        print("\nLAYERS:")
        for tensor in interpreter.get_tensor_details():
            name = tensor['name']
            shape = tensor['shape']
            if 'conv' in name.lower() or 'dense' in name.lower() or 'mfcc' in name.lower() or 'spectrogram' in name.lower() or 'reshape' in name.lower():
                print(f"- {name}: {shape}")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == '__main__':
    inspect_model()
