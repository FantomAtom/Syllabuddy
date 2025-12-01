import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../theme.dart';

class AppOptionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const AppOptionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // In light mode: white card with primary-coloured icon/text (original look)
    // In dark mode: use theme.cardColor + readable primaryText (from your extension)
    final bgColor = isDark ? theme.cardColor : Colors.white;
    final contentColor = isDark ? theme.colorScheme.primaryText : theme.primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
          boxShadow: [
            AppStyles.shadow(context),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, size: 36, color: contentColor),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: contentColor,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: contentColor, size: 18),
          ],
        ),
      ),
    );
  }
}
