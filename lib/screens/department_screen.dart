// lib/screens/department_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/option_card.dart';
import 'year_selection_screen.dart';

class DepartmentScreen extends StatelessWidget {
  final String courseLevel;
  const DepartmentScreen({Key? key, required this.courseLevel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    // Reference to the parent document: /degree-level/<courseLevel>
    final parentDocRef = FirebaseFirestore.instance
        .collection('degree-level')
        .doc(courseLevel);

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

          // Department options (first ensure the parent doc exists)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: parentDocRef.get(),
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
                              'Error checking degree-level:\n${parentSnapshot.error}',
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
                    // Helpful message if the degree-level document doesn't exist
                    return Center(
                      child: Text(
                        'No degree-level document found at /degree-level/$courseLevel.\n'
                        'Make sure the document exists and the collection name is "degree-level".',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                      ),
                    );
                  }

                  // Parent exists — stream the department subcollection:
                  final deptStream = parentDocRef.collection('department').snapshots();

                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: deptStream,
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
                                  'Error loading departments:\n${snapshot.error}',
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
                            'No departments found for $courseLevel.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data();
                          final displayName = (data['displayName'] as String?) ?? doc.id;

                          return OptionCard(
                            title: displayName,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => YearSelectionScreen(
                                    courseLevel: courseLevel,
                                    department: doc.id, // pass the department id
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
