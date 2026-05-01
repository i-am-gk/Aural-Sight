import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:math';

import '../main.dart';
import '../providers/language_provider.dart';
import '../screens/object_detection_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/ocr_screen.dart';
import '../screens/gesture_screen.dart';
import 'tts_service.dart';
import 'command_service.dart';

class WakeWordService {
  static final WakeWordService _instance = WakeWordService._internal();
  factory WakeWordService() => _instance;
  WakeWordService._internal();

  final AudioRecorder _audioRecorder = AudioRecorder();
  StreamSubscription<Uint8List>? _audioStreamSubscription;

  bool _isListening = false;
  bool _isActivated = false;
  bool _isCooldown = false;

  DateTime _lastActivationTime = DateTime.now();

  Interpreter? _interpreter;
  bool _isModelReady = false;
  static const int _sampleRate = 16000;
  static const int _windowSamples = 16000;
  final Float64List _ringBuffer = Float64List(_windowSamples);
  int _bufferIndex = 0;
  bool _bufferFilled = false;

  Timer? _inferenceTimer;
  static const int _inferenceIntervalMs = 200;
  static const double _wakeThreshold = 0.99;
  static const double _energyThreshold = 0.01;
  static const int _debounceMs = 2000;
  static const int _cooldownMs = 3000;
  Timer? _activationTimer;
  bool _pendingActivation = false;

