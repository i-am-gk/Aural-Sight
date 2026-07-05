import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../utils/app_localization.dart';

class AboutScreen extends StatelessWidget {
  AboutScreen({super.key});

  final String email = "auralsight@gmail.com";
  final String version = "Version 1.0.0";

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LanguageProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.t(context, 'about_title'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // App Logo
            Image.asset(
              "assets/images/teammgh.png",
              height: 120,
            ),
            const SizedBox(height: 12),

            // Version
            Text(
              version,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),

            // Developed by
            const Text(
              "Developed by Team MGH",
              style: TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: Colors.teal,
              ),
            ),

            const SizedBox(height: 24),

            // Mission Statement
            const Text(
              "AuralSight is an assistive application designed to support visually impaired individuals through offline AI-powered assistance. It provides object detection, text reading using OCR, gesture recognition, and voice-guided interaction. These features help users navigate their daily tasks with greater independence and confidence.",
              style: TextStyle(fontSize: 16, height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Privacy Statement
            const Text(
              "All processing happens entirely on your device. Camera frames, text, speech, and user data are never stored or sent to any server. Your privacy and safety remain completely protected.",
              style: TextStyle(fontSize: 16, height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Contact Email
            Text(
              "Contact: $email",
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}