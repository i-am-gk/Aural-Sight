import 'package:flutter/material.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Legal Concerns")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: const Text(
          """AuralSight – Legal Concerns

Last Updated: January 2025

This document outlines important legal considerations related to the use of the AuralSight mobile application. By using this app, you acknowledge and accept the following terms regarding safety, usage limitations, intellectual property, and privacy.

1. Application Purpose
AuralSight is developed as an assistive tool to support individuals with visual impairments through features such as object detection, OCR-based text reading, gesture recognition, and voice-assisted guidance. It is created strictly for educational and research purposes as part of a Final Year Project (FYP).

2. Accuracy & Limitations
The AI/ML models used in AuralSight may occasionally produce incorrect or incomplete results due to environmental factors, camera quality, or model limitations. The app must not be considered a fully accurate or professionally certified detection tool.

3. Safety Disclaimer
Users must remain alert and aware of their surroundings while using the app. AuralSight should not be relied upon for critical decision-making, navigation, or safety-sensitive tasks. The developers are not responsible for accidents, injuries, or damages resulting from incorrect usage or technical limitations.

4. Data & Privacy
AuralSight does not store or transmit user images, camera data, or personal information to any external server. All processing occurs locally on the user’s device.

5. Third-Party Components
The app uses third-party libraries and tools such as TensorFlow Lite, camera APIs, and text-to-speech engines. These components remain the property of their respective owners and operate under their own licenses.

6. Liability Limitation
AuralSight is provided “as-is” without warranties of any kind. The developers are not liable for inaccuracies, technical issues, or any consequences arising from the use of the application.

7. Updates & Changes
The application may be modified, improved, or updated over time as part of ongoing academic development. These updates may alter functionality, features, or performance.

8. Acceptance
By using AuralSight, you agree to all legal considerations described above.
""",
          style: TextStyle(
            fontSize: 16,
            height: 1.5,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
