import 'package:flutter/material.dart';
import 'subject_syllabus_screen.dart';

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
      body: Column(
        children: [
          // Header with back button
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
            child: Container(
              width: double.infinity,
              color: primary,
              padding: const EdgeInsets.only(top: 80, bottom: 40),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Center(
                    child: Text(
                      '$semester Subjects',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.95),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Subject list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: subjects.length,
              itemBuilder: (_, i) {
                final sub = subjects[i];
                return Card(
                  child: ListTile(
                    title: Text(sub['name']!),
                    subtitle: Text(sub['code']!),
                    trailing: Icon(Icons.arrow_forward_ios, color: primary),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SubjectSyllabusScreen(
                            subjectName: sub['name']!,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
