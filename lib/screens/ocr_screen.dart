// lib/screens/ocr_screen.dart
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:provider/provider.dart';
import '../services/metrics_logger.dart';
import '../services/tts_service.dart';
import '../providers/language_provider.dart';
import '../utils/app_localization.dart';

class OcrScreen extends StatefulWidget {
  final bool fromVoice;
  const OcrScreen({super.key, this.fromVoice = false});

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _busy = false;
  bool _autoMode = false;
  Timer? _autoTimer;
  String _ocrText = "";
  String _lastReadText = "";

  final TtsService _tts = TtsService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupCamera().then((_) {
      if (mounted && _isCameraInitialized && !_autoMode) {
        _toggleAutoMode(initialCall: true);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoTimer?.cancel();
    _disposeCamera();
    _tts.stop();
    super.dispose();
  }

  /// CAMERA LIFECYCLE
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      _setupCamera();
    }
  }

  Future<void> _setupCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) return;

      final camera = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) return;

      setState(() {
        _controller = controller;
        _isCameraInitialized = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _ocrText = "Camera error");
    }
  }

  Future<void> _disposeCamera() async {
    try {
      if (_controller != null) {
        await _controller!.dispose();
      }
    } catch (_) {}
    _controller = null;
    _isCameraInitialized = false;

    if (mounted) setState(() {});
  }

  /// AUTO MODE
  void _toggleAutoMode({bool initialCall = false}) async {
    final settings = Provider.of<LanguageProvider>(context, listen: false);

    if (_autoMode) {
      _autoTimer?.cancel();
      setState(() => _autoMode = false);
      if (!initialCall || !widget.fromVoice) {
        await _tts.speak(AppLocalizations.t(context, 'auto_read_stopped'),
            lang: settings.ttsLanguage);
      }
      return;
    }

    setState(() => _autoMode = true);

    if (!initialCall || !widget.fromVoice) {
      await _tts.speak(AppLocalizations.t(context, 'auto_read_started'),
          lang: settings.ttsLanguage);
    }

    _autoTimer = Timer.periodic(
        const Duration(seconds: 5), (_) => _autoCaptureAndRead());
  }

  Future<void> _autoCaptureAndRead() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        !_isCameraInitialized ||
        _busy) return;

    final settings = Provider.of<LanguageProvider>(context, listen: false);
    // [METRICS] Start response time measurement
    final metricsStopwatch = Stopwatch()..start();

    try {
      _busy = true;

      final XFile file = await _controller!.takePicture();
      final inputImage = InputImage.fromFilePath(file.path);

      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final result = await recognizer.processImage(inputImage);
      await recognizer.close();

      final text = result.text.trim();

      // [METRICS] Log OCR result (non-blocking, silent fail)
      try {
        metricsStopwatch.stop();
        MetricsLogger().logDetection(
          module: 'ocr',
          input: 'camera_frame_auto',
          actualOutput: text.isEmpty ? '[no_text]' : text.length > 80 ? '${text.substring(0, 80)}...' : text,
          success: text.isNotEmpty,
          confidence: text.isNotEmpty ? 1.0 : 0.0,
          responseTime: metricsStopwatch.elapsedMilliseconds / 1000.0,
        );
      } catch (_) {}

      if (text.isEmpty || text == _lastReadText) return;

      _lastReadText = text;
      _ocrText = text;

      if (mounted) setState(() {});

      await _tts.speak(text, lang: settings.ttsLanguage);
    } catch (e) {
      debugPrint("Auto OCR error: $e");
    } finally {
      _busy = false;
    }
  }

  /// MANUAL CAPTURE
  Future<void> _captureAndRead() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        !_isCameraInitialized ||
        _busy) return;

    final settings = Provider.of<LanguageProvider>(context, listen: false);
    // [METRICS] Start response time measurement
    final metricsStopwatch = Stopwatch()..start();

    setState(() {
      _busy = true;
      _ocrText = "";
    });

    try {
      final XFile file = await _controller!.takePicture();
      final inputImage = InputImage.fromFilePath(file.path);

      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final result = await recognizer.processImage(inputImage);
      await recognizer.close();

      final text = result.text.trim();

      // [METRICS] Log OCR result (non-blocking, silent fail)
      try {
        metricsStopwatch.stop();
        MetricsLogger().logDetection(
          module: 'ocr',
          input: 'camera_frame_manual',
          actualOutput: text.isEmpty ? '[no_text]' : text.length > 80 ? '${text.substring(0, 80)}...' : text,
          success: text.isNotEmpty,
          confidence: text.isNotEmpty ? 1.0 : 0.0,
          responseTime: metricsStopwatch.elapsedMilliseconds / 1000.0,
        );
      } catch (_) {}

      _ocrText = text.isEmpty
          ? AppLocalizations.t(context, 'no_text_recognized_yet')
          : text;

      await _tts.speak(_ocrText, lang: settings.ttsLanguage);
    } catch (e) {
      debugPrint("Manual OCR error: $e");
      _ocrText = AppLocalizations.t(context, 'camera_error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _speakLast() async {
    final settings = Provider.of<LanguageProvider>(context, listen: false);

    final text = _ocrText.trim().isEmpty
        ? AppLocalizations.t(context, 'no_text_recognized_yet')
        : _ocrText;

    await _tts.speak(text, lang: settings.ttsLanguage);
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.t(context, 'text_sign_reading')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            await _tts.stop();
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 6,
            child: Container(
              color: Colors.grey.shade200,
              child: (!_isCameraInitialized ||
                      _controller == null ||
                      !_controller!.value.isInitialized)
                  ? Center(
                      child: _busy
                          ? const CircularProgressIndicator()
                          : Text(
                              AppLocalizations.t(context, 'camera_not_ready'),
                              style: const TextStyle(
                                  fontSize: 18, color: Colors.grey),
                            ),
                    )
                  : AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: CameraPreview(_controller!),
                    ),
            ),
          ),

          /// BUTTONS
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _tts.stop();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: Text(AppLocalizations.t(context, 'back')),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _busy ? null : _speakLast,
                    icon: const Icon(Icons.mic),
                    label: Text(AppLocalizations.t(context, 'speak')),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _busy ? null : _captureAndRead,
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.camera_alt),
                    label: Text(AppLocalizations.t(context, 'capture_read')),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _toggleAutoMode,
                    icon: Icon(_autoMode ? Icons.stop : Icons.autorenew),
                    label: Text(_autoMode
                        ? AppLocalizations.t(context, 'auto_read_stop')
                        : AppLocalizations.t(context, 'auto_read')),
                  ),
                ],
              ),
            ),
          ),

          /// RECOGNIZED TEXT
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade50,
              child: SingleChildScrollView(
                child: Text(
                  _ocrText.isEmpty
                      ? AppLocalizations.t(
                          context, 'recognized_text_will_appear')
                      : _ocrText,
                  style: TextStyle(
                    fontSize: settings.fontSize,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
