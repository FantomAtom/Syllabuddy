// lib/screens/landing_screen.dart
import 'package:flutter/material.dart';
import 'package:syllabuddy/screens/login.dart';
import 'package:syllabuddy/widgets/app_primary_button.dart';
import 'package:syllabuddy/styles/app_styles.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;

    final headerGradient = AppStyles.primaryGradient(context);

    // Subtitle text style (larger + readable)
    final subtitleStyle = TextStyle(
      fontSize: 20,
      height: 1.45,
      color: Colors.black87,
      fontWeight: FontWeight.w400,
    );

    // Bold black text for “Syllabuddy”
    final boldBlack = const TextStyle(
      fontWeight: FontWeight.w800,
      color: Colors.black87,
    );

    // Soft gradient for subtitle container
    final subtitleGradient = LinearGradient(
      colors: [
        primary.withOpacity(0.35), // darker
        primary.withOpacity(0.25), // lighter middle
        primary.withOpacity(0.35), // darker again
      ],
      stops: const [
        0.0,   // start
        0.5,   // middle
        1.0,   // end
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    // Adjust landing image sizing
    final screenW = MediaQuery.of(context).size.width;
    double imgSize = screenW * 0.62;
    imgSize = imgSize.clamp(260, 420);

    return Scaffold(
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Column(
              children: [
                // HEADER
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(AppStyles.radiusLarge),
                    bottomRight: Radius.circular(AppStyles.radiusLarge),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(
                        top: 60, bottom: 40, left: 20, right: 20),
                    decoration: BoxDecoration(gradient: headerGradient),
                    child: Center(
                      child: Image.asset(
                        'assets/landing.png',
                        height: imgSize,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                // BODY CONTENT
                Expanded(
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        RichText(
                          text: TextSpan(
                            text: 'Welcome to ',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            children: [
                              TextSpan(
                                text: 'Syllabuddy!',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: primary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Subtitle container
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: subtitleGradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text.rich(
                            TextSpan(
                              style: subtitleStyle,
                              children: [
                                const TextSpan(
                                    text:
                                        'A smart companion built to support your college experience. '),
                                TextSpan(
                                    text: 'Syllabuddy ',
                                    style: boldBlack ),
                                const TextSpan(text: 'keeps your '),
                                TextSpan(
                                  text: 'syllabi',
                                  style: TextStyle(fontWeight: FontWeight.w700, color: primary)
                                ),
                                const TextSpan(text: ', '),
                                TextSpan(
                                  text: 'schedules',
                                  style: TextStyle(fontWeight: FontWeight.w700, color: primary)
                                ),
                                const TextSpan(text: ', '),
                                TextSpan(
                                  text: 'exams',
                                  style: TextStyle(fontWeight: FontWeight.w700, color: primary)
                                ),
                                const TextSpan(text: ', and '),
                                TextSpan(
                                  text: 'hall allotments',
                                  style: TextStyle(fontWeight: FontWeight.w700, color: primary)
                                ),
                                const TextSpan(
                                  text:
                                      ', along with other important academic essentials to help you stay prepared and manage each semester with ease.',
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 110), // space above the button
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // BOTTOM-ALIGNED BUTTON
            Positioned(
              left: 24,
              right: 24,
              bottom: 32,
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: AppPrimaryButton(
                  text: "Get Started",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
