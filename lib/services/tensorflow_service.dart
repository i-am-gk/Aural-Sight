import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../utils/detection_constants.dart';

class TensorflowService {
  // Singleton pattern
  static final TensorflowService _instance = TensorflowService._internal();
  factory TensorflowService() => _instance;
  TensorflowService._internal();

  Interpreter? _interpreter;
  List<String>? _labels;

  Interpreter? get interpreter => _interpreter;
  List<String> get labels => _labels ?? [];

  Future<void> initialize() async {
    await Future.wait([
      _loadModel(),
      _loadLabels(),
    ]);
  }

  Future<void> _loadModel() async {
    try {
      final options = InterpreterOptions();
      // Add delegates if needed, e.g., XNNPackDelegate or GPUDelegate
      // options.addDelegate(XNNPackDelegate()); 

      _interpreter = await Interpreter.fromAsset(
        DetectionConstants.modelPath,
        options: options,
      );
      
      // Allocate tensors if required by specific TFLite version/model
      // _interpreter?.allocateTensors(); 
    } catch (e) {
      print('Error loading model: $e');
    }
  }

  Future<void> _loadLabels() async {
    try {
      final labelsRaw = await rootBundle.loadString(DetectionConstants.labelPath);
      _labels = labelsRaw.split('\n');
    } catch (e) {
      print('Error loading labels: $e');
    }
  }

  void dispose() {
    _interpreter?.close();
  }
}
