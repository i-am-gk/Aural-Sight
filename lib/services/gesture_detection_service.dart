import 'package:camera/camera.dart';
import 'package:hand_detection/hand_detection.dart';

class GestureDetectionService {
  HandDetector? _handDetector;

  bool get isReady => _handDetector?.isReady ?? false;

  Future<void> initialize() async {
    _handDetector = await HandDetector.create(
      enableGestures: true,
      gestureMinConfidence: 0.55,
      mode: HandMode.boxesAndLandmarks,
    );
  }

  Future<List<Hand>> detectFromCameraImage(
    CameraImage image, {
    CameraFrameRotation? rotation,
    bool? isBgra,
    int? maxDim,
  }) async {
    if (_handDetector == null) {
      throw StateError('GestureDetectionService not initialized.');
    }
    return _handDetector!.detectFromCameraImage(
      image,
      rotation: rotation,
      isBgra: isBgra,
      maxDim: maxDim,
    );
  }

  Future<void> dispose() async {
    await _handDetector?.dispose();
    _handDetector = null;
  }
}