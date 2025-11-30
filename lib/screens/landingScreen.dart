// lib/screens/landing_screen.dart
import 'package:flutter/material.dart';
import 'package:syllabuddy/screens/login.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    // responsive image size
    final screenW = MediaQuery.of(context).size.width;
    double imgSize = screenW * 0.62;
    if (imgSize > 420) imgSize = 420;
    if (imgSize < 260) imgSize = 260;

    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Top banner with curved bottom and gradient
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 80, bottom: 40, left: 20, right: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColorDark,
                      Theme.of(context).primaryColor,
                    ],
                    stops: const [0.0, 0.8],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // responsive image
                    Image.asset(
                      'assets/landing.png',
                      height: 350,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Content
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
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        children: [
                          TextSpan(
                            text: 'Syllabuddy!',
                            style: TextStyle(
                              color: primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Subtitle (requested text)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'A smart companion built to support your college experience. Syllabuddy keeps your syllabi, schedules, exams, hall allotments, and important academic essentials in one organized place, helping you stay prepared and manage each semester with ease.',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black87,
                          height: 1.35,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Get Started Button with matching gradient
                    SafeArea(
                      top: false,
                      child: SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).primaryColorDark,
                                Theme.of(context).primaryColor,
                              ],
                              stops: const [0.0, 0.8],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginPage()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Get Started',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
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
      ),
    );
  }
}
