// lib/screens/degrees_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ added for user name
import 'package:syllabuddy/screens/landingScreen.dart';
import 'package:syllabuddy/theme.dart';
import 'department_screen.dart';
import 'subject_syllabus_screen.dart';
import 'profile_screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({Key? key}) : super(key: key);

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  // Search controls
  String? _selectedDegreeId;
  String? _selectedDepartmentId;
  String? _selectedYearId;
  String? _selectedSemesterId;
  String _subjectQuery = '';

  // Dropdown lists loaded from Firestore
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _degreeDocs = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _departmentDocs = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _yearDocs = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _semesterDocs = [];

  // Loading flags
  bool _loadingDepartments = false;
  bool _loadingYears = false;
  bool _loadingSemesters = false;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ✅ User display name (minimal change replacing hardcoded "John")
  String? _userName;
  bool _loadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadDegrees();
    _fetchUserName(); // ✅ fetch the logged-in user's name
  }

  Future<void> _fetchUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _userName = "User";
          _loadingUser = false;
        });
        return;
      }

      final doc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      final last = data?['lastName'] ?? '';
      setState(() {
        _userName = "$last".trim().isEmpty ? "User" : "$last".trim();
        _loadingUser = false;
      });
    } catch (e) {
      debugPrint("Failed to fetch user name: $e");
      setState(() {
        _userName = "User";
        _loadingUser = false;
      });
    }
  }

  Future<void> _loadDegrees() async {
    final snap = await _db.collection('degree-level').get();
    setState(() => _degreeDocs = snap.docs);
  }

  Future<void> _loadDepartmentsForDegree(String? degreeId) async {
    setState(() {
      _loadingDepartments = true;
      _departmentDocs = [];
      _selectedDepartmentId = null;
      _yearDocs = [];
      _selectedYearId = null;
      _semesterDocs = [];
      _selectedSemesterId = null;
    });

    if (degreeId == null) {
      setState(() => _loadingDepartments = false);
      return;
    }

    final snap =
        await _db.collection('degree-level').doc(degreeId).collection('department').get();
    setState(() {
      _departmentDocs = snap.docs;
      _loadingDepartments = false;
    });
  }

  Future<void> _loadYearsFor(String? degreeId, String? departmentId) async {
    setState(() {
      _loadingYears = true;
      _yearDocs = [];
      _selectedYearId = null;
      _semesterDocs = [];
      _selectedSemesterId = null;
    });

    if (degreeId == null || departmentId == null) {
      setState(() => _loadingYears = false);
      return;
    }

    final snap = await _db
        .collection('degree-level')
        .doc(degreeId)
        .collection('department')
        .doc(departmentId)
        .collection('year')
        .get();

    setState(() {
      _yearDocs = snap.docs;
      _loadingYears = false;
    });
  }

  Future<void> _loadSemestersFor(
      String? degreeId, String? departmentId, String? yearId) async {
    setState(() {
      _loadingSemesters = true;
      _semesterDocs = [];
      _selectedSemesterId = null;
    });

    if (degreeId == null || departmentId == null || yearId == null) {
      setState(() => _loadingSemesters = false);
      return;
    }

    final snap = await _db
        .collection('degree-level')
        .doc(degreeId)
        .collection('department')
        .doc(departmentId)
        .collection('year')
        .doc(yearId)
        .collection('semester')
        .get();

    setState(() {
      _semesterDocs = snap.docs;
      _loadingSemesters = false;
    });
  }

  void _navigateToDept(BuildContext context, String level) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DepartmentScreen(courseLevel: level),
      ),
    );
  }

  void _onSearchPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubjectsResultsScreen(
          degreeId: _selectedDegreeId,
          departmentId: _selectedDepartmentId,
          yearId: _selectedYearId,
          semesterId: _selectedSemesterId,
          subjectQuery: _subjectQuery,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final userName = _loadingUser ? '...' : (_userName ?? 'User'); // ✅ minimal change

    // Build degree cards widgets
    final degreeWidgets = <Widget>[];
    if (_degreeDocs.isEmpty) {
      degreeWidgets.add(const Center(child: CircularProgressIndicator()));
    } else {
      // Order UG then PG
      final mapById = {for (var d in _degreeDocs) d.id.toUpperCase(): d};
      final ordered = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      if (mapById.containsKey('UG')) ordered.add(mapById['UG']!);
      if (mapById.containsKey('PG')) ordered.add(mapById['PG']!);
      for (var d in _degreeDocs) {
        final idUp = d.id.toUpperCase();
        if (idUp != 'UG' && idUp != 'PG') ordered.add(d);
      }

      for (var doc in ordered) {
        final data = doc.data();
        final displayName = (data['displayName'] as String?) ?? doc.id;
        final idUp = doc.id.toUpperCase();
        final lowerDisplay = displayName.toLowerCase();
        final isPg = idUp == 'PG' ||
            idUp.contains('PG') ||
            lowerDisplay.contains('post') ||
            lowerDisplay.contains('postgraduate') ||
            lowerDisplay.contains('post graduate');
        final icon = isPg ? Icons.workspace_premium : Icons.school;

        degreeWidgets.add(_CourseCard(
          title: displayName,
          icon: icon,
          onTap: () => _navigateToDept(context, doc.id),
        ));
        degreeWidgets.add(const SizedBox(height: 24));
      }
    }

    // Search UI widget (to be placed in same scroll view)
    final searchSection = Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Search Syllabus',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primary)),
          const SizedBox(height: 12),

          // Degree dropdown
          _buildDegreeDropdown(),

          const SizedBox(height: 8),

          // Department dropdown
          _buildDepartmentDropdown(),

          const SizedBox(height: 8),

          // Year & Semester
          Row(
            children: [
              Expanded(child: _buildYearDropdown()),
              const SizedBox(width: 12),
              Expanded(child: _buildSemesterDropdown()),
            ],
          ),

          const SizedBox(height: 8),

          // Subject search field
          TextField(
            decoration: const InputDecoration(
              labelText: 'Subject name or code (optional)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _subjectQuery = v.trim()),
          ),

          const SizedBox(height: 12),

          // Search button
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('Search'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _onSearchPressed,
            ),
          ),
        ],
      ),
    );

    // Combine degree widgets + search into a single scrollable list
    final children = <Widget>[];
    children.add(const SizedBox(height: 16));
    children.addAll(degreeWidgets);
    children.add(const SizedBox(height: 8));
    children.add(searchSection);
    children.add(const SizedBox(height: 24));

    return Scaffold(
      body: Column(
        children: [
          // Fixed Top curved banner (stays on top while rest scrolls)
          ClipRRect(
            borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
            child: Container(
              width: double.infinity,
              color: primary,
              padding: const EdgeInsets.only(top: 80, bottom: 40),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      'Select Degree Level',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.9)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Scrollable content
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Welcome message + profile button row
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Welcome, $userName', // ✅ uses real name
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // degrees + search
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      ...children,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDegreeDropdown() {
    return DropdownButtonFormField<String?>(
      value: _selectedDegreeId,
      decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Degree'),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('All Degrees')),
        ..._degreeDocs.map((d) {
          final display = (d.data()['displayName'] as String?) ?? d.id;
          return DropdownMenuItem<String?>(value: d.id, child: Text(display));
        }),
      ],
      onChanged: (v) async {
        setState(() => _selectedDegreeId = v);
        await _loadDepartmentsForDegree(v);
      },
    );
  }

  Widget _buildDepartmentDropdown() {
    if (_loadingDepartments) {
      return const SizedBox(height: 56, child: Center(child: CircularProgressIndicator()));
    }

    return DropdownButtonFormField<String?>(
      value: _selectedDepartmentId,
      decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Department'),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('All Departments')),
        ..._departmentDocs.map((d) {
          final display = (d.data()['displayName'] as String?) ?? d.id;
          return DropdownMenuItem<String?>(value: d.id, child: Text(display));
        }),
      ],
      onChanged: (v) async {
        setState(() => _selectedDepartmentId = v);
        await _loadYearsFor(_selectedDegreeId, v);
      },
    );
  }

  Widget _buildYearDropdown() {
    if (_loadingYears) {
      return const SizedBox(height: 56, child: Center(child: CircularProgressIndicator()));
    }

    return DropdownButtonFormField<String?>(
      value: _selectedYearId,
      decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Year'),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('All Years')),
        ..._yearDocs.map((d) {
          final display = (d.data()['displayName'] as String?) ?? (d.data()['value']?.toString() ?? d.id);
          return DropdownMenuItem<String?>(value: d.id, child: Text(display));
        }),
      ],
      onChanged: (v) async {
        setState(() => _selectedYearId = v);
        await _loadSemestersFor(_selectedDegreeId, _selectedDepartmentId, v);
      },
    );
  }

  Widget _buildSemesterDropdown() {
    if (_loadingSemesters) {
      return const SizedBox(height: 56, child: Center(child: CircularProgressIndicator()));
    }

    return DropdownButtonFormField<String?>(
      value: _selectedSemesterId,
      decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Semester'),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('All Semesters')),
        ..._semesterDocs.map((d) {
          final display = (d.data()['displayName'] as String?) ?? (d.data()['value']?.toString() ?? d.id);
          return DropdownMenuItem<String?>(value: d.id, child: Text(display));
        }),
      ],
      onChanged: (v) => setState(() => _selectedSemesterId = v),
    );
  }
}

