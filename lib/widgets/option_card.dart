// lib/widgets/option_card.dart
import 'package:flutter/material.dart';
import 'package:syllabuddy/theme.dart'; // extension and constants

class OptionCard extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  const OptionCard({
    Key? key,
    required this.title,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryText = theme.colorScheme.primaryText;
    final bg = theme.cardColor;
    final isDark = theme.brightness == Brightness.dark;

    final shadowColor = isDark ? kShadowDark : kShadowLight;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: shadowColor, blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: bg,
          child: InkWell(
            onTap: onTap,
            splashFactory: InkRipple.splashFactory,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Center(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryText,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
