import 'dart:async';
import 'dart:isolate';
import 'dart:ui'; // For RootIsolateToken

import 'package:camera/camera.dart';
import 'package:flutter/services.dart'; // For BackgroundIsolateBinaryMessenger
import 'package:tflite_flutter/tflite_flutter.dart';

import 'tensorflow_service.dart';
import '../models/detected_object.dart';
import '../utils/detection_constants.dart';
import '../utils/detection_helper.dart';
import '../utils/image_utils.dart';

// Command types for Isolate communication
enum _CommandType { init, detect, busy, result, ready }

class _Command {
  final _CommandType type;
  final List<Object?>? args;
  const _Command(this.type, {this.args});
}

class DetectorService {
  DetectorService._(this._isolate, this._sendPort);

  final Isolate _isolate;
  final SendPort _sendPort;
  SendPort? _isolateSendPort;
  bool _isReady = false;

  // Stream to send results back to UI
  final StreamController<List<DetectedObject>> _resultsStreamController = StreamController<List<DetectedObject>>();
  Stream<List<DetectedObject>> get resultsStream => _resultsStreamController.stream;

  static Future<DetectorService> start() async {
    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn(_DetectorIsolate._run, receivePort.sendPort);

    final result = DetectorService._(isolate, receivePort.sendPort);
    
    // Listen to messages from the isolate
    receivePort.listen((message) {
      result._handleCommand(message as _Command);
    });

    return result;
  }

  void processFrame(CameraImage cameraImage) {
    if (_isReady && _isolateSendPort != null) {
      _isolateSendPort!.send(_Command(_CommandType.detect, args: [cameraImage]));
    }
  }

  void _handleCommand(_Command command) {
    switch (command.type) {
      case _CommandType.init:
        // The isolate needs the RootIsolateToken to initialize background plugins
         final sendPort = command.args?[0] as SendPort;
         _isolateSendPort = sendPort;
         RootIsolateToken rootIsolateToken = RootIsolateToken.instance!;
         
         // Reuse interpreter from singleton
         final interpreter = TensorflowService().interpreter;
         final labels = TensorflowService().labels;
         
         sendPort.send(_Command(_CommandType.init, args: [
           rootIsolateToken,
           interpreter?.address, // Passing native address of the interpreter
           labels
         ]));
        break;
      case _CommandType.ready:
        _isReady = true;
        break;
      case _CommandType.busy:
        _isReady = false;
        break;
      case _CommandType.result:
        _isReady = true;
        final rawList = command.args?[0] as List?;
        final results = rawList == null ? <DetectedObject>[] : List<DetectedObject>.from(rawList);
        if (!_resultsStreamController.isClosed) {
          _resultsStreamController.add(results);
        }
        break;
      default:
        print('DetectorService: Unknown command ${command.type}');
    }
  }

  void dispose() {
    _resultsStreamController.close();
    _isolate.kill();
  }
}

class _DetectorIsolate {
  static void _run(SendPort sendPort) {
    final receivePort = ReceivePort();
    final server = _DetectorIsolate(sendPort);
    
    receivePort.listen((message) {
      server._handleCommand(message as _Command);
    });

    // Handshake: send our receivePort to the main isolate
    sendPort.send(_Command(_CommandType.init, args: [receivePort.sendPort]));
  }

  final SendPort _sendPort;
  Interpreter? _interpreter;
  List<String>? _labels;

  _DetectorIsolate(this._sendPort);

  Future<void> _handleCommand(_Command command) async {
    switch (command.type) {
      case _CommandType.init:
        try {
          final rootToken = command.args?[0] as RootIsolateToken;
          final interpreterAddress = command.args?[1] as int?;
          final labels = (command.args?[2] as List?)?.cast<String>();

          BackgroundIsolateBinaryMessenger.ensureInitialized(rootToken);

          if (interpreterAddress != null) {
            _interpreter = Interpreter.fromAddress(interpreterAddress);
          }
          _labels = labels;

          _sendPort.send(const _Command(_CommandType.ready));
        } catch (e) {
          print('DetectorIsolate Init Error: $e');
        }
        break;

      case _CommandType.detect:
        _sendPort.send(const _Command(_CommandType.busy));
        final cameraImage = command.args?[0] as CameraImage;
        _runInference(cameraImage);
        break;
        
      default:
        print('_DetectorIsolate: Unknown command ${command.type}');
    }
  }

  void _runInference(CameraImage cameraImage) {
    if (_interpreter == null || _labels == null) {
      // Return empty list if not ready
      _sendPort.send(const _Command(_CommandType.result, args: [[]])); 
      return;
    }

    try {
      // 1 & 2. Convert and Resize in one pass (Optimized)
      final resizedImage = ImageUtils.convertAndResize(
        cameraImage, 
        DetectionConstants.inputSize,
      );
      
      if (resizedImage == null) {
        _sendPort.send(const _Command(_CommandType.result, args: [[]]));
        return;
      }

      // 3. Run Inference
      final results = DetectionHelper.runInference(
        image: resizedImage,
        interpreter: _interpreter!,
        labels: _labels!,
      );

      // 4. Send Results Back
      _sendPort.send(_Command(_CommandType.result, args: [results]));
      
    } catch (e) {
      print('Inference Error: $e');
      _sendPort.send(const _Command(_CommandType.result, args: [[]]));
    }
  }
}
