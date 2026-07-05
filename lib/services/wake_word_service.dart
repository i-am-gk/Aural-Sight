import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:vosk_flutter/vosk_flutter.dart';

import '../main.dart';
import '../providers/language_provider.dart';
import '../screens/gesture_screen.dart';
import '../screens/object_detection_screen.dart';
import '../screens/ocr_screen.dart';
import '../screens/settings_screen.dart';
import 'tts_service.dart';

class WakeWordService {
  static final WakeWordService _instance = WakeWordService._internal();
  factory WakeWordService() => _instance;
  WakeWordService._internal();

  final VoskFlutterPlugin _vosk = VoskFlutterPlugin.instance();
  Model? _model;
  Recognizer? _recognizer;
  SpeechService? _speechService;

  bool _initialized = false;
  bool _isListening = false;
  bool _isCommandMode = false;
  bool _isCooldown = false;

  final ValueNotifier<bool> isCommandModeNotifier = ValueNotifier<bool>(false);

  Timer? _commandModeTimer;
  Timer? _cooldownTimer;
  StreamSubscription<String>? _resultSubscription;
  DateTime? _lastThemeToggle;
  double _fontScale = 1.0;
  static const double _fontScaleStep = 0.2;

  static const String _modelAssetPath = 'assets/model/vosk-model-small-en-us-0.15.zip';
  static const int _sampleRate = 16000;
  static const int _commandTimeoutSeconds = 8;
  static const int _cooldownMs = 3000;

  Future<void> startListening() async {
    if (_isListening || _isCooldown) return;

    final hasPermission = await Permission.microphone.request().isGranted;
    if (!hasPermission) {
      print('WakeWordService: microphone permission denied.');
      return;
    }

    await _initVosk();
    if (_speechService == null) return;

    await _resultSubscription?.cancel();
    _resultSubscription = _speechService!.onResult().listen(_onResult);

    try {
      await _speechService!.start();
      _isListening = true;
      print('WakeWordService: listening for wake word...');
    } catch (e) {
      print('WakeWordService: failed to start speech service: $e');
    }
  }

  Future<void> _initVosk() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final modelPath = await ModelLoader().loadFromAssets(_modelAssetPath);
      _model = await _vosk.createModel(modelPath);
      _recognizer = await _vosk.createRecognizer(
        model: _model!,
        sampleRate: _sampleRate,
      );
      _speechService = await _vosk.initSpeechService(_recognizer!);
      print('WakeWordService: Vosk model loaded.');
    } catch (e) {
      print('WakeWordService: Vosk initialization failed: $e');
    }
  }

  void _onResult(String resultJson) async {
    if (!_isListening) return;

    try {
      final data = jsonDecode(resultJson) as Map<String, dynamic>;
      final rawText = (data['text'] as String? ?? '').trim().toLowerCase();
      if (rawText.isEmpty) return;

      print('WakeWordService heard: "$rawText"');

      // ✅ IGNORE TTS ECHO - prevents "command not recognized" bug
      if (_isTTSResponse(rawText)) {
        print('WakeWordService: ignoring TTS echo: "$rawText"');
        return;
      }

      if (_isCommandMode) {
        final handled = await _handleCommand(rawText);
        if (handled) {
          _resetCommandMode();
        } else {
          HapticFeedback.vibrate();
          await TtsService().speak('Command not recognized.');
          _resetCommandMode();
        }
        return;
      }

      if (_containsWakeWord(rawText)) {
        await _activateCommandMode(rawText);
      }
    } catch (e) {
      print('WakeWordService: result parse error: $e');
    }
  }

bool _containsWakeWord(String text) {
  // Check for variations of "Alexa" and "Elixir"
  return text.contains('hey alexa') || 
         text.contains('hey alixir') || 
         text.contains('hey elixir') ||
         text.contains('alexa') ||
         text.contains('alixir') ||
         text.contains('elixir') ||
         text.contains('alexi') ||
         text.contains('alixi') ||
         text.contains('alex') ||
         text.contains('he alexa') ||
         text.contains('he alixir') ||
         text.contains('he elixir') ||
         text.contains('hi alexa') ||
         text.contains('hi alixir') ||
         text.contains('hi elixir') ||
         text.contains('hey alexi') ||
         text.contains('hey alixi');
}

  // ✅ NEW METHOD: Ignore TTS responses from being treated as commands
  bool _isTTSResponse(String text) {
    final ttsPhrases = [
      'i am listening',
      "i'm listening",
      'im listening',
      'listening',
      'command not recognized',
      'listening stopped'
    ];
    return ttsPhrases.any((phrase) => text.contains(phrase));
  }
