import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/loading_screen.dart';
import 'providers/language_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
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