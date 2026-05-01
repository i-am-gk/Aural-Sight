import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Terms & Conditions")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: const Text(
          """
AuralSight – Terms & Conditions

Last Updated: January 2025

Welcome to AuralSight. These Terms & Conditions outline the rules for using this application. By installing or using AuralSight, you agree to these terms.

1. Purpose of the Application
AuralSight is an assistive mobile app developed as a Final Year Project (FYP). It provides on-device features such as:
• Object Detection  
• Text and Sign Reading (OCR)  
• Gesture Recognition  
• Voice-Based Feedback and Navigation  

The app is intended for educational and research purposes only.

2. Not a Medical or Safety Device
AuralSight is not a certified medical, safety, or navigation tool. Outputs may be inaccurate due to environmental conditions, camera limitations, or AI model constraints. Users should not rely on the app for making critical decisions.

3. User Responsibility
The user must remain aware of their surroundings at all times. The developers are not responsible for injuries, damages, or misuse resulting from the app’s use.

4. Privacy & Data Processing
AuralSight does not collect, store, or share personal data.  
All processing—including camera frames, OCR, and detection—is performed offline and on the user’s device.

5. Required Permissions
The app may require:
• Camera access (for object detection and OCR)  
• Microphone access (for voice features)  
• Storage access (for model loading if needed)  

Declining permissions may limit functionality.

6. Intellectual Property
All design, code, and content are the property of the developers unless otherwise stated. Third-party libraries and models retain their respective open-source licenses.

7. Limitation of Liability
AuralSight is provided “as-is” without warranties of any kind. The developers are not liable for inaccuracies, feature limitations, or damages arising from the app’s use.

8. Updates & Modifications
Features may be updated, improved, or removed as part of the academic development process.

9. Acceptance of Terms
By using AuralSight, you acknowledge that you have read, understood, and agreed to these Terms & Conditions.
          """,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
