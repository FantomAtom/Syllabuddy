import 'package:flutter/material.dart';
import '../theme.dart';

class AppSectionTitle extends StatelessWidget {
  final String text;

  const AppSectionTitle({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primaryText;

    return Text(
      text,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
    );
  }
}
