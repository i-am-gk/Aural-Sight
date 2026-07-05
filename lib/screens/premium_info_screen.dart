import 'package:flutter/material.dart';

class PremiumInfoScreen extends StatelessWidget {
  PremiumInfoScreen({super.key});

  final String email = "auralsight@gmail.com";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Premium Features")),
      body: SafeArea(
        // ✅ Ensures text stays above system buttons
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "AuralSight – Current Features",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "AuralSight currently provides the following features completely "
                "FREE and fully offline as part of our FYP:",
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 12),
              _currentFeature("Object Detection"),
              _currentFeature("OCR (Text/Sign Reading)"),
              _currentFeature("Gesture Recognition"),
              _currentFeature("Voice Feedback"),
              _currentFeature("Accessibility Enhancements"),
              const SizedBox(height: 25),

              const Text(
                "Future Premium Features",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Advanced features available through Premium Subscription:",
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 12),

              // ✅ Premium Features dynamically listed
              ..._premiumFeaturesList
                  .map((feature) => _premiumFeature(feature)),

              const SizedBox(height: 25),
              const Divider(),
              const SizedBox(height: 15),
              const Text(
                "These advanced features require cloud servers, heavy AI models, "
                "and continuous updates. They will be offered only in Premium. "
                "Basic accessibility features will always remain free.",
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 25),
              const Divider(),
              const SizedBox(height: 10),
              Text(
                "For premium access, collaboration, or inquiries, contact us: $email\n",
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // Current Features Widget
  Widget _currentFeature(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.teal, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  // Premium Features Widget
  Widget _premiumFeature(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium, color: Colors.amber, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  // ✅ List of Premium Features
  final List<String> _premiumFeaturesList = [
    "Advanced Scene Description (Cloud-based)",
    "Indoor / Outdoor Navigation Assistance",
    "Real-time Route Guidance & Alerts",
    "Enhanced AI Object Recognition Models",
    "AI Personal Assistant Mode",
    "Cloud Storage & History Logs",
    "Multi-language Deep OCR",
  ];
}
