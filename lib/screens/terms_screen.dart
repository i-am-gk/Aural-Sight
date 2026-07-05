import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Terms & Conditions")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
            children: const [
              TextSpan(
                text: 'AuralSight – Terms & Conditions\n\n',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              TextSpan(
                text: 'Last Updated: July 2026\n\n',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              TextSpan(
                text: 'Welcome to AuralSight. These Terms & Conditions outline the rules for using this application. By installing or using AuralSight, you agree to these terms.\n\n',
              ),
              TextSpan(
                text: '1. Purpose of the Application\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: 'AuralSight is an assistive mobile application designed to support visually impaired individuals. It provides on-device features such as:\n• Object Detection\n• Text and Sign Reading (OCR)\n• Gesture Recognition\n• Voice-Based Feedback and Navigation\n\nThe application is developed for educational and research purposes.\n\n',
              ),
              TextSpan(
                text: '2. Not a Medical or Safety Device\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: 'AuralSight is not a certified medical, safety, or navigation tool. Outputs may be inaccurate due to environmental conditions, camera limitations, or AI model constraints. Users should not rely on the application for making critical decisions.\n\n',
              ),
              TextSpan(
                text: '3. User Responsibility\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: 'Users must remain aware of their surroundings at all times. The developers are not responsible for injuries, damages, or misuse resulting from the application\'s use.\n\n',
              ),
              TextSpan(
                text: '4. Privacy & Data Processing\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: 'AuralSight does not collect, store, or share personal data. All processing—including camera frames, OCR, and detection—is performed offline and on the user\'s device.\n\n',
              ),
              TextSpan(
                text: '5. Required Permissions\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: 'The application may require:\n• Camera access (for object detection and OCR)\n• Microphone access (for voice features)\n• Storage access (for model loading if needed)\n\nDeclining permissions may limit functionality.\n\n',
              ),
              TextSpan(
                text: '6. Intellectual Property\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: 'All design, code, and content are the property of the developers unless otherwise stated. Third-party libraries and models retain their respective open-source licenses.\n\n',
              ),
              TextSpan(
                text: '7. Limitation of Liability\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: 'AuralSight is provided "as-is" without warranties of any kind. The developers are not liable for inaccuracies, feature limitations, or damages arising from the application\'s use.\n\n',
              ),
              TextSpan(
                text: '8. Updates & Modifications\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: 'Features may be updated, improved, or removed as part of the ongoing development process.\n\n',
              ),
              TextSpan(
                text: '9. Acceptance of Terms\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: 'By using AuralSight, you acknowledge that you have read, understood, and agreed to these Terms & Conditions.\n',
              ),
            ],
          ),
        ),
      ),
    );
  }
}