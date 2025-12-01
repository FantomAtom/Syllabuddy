import 'package:flutter/material.dart';

class AppDropdown extends StatelessWidget {
  final String label;
  final dynamic value;
  final List<DropdownMenuItem> items;
  final void Function(dynamic)? onChanged;

  const AppDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField(
      value: value,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: items,
      onChanged: onChanged,
    );
  }
}