Future<void> _activateCommandMode(String text) async {
  if (_isCommandMode || _isCooldown) return;
  _isCommandMode = true;
  isCommandModeNotifier.value = true;

  _commandModeTimer?.cancel();
  _commandModeTimer = Timer(Duration(seconds: _commandTimeoutSeconds), () {
    print('WakeWordService: command mode timeout');
    HapticFeedback.vibrate();
    TtsService().speak('Listening stopped.');
    _resetCommandMode();
  });

  print('WakeWordService: wake word detected, entering command mode');
  HapticFeedback.lightImpact();
  
  // ✅ Speak and wait for it to complete
  await TtsService().speak('I am listening');
  
  // ✅ CRITICAL FIX: Wait for TTS echo to fully finish
  await Future.delayed(Duration(milliseconds: 800));
  
  // ✅ Small vibration to signal "ready" for the user
  HapticFeedback.lightImpact();

  // Now the app waits for the user to speak naturally
}

  Future<bool> _handleCommand(String text) async {
    final context = navigatorKey.currentContext;
    if (context == null) {
      print('WakeWordService: navigator context unavailable.');
      return false;
    }

    if (_isGoBack(text)) {
      HapticFeedback.lightImpact();
      if (Navigator.canPop(context)) {
        await TtsService().speak('Going back');
        await Future.delayed(const Duration(milliseconds: 600));
        Navigator.pop(context);
      } else {
        await TtsService().speak('You are already at the home screen.');
        await Future.delayed(const Duration(milliseconds: 600));
      }
      return true;
    }

    if (_isObjectDetection(text)) {
      HapticFeedback.mediumImpact();
      await TtsService().speak('Opening object detection');
      await Future.delayed(const Duration(milliseconds: 600));
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ObjectDetectionScreen(fromVoice: true)));
      return true;
    }

    if (_isOcrMode(text)) {
      HapticFeedback.mediumImpact();
      await TtsService().speak('Opening text Reading mode');
      await Future.delayed(const Duration(milliseconds: 600));
      Navigator.push(context, MaterialPageRoute(builder: (_) => const OcrScreen(fromVoice: true)));
      return true;
    }

    if (_isGestureMode(text)) {
      HapticFeedback.mediumImpact();
      await TtsService().speak('Opening Hand Detection');
      await Future.delayed(const Duration(milliseconds: 600));
      Navigator.push(context, MaterialPageRoute(builder: (_) => const GestureScreen(fromVoice: true)));
      return true;
    }

    if (_isOpenSetting(text)) {
      HapticFeedback.mediumImpact();
      await TtsService().speak('Opening settings');
      await Future.delayed(const Duration(milliseconds: 600));
      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen(fromVoice: true)));
      return true;
    }

    if (_isFontBigger(text)) {
      HapticFeedback.lightImpact();
      final provider = Provider.of<LanguageProvider>(context, listen: false);
      if (provider.fontSize >= 32.0) {
        await TtsService().speak('Font is already at maximum size');
      } else {
        provider.fontSize = (provider.fontSize + 2.0).clamp(10.0, 32.0);
        await TtsService().speak('Font size increased');
      }
      await Future.delayed(const Duration(milliseconds: 600));
      return true;
    }

    if (_isFontSmaller(text)) {
      HapticFeedback.lightImpact();
      final provider = Provider.of<LanguageProvider>(context, listen: false);
      if (provider.fontSize <= 10.0) {
        await TtsService().speak('Font is already at minimum size');
      } else {
        provider.fontSize = (provider.fontSize - 2.0).clamp(10.0, 32.0);
        await TtsService().speak('Font size decreased');
      }
      await Future.delayed(const Duration(milliseconds: 600));
      return true;
    }

    if (_isChangeTheme(text)) {
      final now = DateTime.now();
      if (_lastThemeToggle != null && now.difference(_lastThemeToggle!).inSeconds < 3) {
        return false;
      }
      _lastThemeToggle = now;
      HapticFeedback.mediumImpact();
      final provider = Provider.of<LanguageProvider>(context, listen: false);
      provider.theme = provider.theme == 'teal' ? 'dark' : 'teal';
      await TtsService().speak('Theme changed');
      await Future.delayed(const Duration(milliseconds: 600));
      return true;
    }

    return false;
  }

