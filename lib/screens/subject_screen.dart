// lib/screens/subject_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'subject_syllabus_screen.dart';

class SubjectScreen extends StatelessWidget {
  final String courseLevel;
  final String department;
  final String year;
  final String semester;

  const SubjectScreen({
    Key? key,
    required this.courseLevel,
    required this.department,
    required this.year,
    required this.semester,
  }) : super(key: key);

  String _subjectTitleFromDoc(Map<String, dynamic>? data, String docId) {
    if (data == null) return docId;
    final dn = data['displayName'];
    if (dn is String && dn.trim().isNotEmpty) return dn.trim();
    return docId;
  }

  String? _subjectCodeFromDoc(Map<String, dynamic>? data) {
    if (data == null) return null;
    final candidates = ['subCode', 'subcode', 'code', 'subjectCode'];
    for (final k in candidates) {
      final v = data[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  String _formatSemesterTitle(String sem) {
  switch (sem) {
    case '1': return '1st Semester';
    case '2': return '2nd Semester';
    case '3': return '3rd Semester';
    default: return '${sem}th Semester';
  }
}


  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    // Reference to the semester document (to validate existence) and its subjects subcollection
    final semesterDocRef = FirebaseFirestore.instance
        .collection('degree-level')
        .doc(courseLevel)
        .collection('department')
        .doc(department)
        .collection('year')
        .doc(year)
        .collection('semester')
        .doc(semester);

    final subjectsCollection = semesterDocRef.collection('subjects');

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
                      '${_formatSemesterTitle(semester)} Subjects',
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

          // Subject list: validate semester exists (FutureBuilder) then stream subjects
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: semesterDocRef.get(),
                builder: (context, semSnapshot) {
                  if (semSnapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              'Error checking semester:\n${semSnapshot.error}',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (semSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final semDoc = semSnapshot.data;
                  if (semDoc == null || !semDoc.exists) {
                    return Center(
                      child: Text(
                        'No semester found at /degree-level/$courseLevel/department/$department/year/$year/semester/$semester.\n'
                        'Please double-check the path or IDs.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                      ),
                    );
                  }

                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: subjectsCollection.snapshots(),
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
                                  'Error loading subjects:\n${snapshot.error}',
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
                            'No subjects found for this semester.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                          ),
                        );
                      }

                      // Optionally sort by subject code if available
                      docs.sort((a, b) {
                        final ad = a.data();
                        final bd = b.data();
                        final ac = _subjectCodeFromDoc(ad) ?? '';
                        final bc = _subjectCodeFromDoc(bd) ?? '';
                        if (ac.isNotEmpty && bc.isNotEmpty) return ac.compareTo(bc);
                        return a.id.compareTo(b.id);
                      });

                      return ListView.separated(
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final doc = docs[i];
                          final data = doc.data();
                          final title = _subjectTitleFromDoc(data, doc.id);
                          final code = _subjectCodeFromDoc(data);

                          return Card(
                            child: ListTile(
                              title: Text(title),
                              subtitle: code != null ? Text(code) : null,
                              trailing: Icon(Icons.arrow_forward_ios, color: primary),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SubjectSyllabusScreen(
                                      courseLevel: courseLevel,
                                      department: department,
                                      year: year,
                                      semester: semester,
                                      subjectId: doc.id,        // important: pass the subject document id (e.g. "CS102")
                                      subjectName: title,       // optional friendly name
                                    ),
                                  ),
                                );
                              },
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
