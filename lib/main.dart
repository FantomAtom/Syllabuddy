import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/landingScreen.dart';
import 'screens/degree_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool? _isLoggedIn;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLogin = prefs.getBool('isLoggedIn') ?? false;

    // If Firebase still has a user, keep them logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _isLoggedIn = true;
    } else {
      _isLoggedIn = savedLogin;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Syllabuddy',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: _isLoggedIn == null
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            )
          : _isLoggedIn!
              ? const CoursesScreen()
              : const LandingScreen(),
    );
  }
}
