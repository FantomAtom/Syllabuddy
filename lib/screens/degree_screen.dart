// lib/screens/degrees_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syllabuddy/screens/landingScreen.dart';
import 'department_screen.dart';

class CoursesScreen extends StatelessWidget {
  const CoursesScreen({Key? key}) : super(key: key);

  void _navigateToDept(BuildContext context, String level) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DepartmentScreen(courseLevel: level),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    // Sample user name for now
    const userName = 'John';

    return Scaffold(
      body: Column(
        children: [
          // Top curved banner
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
            child: Container(
              width: double.infinity,
              color: primary,
              padding: const EdgeInsets.only(top: 80, bottom: 40),
              child: Center(
                child: Text(
                  'Select Degree Level',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
            ),
          ),

          // Welcome message
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Welcome, $userName',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: primary,
                ),
              ),
            ),
          ),

          // Course options (only using displayName from Firestore; icons chosen client-side)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('degree-level')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(child: Text('No degree levels found.'));
                  }

                  // Put UG first then PG if present (nice UX); then any other docs after.
                  final mapById = {for (var d in docs) d.id.toUpperCase(): d};
                  final ordered = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                  if (mapById.containsKey('UG')) ordered.add(mapById['UG']!);
                  if (mapById.containsKey('PG')) ordered.add(mapById['PG']!);

                  // Add remaining docs that are neither UG nor PG
                  for (var d in docs) {
                    final idUp = d.id.toUpperCase();
                    if (idUp != 'UG' && idUp != 'PG') ordered.add(d);
                  }

                  return ListView.separated(
                    itemCount: ordered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 24),
                    itemBuilder: (context, index) {
                      final doc = ordered[index];
                      final data = doc.data();
                      final displayName =
                          (data['displayName'] as String?) ?? doc.id;

                      // Choose icon client-side:
                      // PG -> workspace_premium, else -> school (UG or fallback)
                      final idUp = doc.id.toUpperCase();
                      final lowerDisplay = displayName.toLowerCase();
                      final isPg = idUp == 'PG' ||
                          idUp.contains('PG') ||
                          lowerDisplay.contains('post') ||
                          lowerDisplay.contains('postgraduate') ||
                          lowerDisplay.contains('post graduate');

                      final icon = isPg ? Icons.workspace_premium : Icons.school;

                      return _CourseCard(
                        title: displayName,
                        icon: icon,
                        onTap: () => _navigateToDept(context, doc.id),
                      );
                    },
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                  );
                },
              ),
            ),
          ),

          // Logout & Delete Account buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary, // primary color
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LandingScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Delete Account'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600, // red for danger
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      // TODO: delete account logic
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  const _CourseCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, size: 40, color: primary),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, color: primary),
          ],
        ),
      ),
    );
  }
}
