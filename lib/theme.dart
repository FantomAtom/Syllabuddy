import 'package:flutter/material.dart';

// 1) Your brand color
const Color kPrimaryColor = Color(0xFF136B5B);

// 2) A full swatch so that Flutter can generate shades
const MaterialColor kPrimarySwatch = MaterialColor(
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
);

// 3) Global ThemeData
final ThemeData appTheme = ThemeData(
  // Sets your primary color everywhere
  primarySwatch: kPrimarySwatch,
  // If you need the raw Color, you can still access it via theme.primaryColor
  primaryColor: kPrimaryColor,

  scaffoldBackgroundColor: Colors.white,

  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide.none,
    ),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      // <-- use backgroundColor instead of the old `primary:`
      backgroundColor: kPrimaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      elevation: 4,
    ),
  ),

  // Correct use of fromSwatch + copyWith only valid parameters.
  colorScheme: ColorScheme.fromSwatch(
    primarySwatch: kPrimarySwatch,
  ).copyWith(
    // override just your accent/secondary color
    secondary: kPrimaryColor,
  ),
);
