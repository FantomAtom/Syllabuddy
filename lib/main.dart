import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/landingScreen.dart';
import 'screens/main_shell.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Syllabuddy',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const RootDecider(),
    );
  }
}

/// RootDecider shows the appropriate initial screen depending on Firebase auth state
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
        if (user == null) {
          return const LandingScreen();
        } else {
          return const MainShell();
        }
      },
    );
  }
}
