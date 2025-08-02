// lib/screens/department_screen.dart
import 'package:flutter/material.dart';
import 'year_selection_screen.dart';

class DepartmentScreen extends StatelessWidget {
  final String courseLevel;
  const DepartmentScreen({Key? key, required this.courseLevel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final departments = courseLevel == 'UG'
      ? ['Computer Science', 'Electronics', 'Mechanical']
      : ['M.Sc. CS', 'M.E. Electronics'];

    return Scaffold(
      appBar: AppBar(
        title: Text('$courseLevel Departments'),
        backgroundColor: primary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: departments.length,
        itemBuilder: (_, i) {
          final dept = departments[i];
          return Card(
            child: ListTile(
              title: Text(dept),
              trailing: Icon(Icons.arrow_forward_ios, color: primary),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => YearSelectionScreen(
                    courseLevel: courseLevel,
                    department: dept,
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
