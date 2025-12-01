// lib/widgets/app_header.dart
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final bool showBack;
  final List<Widget>? actions; // NEW: optional trailing action widgets

  const AppHeader({
    super.key,
    required this.title,
    this.showBack = true,
    this.actions,
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
        padding: const EdgeInsets.only(top: 45, bottom: 30),
        decoration: BoxDecoration(
          gradient: AppStyles.primaryGradient(context),
        ),
        child: Stack(
          children: [
            if (showBack)
              Positioned(
                left: 10,
                top: 0,
                bottom: 0,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

            // Center title
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

            // RIGHT-SIDE actions (optional)
            if (actions != null && actions!.isNotEmpty)
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
