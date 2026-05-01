import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/app_localization.dart';
import '../providers/language_provider.dart';
import '../services/tts_service.dart';

import 'object_detection_screen.dart';
import 'ocr_screen.dart';
import 'gesture_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tts = TtsService();

    return Consumer<LanguageProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),

                  // App Title
                  Center(
                    child: Text(
                      AppLocalizations.t(context, 'app_title'),
                      style: TextStyle(
                        fontSize: provider.fontSize + 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade700,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Tagline
                  Center(
                    child: Text(
                      AppLocalizations.t(context, 'tagline'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: provider.fontSize - 2,
                        color: Colors.black54,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ----- Object Detection -----
                  _buildTile(
                    context: context,
                    title: AppLocalizations.t(context, 'object_detection'),
                    icon: Icons.camera_alt,
                    screen: const ObjectDetectionScreen(),
                    tts: tts,
                    provider: provider,
                  ),

                  const SizedBox(height: 20),

                  // ----- OCR / Sign Reading -----
                  _buildTile(
                    context: context,
                    title: AppLocalizations.t(context, 'ocr_mode'), // CHANGED
                    icon: Icons.text_fields,
                    screen: const OcrScreen(),
                    tts: tts,
                    provider: provider,
                  ),

                  const SizedBox(height: 20),

                  // ----- Gestures -----
                  _buildTile(
                    context: context,
                    title: AppLocalizations.t(context, 'gesture_mode'), // CHANGED
                    icon: Icons.back_hand,
                    screen: const GestureScreen(),
                    tts: tts,
                    provider: provider,
                  ),

                  const SizedBox(height: 20),

                  // ----- Settings -----
                  _buildTile(
                    context: context,
                    title: AppLocalizations.t(context, 'open_settings'), // CHANGED
                    icon: Icons.settings,
                    screen: const SettingsScreen(),
                    tts: tts,
                    provider: provider,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // 🔥 UI Tile Builder (with TTS support)
  // ==========================================
  Widget _buildTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Widget screen,
    required TtsService tts,
    required LanguageProvider provider,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () async {
        // Speak the button title
        await tts.speak(title, lang: provider.language);

        // Navigate to next screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.teal.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.teal, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.teal, size: 30),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: provider.fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
