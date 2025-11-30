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
                padding: const EdgeInsets.only(top: 60, bottom: 40, left: 20, right: 20),
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
              child: SingleChildScrollView(
                // same padding you used before
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title (unchanged)
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

                    const SizedBox(height: 10),

                    // Subtitle (your styled container, unchanged)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text.rich(
                        TextSpan(
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.black87,
                            height: 1.35,
                          ),
                          children: [
                            const TextSpan(
                              text: 'A smart companion built to support your college experience. ',
                            ),

                            TextSpan(
                              text: 'Syllabuddy ',
                              style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).primaryColorDark),
                            ),

                            const TextSpan(text: 'keeps your '),

                            TextSpan(
                              text: 'syllabi',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),

                            const TextSpan(text: ', '),

                            TextSpan(
                              text: 'schedules',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),

                            const TextSpan(text: ', '),

                            TextSpan(
                              text: 'exams',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),

                            const TextSpan(text: ', and '),

                            TextSpan(
                              text: 'hall allotments',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),

                            const TextSpan(
                              text:
                                  ', along with other important academic essentials, all in one organized place to help you stay prepared and manage each semester with ease.',
                            ),
                          ],
                        ),
                      ),

                    ),

                    // small spacer (keeps the same visual gap as before)
                    const SizedBox(height: 20),

                    // Get Started Button with its SafeArea to keep it off the phone's bottom inset
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
                              stops: const [0.0, 0.5],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
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
