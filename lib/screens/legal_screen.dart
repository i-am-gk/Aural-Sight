import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../utils/app_localization.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LanguageProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.t(context, 'legal_title'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
            children: const [
              TextSpan(
                text: 'AuralSight – Legal Concerns\n\n',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              TextSpan(
                text: 'Last Updated: July 2026\n\n',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              TextSpan(
                text: 'This document outlines important legal considerations related to the use of the AuralSight mobile application. By using this app, you acknowledge and accept the following terms regarding safety, usage limitations, intellectual property, and privacy.\n\n',
              ),
              TextSpan(
                text: '1. Application Purpose\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: 'AuralSight is developed as an assistive tool to support individuals with visual impairments through features such as object detection, OCR-based text reading, gesture recognition, and voice-assisted guidance. It is created for educational and research purposes.\n\n',
              ),
              TextSpan(
                text: '2. Accuracy & Limitations\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: 'The AI and machine learning models used in AuralSight may occasionally produce incorrect or incomplete results due to environmental factors, camera quality, or model limitations. The application must not be considered a fully accurate or professionally certified detection tool.\n\n',
              ),
              TextSpan(
                text: '3. Safety Disclaimer\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: 'Users must remain alert and aware of their surroundings while using the application. AuralSight should not be relied upon for critical decision-making, navigation, or safety-sensitive tasks. The developers are not responsible for accidents, injuries, or damages resulting from incorrect usage or technical limitations.\n\n',
              ),
              TextSpan(
                text: '4. Data & Privacy\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: 'AuralSight does not store or transmit user images, camera data, or personal information to any external server. All processing occurs locally on the user\'s device.\n\n',
              ),
              TextSpan(
                text: '5. Third-Party Components\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: 'The application uses third-party libraries and tools such as TensorFlow Lite, camera APIs, and text-to-speech engines. These components remain the property of their respective owners and operate under their own licenses.\n\n',
              ),
              TextSpan(
                text: '6. Liability Limitation\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: 'AuralSight is provided "as-is" without warranties of any kind. The developers are not liable for inaccuracies, technical issues, or any consequences arising from the use of the application.\n\n',
              ),
              TextSpan(
                text: '7. Updates & Changes\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: 'The application may be modified, improved, or updated over time as part of ongoing development. These updates may alter functionality, features, or performance.\n\n',
              ),
              TextSpan(
                text: '8. Acceptance\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: 'By using AuralSight, you agree to all legal considerations described above.\n',
              ),
            ],
          ),
        ),
      ),
    );
  }
}