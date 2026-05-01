// lib/providers/language_provider.dart
import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class LanguageProvider extends ChangeNotifier {
  String _language = 'en';
  String _ttsLanguage = 'en';
  bool _autoOcr = false;
  bool _ttsEnabled = true;
  double _fontSize = 18.0;
  String _theme = 'teal';

  LanguageProvider() {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    _language = SettingsService.language;
    _ttsLanguage = SettingsService.ttsLanguage;
    _autoOcr = SettingsService.autoOcr;
    _ttsEnabled = SettingsService.ttsEnabled;
    _fontSize = SettingsService.fontSize;
    _theme = SettingsService.theme;
    notifyListeners();
  }

  String get language => _language;
  String get ttsLanguage => _ttsLanguage;
  bool get autoOcr => _autoOcr;
  bool get ttsEnabled => _ttsEnabled;
  double get fontSize => _fontSize;
  String get theme => _theme;

  set language(String v) {
    _language = v;
    SettingsService.language = v;
    notifyListeners();
  }

  set ttsLanguage(String v) {
    _ttsLanguage = v;
    SettingsService.ttsLanguage = v;
    notifyListeners();
  }

  set autoOcr(bool v) {
    _autoOcr = v;
    SettingsService.autoOcr = v;
    notifyListeners();
  }

  set ttsEnabled(bool v) {
    _ttsEnabled = v;
    SettingsService.ttsEnabled = v;
    notifyListeners();
  }

  set fontSize(double v) {
    _fontSize = v;
    SettingsService.fontSize = v;
    notifyListeners();
  }

  set theme(String v) {
    _theme = v;
    SettingsService.theme = v;
    notifyListeners();
  }

  // -------------------------
  // ADD THIS: THEME SWITCHER
  // -------------------------
  ThemeData getThemeData() {
    switch (_theme) {
      case 'dark':
        return ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Colors.teal),
        );

      case 'contrast':
        return ThemeData(
          brightness: Brightness.light,
          colorScheme: ColorScheme.highContrastLight(),
        );

      default: // teal
        return ThemeData(
          primaryColor: Colors.teal,
          scaffoldBackgroundColor: Colors.white,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        );
    }
  }
}
