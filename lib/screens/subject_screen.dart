// lib/screens/subject_screen.dart
import 'package:flutter/material.dart';

class SubjectScreen extends StatelessWidget {
  final String department;
  final String year;
  final String semester;
  const SubjectScreen({Key? key, required this.department, required this.year, required this.semester}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final subjects = [
      {'code': 'CS101', 'name': 'Data Structures'},
      {'code': 'CS102', 'name': 'Algorithms'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('$semester Subjects'),
        backgroundColor: primary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: subjects.length,
        itemBuilder: (_, i) {
          final sub = subjects[i];
          return Card(
            child: ListTile(
              title: Text(sub['name']!),
              subtitle: Text(sub['code']!),
            ),
          );
        },
      ),
    );
  }
}
