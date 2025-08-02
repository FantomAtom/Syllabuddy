// lib/screens/semester_screen.dart
import 'package:flutter/material.dart';
import 'package:syllabuddy/screens/subject_screen.dart';
import '../theme.dart';
import 'subject_screen.dart';

class SemesterScreen extends StatelessWidget {
  final String courseLevel;
  final String department;
  final String year;
  const SemesterScreen({Key? key, required this.courseLevel, required this.department, required this.year}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final sems = ['Semester 1', 'Semester 2', 'Semester 3', 'Semester 4'];

    return Scaffold(
      appBar: AppBar(
        title: Text('$year Semesters'),
        backgroundColor: primary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sems.length,
        itemBuilder: (_, i) {
          final sem = sems[i];
          return Card(
            child: ListTile(
              title: Text(sem),
              trailing: Icon(Icons.arrow_forward_ios, color: primary),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SubjectScreen(
                    department: department,
                    year: year,
                    semester: sem,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
