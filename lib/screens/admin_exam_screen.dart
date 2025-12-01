// lib/screens/admin_exam_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'admin_edit_exam_set.dart'; // editing screen (kept separate)

// shared widgets & styles
import '../styles/app_styles.dart';
import '../theme.dart';
import '../widgets/app_primary_button.dart';

class AdminExamScreen extends StatefulWidget {
  const AdminExamScreen({super.key});

  @override
  State<AdminExamScreen> createState() => _AdminExamScreenState();
}

class _AdminExamScreenState extends State<AdminExamScreen> {
  final _db = FirebaseFirestore.instance;

  Future<void> _deleteExamSet(DocumentSnapshot<Map<String, dynamic>> doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete exam set'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text('Delete "${doc.data()?['examName'] ?? doc.id}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await doc.reference.delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exam set deleted')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Exam Schedules', style: TextStyle(color: theme.colorScheme.onPrimary)),
        backgroundColor: theme.primaryColor,
        iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView(
          children: [
            // create button top - styled to match app
            Row(
              children: [
                Expanded(
                  child: AppPrimaryButton(
                    text: 'Create Exam Set',
                    icon: Icons.add,
                    onPressed: () async {
                      final created = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminExamCreateScreen()),
                      );
                      if (created == true && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exam set created')));
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Text('Upcoming / Ongoing Exam Sets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primaryText)),
            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _db.collection('exam-sets').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                }
                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text('Error: ${snap.error}', style: TextStyle(color: theme.colorScheme.error)),
                  );
                }

                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text('No exam sets found.', style: TextStyle(color: theme.textTheme.bodySmall?.color)),
                  );
                }

                return Column(
                  children: docs.map((d) {
                    final data = d.data();
                    final name = (data['examName'] ?? d.id).toString();
                    final degree = (data['degreeId'] ?? '').toString();
                    final dept = (data['departmentId'] ?? '').toString();
                    final subjects = (data['subjects'] as List<dynamic>?) ?? [];
                    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

                    final subtitleParts = <String>[];
                    if (degree.isNotEmpty) subtitleParts.add(degree);
                    if (dept.isNotEmpty) subtitleParts.add(dept);
                    subtitleParts.add('${subjects.length} subject${subjects.length == 1 ? '' : 's'}');
                    if (createdAt != null) subtitleParts.add('Created ${createdAt.toLocal().toString().split(' ')[0]}');

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                        boxShadow: [AppStyles.shadow(context)],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        title: Text(name, style: TextStyle(fontWeight: FontWeight.w700, color: theme.colorScheme.primaryText)),
                        subtitle: Text(subtitleParts.join(' • '), style: TextStyle(color: theme.textTheme.bodySmall?.color)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              tooltip: 'Edit',
                              onPressed: () async {
                                final res = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(builder: (_) => AdminEditExamSet(docId: d.id)),
                                );
                                if (res == true && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exam set updated')));
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Delete',
                              onPressed: () => _deleteExamSet(d),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// AdminExamCreateScreen — create form (keeps create isolated)
/// ---------------------------------------------------------------------------
class AdminExamCreateScreen extends StatefulWidget {
  const AdminExamCreateScreen({super.key});

  @override
  State<AdminExamCreateScreen> createState() => _AdminExamCreateScreenState();
}

class _AdminExamCreateScreenState extends State<AdminExamCreateScreen> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String _examName = '';
  String? _selectedDegree;
  String? _selectedDept;
  String? _selectedYear;
  String? _selectedSem;
  bool _saving = false;
  String? _error;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _degrees = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _departments = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _years = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _sems = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _subjects = [];

  final Map<String, DateTime?> _selectedSubjects = {};

  @override
  void initState() {
    super.initState();
    _loadDegrees();
  }

  Future<void> _loadDegrees() async {
    final snap = await _db.collection('degree-level').get();
    if (!mounted) return;
    setState(() => _degrees = snap.docs);
  }

  Future<void> _loadDepartments() async {
    if (_selectedDegree == null) return;
    final snap = await _db.collection('degree-level').doc(_selectedDegree).collection('department').get();
    if (!mounted) return;
    setState(() {
      _departments = snap.docs;
      _years = [];
      _sems = [];
      _subjects = [];
      _selectedDept = _departments.any((d) => d.id == _selectedDept) ? _selectedDept : null;
      _selectedYear = null;
      _selectedSem = null;
      _selectedSubjects.clear();
    });
  }

  Future<void> _loadYears() async {
    if (_selectedDegree == null || _selectedDept == null) return;
    final snap = await _db
        .collection('degree-level')
        .doc(_selectedDegree)
        .collection('department')
        .doc(_selectedDept)
        .collection('year')
        .orderBy('value')
        .get();
    if (!mounted) return;
    setState(() {
      _years = snap.docs;
      _sems = [];
      _selectedYear = _years.any((y) => y.id == _selectedYear) ? _selectedYear : null;
      _selectedSem = null;
      _subjects = [];
      _selectedSubjects.clear();
    });
  }

  Future<void> _loadSems() async {
    if (_selectedDegree == null || _selectedDept == null || _selectedYear == null) return;
    final snap = await _db
        .collection('degree-level')
        .doc(_selectedDegree)
        .collection('department')
        .doc(_selectedDept)
        .collection('year')
        .doc(_selectedYear)
        .collection('semester')
        .orderBy('value')
        .get();
    if (!mounted) return;
    setState(() {
      _sems = snap.docs;
      _selectedSem = _sems.any((s) => s.id == _selectedSem) ? _selectedSem : null;
      _subjects = [];
      _selectedSubjects.clear();
    });
  }

  Future<void> _loadSubjects() async {
    if (_selectedDegree == null || _selectedDept == null || _selectedYear == null || _selectedSem == null) return;
    final snap = await _db
        .collection('degree-level')
        .doc(_selectedDegree)
        .collection('department')
        .doc(_selectedDept)
        .collection('year')
        .doc(_selectedYear)
        .collection('semester')
        .doc(_selectedSem)
        .collection('subjects')
        .get();
    if (!mounted) return;
    setState(() {
      _subjects = snap.docs;
      _selectedSubjects.clear();
      for (var s in _subjects) {
        _selectedSubjects[s.id] = null;
      }
    });
  }

  Future<void> _pickDateForSubject(String subjectId) async {
    final initial = _selectedSubjects[subjectId] ?? DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: initial, firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (picked == null) return;
    if (!mounted) return;
    setState(() => _selectedSubjects[subjectId] = picked);
  }

  QueryDocumentSnapshot<Map<String, dynamic>>? _findSubjectDoc(String id) {
    for (var s in _subjects) {
      if (s.id == id) return s;
    }
    return null;
  }

  Future<void> _saveExamSet() async {
    if (_examName.trim().isEmpty) {
      setState(() => _error = 'Enter exam name');
      return;
    }
    if (_selectedDegree == null || _selectedDept == null) {
      setState(() => _error = 'Select degree and department');
      return;
    }

    final selectedEntries = _selectedSubjects.entries.where((e) => e.value != null).toList();
    if (selectedEntries.isEmpty) {
      setState(() => _error = 'Select at least one subject and assign a date');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      if (!mounted) return;
      setState(() {
        _error = 'Not signed in';
        _saving = false;
      });
      return;
    }

    try {
      final subjectsPayload = <Map<String, dynamic>>[];
      for (var entry in selectedEntries) {
        final subjDoc = _findSubjectDoc(entry.key);
        final displayName = subjDoc?.data()?['displayName'] ?? entry.key;
        subjectsPayload.add({
          'subjectId': entry.key,
          'displayName': displayName,
          'date': Timestamp.fromDate(entry.value!),
        });
      }

      final docRef = _db.collection('exam-sets').doc();
      await docRef.set({
        'examName': _examName.trim(),
        'degreeId': _selectedDegree,
        'departmentId': _selectedDept,
        if (_selectedYear != null) 'yearId': _selectedYear,
        if (_selectedSem != null) 'semesterId': _selectedSem,
        'subjects': subjectsPayload,
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) { 
      if (!mounted) return;
      setState(() => _error = 'Save failed: $e');
    } finally {
      if (!mounted) return;
      setState(() => _saving = false);
    }
  }

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> items,
    required String Function(QueryDocumentSnapshot<Map<String, dynamic>>) labelFn,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value as T?,
      decoration: InputDecoration(labelText: label),
      items: items.map((d) => DropdownMenuItem<T>(
        value: d.id as T,
        child: Text(labelFn(d)),
      )).toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Create Exam Set', style: TextStyle(color: theme.colorScheme.onPrimary)),
        backgroundColor: theme.primaryColor,
        iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView(
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Exam name (e.g. Model Exam)'),
              onChanged: (v) => _examName = v,
            ),
            const SizedBox(height: 12),
            _dropdown<String>(
              label: 'Degree',
              value: _selectedDegree,
              items: _degrees,
              labelFn: (d) => (d.data()?['displayName'] ?? d.id).toString(),
              onChanged: (val) async {
                setState(() => _selectedDegree = val);
                await _loadDepartments();
              },
            ),
            const SizedBox(height: 12),
            _dropdown<String>(
              label: 'Department',
              value: _selectedDept,
              items: _departments,
              labelFn: (d) => (d.data()?['displayName'] ?? d.id).toString(),
              onChanged: (val) async {
                setState(() => _selectedDept = val);
                await _loadYears();
              },
            ),
            const SizedBox(height: 12),
            _dropdown<String>(
              label: 'Year (optional)',
              value: _selectedYear,
              items: _years,
              labelFn: (d) => (d.data()?['displayName'] ?? d.id).toString(),
              onChanged: (val) async {
                setState(() => _selectedYear = val);
                await _loadSems();
              },
            ),
            const SizedBox(height: 12),
            _dropdown<String>(
              label: 'Semester (optional)',
              value: _selectedSem,
              items: _sems,
              labelFn: (d) => (d.data()?['displayName'] ?? d.id).toString(),
              onChanged: (val) async {
                setState(() => _selectedSem = val);
                await _loadSubjects();
              },
            ),
            const SizedBox(height: 18),
            Text('Subjects (assign date to include)', style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.primaryText)),
            const SizedBox(height: 8),

            if (_subjects.isEmpty)
              Text('No subjects loaded. Select year & semester to load subjects.', style: TextStyle(color: theme.textTheme.bodySmall?.color))
            else
              ..._subjects.map((s) {
                final id = s.id;
                final display = (s.data()?['displayName'] ?? id).toString();
                final selDate = _selectedSubjects[id];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                    boxShadow: [AppStyles.shadow(context)],
                  ),
                  child: ListTile(
                    title: Text(display, style: TextStyle(color: theme.colorScheme.primaryText)),
                    subtitle: selDate == null ? const Text('No date assigned') : Text('${selDate.toLocal()}'.split(' ')[0]),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(icon: const Icon(Icons.calendar_today), onPressed: () => _pickDateForSubject(id)),
                      Checkbox(
                        value: selDate != null,
                        onChanged: (checked) async {
                          if (checked == true) {
                            await _pickDateForSubject(id);
                          } else {
                            if (!mounted) return;
                            setState(() => _selectedSubjects[id] = null);
                          }
                        },
                      ),
                    ]),
                  ),
                );
              }).toList(),

            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],

            const SizedBox(height: 16),
            AppPrimaryButton(
              text: _saving ? 'Saving...' : 'Create Exam Set',
              icon: _saving ? Icons.hourglass_top : Icons.save,
              onPressed: _saving ? () {} : _saveExamSet,
            ),
          ],
        ),
      ),
    );
  }
}
