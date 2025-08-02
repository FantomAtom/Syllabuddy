// lib/screens/landing_screen.dart
import 'package:flutter/material.dart';
import 'package:syllabuddy/screens/login.dart';
import '../theme.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      body: Column(
        children: [
          // ─────────── Top Banner with Curved Bottom ───────────
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
            child: Container(
              width: double.infinity,
              color: primary,
              padding: const EdgeInsets.only(top: 80, bottom: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Welcome Image
                  Image.asset(
                    'assets/landing.png',
                    height: 400,
                    width: 400,
                  ),
                ],
              ),
            ),
          ),

          // ─────────── Bottom Content ───────────
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  RichText(
                  text: TextSpan(
                    text: 'Welcome to ',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,        // black for "Welcome to "
                    ),
                    children: [
                      TextSpan(
                        text: 'Syllabuddy!',
                        style: TextStyle(
                          color: primary,         // primary color for "Syllabuddy"
                        ),
                      ),
                    ],
                  ),
                ),

                  const SizedBox(height: 16),
                  // Description Text
                  Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.5),    // slight darker background
                    borderRadius: BorderRadius.circular(12),   // rounded corners
                  ),
                  child: Text(
                    'Your personal companion to manage syllabi and stay organized throughout your academic journey!',
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                      fontWeight: FontWeight.normal
                    ),
                  ),
                ),
                  const Spacer(),
                  // Get Started Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginPage(),
                              ),
                            );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 20,         // <-- increased font size
                          fontWeight: FontWeight.w600, // optional: make it bolder
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
