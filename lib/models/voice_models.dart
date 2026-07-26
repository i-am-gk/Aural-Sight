/// Command to User-Friendly Name Mapping
class CommandMapper {
  static const Map<String, String> commandMap = {
    'gesture_mode': 'hand detection',
    'ocr_mode': 'word reading',
    'object_detection': 'object detection',
    'go_back': 'go back',
    'open_setting': 'settings',
    'change_theme': 'change theme',
    'font_bigger': 'font bigger',
    'font_smaller': 'font smaller',
  };
  
  static String getDisplayName(String className) {
    return commandMap[className] ?? className;
  }
}