/// Results screen that queries collectionGroup('subjects') and filters
/// client-side by the selected path parts and search query.
class SubjectsResultsScreen extends StatelessWidget {
  final String? degreeId;
  final String? departmentId;
  final String? yearId;
  final String? semesterId;
  final String subjectQuery;

  const SubjectsResultsScreen({
    Key? key,
    required this.degreeId,
    required this.departmentId,
    required this.yearId,
    required this.semesterId,
    required this.subjectQuery,
  }) : super(key: key);

  Map<String, String> _pathToMap(String path) {
    final segs = path.split('/');
    final map = <String, String>{};
    for (var i = 0; i + 1 < segs.length; i += 2) {
      final key = segs[i];
      final val = segs[i + 1];
      map[key] = val;
    }
    return map;
  }

  bool _matchesFilters(DocumentSnapshot<Map<String, dynamic>> doc) {
    final pathMap = _pathToMap(doc.reference.path);

    if (degreeId != null) {
      final p = pathMap['degree-level'];
      if (p == null || p.toLowerCase() != degreeId!.toLowerCase()) return false;
    }
    if (departmentId != null) {
      final p = pathMap['department'];
      if (p == null || p.toLowerCase() != departmentId!.toLowerCase()) return false;
    }
    if (yearId != null) {
      final p = pathMap['year'];
      if (p == null || p.toLowerCase() != yearId!.toLowerCase()) return false;
    }
    if (semesterId != null) {
      final p = pathMap['semester'];
      if (p == null || p.toLowerCase() != semesterId!.toLowerCase()) return false;
    }

    // text match against displayName/title or doc id (subject code)
    if (subjectQuery.isNotEmpty) {
      final data = doc.data();
      final name = (data?['displayName'] as String?) ?? (data?['title'] as String?) ?? '';
      final code = doc.id;
      final q = subjectQuery.toLowerCase();
      if (!name.toLowerCase().contains(q) && !code.toLowerCase().contains(q)) {
        return false;
      }
    }

    return true;
  }