bool _isObjectDetection(String text) {
  if (text.contains('object detection')) return true;
  if (text.contains('Object Detection')) return true;
  if (text.contains('object detect')) return true;
    if (text.contains('abject Detection')) return true;
  if (text.contains('oobject detect')) return true;
  if (text.contains('detect object')) return true;
  if (text.contains('find objects')) return true;
  if (text.contains('Find Objects')) return true;
  return false;
}

bool _isOcrMode(String text) {
  // 🔥 PRIMARY - Word Reading
  if (text.contains('word reading')) return true;
  if (text.contains('Word Reading')) return true;
  if (text.contains('WORD READING')) return true;
  if (text.contains('reading word')) return true;
  if (text.contains('Reading Word')) return true;
  if (text.contains('word read')) return true;
  if (text.contains('Word Read')) return true;
  if (text.contains('read word')) return true;
  if (text.contains('Read Word')) return true;
  
  // 🔥 Common mishearings
  if (text.contains('word redeeming')) return true;
  if (text.contains('word reding')) return true;
  if (text.contains('void reading')) return true;
  if (text.contains('ward reading')) return true;
  if (text.contains('werd reading')) return true;
  if (text.contains('word reed')) return true;
  if (text.contains('reading words')) return true;
  if (text.contains('word reader')) return true;
  if (text.contains('Word Reader')) return true;
  
  // 🔥 Catch if "word" + "read/reading" appears anywhere
  if (text.contains('word') && text.contains('read')) return true;
  if (text.contains('word') && text.contains('reed')) return true;
  if (text.contains('word') && text.contains('red')) return true;
  if (text.contains('word') && text.contains('reading')) return true;
  if (text.contains('reading') && text.contains('mode')) return true;
  
  // 🔥 Catch "reading" or "reeding"
  if (text.contains('reading')) return true;
  if (text.contains('Reading')) return true;
  if (text.contains('reeding')) return true;
  
  return false;
}

