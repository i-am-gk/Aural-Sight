import 'dart:ui';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/detected_object.dart';
import 'detection_constants.dart';

class DetectionHelper {
  const DetectionHelper._();

  static List<DetectedObject> runInference({
    required img.Image image,
    required Interpreter interpreter,
    required List<String> labels,
  }) {
    // 1. Pre-process: Resize to 300x300 (Assumes image is already resized or we check)
    // For optimal performance, assume caller resizes, but we can verify.
    // However, image argument should ideally be 300x300.
    
    // Convert to input array [1, 300, 300, 3] of uint8 (0-255)
    // SSD MobileNet v1 usually expects uint8.
    
    final inputMatrix = List.generate(
      DetectionConstants.inputSize,
      (y) => List.generate(
        DetectionConstants.inputSize,
        (x) {
          final pixel = image.getPixel(x, y);
          // image package v4 pixel access
          return [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()];
        },
      ),
    );
    
    final input = [[inputMatrix]]; // Wrap in nested list for runForMultipleInputs [[ [1, H, W, 3] ]]
    
    // Debug logs for tensor shapes
    print("Model expects: ${interpreter.getInputTensor(0).shape}");
    print("Input provided structure: [1, ${DetectionConstants.inputSize}, ${DetectionConstants.inputSize}, 3]");

    // 2. Prepare Output Tensors
    // SSD MobileNet V1 Outputs:
    // 0: Locations [1, 10, 4] -> [ymin, xmin, ymax, xmax]
    // 1: Classes [1, 10]
    // 2: Scores [1, 10]
    // 3: Number of detections [1]
    
    // Note: The number 10 is the max detections usually, but it might be more depending on the model.
    // We'll use Map for output to allow flexible sizing if the model supports it, 
    // or allocate strictly if needed.
    // Generally maps work well with tflite_flutter.
    
    final outputLocations = List.filled(1 * 10 * 4, 0.0).reshape([1, 10, 4]);
    final outputClasses = List.filled(1 * 10, 0.0).reshape([1, 10]);
    final outputScores = List.filled(1 * 10, 0.0).reshape([1, 10]);
    final outputNumDetections = List.filled(1, 0.0).reshape([1]);

    final outputs = {
      0: outputLocations,
      1: outputClasses,
      2: outputScores,
      3: outputNumDetections,
    };

    // 3. Run Inference
    interpreter.runForMultipleInputs(input, outputs);

    // 4. Parse Results
    final numDetectionsRaw = (outputs[3] as List)[0] as double;
    final int numDetections = numDetectionsRaw.toInt();
    
    // Check bounds
    final int maxDetections = 10; 
    final int loopCount = numDetections < maxDetections ? numDetections : maxDetections;

    final results = <DetectedObject>[];

    final locations = (outputs[0] as List).first as List<List<double>>;
    final classes = (outputs[1] as List).first as List<double>;
    final scores = (outputs[2] as List).first as List<double>;

    for (int i = 0; i < loopCount; i++) {
        final score = scores[i];
        
        if (score >= DetectionConstants.confidenceThreshold) {
            // Get label
            final classIndex = classes[i].toInt();
            String label = 'Unknown';
            if (classIndex >= 0 && classIndex < labels.length) {
              label = labels[classIndex];
            }
            // Note: Some models leverage 'Background' as 0, others start classes at 0.
            // Adjust based on observation if needed (usually +1 for some, but standard is direct index).
            
            // Get Box [ymin, xmin, ymax, xmax] normalized
            final rawLoc = locations[i];
            final ymin = rawLoc[0];
            final xmin = rawLoc[1];
            final ymax = rawLoc[2];
            final xmax = rawLoc[3];
            
            // Convert to Rect [left, top, width, height]
            // We store it normalized (0.0 - 1.0) so the UI can scale it to the screen.
            final rect = Rect.fromLTRB(xmin, ymin, xmax, ymax);
            
            results.add(DetectedObject(
                label: label,
                confidence: score,
                boundingBox: rect,
            ));
        }
    }

    return results;
  }
}
