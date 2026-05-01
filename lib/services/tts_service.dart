import 'package:flutter_tts/flutter_tts.dart';

/// A small singleton wrapper around flutter_tts to use across screens.
/// Supports optional language selection (en-US default, ur-PK fallback).
class TtsService {
  static TtsService? _instance;
  static bool _initializing = false;
  
  FlutterTts? _tts;
  String _currentLanguage = "en-US";
  
  TtsService._internal();
  
  static TtsService get instance {
    if (_instance == null && !_initializing) {
      _initializing = true;
      _instance = TtsService._internal();
      // Initialize in background - don't block!
      _instance!._initAsync();
    }
    return _instance!;
  }
  
  // Factory constructor for backward compatibility
  factory TtsService() => instance;
  
  Future<void> _initAsync() async {
    try {
      _tts = FlutterTts();
      await _tts!.setSharedInstance(true);
      await _tts!.setSpeechRate(0.45);
      await _tts!.setPitch(1.0);
      await _tts!.setVolume(1.0);
    } catch (e) {
      // ignore init problems
    }
  }
  
  Future<void> _ensureInitialized() async {
    if (_tts == null) {
      await _initAsync();
    }
  }

  /// Speak the given text with consistent voice
  Future<void> speak(String text, {String? lang}) async {
    if (text.isEmpty) return;
    
    await _ensureInitialized();
    if (_tts == null) return;
    
    try {
      await _tts!.stop();
      await Future.delayed(const Duration(milliseconds: 50));
      
      if (lang != null) {
        if (lang.toLowerCase().startsWith('ur')) {
          await _tts!.setLanguage("ur-PK");
          _currentLanguage = "ur-PK";
        } else if (lang.toLowerCase().startsWith('en')) {
          await _tts!.setLanguage("en-US");
          _currentLanguage = "en-US";
        } else {
          await _tts!.setLanguage(lang);
          _currentLanguage = lang;
        }
      } else {
        await _tts!.setLanguage(_currentLanguage);
      }
      
      await _tts!.setSpeechRate(0.45);
      await _tts!.setPitch(1.0);
      await _tts!.setVolume(1.0);
      await _tts!.speak(text);
      
    } catch (e) {
      try {
        await _tts!.stop();
        await Future.delayed(const Duration(milliseconds: 50));
        await _tts!.setLanguage("en-US");
        await _tts!.setSpeechRate(0.45);
        await _tts!.setPitch(1.0);
        await _tts!.setVolume(1.0);
        await _tts!.speak(text);
      } catch (_) {}
    }
  }

  Future<void> stop() async {
    if (_tts == null) return;
    try {
      await _tts!.stop();
    } catch (_) {}
  }
  
  /// Prepare TTS before speaking
  Future<void> prepare() async {
    await _ensureInitialized();
    if (_tts == null) return;
    try {
      await _tts!.stop();
      await Future.delayed(const Duration(milliseconds: 100));
      await _tts!.setLanguage(_currentLanguage);
      await _tts!.setSpeechRate(0.45);
      await _tts!.setPitch(1.0);
      await _tts!.setVolume(1.0);
    } catch (_) {}
  }
}