  String _formatShortPath(DocumentSnapshot<Map<String, dynamic>> doc) {
    final pm = _pathToMap(doc.reference.path);
    final parts = <String>[];
    if ((pm['degree-level'] ?? '').isNotEmpty) parts.add(pm['degree-level']!);
    if ((pm['department'] ?? '').isNotEmpty) parts.add(pm['department']!);
    if ((pm['year'] ?? '').isNotEmpty) parts.add('Year ${pm['year']!}');
    if ((pm['semester'] ?? '').isNotEmpty) parts.add('Sem ${pm['semester']!}');
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final stream = FirebaseFirestore.instance.collectionGroup('subjects').snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Search Results')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          final allDocs = snap.data!.docs;
          final filtered = allDocs.where((d) => _matchesFilters(d)).toList(growable: false);

          if (filtered.isEmpty) {
            return const Center(child: Text('No subjects found for these filters.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: filtered.length,
            itemBuilder: (context, i) {
              final doc = filtered[i];
              final data = doc.data();
              final title = (data?['displayName'] as String?) ??
                  (data?['title'] as String?) ??
                  doc.id;
              final subtitle = _formatShortPath(doc);

              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  // Parse the path into parts and navigate to the SubjectSyllabusScreen
                  final pathMap = _pathToMap(doc.reference.path);
                  final degree = pathMap['degree-level'] ?? '';
                  final department = pathMap['department'] ?? '';
                  final year = pathMap['year'] ?? '';
                  final sem = pathMap['semester'] ?? '';
                  final subjectId = doc.id;
                  final subjectName =
                      (data?['displayName'] as String?) ?? (data?['title'] as String?);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SubjectSyllabusScreen(
                        courseLevel: degree,
                        department: department,
                        year: year,
                        semester: sem,
                        subjectId: subjectId,
                        subjectName: subjectName,
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 6),
                          Text(subtitle,
                              style: const TextStyle(fontSize: 13, color: Colors.white70)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
                  ],
                ),
              );
            },
          );
        },
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
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, size: 40, color: primary),
            const SizedBox(width: 16),
            Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primary)),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, color: primary),
          ],
        ),
      ),
    );
  }
}
