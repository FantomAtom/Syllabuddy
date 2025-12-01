import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../theme.dart';

/// starting_screens_header.dart
/// Reusable header used across Login / Signup / Verify pages.
///
/// Example usage:
/// ```dart
/// AppStartingHeader(title: 'Welcome back!', subtitle: 'Login', imgSize: imgSize)
/// ```

class AppStartingHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double imgSize;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;
  final String logoAsset;
  final bool centerLogoMargin;

  const AppStartingHeader({
    Key? key,
    required this.title,
    this.subtitle,
    required this.imgSize,
    this.padding = const EdgeInsets.only(top: 80, bottom: 40, left: 20, right: 20),
    this.borderRadius = const BorderRadius.only(
      bottomLeft: Radius.circular(AppStyles.radiusLarge),
      bottomRight: Radius.circular(AppStyles.radiusLarge),
    ),
    this.logoAsset = 'assets/logo-transparent.png',
    this.centerLogoMargin = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerGradient = AppStyles.primaryGradient(context);

    // text styles with safe fallbacks
    final titleStyle = theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white) ??
        const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white);
    final subtitleStyle = theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.white) ??
        const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white);

    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(gradient: headerGradient),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: texts
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: titleStyle),
                  if (subtitle != null) const SizedBox(height: 6),
                  if (subtitle != null) Text(subtitle!, style: subtitleStyle),
                ],
              ),
            ),

            // Right: circular logo WITH themed bright background (no hardcoded color)
            Container(
              width: imgSize,
              height: imgSize,
              margin: centerLogoMargin ? const EdgeInsets.only(left: 16) : EdgeInsets.zero,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 8, offset: const Offset(0, 4))],
                color: theme.logoBackground,
              ),
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Image.asset(logoAsset, fit: BoxFit.cover),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
