import 'package:flutter/material.dart';
import '../styles/app_styles.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final bool showBack;

  const AppHeader({
    super.key,
    required this.title,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(AppStyles.radiusLarge),
        bottomRight: Radius.circular(AppStyles.radiusLarge),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(top: 60, bottom: 28),
        decoration: BoxDecoration(
          gradient: AppStyles.primaryGradient(context),
        ),
        child: Stack(
          children: [
            if (showBack)
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            Center(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
