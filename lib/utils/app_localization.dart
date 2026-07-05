// lib/utils/app_localization.dart
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../services/settings_service.dart';

class AppLocalizations {
  static const Map<String, Map<String, String>> _strings = {
    'en': {
      'app_title': 'AuralSight',
      'tagline': 'Let Your Ears Guide Your Eyes',
      'object_detection': 'Object Detection',
      'text_sign_reading': 'Text/Sign Reading',
      'gesture_detection': 'Gesture Detection',
      'settings': 'Settings',
      'ocr_mode': 'Word Reading', // CHANGED
      'gesture_mode': 'Detect Hand', // CHANGED
      'open_settings': 'Open Settings',  // CHANGED
      'back': 'Back',
      'speak': 'Speak',
      'capture_read': 'Capture & Read',
      'capture_detect': 'Capture & Detect',
      'capture_detect_started': 'Capture and detect started',
      'auto_read': 'Auto Read',
      'auto_detect': 'Auto Detect',
      'auto_detect_started': 'Auto detection started',
      'auto_detect_stopped': 'Auto detection stopped',
      'camera_not_ready': 'Camera not ready',
      'recognized_text_will_appear': 'Recognized text will appear here.',
      'no_text_recognized_yet': 'No text recognized yet',
      'no_camera_available': 'No camera available',
      'camera_error': 'Camera error',
      'guidance_no_objects': "I can't see any objects clearly yet.",
      'guidance_adjust_light': "Try adjusting the light or moving the camera slowly.",
      'guidance_move_camera': "Please move a bit further or adjust your position.",
      'auto_read_started': 'Auto reading started',
      'auto_read_stopped': 'Auto reading stopped',
      'tts_enabled': 'Text-to-Speech',
      'auto_ocr': 'Auto OCR',
      'ui_language': 'UI Language',
      'tts_language': 'TTS Language',
      'font_size': 'Font Size',
      'theme': 'Theme',
      'theme_teal': 'Teal',
      'theme_dark': 'Dark',
      'theme_high_contrast': 'High Contrast',
      // add more keys as needed
      'user_profile_settings': 'User Profile Settings',
      'language': 'Language',
      'settings_user_profile': 'User Profile',
      'settings_user_profile_sub': 'Language, theme, accessibility',

      'settings_terms': 'Terms & Conditions',
      'settings_terms_sub': 'Read the app policies',
      'terms_title': 'Terms & Conditions',

      'settings_legal': 'Legal Concerns',
      'settings_legal_sub': 'Copyright & disclaimers',
      'legal_title': 'Legal Concerns',

      'settings_about': 'About Us',
      'settings_about_sub': 'Learn about AuralSight',
      'about_title': 'About Us',

      'future_premium': 'Future Premium Features',
      'future_premium_sub': 'Cloud-based scene and navigation',
    },
    'ur': {
      'app_title': 'اورل سائٹ',
      'tagline': 'اپنی آنکھوں کی رہنمائی کے لیے اپنی کانوں کو استعمال کریں',
      'object_detection': 'اشیاء کی شناخت',
      'text_sign_reading': 'متن/اشارہ پڑھنا',
      'gesture_detection': 'اشارے کی شناخت',
      'settings': 'ترتیبات',
  'ocr_mode': 'لفظ پڑھنا', // Word Reading
'gesture_mode': 'ہاتھ کی شناخت', // Hand Detection
      'open_settings': 'سیٹنگز کھولیں', // CHANGED
      'back': 'واپس',
      'speak': 'بولیں',
      'capture_read': 'پکڑیں اور پڑھیں',
      'capture_detect': 'پکڑیں اور پہچانیں',
      'capture_detect_started': 'پکڑیں اور پہچانیں شروع کیا گیا',
      'auto_read': 'خود کار پڑھائی',
      'auto_detect': 'خود کار پہچان',
      'auto_detect_started': 'خود کار پہچان شروع ہوگئی',
      'auto_detect_stopped': 'خود کار پہچان بند ہوگئی',
      'camera_not_ready': 'کیمرہ تیار نہیں',
      'recognized_text_will_appear': 'پہچانا گیا متن یہاں ظاہر ہوگا۔',
      'no_text_recognized_yet': 'ابھی تک کوئی متن نہیں پہچانا گیا',
      'no_camera_available': 'کوئی کیمرہ دستیاب نہیں',
      'camera_error': 'کیمرہ خرابی',
      'guidance_no_objects': "مجھے ابھی تک کوئی چیز واضح طور پر نظر نہیں آ رہی۔",
      'guidance_adjust_light': "روشنی کو درست کرنے یا کیمرے کو آہستہ سے ہلانے کی کوشش کریں۔",
      'guidance_move_camera': "براہ کرم تھوڑا پیچھے ہٹیں یا اپنی جگہ درست کریں۔",
      'auto_read_started': 'خود کار پڑھائی شروع ہوگئی',
      'auto_read_stopped': 'خود کار پڑھائی بند ہوگئی',
      'tts_enabled': 'متن سے تقریر',
      'auto_ocr': 'خود کار OCR',
      'ui_language': 'یوزر انٹرفیس زبان',
      'tts_language': 'TTS زبان',
      'font_size': 'فونٹ سائز',
      'theme': 'تھیم',
      'theme_teal': 'ٹییل',
      'theme_dark': 'ڈارک',
      'theme_high_contrast': 'ہائی کانٹراسٹ',
      // add more keys as needed
      'user_profile_settings': 'یوزر پروفائل سیٹنگز',
      'language': 'زبان',
      'settings_user_profile': 'یوزر پروفائل',
      'settings_user_profile_sub': 'زبان، تھیم، ایکسیسبیلٹی',

      'settings_terms': 'شرائط و ضوابط',
      'settings_terms_sub': 'ایپ کی پالیسی پڑھیں',
      'terms_title': 'شرائط و ضوابط',

      'settings_legal': 'قانونی معلومات',
      'settings_legal_sub': 'کاپی رائٹس اور ڈسکلیمرز',
      'legal_title': 'قانونی معلومات',

      'settings_about': 'ہمارے بارے میں',
      'settings_about_sub': 'اورل سائٹ کے بارے میں جانیں',
      'about_title': 'ہمارے بارے میں',

      'future_premium': 'مستقبل کی پریمیم خصوصیات',
      'future_premium_sub': 'کلاؤڈ سے چلنے والی خصوصیات',
    },
  };

  static String t(BuildContext context, String key) {
    String lang = 'en';

    // 1) Try to read provider from context (safe)
    try {
      final provider = Provider.of<LanguageProvider>(context, listen: false);
      lang = provider.language;
    } catch (_) {
      // if provider is not available in this context yet, fallback to SettingsService
      try {
        lang = SettingsService.language;
      } catch (_) {
        lang = 'en';
      }
    }

    return _strings[lang]?[key] ?? _strings['en']![key] ?? key;
  }
}
