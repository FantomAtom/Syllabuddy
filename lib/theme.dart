// lib/theme.dart
import 'package:flutter/material.dart';

/// Base light primary (keeps your previous green for light mode)
const Color kPrimaryLight = Color(0xFF136B5B);

/// Dark-mode primary (palette A)
const Color kPrimaryDark = Color(0xFF0DBF82);

/// Accent for dark mode (muted mint)
const Color kAccentDark = Color(0xFF9FE8C2);

/// Card / surface colors
const Color kCardColorLight = Colors.white;
const Color kCardColorDark = Color(0xFF1A2421);

/// Backgrounds
const Color kScaffoldLight = Colors.white;
const Color kScaffoldDark = Color(0xFF0F1513);

/// Shadows
const Color kShadowLight = Colors.black12;
const Color kShadowDark = Colors.black54;

//////////////////////////////////////////////////////
/// LIGHT THEME
final ThemeData lightTheme = ThemeData(
  // keep seed color as previous light primary
  colorScheme: ColorScheme.fromSeed(seedColor: kPrimaryLight, brightness: Brightness.light).copyWith(
    error: const Color(0xFFC54B4B),
    onPrimary: Colors.white,
  ),

  primaryColor: kPrimaryLight,
  scaffoldBackgroundColor: kScaffoldLight,
  cardColor: kCardColorLight,

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
      backgroundColor: kPrimaryLight,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 16),
    ),
  ),

  textTheme: Typography.material2018().black.apply(bodyColor: Colors.black87),
  visualDensity: VisualDensity.adaptivePlatformDensity,
);

//////////////////////////////////////////////////////
/// DARK THEME (PALETTE A: Emerald + Charcoal)
final ThemeData darkTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: kPrimaryDark, brightness: Brightness.dark).copyWith(
    error: const Color(0xFFC54B4B),
    onPrimary: Colors.black, // buttons with light background may use dark text optionally
  ),

  primaryColor: kPrimaryDark,
  scaffoldBackgroundColor: kScaffoldDark,
  cardColor: kCardColorDark,

  // Text & surfaces
  textTheme: Typography.material2018().white.apply(bodyColor: Colors.white70),

  // Inputs (dropdowns, textfields)
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF111919), // slightly lighter than scaffold but still dark
    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    labelStyle: const TextStyle(color: Colors.white70),
    hintStyle: const TextStyle(color: Colors.white54),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.white24),
    ),
  ),

  // Buttons (primary = emerald)
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kPrimaryDark,
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 14),
    ),
  ),

  // App bar, dialogs
  appBarTheme: const AppBarTheme(
    backgroundColor: kScaffoldDark,
    elevation: 0,
    iconTheme: IconThemeData(color: Colors.white),
  ),

  // small tweak for dialog/card colors
  dialogBackgroundColor: const Color(0xFF101816),

  // Visual density
  visualDensity: VisualDensity.adaptivePlatformDensity,
);

/// App-wide extension to choose readable "primary text" color depending on brightness.
/// Use: Theme.of(context).colorScheme.primaryText
extension AppColors on ColorScheme {
  /// When dark: prefer white text for titles that otherwise used primary (emerald might be too low contrast).
  /// When light: use the original green primary.
  Color get primaryText {
    return brightness == Brightness.dark ? Colors.white : kPrimaryLight;
  }

  /// Helper: an accent for clickable subtle items in dark mode.
  Color get accentDarkMode {
    return kAccentDark;
  }
}