  Future<void> startListening() async {
    if (_isListening) return;

    final hasPermission = await Permission.microphone.request().isGranted;
    if (!hasPermission) {
      print("WakeWord: Microphone permission denied.");
      return;
    }

    print("WakeWord: Initializing...");

    if (!_isModelReady) {
      await _initModel();
    }

    try {
      final stream = await _audioRecorder.startStream(const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _sampleRate,
        numChannels: 1,
      ));

      _isListening = true;
      print("WakeWord: ✅ Listening for 'hey luna'...");

      _audioStreamSubscription = stream.listen((Uint8List data) {
        if (_isActivated || _isCooldown) return;
        _addAudioData(data);
      });

      _startInferenceTimer();
    } catch (e) {
      print("WakeWord: Error starting stream: $e");
      _isListening = false;
    }
  }

  Future<void> _initModel() async {
    print("WakeWord: Loading custom TFLite wake word model...");

    final tempDir = await getTemporaryDirectory();
    final modelPath = '${tempDir.path}/hey_luna_raw_model.tflite';
    final modelFile = File(modelPath);
    if (!await modelFile.exists()) {
      final byteData = await rootBundle.load('assets/hey_luna_raw_model.tflite');
      await modelFile.writeAsBytes(byteData.buffer.asUint8List());
      print("WakeWord: Model copied to temp, size: ${byteData.lengthInBytes} bytes");
    } else {
      final size = await modelFile.length();
      print("WakeWord: Model already exists at $modelPath, size: $size bytes");
    }

    _interpreter = await Interpreter.fromFile(modelFile);
    _isModelReady = true;

    final inputTensor = _interpreter!.getInputTensor(0);
    final outputTensor = _interpreter!.getOutputTensor(0);
    print("========== MODEL DETAILS ==========");
    print("Input shape: ${inputTensor.shape}");
    print("Input type: ${inputTensor.type}");
    print("Output shape: ${outputTensor.shape}");
    print("Output type: ${outputTensor.type}");
    print("===================================");
  }

  void _addAudioData(Uint8List data) {
    for (int i = 0; i < data.length; i += 2) {
      if (i + 1 >= data.length) break;
      final sample = (data[i] | (data[i + 1] << 8)).toSigned(16);
      _ringBuffer[_bufferIndex] = sample.toDouble();
      _bufferIndex++;
      if (_bufferIndex >= _windowSamples) {
        _bufferIndex = 0;
        _bufferFilled = true;
      }
    }
  }

  void _startInferenceTimer() {
    _inferenceTimer?.cancel();
    _inferenceTimer = Timer.periodic(Duration(milliseconds: _inferenceIntervalMs), (_) {
      if (_isActivated || _isCooldown) return;
      if (!_bufferFilled) return;
      _runInference();
    });
  }

  void _runInference() {
    if (_interpreter == null) return;

    final inputData = Float32List(_windowSamples);
    double energy = 0.0;
    for (int i = 0; i < _windowSamples; i++) {
      final sample = _ringBuffer[i] / 32768.0;
      inputData[i] = sample;
      energy += sample * sample;
    }
    energy = sqrt(energy / _windowSamples);

    if (energy < _energyThreshold) return;

    final input = inputData.reshape([1, _windowSamples]);
    final output = List.filled(1, 0.0).reshape([1, 1]);

    try {
      _interpreter!.run(input, output);
      final confidence = output[0][0];
      if (confidence >= _wakeThreshold) {
        _onWakeWordDetected(confidence);
      }
    } catch (e) {
      print("WakeWord: Inference error: $e");
    }
  }

  void _onWakeWordDetected(double confidence) {
    final now = DateTime.now();
    if (now.difference(_lastActivationTime).inMilliseconds < _debounceMs) {
      print("WakeWord: ⏸️ Debounced (conf: ${confidence.toStringAsFixed(2)})");
      return;
    }
    _lastActivationTime = now;

    if (_pendingActivation) return;
    _pendingActivation = true;

    _activationTimer?.cancel();
    _activationTimer = Timer(const Duration(milliseconds: 150), () {
      _pendingActivation = false;
      print("🎯 WAKE WORD CONFIRMED! (conf: ${confidence.toStringAsFixed(2)})");
      _triggerActivation();
    });
  }

  Future<void> stopListening() async {
    print("WakeWord: Stopping...");
    _isListening = false;
    _pendingActivation = false;
    _activationTimer?.cancel();
    _inferenceTimer?.cancel();
    await _audioStreamSubscription?.cancel();
    await _audioRecorder.stop();
    _bufferFilled = false;
    _bufferIndex = 0;
  }

  Future<void> _triggerActivation() async {
    if (_isActivated || _isCooldown) return;

    _isActivated = true;
    _inferenceTimer?.cancel();
    await _audioStreamSubscription?.cancel();
    await _audioRecorder.stop();
    _isListening = false;

    await Future.delayed(const Duration(milliseconds: 200));

    print("🔥🔥🔥 WAKE WORD ACTIVATED! 🔥🔥🔥");

    await TtsService().prepare();
    await TtsService().stop();

    await TtsService().speak("I am listening");

    await Future.delayed(const Duration(milliseconds: 800));

    bool commandHandled = false;

    await CommandService().startCommandListening(
      onCommandDetected: (String command) async {
        if (commandHandled) return;
        commandHandled = true;

        await CommandService().stopCommandListening();

        print("WakeWord: 🎯 EXECUTING COMMAND: $command");

        final context = navigatorKey.currentContext;
        if (context != null) {
          if (command == "object_detection") {
            await TtsService().stop();
            await TtsService().speak("Opening object detection");
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => const ObjectDetectionScreen()
            ));
          } else if (command == "ocr_mode") {
            await TtsService().stop();
            await TtsService().speak("Opening OCR mode");
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => const OcrScreen()
            ));
          } else if (command == "gesture_mode") {
            await TtsService().stop();
            await TtsService().speak("Opening gesture mode");
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => const GestureScreen()
            ));
          } else if (command == "open_setting") {
            await TtsService().stop();
            await TtsService().speak("Opening settings");
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => const SettingsScreen()
            ));
          } else if (command == "go_back") {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              await TtsService().speak("You are already on the home screen");
            }
          } else if (command == "font_bigger") {
            final provider = Provider.of<LanguageProvider>(context, listen: false);
            if (provider.fontSize >= 32.0) {
              await TtsService().speak("Font is already at maximum size");
            } else {
              provider.fontSize = (provider.fontSize + 2.0).clamp(10.0, 32.0);
              await TtsService().speak("Font size increased to ${provider.fontSize.toStringAsFixed(0)}");
            }
          } else if (command == "font_smaller") {
            final provider = Provider.of<LanguageProvider>(context, listen: false);
            if (provider.fontSize <= 10.0) {
              await TtsService().speak("Font is already at minimum size");
            } else {
              provider.fontSize = (provider.fontSize - 2.0).clamp(10.0, 32.0);
              await TtsService().speak("Font size decreased to ${provider.fontSize.toStringAsFixed(0)}");
            }
          } else if (command == "change_theme") {
            final provider = Provider.of<LanguageProvider>(context, listen: false);
            provider.theme = provider.theme == 'teal' ? 'dark' : 'teal';
            await TtsService().speak("Theme changed");
          }
        }

        _isActivated = false;
        _isCooldown = true;

        print("WakeWord: ⏳ Cooldown (${_cooldownMs ~/ 1000} seconds)");
        await Future.delayed(Duration(milliseconds: _cooldownMs));

        _isCooldown = false;
        print("WakeWord: ✅ Listening resumed");
        await startListening();
      }
    );

    await Future.delayed(const Duration(seconds: 5));

    if (!commandHandled) {
      commandHandled = true;
      await CommandService().stopCommandListening();

      await TtsService().stop();
      await TtsService().speak("Listening cancelled");

      _isActivated = false;
      _isCooldown = true;
      await Future.delayed(Duration(milliseconds: _cooldownMs));
      _isCooldown = false;
      await startListening();
    }
  }

  void dispose() {
    _inferenceTimer?.cancel();
    _activationTimer?.cancel();
    _audioStreamSubscription?.cancel();
    _audioRecorder.dispose();
    _interpreter?.close();
  }
}