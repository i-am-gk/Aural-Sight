// gesture_screen.dart
import 'package:flutter/material.dart';
import '../services/tts_service.dart';

class GestureScreen extends StatelessWidget {
  const GestureScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final tts = TtsService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gesture Detection'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            tts.stop();
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.back_hand, size: 80, color: Colors.teal),
              SizedBox(height: 20),
              Text('Gesture Detection (dummy)', style: TextStyle(fontSize: 20)),
              SizedBox(height: 12),
              Text(
                  'This is a placeholder. Gesture recognition will be added later.',
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
