import 'package:flutter/material.dart';

/// Centralised light & dark themes for the Gallery app.
class AppTheme {
  AppTheme._();

  static const Color _accent = Color(0xFF6C63FF);

  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorSchemeSeed: _accent,
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        fontFamily: 'Roboto',
      );

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: _accent,
        scaffoldBackgroundColor: const Color(0xFF0E0E12),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        fontFamily: 'Roboto',
      );

  static const Color accent = _accent;
}
