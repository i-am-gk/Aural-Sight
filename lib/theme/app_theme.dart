import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get defaultTheme => ThemeData(
    primaryColor: Colors.teal,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)
        .copyWith(secondary: Colors.grey.shade600),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal),
      bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
      labelLarge: TextStyle(fontSize: 18, color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      ),
    ),
  );
}
