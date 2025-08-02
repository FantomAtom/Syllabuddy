import 'package:flutter/material.dart';
import '../widgets/option_card.dart';
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
      body: Column(
        children: [
          // Top curved banner with back button
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
                    alignment: Alignment.center,
                    child: Text(
                      'Select Department',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    top: 0,
                    bottom: 0,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Department options
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ListView(
                children: departments.map((dept) {
                  return OptionCard(
                    title: dept,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => YearSelectionScreen(
                            courseLevel: courseLevel,
                            department: dept,
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