bool _isGestureMode(String text) {
  final lower = text.toLowerCase();
  
  // 🔥 PRIMARY - "detect hand"
  if (lower.contains('detect hand')) return true;
  if (lower.contains('Detect Hand')) return true;
  if (lower.contains('DETECT HAND')) return true;
  
  // 🔥 VARIATIONS
  if (lower.contains('detect hand')) return true;
  if (lower.contains('detect hands')) return true;
  if (lower.contains('hand detect')) return true;
  if (lower.contains('hand detection')) return true;
  if (lower.contains('hands')) return true;
  
  // 🔥 COMMON MISHEARINGS FROM LOGS
  if (lower.contains('detect and')) return true;        // "detect and" → "detect hand"
  if (lower.contains('detect an')) return true;         // "detect an"
  if (lower.contains('and detection')) return true;     // "and detection" → "hand detection"
  if (lower.contains('hen detection')) return true;     // "hen detection"
  if (lower.contains('hearn detection')) return true;   // "hearn detection"
  
  // 🔥 IF "detect" + "hand" appear anywhere
  if (lower.contains('detect') && lower.contains('hand')) return true;
  
  return false;
}

 bool _isOpenSetting(String text) {
  // 🔥 EXACT MATCHES
  if (text.contains('open setting')) return true;
  if (text.contains('open settings')) return true;
  if (text.contains('settings')) return true;
  if (text.contains('setting')) return true;
  
  // 🔥 COMMON MISHEARINGS (SAFE - not too broad)
  if (text.contains('open set in')) return true;   // Vosk hears this
  if (text.contains('opening set')) return true;    // Vosk hears this
  if (text.contains('open set it')) return true;    // Vosk hears this
  if (text.contains('opensetting')) return true;    // Spoken fast
  
  // 🔥 SAFE FALLBACK - Only if "open" AND "set" are both present
  if (text.contains('open') && text.contains('set')) return true;
  if (text.contains('opening') && text.contains('set')) return true;
  
  return false;
}
 bool _isGoBack(String text) {
  // 🔥 EXACT MATCHES
  if (text.contains('go back')) return true;
  
  // 🔥 COMMON MISHEARINGS (SAFE - not too broad)
  if (text.contains('go bck')) return true;    // Missing 'a'
  if (text.contains('goback')) return true;    // One word
  if (text.contains('go bad')) return true;    // Vosk hears this sometimes
  if (text.contains('go backet')) return true; // Vosk adds extra sound
  if (text.contains('go ba')) return true;     // Cut off speech
  
  // 🔥 SAFE FALLBACK - Only if "go" AND "back" are both present
  if (text.contains('go') && text.contains('back')) return true;
  
  return false;
}

  bool _isFontBigger(String text) {
    if (text.contains('font bigger')) return true;
    if (text.contains('font be good')) return true;
    if (text.contains('font be gooder')) return true;
    if (text.contains('font be bigger')) return true;
    if (text.contains('font big')) return true;
    if (text.contains('font biggest')) return true;
    if (text.contains('font biggerest')) return true;
    if (text.contains('far bigger')) return true;
    if (text.contains('far be good')) return true;
    if (text.contains('for bigger')) return true;
    if (text.contains('for be good')) return true;
    if (text.contains('fotn bigger')) return true;
    if (text.contains('fotn biggest')) return true;
    if (text.contains('fotn bgigest')) return true;
    if (text.contains('fotn be good')) return true;
    if (text.contains('font bgigest')) return true;
    if (text.contains('font bgger')) return true;
    if (text.contains('font') && (text.contains('bigger') || text.contains('big'))) return true;
    return false;
  }

  bool _isFontSmaller(String text) {
    if (text.contains('font smaller')) return true;
    if (text.contains('font small')) return true;
    if (text.contains('font smol')) return true;
    if (text.contains('font smoller')) return true;
    if (text.contains('font smallish')) return true;
    if (text.contains('font smal')) return true;
    if (text.contains('font smallerest')) return true;
    if (text.contains('far smaller')) return true;
    if (text.contains('for smaller')) return true;
    if (text.contains('fotn smaller')) return true;
    if (text.contains('fotn small')) return true;
    if (text.contains('fotn smal')) return true;
    if (text.contains('font') && (text.contains('smaller') || text.contains('small'))) return true;
    return false;
  }

  bool _isChangeTheme(String text) {
    if (text.contains('change theme')) return true;
    if (text.contains('changed theme')) return true;
    if (text.contains('change team')) return true;
    if (text.contains('chanegd team')) return true;
    if (text.contains('chaneg team')) return true;
    if (text.contains('change teams')) return true;
    if (text.contains('chaneg teams')) return true;
    if (text.contains('james team')) return true;
    if (text.contains('james teams')) return true;
    if (text.contains('james theme')) return true;
    if (text.contains('jame team')) return true;
    if (text.contains('jame theme')) return true;
    if (text.contains('chain theme')) return true;
    if (text.contains('chain team')) return true;
    if ((text.contains('change') || text.contains('chaneg')) &&
        (text.contains('team') || text.contains('theme'))) {
      return true;
    }
    return false;
  }

  void _resetCommandMode() {
    if (!_isCommandMode) return;
    _isCommandMode = false;
    isCommandModeNotifier.value = false;
    _commandModeTimer?.cancel();
    _commandModeTimer = null;
    _startCooldown();
  }

  void _startCooldown() {
    if (_isCooldown) return;
    _isCooldown = true;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(Duration(milliseconds: _cooldownMs), () async {
      _isCooldown = false;
      print('WakeWordService: cooldown complete, resuming listening');
      await startListening();
    });
  }

  Future<void> stopListening() async {
    _isListening = false;
    _commandModeTimer?.cancel();
    _cooldownTimer?.cancel();
    await _resultSubscription?.cancel();
    _resultSubscription = null;
    try {
      await _speechService?.stop();
    } catch (_) {}
  }

  void dispose() {
    _commandModeTimer?.cancel();
    _cooldownTimer?.cancel();
    _resultSubscription?.cancel();
    _resultSubscription = null;
    try {
      _speechService?.stop();
    } catch (_) {}
  }
}