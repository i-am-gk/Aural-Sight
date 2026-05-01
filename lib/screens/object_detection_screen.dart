import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/detected_object.dart';
import '../services/detector_service.dart';
import '../services/tensorflow_service.dart';
import '../services/tts_service.dart';
import '../providers/language_provider.dart';
import '../utils/app_localization.dart';
import '../utils/detection_constants.dart';
import '../widgets/detection_box_overlay.dart';

class ObjectDetectionScreen extends StatefulWidget {
  const ObjectDetectionScreen({super.key});

  @override
  State<ObjectDetectionScreen> createState() =>
      _ObjectDetectionScreenState();
}

class _ObjectDetectionScreenState
    extends State<ObjectDetectionScreen>
    with WidgetsBindingObserver {

  CameraController? _cameraController;
  DetectorService? _detectorService;
  StreamSubscription<List<DetectedObject>>? _subscription;

  List<DetectedObject> _detections = [];
  bool _isInitializing = true;
  String? _errorMessage;

  bool _isBusy = false;
  bool _autoMode = false;
  bool _isLiveMode = true;
  bool _isCapturingSingleFrame = false;
  bool _isProcessingFrame = false;

  int _frameCount = 0;
  double _currentFps = 0.0;
  Timer? _fpsTimer;

  int _frameSkip = 0;
  int _lastProcessedTime = 0;

  String? _lastSpokenLabel;
  DateTime? _lastSpokenTime;
  double _lastSpokenConfidence = 0.0;

  // Temporal Label Stability History
  final List<String> _labelHistory = [];
  String? _stabilizedLabel;

  // Guidance logic
  DateTime? _lastDetectionTime;
  Timer? _guidanceTimer;
  bool _isPrioritySpeaking = false;
  final List<String> _guidanceKeys = [
    'guidance_no_objects',
    'guidance_adjust_light',
    'guidance_move_camera',
  ];
  int _guidanceIndex = 0;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
    _startFpsTimer();

  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fpsTimer?.cancel();
    _guidanceTimer?.cancel();


    _disposeResources();
    super.dispose();
  }

  void _startFpsTimer() {
    _fpsTimer?.cancel();
    _fpsTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isLiveMode) {
        setState(() {
          _currentFps = _frameCount.toDouble();
          _frameCount = 0;
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _fpsTimer?.cancel();
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _startFpsTimer();
      _initializeCamera();
    }
  }

  Future<void> _disposeResources() async {
    _subscription?.cancel();
    _detectorService?.dispose();
    if (_cameraController != null &&
        _cameraController!.value.isStreamingImages) {
      await _cameraController?.stopImageStream();
    }
    await _cameraController?.dispose();
  }

  Future<void> _initialize() async {
    try {
      await TensorflowService().initialize();
      await _initializeCamera();

      _detectorService = await DetectorService.start();

      _subscription =
          _detectorService?.resultsStream.listen((detections) {

        final filtered = _processDetections(detections);

        if (mounted) {
          _frameCount++;
          
          if (_detections.isEmpty && filtered.isEmpty) {
            // [NEW] Skip heavy UI rebuilding if nothing is detected
            _isProcessingFrame = false;
            return;
          }

          setState(() {
            _detections = _smoothBoxes(_detections, filtered);
            
            if (filtered.isNotEmpty) {
              _lastDetectionTime = DateTime.now();
            }
          });

          // Only announce automatically if Auto Mode is ON
          if (_autoMode) {
            _handleTts(filtered);
          }
        }

        _isProcessingFrame = false;
      });

      setState(() => _isInitializing = false);
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Failed to initialize: $e';
      });
    }
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final cameraDescription = cameras.firstWhere(
      (camera) =>
          camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await controller.initialize();

    if (mounted) {
      setState(() => _cameraController = controller);

      if (_isLiveMode) {
        await controller.startImageStream((image) {

          _frameSkip++;
          if (_frameSkip % 3 != 0) return;

          // [NEW] Time-based throttle (~3 FPS)
          final now = DateTime.now().millisecondsSinceEpoch;
          if (now - _lastProcessedTime < 300) return;

          // [NEW] Prevent overload
          if (_isProcessingFrame) return;

          _isProcessingFrame = true;
          _lastProcessedTime = now;

          // [NEW] Safer fallback unlock
          Future.delayed(const Duration(milliseconds: 300), () {
            if (_isProcessingFrame) {
              _isProcessingFrame = false;
            }
          });

          _detectorService?.processFrame(image);
        });
      }
    }
  }

  List<DetectedObject> _processDetections(
      List<DetectedObject> detections) {

    final List<DetectedObject> filtered = [];

    // 1. Filter by standardized confidence threshold
    for (var detection in detections) {
      if (detection.confidence < DetectionConstants.confidenceThreshold) continue;

      if (detection.label == "???" || detection.label == "??") continue;

      // Duplicate check (IOU/NMS approach for normalized coordinates)
      bool isDuplicate = filtered.any((existing) {
        if (existing.label != detection.label) return false;

        final r1 = existing.boundingBox;
        final r2 = detection.boundingBox;

        final intersectLeft = r1.left > r2.left ? r1.left : r2.left;
        final intersectTop = r1.top > r2.top ? r1.top : r2.top;
        final intersectRight = r1.right < r2.right ? r1.right : r2.right;
        final intersectBottom = r1.bottom < r2.bottom ? r1.bottom : r2.bottom;

        final intersectWidth = intersectRight - intersectLeft;
        final intersectHeight = intersectBottom - intersectTop;

        if (intersectWidth <= 0 || intersectHeight <= 0) return false;

        final intersectArea = intersectWidth * intersectHeight;
        final r1Area = r1.width * r1.height;
        final r2Area = r2.width * r2.height;

        final unionArea = r1Area + r2Area - intersectArea;
        
        // Return true if boxes overlap by more than 40% (IOU > 0.4)
        return (intersectArea / unionArea) > 0.4;
      });

      if (!isDuplicate) {
        filtered.add(detection);
      }
    }

    // 2. Temporal Label Stabilization (Majority Voting)
    if (filtered.isNotEmpty) {
      filtered.sort((a, b) => b.confidence.compareTo(a.confidence));
      final bestDetection = filtered.first;

      // Update rolling buffer (max 5 frames for lower latency)
      _labelHistory.add(bestDetection.label);
      if (_labelHistory.length > 5) {
        _labelHistory.removeAt(0);
      }

      // Calculate label frequencies in the buffer
      final labelCounts = <String, int>{};
      for (var label in _labelHistory) {
        labelCounts[label] = (labelCounts[label] ?? 0) + 1;
      }

      String? modeLabel;
      int maxCount = 0;
      labelCounts.forEach((label, count) {
        if (count > maxCount) {
          maxCount = count;
          modeLabel = label;
        }
      });

      // Require 3 out of 5 frames to confirm a label (majority vote)
      if (modeLabel != null && maxCount >= 3) {
        _stabilizedLabel = modeLabel;
      }
    } else {
      // If no detections, add 'None' to phase out history
      _labelHistory.add('None');
      if (_labelHistory.length > 5) _labelHistory.removeAt(0);
      
      // If majority of last 5 frames are 'None', clear the stabilized label
      int noneCount = _labelHistory.where((l) => l == 'None').length;
      if (noneCount >= 3) _stabilizedLabel = null;
    }

    // 3. Return stabilized result
    // We only show detections that match the consensus stabilized label
    if (_stabilizedLabel != null && _stabilizedLabel != 'None') {
      return filtered.where((d) => d.label == _stabilizedLabel).toList();
    }

    return [];
  }

  List<DetectedObject> _smoothBoxes(
    List<DetectedObject> old,
    List<DetectedObject> newList,
  ) {
    if (old.isEmpty) return newList;

    final smoothed = <DetectedObject>[];

    for (var n in newList) {
      // --- Improved Matching: label + spatial proximity ---
      // Find closest old box with the same label within a normalized distance threshold.
      // This prevents incorrect matching when multiple same-label objects exist.
      DetectedObject match = n; // fallback: no match means treat new as authoritative
      double bestDist = double.infinity;
      final nCenter = n.boundingBox.center;

      for (final o in old) {
        if (o.label != n.label) continue;
        final oCenter = o.boundingBox.center;
        final dx = nCenter.dx - oCenter.dx;
        final dy = nCenter.dy - oCenter.dy;
        final dist = dx * dx + dy * dy; // squared distance (no sqrt needed for comparison)
        if (dist < bestDist) {
          bestDist = dist;
          match = o;
        }
      }

      // Only use old match if within 0.3 normalized units (0.09 squared)
      // Beyond that, treat the new detection as authoritative to avoid drifting
      if (bestDist > 0.09) {
        smoothed.add(n);
        continue;
      }

      // --- Adaptive Smoothing: movement-based blend factor ---
      // Small movement → stronger smoothing (less jitter)
      // Large movement → weaker smoothing (more responsive)
      // dist is already squared; sqrt to get real distance
      final centerDist = bestDist < 0.0001 ? 0.0 : bestDist.isFinite ? (bestDist < 1.0 ? bestDist : 1.0) : 1.0;

      // Map distance to new-box weight: small dist → lower newWeight, large dist → higher newWeight
      // Range: newWeight in [0.55, 0.85] based on movement magnitude
      // At dist=0.0 → newWeight=0.55 (heavy smoothing), at dist=0.09 → newWeight=0.85 (responsive)
      double newWeight = 0.55 + (centerDist / 0.09) * 0.30;
      newWeight = newWeight.clamp(0.55, 0.85);

      // --- Confidence-Aware Smoothing ---
      // High confidence → trust new box more (+0.05 shift toward new)
      // Low confidence  → trust old box more (-0.05 shift toward new)
      if (n.confidence >= 0.75) {
        newWeight = (newWeight + 0.05).clamp(0.55, 0.90);
      } else if (n.confidence < 0.50) {
        newWeight = (newWeight - 0.05).clamp(0.50, 0.85);
      }

      final oldWeight = 1.0 - newWeight;

      final smoothRect = Rect.fromLTRB(
        (match.boundingBox.left  * oldWeight) + (n.boundingBox.left  * newWeight),
        (match.boundingBox.top   * oldWeight) + (n.boundingBox.top   * newWeight),
        (match.boundingBox.right * oldWeight) + (n.boundingBox.right * newWeight),
        (match.boundingBox.bottom * oldWeight) + (n.boundingBox.bottom * newWeight),
      );

      smoothed.add(
        DetectedObject(
          label: n.label,
          confidence: n.confidence,
          boundingBox: smoothRect,
        ),
      );
    }

    return smoothed;
  }

  Future<void> _handleTts(List<DetectedObject> detections) async {
    if (detections.isEmpty || _isPrioritySpeaking) return;

    final best = detections.reduce(
        (a, b) => a.confidence > b.confidence ? a : b);

    if (best.confidence < DetectionConstants.speechThreshold) return;

    final now = DateTime.now();
    final isNewObject = _lastSpokenLabel != best.label;

    if (!isNewObject && _lastSpokenTime != null &&
        now.difference(_lastSpokenTime!).inSeconds < 5) {
      return;
    }

    final confidenceJump =
        best.confidence > (_lastSpokenConfidence + 0.25);

    if (isNewObject || confidenceJump) {
      _lastSpokenLabel = best.label;
      _lastSpokenTime = now;
      _lastSpokenConfidence = best.confidence;

      String spatialText;
      final centerX = best.boundingBox.center.dx;
      if (centerX < 0.33) {
        spatialText = "on your left";
      } else if (centerX > 0.66) {
        spatialText = "on your right";
      } else {
        spatialText = "in front of you";
      }

      final speechText = "${best.label} $spatialText";

      await TtsService().stop();
      await TtsService().speak(speechText);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Object Detection')),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    final previewSize = _cameraController!.value.previewSize!;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.t(context, 'object_detection')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            await TtsService().stop();
            if (mounted) Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: AspectRatio(
              aspectRatio:
                  _cameraController!.value.aspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CameraPreview(_cameraController!),
                  DetectionBoxOverlay(
                    detections: _detections,
                    previewSize: Size(
                      previewSize.height,
                      previewSize.width,
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'FPS: ${_currentFps.toInt()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// BUTTONS (Aligned with OCR Screen)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      await TtsService().stop();
                      if (mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: Text(AppLocalizations.t(context, 'back')),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _isBusy ? null : _handleSpeakPressed,
                    icon: const Icon(Icons.mic),
                    label: Text(AppLocalizations.t(context, 'speak')),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _isBusy ? null : _handleCaptureDetectPressed,
                    icon: _isBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.camera_alt),
                    label: Text(AppLocalizations.t(context, 'capture_detect')),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _toggleAutoDetect,
                    icon: Icon(_autoMode ? Icons.stop : Icons.autorenew),
                    label: Text(_autoMode
                        ? AppLocalizations.t(context, 'auto_detect_stop')
                        : AppLocalizations.t(context, 'auto_detect')),
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
              child: SingleChildScrollView(
                child: Text(
                  _detections.isEmpty
                      ? AppLocalizations.t(context, 'recognized_text_will_appear') // Or equivalent for objects
                      : _detections
                          .map((d) =>
                              "${d.label} (${(d.confidence * 100).toStringAsFixed(0)}%)")
                          .join("\n"),
                  style: TextStyle(
                    fontSize: Provider.of<LanguageProvider>(context).fontSize,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Button Handlers (Implemented) ---

  String _getDetectionsSummary() {
    if (_detections.isEmpty) {
      // Return localized guidance instead of empty string
      final key = _guidanceKeys[_guidanceIndex % _guidanceKeys.length];
      _guidanceIndex++;
      return AppLocalizations.t(context, key);
    }

    final labels = _detections.map((d) => d.label).toSet().toList();
    if (labels.length == 1) {
      return "I see a ${labels[0]}";
    }

    final last = labels.removeLast();
    return "I see ${labels.join(', ')} and $last";
  }

  Future<void> _handleSpeakPressed() async {
    final summary = _getDetectionsSummary();
    setState(() => _isPrioritySpeaking = true);
    await TtsService().stop();
    await TtsService().speak(summary);
    // Block detections for 2 seconds to let it finish
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isPrioritySpeaking = false);
    });
  }

  Future<void> _handleCaptureDetectPressed() async {
    setState(() {
      _isBusy = true;
      _isPrioritySpeaking = true;
    });
    
    // Provide immediate feedback with button name
    await TtsService().stop();
    await TtsService().speak(AppLocalizations.t(context, 'capture_detect_started'));

    // Wait for the button name to finish speaking (increased delay)
    await Future.delayed(const Duration(seconds: 2));

    final summary = _getDetectionsSummary();
    await TtsService().speak(summary);

    if (mounted) {
      setState(() => _isBusy = false);
      // Wait for the summary itself to finish before releasing priority
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _isPrioritySpeaking = false);
      });
    }
  }

  Future<void> _toggleAutoDetect() async {
    final settings = Provider.of<LanguageProvider>(context, listen: false);
    
    setState(() {
      _autoMode = !_autoMode;
      _isPrioritySpeaking = true;
      // Reset history when toggling to avoid stale announcements
      _labelHistory.clear();
      _stabilizedLabel = null;
      _lastDetectionTime = DateTime.now();
    });

    if (_autoMode) {
      _startGuidanceTimer();
    } else {
      _guidanceTimer?.cancel();
    }

    final messageKey = _autoMode ? 'auto_detect_started' : 'auto_detect_stopped';
    
    await TtsService().stop();
    await TtsService().speak(
      AppLocalizations.t(context, messageKey),
      lang: settings.ttsLanguage,
    );

    // Let the "Auto detection started/stopped" finish
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isPrioritySpeaking = false);
    });
  }

  void _startGuidanceTimer() {
    _guidanceTimer?.cancel();
    _guidanceTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      if (!mounted || !_autoMode || _isBusy) return;

      final now = DateTime.now();
      if (_lastDetectionTime != null && 
          now.difference(_lastDetectionTime!).inSeconds >= 15) {
        
        final key = _guidanceKeys[_guidanceIndex % _guidanceKeys.length];
        _guidanceIndex++;
        
        await TtsService().stop();
        await TtsService().speak(AppLocalizations.t(context, key));
        
        // Update last detection time to prevent immediate re-trigger
        _lastDetectionTime = now;
      }
    });
  }

}