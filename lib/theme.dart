import 'package:flutter/material.dart';

const Color kPrimaryColor = Color(0xFF136B5B);

final ThemeData appTheme = ThemeData(
  primaryColor: kPrimaryColor,
  // build a ColorScheme from a MaterialColor and set an explicit error color
  colorScheme: ColorScheme.fromSwatch(
    primarySwatch: const MaterialColor(
      0xFF136B5B,
      <int, Color>{
        50:  Color(0xFFE6F2EF),
        100: Color(0xFFB3D9CF),
        200: Color(0xFF80C0AF),
        300: Color(0xFF4DA88F),
        400: Color(0xFF269673),
        500: Color(0xFF136B5B),
        600: Color(0xFF125C52),
        700: Color(0xFF104D47),
        800: Color(0xFF0D3E3C),
        900: Color(0xFF082A2A),
      },
    ),
  ).copyWith(
    error: const Color(0xFFC54B4B), // explicit error color used by Theme.of(context).colorScheme.error
  ),

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
);
