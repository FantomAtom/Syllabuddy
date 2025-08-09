// lib/screens/subject_syllabus_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart'; // Clipboard

class SubjectSyllabusScreen extends StatelessWidget {
  final String courseLevel;
  final String department;
  final String year;
  final String semester;
  final String subjectId;
  final String? subjectName;

  const SubjectSyllabusScreen({
    Key? key,
    required this.courseLevel,
    required this.department,
    required this.year,
    required this.semester,
    required this.subjectId,
    this.subjectName,
  }) : super(key: key);

  String _buildUnitTitle(String docId, Map<String, dynamic>? data) {
    final unitField = data != null && data['unit'] is String
        ? (data['unit'] as String).trim()
        : '';
    final hours = (data != null && data['hours'] != null) ? data['hours'].toString().trim() : '';

    if (unitField.isNotEmpty) {
      // If the unit field already mentions hours, don't append again
      final lower = unitField.toLowerCase();
      if (hours.isNotEmpty && !lower.contains('hr') && !lower.contains('hrs')) {
        return '$unitField ($hours Hrs)';
      }
      return unitField;
    }

    // Fallback: use docId (common to have docs like "1", "2", ...)
    final idNumeric = int.tryParse(docId);
    final idLabel = idNumeric != null ? 'Unit $docId' : docId;
    if (hours.isNotEmpty) return '$idLabel ($hours Hrs)';
    return idLabel;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    final subjectDocRef = FirebaseFirestore.instance
        .collection('degree-level')
        .doc(courseLevel)
        .collection('department')
        .doc(department)
        .collection('year')
        .doc(year)
        .collection('semester')
        .doc(semester)
        .collection('subjects')
        .doc(subjectId);

    final unitsCollection = subjectDocRef.collection('units');

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
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Center(
                    child: Text(
                      subjectName != null && subjectName!.trim().isNotEmpty
                          ? subjectName!
                          : subjectId,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.95),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Units list: validate subject exists, then stream units
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: subjectDocRef.get(),
                builder: (context, subjectSnapshot) {
                  if (subjectSnapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              'Error checking subject:\n${subjectSnapshot.error}',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (subjectSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final sdoc = subjectSnapshot.data;
                  if (sdoc == null || !sdoc.exists) {
                    return Center(
                      child: Text(
                        'No subject found at:\n/degree-level/$courseLevel/department/$department/year/$year/semester/$semester/subjects/$subjectId',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                      ),
                    );
                  }

                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: unitsCollection.snapshots(),
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
                                  'Error loading units:\n${snapshot.error}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
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
                            'No units found for this subject.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                          ),
                        );
                      }

                      // Sort numeric unit IDs ascending if possible
                      docs.sort((a, b) {
                        final ai = int.tryParse(a.id);
                        final bi = int.tryParse(b.id);
                        if (ai != null && bi != null) return ai.compareTo(bi);
                        return a.id.compareTo(b.id);
                      });

                      return ListView.separated(
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data();
                          final content = (data != null && data['content'] is String) ? (data['content'] as String) : '';
                          final title = _buildUnitTitle(doc.id, data);

                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ExpansionTile(
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 20),
                                    tooltip: 'Copy unit content',
                                    onPressed: content.isNotEmpty
                                        ? () {
                                            Clipboard.setData(ClipboardData(text: content));
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Unit content copied to clipboard!'),
                                                duration: Duration(seconds: 1),
                                              ),
                                            );
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: content.isNotEmpty
                                      ? Text(content, style: const TextStyle(fontSize: 15, height: 1.5))
                                      : Text(
                                          'No content available for this unit.',
                                          style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                                        ),
                                ),
                              ],
                            ),
                          );
                        },
                        padding: const EdgeInsets.only(bottom: 16),
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
