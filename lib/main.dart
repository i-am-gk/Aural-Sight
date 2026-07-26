import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/loading_screen.dart';
import 'providers/language_provider.dart';
import 'services/metrics_logger.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MetricsLifecycleObserver(child: MyApp()));
}

/// Thin StatefulWidget that observes the app lifecycle and prints a metrics
/// summary to the console whenever the app is backgrounded or closed.
/// Only active in debug mode — zero impact on release builds.
class MetricsLifecycleObserver extends StatefulWidget {
  final Widget child;
  const MetricsLifecycleObserver({super.key, required this.child});
  @override
  State<MetricsLifecycleObserver> createState() => _MetricsLifecycleObserverState();
}

class _MetricsLifecycleObserverState extends State<MetricsLifecycleObserver> {
  AppLifecycleListener? _lifecycleListener;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      _lifecycleListener = AppLifecycleListener(
        onPause: () => unawaited(MetricsLogger().printSummary()),
        onDetach: () => unawaited(MetricsLogger().printSummary()),
      );
    }
  }

  @override
  void dispose() {
    _lifecycleListener?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: Consumer<LanguageProvider>(
        builder: (context, provider, child) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'AuralSight',
            theme: provider.getThemeData(),
            home: const LoadingScreen(),
          );
        },
      ),
    );
  }
}