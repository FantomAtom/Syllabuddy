import 'package:flutter/material.dart';

class AppStyles {
  // Radii
  static const double radiusLarge = 40;
  static const double radiusMedium = 16;
  static const double radiusSmall = 10;

  // Spacing
  static const double padLarge = 24;
  static const double padMedium = 16;
  static const double padSmall = 8;

  // Shadow
  static BoxShadow shadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxShadow(
      color: isDark ? Colors.black54 : Colors.black12,
      blurRadius: 8,
      offset: const Offset(0, 4),
    );
  }

  // Gradient (darkened→primary)
  static LinearGradient primaryGradient(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    final darkened = HSLColor.fromColor(primary)
        .withLightness(
          (HSLColor.fromColor(primary).lightness - 0.08).clamp(0.0, 1.0),
        )
        .toColor();

    return LinearGradient(
      colors: [darkened, primary],
      stops: const [0.0, 0.5],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    );
  }
}
