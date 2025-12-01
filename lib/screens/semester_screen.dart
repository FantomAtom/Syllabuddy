// lib/screens/semester_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:syllabuddy/widgets/app_header.dart';
import 'package:syllabuddy/widgets/app_option_card.dart';
import 'package:syllabuddy/screens/subject_screen.dart';

class SemesterScreen extends StatelessWidget {
  final String courseLevel;
  final String department;
  final String year;

  const SemesterScreen({
    Key? key,
    required this.courseLevel,
    required this.department,
    required this.year,
  }) : super(key: key);

  String _ordinalSuffix(int n) {
    final rem100 = n % 100;
    if (rem100 >= 11 && rem100 <= 13) return 'th';
    switch (n % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  String _semesterDisplayFromDoc(String docId, Map<String, dynamic>? data) {
    final display = data != null && data['displayName'] is String
        ? (data['displayName'] as String).trim()
        : '';

    if (display.isNotEmpty) return display;

    final numeric = int.tryParse(docId);
    if (numeric != null) return '${numeric}${_ordinalSuffix(numeric)} Semester';

    // fallback to docId
    return docId;
  }

  Color _textColorOrFallback(BuildContext context, Color fallback) {
    return Theme.of(context).textTheme.bodyMedium?.color ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    final yearDocRef = FirebaseFirestore.instance
        .collection('degree-level')
        .doc(courseLevel)
        .collection('department')
        .doc(department)
        .collection('year')
        .doc(year);

    return Scaffold(
      body: Column(
        children: [
          // Reuse centralized header for consistency
          const AppHeader(title: 'Select Semester', showBack: true),

          // Semester options (validate year exists, then stream semester subcollection)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: yearDocRef.get(),
                builder: (context, parentSnapshot) {
                  if (parentSnapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              'Error checking year:\n${parentSnapshot.error}',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: _textColorOrFallback(context, Colors.grey.shade800)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (parentSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final parentDoc = parentSnapshot.data;
                  if (parentDoc == null || !parentDoc.exists) {
                    return Center(
                      child: Text(
                        'No year found at /degree-level/$courseLevel/department/$department/year/$year.\n'
                        'Double-check the path or department/year IDs.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: _textColorOrFallback(context, Colors.grey.shade800)),
                      ),
                    );
                  }

                  final semestersStream = yearDocRef.collection('semester').snapshots();

                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: semestersStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Text(
                                  'Error loading semesters:\n${snapshot.error}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 16, color: _textColorOrFallback(context, Colors.grey.shade800)),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data?.docs ?? [];

                      if (docs.isEmpty) {
                        return Center(
                          child: Text(
                            'No semesters found for year "$year".',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: _textColorOrFallback(context, Colors.grey.shade800)),
                          ),
                        );
                      }

                      // Sort numeric semester IDs ascending if possible
                      docs.sort((a, b) {
                        final ai = int.tryParse(a.id);
                        final bi = int.tryParse(b.id);
                        if (ai != null && bi != null) return ai.compareTo(bi);
                        return a.id.compareTo(b.id);
                      });

                      return ListView.separated(
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data();
                          final title = _semesterDisplayFromDoc(doc.id, data);

                          return AppOptionCard(
                            title: title,
                            icon: Icons.view_week, // change this to any icon you prefer
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SubjectScreen(
                                    courseLevel: courseLevel,
                                    department: department,
                                    year: year,
                                    semester: doc.id, // pass semester doc id (e.g. "1")
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
