import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hand_detection/hand_detection.dart';
import '../services/gesture_detection_service.dart';
import '../services/tts_service.dart';
import '../providers/language_provider.dart';
import '../utils/app_localization.dart';
import 'package:provider/provider.dart';

class GestureScreen extends StatefulWidget {
  final bool fromVoice;
  const GestureScreen({super.key, this.fromVoice = false});

  @override
  State<GestureScreen> createState() => _GestureScreenState();
}

class _GestureScreenState extends State<GestureScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  GestureDetectionService? _gestureService;
  bool _isCameraReady = false;
  bool _isDetectorReady = false;
  bool _isProcessing = false;
  bool _isFrontCamera = false;
  String _gestureLabel = '';
  String? _lastSpokenGesture;
  bool _isGestureSpeaking = false;
  int _fps = 0;
  int _frameCount = 0;
  Timer? _fpsTimer;
  StreamSubscription<CameraImage>? _cameraStreamSubscription;
  final TtsService _tts = TtsService();

  // No-hand grace period (300 ms) before clearing gesture state
  Timer? _noHandGraceTimer;
  // Periodic 5-second reminder while hand remains absent
  Timer? _noGestureReminderTimer;
  // Prevents "no gesture detected" from being spoken more than once per absence
  bool _hasAnnouncedNoGesture = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fpsTimer?.cancel();
    _noHandGraceTimer?.cancel();
    _noGestureReminderTimer?.cancel();
    _disposeAll();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      _initialize();
    }
  }

  Future<void> _initialize() async {
    await _initializeGestureDetector();
    await _initializeCamera();
    _startFpsTimer();
  }

  Future<void> _initializeGestureDetector() async {
    final service = GestureDetectionService();
    await service.initialize();
    if (!mounted) return;
    setState(() {
      _gestureService = service;
      _isDetectorReady = true;
    });
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await controller.initialize();
      if (!mounted) return;

      _isFrontCamera = camera.lensDirection == CameraLensDirection.front;

      setState(() {
        _cameraController = controller;
        _isCameraReady = true;
      });

      await controller.startImageStream(_processCameraImage);
    } catch (e) {
      debugPrint('Gesture camera init failed: $e');
      if (mounted) {
        setState(() {
          _isCameraReady = false;
          _gestureLabel = AppLocalizations.t(context, 'camera_error');
        });
      }
    }
  }

  Future<void> _disposeCamera() async {
    if (_cameraController != null) {
      try {
        if (_cameraController!.value.isStreamingImages) {
          await _cameraController!.stopImageStream();
        }
      } catch (_) {}
      try {
        await _cameraController!.dispose();
      } catch (_) {}
    }
    _cameraController = null;
    _isCameraReady = false;
  }

  Future<void> _disposeAll() async {
    await _disposeCamera();
    await _gestureService?.dispose();
  }

  void _startFpsTimer() {
    _fpsTimer?.cancel();
    _fpsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _fps = _frameCount;
          _frameCount = 0;
        });
      }
    });
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (!_isCameraReady || !_isDetectorReady || _isProcessing) return;

    _isProcessing = true;
    _frameCount += 1;

    final rotation = rotationForFrame(
      width: image.width,
      height: image.height,
      sensorOrientation: _cameraController?.description.sensorOrientation ?? 0,
      isFrontCamera: _isFrontCamera,
      deviceOrientation: _cameraController?.value.deviceOrientation ??
          DeviceOrientation.portraitUp,
    );

    try {
      final hands = await _gestureService!.detectFromCameraImage(
        image,
        rotation: rotation,
        maxDim: 640,
      );

      if (!mounted) return;

      String label = AppLocalizations.t(context, 'no gesture detected');
      String? spokenGesture;

      if (hands.isNotEmpty) {
        // Hand is visible — cancel any pending no-hand timers and reset absence state
        _noHandGraceTimer?.cancel();
        _noHandGraceTimer = null;
        _noGestureReminderTimer?.cancel();
        _noGestureReminderTimer = null;
        _hasAnnouncedNoGesture = false;

        final first = hands.first;
        final gestureType = first.gesture?.type.name;
        if (gestureType != null && gestureType != 'unknown') {
          // Recognised, supported gesture — announce immediately, no delay
          label = gestureType;
          spokenGesture = gestureType;
        } else {
          // Hand visible but gesture not recognised — update label silently
          label = AppLocalizations.t(context, 'hand detected');
        }
      } else {
        // No hand visible — start 300 ms grace timer (only if not already running)
        if (_noHandGraceTimer == null) {
          _noHandGraceTimer = Timer(const Duration(milliseconds: 300), () {
            _noHandGraceTimer = null;
            _lastSpokenGesture = null; // clear dedup state after grace expires
            _announceNoGesture();
          });
        }
      }

      setState(() {
        _gestureLabel = label;
      });

      // Valid gestures only — fires instantly on the first qualifying frame
      if (spokenGesture != null && spokenGesture != _lastSpokenGesture) {
        _lastSpokenGesture = spokenGesture;
        _speakDetectedGesture(spokenGesture);
      }
    } catch (e) {
      debugPrint('Gesture detection failed: $e');
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _speakGesture() async {
    final text = _gestureLabel.isEmpty
        ? AppLocalizations.t(context, 'no gesture detected')
        : _gestureLabel;
    await _tts.stop();
    await _tts.speak(text, lang: Provider.of<LanguageProvider>(context, listen: false).ttsLanguage);
  }

  Future<void> _speakDetectedGesture(String gesture) async {
    if (_isGestureSpeaking) return;
    _isGestureSpeaking = true;

    final language = Provider.of<LanguageProvider>(context, listen: false).ttsLanguage;
    final friendlyLabel = _getFriendlyGestureLabel(gesture);
    
    try {
      await _tts.stop();
      await _tts.speak(
        friendlyLabel,
        lang: language,
      );
    } finally {
      _isGestureSpeaking = false;
    }
  }

  /// Speaks "no gesture detected" once per hand-absence event,
  /// then sets up a 5-second periodic reminder while the hand stays absent.
  void _announceNoGesture() {
    if (!mounted) return;
    if (_hasAnnouncedNoGesture) return;
    _hasAnnouncedNoGesture = true;
    if (!widget.fromVoice) {
      _speakNoGesture();
    }
    _noGestureReminderTimer?.cancel();
    _noGestureReminderTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _speakNoGesture();
    });
  }

  Future<void> _speakNoGesture() async {
    if (!mounted) return;
    final language =
        Provider.of<LanguageProvider>(context, listen: false).ttsLanguage;
    final text = AppLocalizations.t(context, 'no gesture detected');
    await _tts.stop();
    await _tts.speak(text, lang: language);
  }

  String _getFriendlyGestureLabel(String gestureType) {
    final map = {
      'closedFist': 'Closed Fist',
      'openPalm': 'Open Palm',
      'pointingUp': 'Pointing Up',
      'thumbDown': 'Thumbs Down',
      'thumbUp': 'Thumbs Up',
      'victory': 'Victory Sign',
      'iLoveYou': 'I Love You',
      'unknown': 'Unknown Gesture',
    };
    return map[gestureType] ?? gestureType;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.t(context, 'gesture_mode')),
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
              child: !_isCameraReady
                  ? Center(
                      child: Text(
                        AppLocalizations.t(context, 'camera_not_ready'),
                        style: const TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    )
                  : AspectRatio(
                      aspectRatio: _cameraController!.value.aspectRatio,
                      child: CameraPreview(_cameraController!),
                    ),
            ),
          ),
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
                      if (mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: Text(AppLocalizations.t(context, 'back')),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _speakGesture,
                    icon: const Icon(Icons.mic),
                    label: Text(AppLocalizations.t(context, 'speak')),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _speakGesture,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.pan_tool),
                    label: Text(AppLocalizations.t(context, 'detect')),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade50,
              child: Text(
                _gestureLabel.isEmpty
                    ? AppLocalizations.t(context, 'gesture_instructions')
                    : _getFriendlyGestureLabel(_gestureLabel),
                style: TextStyle(
                  fontSize: Provider.of<LanguageProvider>(context).fontSize,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}