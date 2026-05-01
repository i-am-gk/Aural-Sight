import 'dart:ui';

class DetectedObject {
  final String label;
  final double confidence;
  // boundingBox logic: [left, top, width, height]
  final Rect boundingBox;

  const DetectedObject({
    required this.label,
    required this.confidence,
    required this.boundingBox,
  });

  @override
  String toString() {
    return 'DetectedObject(label: $label, confidence: ${confidence.toStringAsFixed(2)}, box: $boundingBox)';
  }
}
