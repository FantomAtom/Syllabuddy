// lib/screens/admin_edit_exam_set.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminEditExamSet extends StatefulWidget {
  final String docId;
  const AdminEditExamSet({super.key, required this.docId});

  @override
  State<AdminEditExamSet> createState() => _AdminEditExamSetState();
}

class _AdminEditExamSetState extends State<AdminEditExamSet> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  bool _loading = true;
  bool _saving = false;
  String? _error;

  // form fields
  String _examName = '';
  String? _selectedDegree;
  String? _selectedDept;
  String? _selectedYear;
  String? _selectedSem;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _degrees = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _departments = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _years = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _sems = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _subjects = [];

  // subjectId -> date
  final Map<String, DateTime?> _selectedSubjects = {};

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    try {
      final degSnap = await _db.collection('degree-level').get();
      final doc = await _db.collection('exam-sets').doc(widget.docId).get();
      if (!mounted) return;

      setState(() {
        _degrees = degSnap.docs;
      });

      if (!doc.exists) {
        setState(() {
          _error = 'Exam set not found';
          _loading = false;
        });
        return;
      }

      final data = doc.data() ?? {};
      _examName = (data['examName'] ?? '').toString();
      _selectedDegree = (data['degreeId'] as String?)?.toString();
      _selectedDept = (data['departmentId'] as String?)?.toString();
      _selectedYear = (data['yearId'] as String?)?.toString();
      _selectedSem = (data['semesterId'] as String?)?.toString();

      // load dependent collections in order
      if (_selectedDegree != null) {
        await _loadDepartments();
        if (_selectedDept != null) {
          await _loadYears();
          if (_selectedYear != null) {
            await _loadSems();
            if (_selectedSem != null) {
              await _loadSubjects();
            }
          }
        }
      }

      // map saved subjects into _selectedSubjects
      final saved = (data['subjects'] as List<dynamic>?) ?? [];
      for (var s in saved) {
        try {
          final id = s['subjectId']?.toString();
          final ts = s['date'] as Timestamp?;
          if (id != null && ts != null) {
            _selectedSubjects[id] = ts.toDate();
          }
        } catch (_) {}
      }

      // if subject docs loaded, ensure map has entries for them (without overwriting saved date)
      if (_subjects.isNotEmpty) {
        for (var sd in _subjects) {
          _selectedSubjects.putIfAbsent(sd.id, () => _selectedSubjects[sd.id]);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Load failed: $e');
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  QueryDocumentSnapshot<Map<String, dynamic>>? _findSubjectDoc(String id) {
    for (var s in _subjects) {
      if (s.id == id) return s;
    }
    return null;
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
    });
  }

  Future<void> _loadYears() async {
    if (_selectedDegree == null || _selectedDept == null) return;
    final snap = await _db.collection('degree-level').doc(_selectedDegree).collection('department').doc(_selectedDept).collection('year').orderBy('value').get();
    if (!mounted) return;
    setState(() {
      _years = snap.docs;
      _sems = [];
      _subjects = [];
    });
  }

  Future<void> _loadSems() async {
    if (_selectedDegree == null || _selectedDept == null || _selectedYear == null) return;
    final snap = await _db.collection('degree-level').doc(_selectedDegree).collection('department').doc(_selectedDept).collection('year').doc(_selectedYear).collection('semester').orderBy('value').get();
    if (!mounted) return;
    setState(() {
      _sems = snap.docs;
      _subjects = [];
    });
  }

  Future<void> _loadSubjects() async {
    if (_selectedDegree == null || _selectedDept == null || _selectedYear == null || _selectedSem == null) return;
    final snap = await _db.collection('degree-level').doc(_selectedDegree).collection('department').doc(_selectedDept).collection('year').doc(_selectedYear).collection('semester').doc(_selectedSem).collection('subjects').get();
    if (!mounted) return;
    setState(() {
      _subjects = snap.docs;
      // ensure selected map contains these ids (retain any previously loaded dates)
      for (var s in _subjects) {
        _selectedSubjects.putIfAbsent(s.id, () => _selectedSubjects[s.id]);
      }
    });
  }

  Future<void> _pickDateForSubject(String subjectId) async {
    final initial = _selectedSubjects[subjectId] ?? DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: initial, firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (picked == null || !mounted) return;
    setState(() => _selectedSubjects[subjectId] = picked);
  }

  Future<void> _saveUpdate() async {
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

      final docRef = _db.collection('exam-sets').doc(widget.docId);
      await docRef.update({
        'examName': _examName.trim(),
        'degreeId': _selectedDegree,
        'departmentId': _selectedDept,
        if (_selectedYear != null) 'yearId': _selectedYear,
        if (_selectedSem != null) 'semesterId': _selectedSem,
        'subjects': subjectsPayload,
        'updatedBy': uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Update failed: $e');
    } finally {
      if (!mounted) return;
      setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete exam set'),
        content: Text('Delete "$_examName"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _db.collection('exam-sets').doc(widget.docId).delete();
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
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
      items: items.map((d) => DropdownMenuItem<T>(value: d.id as T, child: Text(labelFn(d)))).toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Exam Set')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView(
          children: [
            TextFormField(
              initialValue: _examName,
              decoration: const InputDecoration(labelText: 'Exam name'),
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
            const Text('Subjects (assign date to include)'),
            const SizedBox(height: 8),

            if (_subjects.isEmpty && _selectedSubjects.isEmpty)
              const Text('No subjects loaded for the saved semester. You can still edit subject IDs and dates below.')
            else
              // show subject docs if available, otherwise fallback to keys in map
              ...((_subjects.isNotEmpty)
                  ? _subjects.map((s) {
                      final id = s.id;
                      final display = (s.data()?['displayName'] ?? id).toString();
                      final selDate = _selectedSubjects[id];
                      return Card(
                        child: ListTile(
                          title: Text(display),
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
                    }).toList()
                  : _selectedSubjects.keys.map((id) {
                      final selDate = _selectedSubjects[id];
                      return Card(
                        child: ListTile(
                          title: Text(id),
                          subtitle: selDate == null ? const Text('No date assigned') : Text('${selDate.toLocal()}'.split(' ')[0]),
                          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(
                                icon: const Icon(Icons.calendar_today),
                                onPressed: () async {
                                  final initial = _selectedSubjects[id] ?? DateTime.now();
                                  final picked = await showDatePicker(context: context, initialDate: initial, firstDate: DateTime(2000), lastDate: DateTime(2100));
                                  if (picked != null && mounted) setState(() => _selectedSubjects[id] = picked);
                                }),
                            Checkbox(
                              value: selDate != null,
                              onChanged: (checked) {
                                if (checked == true) {
                                  showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100)).then((picked) {
                                    if (picked != null && mounted) setState(() => _selectedSubjects[id] = picked);
                                  });
                                } else {
                                  if (!mounted) return;
                                  setState(() => _selectedSubjects[id] = null);
                                }
                              },
                            ),
                          ]),
                        ),
                      );
                    }).toList()),

            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _saveUpdate,
                    icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
                    label: Text(_saving ? 'Saving...' : 'Update Exam Set'),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _delete,
                  tooltip: 'Delete exam set',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
