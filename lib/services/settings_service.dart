// lib/services/settings_service.dart
import 'package:hive_flutter/hive_flutter.dart';

class SettingsService {
  static const String boxName = 'settingsBox';
  static Box? _box;

  /// Call once at startup: await SettingsService.init();
  static Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      _box = await Hive.openBox(boxName);
    } else {
      _box = Hive.box(boxName);
    }
  }

  static Box get box {
    if (_box == null) throw Exception('SettingsService not initialized');
    return _box!;
  }

  // defaults
  static bool get ttsEnabled =>
      box.get('tts_enabled', defaultValue: true) as bool;
  static set ttsEnabled(bool v) => box.put('tts_enabled', v);

  static bool get autoOcr => box.get('auto_ocr', defaultValue: false) as bool;
  static set autoOcr(bool v) => box.put('auto_ocr', v);

  static String get language =>
      box.get('language', defaultValue: 'en') as String; // 'en' or 'ur'
  static set language(String v) => box.put('language', v);

  static String get ttsLanguage =>
      box.get('tts_language', defaultValue: 'en') as String; // 'en' or 'ur'
  static set ttsLanguage(String v) => box.put('tts_language', v);

  static double get fontSize =>
      box.get('font_size', defaultValue: 18.0) is double
          ? box.get('font_size', defaultValue: 18.0) as double
          : (box.get('font_size', defaultValue: 18.0) as num).toDouble();
  static set fontSize(double v) => box.put('font_size', v);

  static String get theme => box.get('theme', defaultValue: 'teal') as String;
  static set theme(String v) => box.put('theme', v);
}
