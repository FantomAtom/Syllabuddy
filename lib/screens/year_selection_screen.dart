// lib/screens/year_selection_screen.dart
import 'package:flutter/material.dart';
import 'semester_screen.dart';

class YearSelectionScreen extends StatelessWidget {
  final String courseLevel;
  final String department;
  const YearSelectionScreen({Key? key, required this.courseLevel, required this.department}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final years = ['1st Year', '2nd Year', '3rd Year', '4th Year'];

    return Scaffold(
      appBar: AppBar(
        title: Text('$department - Year'),
        backgroundColor: primary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: years.length,
        itemBuilder: (_, i) {
          final yr = years[i];
          return Card(
            child: ListTile(
              title: Text(yr),
              trailing: Icon(Icons.arrow_forward_ios, color: primary),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SemesterScreen(
                    courseLevel: courseLevel,
                    department: department,
                    year: yr,
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
