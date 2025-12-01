// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'theme.dart';
import 'theme_service.dart'; // <-- new
import 'screens/landingScreen.dart';
import 'screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // Load saved theme before runApp
  await ThemeService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to notifier so MaterialApp rebuilds when theme changes
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.notifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Syllabuddy',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeMode,
          // use builder so we can set the status bar style based on the theme dynamically
          builder: (context, child) {
            final Widget page = child ?? const SizedBox.shrink();

            // derive overlay style from theme primary color
            final primary = Theme.of(context).primaryColor;
            final useLightIcons = primary.computeLuminance() < 0.5;
            final overlayStyle = SystemUiOverlayStyle(
              statusBarColor: primary,
              statusBarIconBrightness: useLightIcons ? Brightness.light : Brightness.dark,
              statusBarBrightness: useLightIcons ? Brightness.dark : Brightness.light,
            );

            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: overlayStyle,
              child: page,
            );
          },
          home: const RootDecider(),
        );
      },
    );
  }
}


/// Shows LandingScreen if logged out, MainShell if logged in
class RootDecider extends StatelessWidget {
  const RootDecider({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snap.data;
        return user == null ? const LandingScreen() : const MainShell();
      },
    );
  }
}
