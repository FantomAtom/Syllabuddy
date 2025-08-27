import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/landingScreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}): super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Syllabuddy',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      // Always provide a stable MaterialApp at the top.
      // Use InitScreen as the initial route which will handle Firebase init.
      home: const InitScreen(),
    );
  }
}

/// InitScreen handles Firebase initialization and shows a loader,
/// error UI, or navigates to LandingScreen when ready.
/// Because MaterialApp is always present, the Navigator is preserved
/// across hot reloads and you won't lose your place as easily.
class InitScreen extends StatefulWidget {
  const InitScreen({Key? key}) : super(key: key);

  @override
  State<InitScreen> createState() => _InitScreenState();
}

class _InitScreenState extends State<InitScreen> {
  late final Future<FirebaseApp> _initFuture;

  @override
  void initState() {
    super.initState();
    // Start initialization once
    _initFuture = Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FirebaseApp>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // show a nice centered loader while firebase initializes
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          // show an error screen (you can style this)
          return Scaffold(
            body: Center(
              child: Text(
                'Firebase init failed:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // Firebase is ready — show the landing screen (replace this if you want to restore last route)
        // Using pushReplacement preserves a single navigator stack entry so back behaves normally.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LandingScreen()),
            );
          }
        });

        // While the replacement is being scheduled, return an empty container.
        return const SizedBox.shrink();
      },
    );
  }
}
