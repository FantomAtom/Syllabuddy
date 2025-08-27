// lib/screens/landing_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:syllabuddy/screens/login.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({Key? key}) : super(key: key);

  static const double _mobileBreakpoint = 600;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _mobileBreakpoint) {
          return _buildMobile(context, primary);
        } else {
          return _buildDesktop(context, primary, constraints.maxWidth);
        }
      },
    );
  }

  // ---------------- Mobile (preserves original look) ----------------
  Widget _buildMobile(BuildContext context, Color primary) {
    return Scaffold(
      body: Column(
        children: [
          // Top Banner with Curved Bottom
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
                    height: 300,
                    width: 300,
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
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
                  // Description Text
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Your personal companion to manage syllabi and stay organized throughout your academic journey!',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.black87,
                        fontWeight: FontWeight.normal,
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
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
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

  // ---------------- Desktop / Large screens (fixed-height content) ----------------
  Widget _buildDesktop(
      BuildContext context, Color primary, double availableWidth) {
    // Constrain the content width for a nicer centered layout
    const double maxContentWidth = 1000;
    final double contentWidth = availableWidth > maxContentWidth
        ? maxContentWidth
        : availableWidth * 0.95;

    // Compute a reasonable height to avoid infinite/unbounded space.
    final double screenH = MediaQuery.of(context).size.height;
    final double containerHeight = math.min(math.max(screenH * 0.72, 560), 920);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: contentWidth,
              // give the row a bounded height so children can use Spacer/Flexible safely
              maxHeight: containerHeight,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // LEFT: Illustration / Banner
                  Flexible(
                    flex: 5,
                    child: Container(
                      color: primary,
                      padding: const EdgeInsets.symmetric(
                          vertical: 28, horizontal: 36),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top-left small title
                          Text(
                            'Syllabuddy',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Centered illustration — sizedBox with constraints instead of Expanded
                          Expanded(
                            child: Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: 460,
                                  maxHeight: containerHeight * 0.6,
                                ),
                                child: Image.asset(
                                  'assets/landing.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Small tagline
                          Text(
                            'Organize. Study. Succeed.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.95),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // RIGHT: Content card
                  Flexible(
                    flex: 6,
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 28, horizontal: 36),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Big Title
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
                          const SizedBox(height: 12),

                          // Short description
                          Text(
                            'Your personal companion to manage syllabi and stay organized throughout your academic journey.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[800],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Feature bullets
                          Row(
                            children: [
                              _featureItem(Icons.book, 'Manage syllabi'),
                              const SizedBox(width: 18),
                              _featureItem(Icons.calendar_today, 'Track deadlines'),
                              const SizedBox(width: 18),
                              _featureItem(Icons.notifications, 'Reminders'),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // CTA box
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: primary.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Access your course outlines, set reminders for submissions and exams, and keep everything in one place.',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[900],
                              ),
                            ),
                          ),

                          const Spacer(),

                          // Action buttons row
                          Row(
                            children: [
                              Expanded(
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
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  child: const Text(
                                    'Get Started',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton(
                                onPressed: () {
                                  // maybe show a demo or open a help page later
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: primary),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14, horizontal: 18),
                                ),
                                child: Text(
                                  'Learn more',
                                  style: TextStyle(
                                    color: primary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // small helper used in desktop features row
  Widget _featureItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 20, color: Colors.black87),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
