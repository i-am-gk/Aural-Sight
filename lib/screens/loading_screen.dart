import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/user_model.dart';
import '../services/metrics_logger.dart';
import '../services/settings_service.dart';
import '../services/tts_service.dart';
import '../services/wake_word_service.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'home_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    // Load Hive and prefs first (fast)
    await Hive.initFlutter();
    Hive.registerAdapter(UserModelAdapter());
    // Initialize metrics logger (non-blocking, silently fails if Hive has issues)
    await MetricsLogger().init();
    
    final prefs = await SharedPreferences.getInstance();
    final registered = prefs.getBool('registered') ?? false;
    final loggedIn = prefs.getBool('loggedIn') ?? false;
    
    await SettingsService.init();
    
    // CRITICAL: DON'T initialize TTS here at all!
    // TTS will be initialized lazily when first needed
    
    if (loggedIn) {
      Permission.microphone.request().then((status) {
        if (status.isGranted) {
          Future.microtask(() {
            WakeWordService().startListening();
          });
        }
      });
    }
    
    if (!mounted) return;
    
    Widget nextScreen;
    if (!registered) {
      nextScreen = const SignupScreen();
    } else if (!loggedIn) {
      nextScreen = const LoginScreen();
    } else {
      nextScreen = const HomeScreen();
    }
    
    // Navigate immediately - TTS not initialized yet
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Allow theme to control background color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/myapplogo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Theme.of(context).primaryColor,
                      child: const Icon(
                        Icons.hearing,
                        color: Colors.white,
                        size: 60,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 40),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 20),
            Text(
              'Starting AuralSight...',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}