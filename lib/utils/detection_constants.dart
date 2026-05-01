
class DetectionConstants {
  const DetectionConstants._();

  static const String modelPath = 'assets/model/ssd_mobilenet_v1.tflite';
  static const String labelPath = 'assets/label/labels.txt';

  static const int inputSize = 300;

  // [IMPROVEMENT 1] Two-tier confidence strategy:
  // visualThreshold — minimum score to display a bounding box / include in results
  static const double confidenceThreshold = 0.45;

  // speechThreshold — minimum score required before TTS speaks the label
  static const double speechThreshold = 0.60;
}
