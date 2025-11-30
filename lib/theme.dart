// lib/app_theme.dart
import 'package:flutter/material.dart';

const Color kPrimaryColor = Color(0xFF136B5B);

final ThemeData appTheme = ThemeData(
  // Build a ColorScheme from a seed color (simpler than manually creating a big swatch)
  colorScheme: ColorScheme.fromSeed(
    seedColor: kPrimaryColor,
    primary: kPrimaryColor,
    // you can change brightness: Brightness.dark for a dark theme
  ).copyWith(
    error: const Color(0xFFC54B4B),
  ),

  // The old properties still work and will be derived from colorScheme
  primaryColor: kPrimaryColor,
  primaryColorDark: const Color.fromARGB(255, 7, 60, 50), // optional explicit override

  scaffoldBackgroundColor: Colors.white,
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.grey[100],
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
    ),
  ),

  // small convenience: readable text defaults
  textTheme: Typography.material2018().black.apply(bodyColor: Colors.black87),
);
