// lib/theme_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const _prefKey = 'theme_mode'; // 'light' or 'dark'
  // ValueNotifier so UI can listen and rebuild
  static final ValueNotifier<ThemeMode> notifier = ValueNotifier(ThemeMode.light);

  /// Call once at app startup before runApp (await ThemeService.init()).
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefKey) ?? 'light';
    notifier.value = stored == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  static Future<void> setTheme(ThemeMode mode) async {
    notifier.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, mode == ThemeMode.dark ? 'dark' : 'light');
  }

  static Future<void> toggle() async {
    await setTheme(notifier.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}
