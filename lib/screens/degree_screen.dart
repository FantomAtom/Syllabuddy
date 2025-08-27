// lib/screens/degrees_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syllabuddy/screens/profile_screen.dart';
import 'package:syllabuddy/screens/department_screen.dart';
import 'package:syllabuddy/screens/subject_syllabus_screen.dart';
import '../widgets/option_card.dart';

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

  @override
  void initState() {
    super.initState();
    _loadDegrees();
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

    final snap = await _db.collection('degree-level').doc(degreeId).collection('department').get();
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

  Future<void> _loadSemestersFor(String? degreeId, String? departmentId, String? yearId) async {
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

  // Helper to build degree card widgets
  List<Widget> _buildDegreeWidgets(Color primary) {
    final degreeWidgets = <Widget>[];
    if (_degreeDocs.isEmpty) {
      degreeWidgets.add(const Center(child: CircularProgressIndicator()));
    } else {
      // Order UG then PG if present
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

        degreeWidgets.add(GestureDetector(
          onTap: () => _navigateToDept(context, doc.id),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 4))],
            ),
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
            child: Row(
              children: [
                Icon(icon, size: 36, color: primary),
                const SizedBox(width: 12),
                Expanded(child: Text(displayName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: primary))),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
          ),
        ));
      }
    }
    return degreeWidgets;
  }

  // --- widgets for dropdowns ---
  Widget _degreeDropdown(Color primary) {
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

  Widget _departmentDropdown() {
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

  Widget _yearDropdown() {
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

  Widget _semesterDropdown() {
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

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    const userName = 'John';

    return LayoutBuilder(builder: (context, constraints) {
      final isDesktop = constraints.maxWidth >= 800;

      if (isDesktop) {
        // Desktop: centered content column, top appbar + search toolbar + degree grid
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            titleSpacing: 20,
            title: Row(
              children: [
                Image.asset('assets/icon.png', height: 34),
                const SizedBox(width: 12),
                Text('Syllabuddy', style: TextStyle(color: primary, fontWeight: FontWeight.bold)),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Center(child: Text('Welcome, $userName', style: TextStyle(color: primary, fontWeight: FontWeight.w600))),
              ),
              IconButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                icon: CircleAvatar(radius: 16, backgroundColor: primary, child: const Icon(Icons.person, color: Colors.white, size: 18)),
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // hero
                      Text('Select Degree Level', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primary)),
                      const SizedBox(height: 6),
                      Text('Find syllabi by degree, department, year or semester. Use filters or browse degree cards below.', style: TextStyle(color: Colors.grey[700])),
                      const SizedBox(height: 20),

                      // Search toolbar (card)
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              // row with dropdowns
                              Row(
                                children: [
                                  Expanded(child: _degreeDropdown(primary)),
                                  const SizedBox(width: 12),
                                  Expanded(child: _departmentDropdown()),
                                  const SizedBox(width: 12),
                                  Expanded(child: _yearDropdown()),
                                  const SizedBox(width: 12),
                                  Expanded(child: _semesterDropdown()),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        hintText: 'Subject name or code (optional)',
                                        prefixIcon: Icon(Icons.search),
                                      ),
                                      onChanged: (v) => setState(() => _subjectQuery = v.trim()),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  SizedBox(
                                    height: 48,
                                    child: ElevatedButton.icon(
                                      onPressed: _onSearchPressed,
                                      icon: const Icon(Icons.search),
                                      label: const Text('Search'),
                                      style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Degrees grid
                      Text('Degrees', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primary)),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _degreeDocs.isEmpty ? 4 : _degreeDocs.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 3.2,
                        ),
                        itemBuilder: (context, i) {
                          final widgets = _buildDegreeWidgets(primary);
                          // if not loaded, show placeholders
                          if (widgets.isEmpty) {
                            return Container(
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                              height: 80,
                              child: const Center(child: CircularProgressIndicator()),
                            );
                          }
                          return widgets[i];
                        },
                      ),
                      const SizedBox(height: 28),

                      // Footer / additional content
                      Center(child: Text('Tip: Click a degree card to explore departments', style: TextStyle(color: Colors.grey[600]))),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }

      // Mobile: keep original curved banner + list
      return Scaffold(
        body: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
              child: Container(
                width: double.infinity,
                color: primary,
                padding: const EdgeInsets.only(top: 80, bottom: 40),
                child: Center(
                  child: Text('Select Degree Level', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.9))),
                ),
              ),
            ),

            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: Row(
                      children: [
                        Expanded(child: Text('Welcome, $userName', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: primary))),
                        InkWell(
                          borderRadius: BorderRadius.circular(100),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: CircleAvatar(radius: 20, backgroundColor: primary, child: const Icon(Icons.person, color: Colors.white, size: 20)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        ..._buildDegreeWidgets(primary),
                        const SizedBox(height: 12),

                        // search section (mobile)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text('Search Syllabus', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                _degreeDropdown(primary),
                                const SizedBox(height: 8),
                                _departmentDropdown(),
                                const SizedBox(height: 8),
                                Row(children: [Expanded(child: _yearDropdown()), const SizedBox(width: 8), Expanded(child: _semesterDropdown())]),
                                const SizedBox(height: 8),
                                TextField(
                                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Subject name or code', prefixIcon: Icon(Icons.search)),
                                  onChanged: (v) => setState(() => _subjectQuery = v.trim()),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(height: 48, child: ElevatedButton.icon(onPressed: _onSearchPressed, icon: const Icon(Icons.search), label: const Text('Search'))),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// Minimal results screen included so the Search button works.
/// You can replace this with your own results screen if you already have one.
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
      map[segs[i]] = segs[i + 1];
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
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));

          final allDocs = snap.data!.docs;
          final filtered = allDocs.where((d) => _matchesFilters(d)).toList(growable: false);

          if (filtered.isEmpty) return const Center(child: Text('No subjects found for these filters.'));

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: filtered.length,
            itemBuilder: (context, i) {
              final doc = filtered[i];
              final data = doc.data();
              final title = (data?['displayName'] as String?) ?? (data?['title'] as String?) ?? doc.id;
              final subtitle = _formatShortPath(doc);

              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final pathMap = _pathToMap(doc.reference.path);
                  final degree = pathMap['degree-level'] ?? '';
                  final department = pathMap['department'] ?? '';
                  final year = pathMap['year'] ?? '';
                  final sem = pathMap['semester'] ?? '';
                  final subjectId = doc.id;
                  final subjectName = (data?['displayName'] as String?) ?? (data?['title'] as String?);

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
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 6),
                        Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                      ]),
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
