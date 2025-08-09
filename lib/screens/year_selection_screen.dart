// lib/screens/year_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/option_card.dart';
import 'semester_screen.dart';

class YearSelectionScreen extends StatelessWidget {
  final String courseLevel;
  final String department;
  const YearSelectionScreen({
    Key? key,
    required this.courseLevel,
    required this.department,
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

  String _yearDisplayFromDoc(String docId, Map<String, dynamic>? data) {
    // If displayName exists in the document data, prefer it
    final display = data != null && data['displayName'] is String
        ? (data['displayName'] as String).trim()
        : '';

    if (display.isNotEmpty) return display;

    // Try to form "1st Year" from numeric docId
    final numeric = int.tryParse(docId);
    if (numeric != null) {
      return '${numeric}${_ordinalSuffix(numeric)} Year';
    }

    // Fallback to docId
    return docId;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    // Reference to the department document
    final deptDocRef = FirebaseFirestore.instance
        .collection('degree-level')
        .doc(courseLevel)
        .collection('department')
        .doc(department);

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
                      'Select Year',
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
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Year options (check department exists then stream years)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: deptDocRef.get(),
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
                              'Error checking department:\n${parentSnapshot.error}',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
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
                        'No department found at /degree-level/$courseLevel/department/$department.\n'
                        'Double-check the department ID or Firestore structure.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                      ),
                    );
                  }

                  // Stream the 'year' subcollection
                  final yearsStream = deptDocRef.collection('year').snapshots();

                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: yearsStream,
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
                                  'Error loading years:\n${snapshot.error}',
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
                            'No years found for department "$department".',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                          ),
                        );
                      }

                      // Optionally sort numeric years ascending (1,2,3...)
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
                          final title = _yearDisplayFromDoc(doc.id, data);

                          return OptionCard(
                            title: title,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SemesterScreen(
                                    courseLevel: courseLevel,
                                    department: department,
                                    year: doc.id, // pass the year doc id (e.g. "1")
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
