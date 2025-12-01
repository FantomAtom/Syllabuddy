import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../theme.dart';

class AppPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;

  const AppPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(AppStyles.radiusMedium);

    return Container(
      decoration: BoxDecoration(
        gradient: AppStyles.primaryGradient(context),
        borderRadius: borderRadius,
      ),
      child: Material(
        // Transparent material so InkWell ripple shows on top of gradient
        color: Colors.transparent,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Center(
              child: icon == null
                  ? Text(
                      text,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          text,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
