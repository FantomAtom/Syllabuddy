import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syllabuddy/widgets/app_header.dart';
import 'package:syllabuddy/widgets/app_option_card.dart';
import 'package:syllabuddy/theme.dart';
import 'package:syllabuddy/screens/year_selection_screen.dart';

class DepartmentScreen extends StatelessWidget {
  final String courseLevel;
  const DepartmentScreen({Key? key, required this.courseLevel}) : super(key: key);

  /// Utility: derive a darker variant from [base] by reducing lightness (HSL).
  Color _deriveDarker(Color base, double reduceBy) {
    final hsl = HSLColor.fromColor(base);
    final newLightness = (hsl.lightness - reduceBy).clamp(0.0, 1.0);
    return hsl.withLightness(newLightness).toColor();
  }

  Color _textColorOrFallback(BuildContext context, Color fallback) {
    // Prefer theme text color if available, otherwise use fallback
    return Theme.of(context).textTheme.bodyMedium?.color ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // primary follows the active theme (kPrimaryDark in dark theme, kPrimaryLight in light)
    final primary = theme.primaryColor;
    // derive darker variant to create the two-tone gradient consistent with degrees screen
    final primaryDarkVariant = _deriveDarker(primary, 0.18);

    // Firestore parent reference
    final parentDocRef = FirebaseFirestore.instance.collection('degree-level').doc(courseLevel);

    return Scaffold(
      body: Column(
        children: [
          // Reuse AppHeader so header and back behaviour / style stays consistent
          AppHeader(title: 'Select Department', showBack: true),

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
                              style: TextStyle(
                                fontSize: 16,
                                color: _textColorOrFallback(context, Colors.grey.shade800),
                              ),
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
                        style: TextStyle(
                          fontSize: 16,
                          color: _textColorOrFallback(context, Colors.grey.shade800),
                        ),
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
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _textColorOrFallback(context, Colors.grey.shade800),
                                  ),
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
                            style: TextStyle(
                              fontSize: 16,
                              color: _textColorOrFallback(context, Colors.grey.shade800),
                            ),
                          ),
                        );
                      }

                      // Use the same AppOptionCard used in degrees_screen so UI and behavior stay consistent
                      return ListView.separated(
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data();
                          final displayName = (data['displayName'] as String?) ?? doc.id;

                          return AppOptionCard(
                            title: displayName,
                            icon: Icons.domain, // neutral icon; AppOptionCard will lay it out consistently
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
