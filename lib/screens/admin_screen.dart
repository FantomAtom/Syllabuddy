// lib/screens/admin_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// AdminConsole checks staff_emails/{uid}.status and only shows editing UI
/// if status == 'verified'. Otherwise shows a friendly locked screen.

class AdminConsole extends StatefulWidget {
  const AdminConsole({Key? key}) : super(key: key);

  @override
  State<AdminConsole> createState() => _AdminConsoleState();
}

class _AdminConsoleState extends State<AdminConsole> {
  bool _loading = true;
  bool _verified = false;
  String? _email;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkVerification();
  }

  Future<void> _checkVerification() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
        _verified = false;
        _error = 'Not signed in';
      });
      return;
    }

    try {
      final uid = user.uid;
      _email = user.email;
      final doc = await FirebaseFirestore.instance.collection('staff_emails').doc(uid).get();
      if (!doc.exists) {
        setState(() {
          _verified = false;
          _loading = false;
        });
        return;
      }
      final data = doc.data();
      final status = data?['status']?.toString() ?? 'unverified';
      setState(() {
        _verified = status.toLowerCase() == 'verified';
        _loading = false;
      });
    } catch (e) {
      debugPrint('Failed to check staff verification: $e');
      setState(() {
        _error = 'Failed to check verification: $e';
        _verified = false;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Console')),
        body: Center(child: Text('Error: $_error')),
      );
    }

    if (!_verified) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Console')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.lock_outline, size: 64, color: Theme.of(context).primaryColor),
              const SizedBox(height: 16),
              Text('Admin Access Pending', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
              const SizedBox(height: 12),
              Text(
                'Your account (${_email ?? "unknown"}) is registered as staff but not verified yet. An administrator must verify your email to enable admin features.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: _checkVerification, child: const Text('Refresh Status')),
              ),
              const SizedBox(height: 8),
              const Text('If you believe this is an error, contact the system administrator.'),
            ]),
          ),
        ),
      );
    }

    // Verified - show the full admin UI (AdminHome + navigation)
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Console')),
      body: const AdminHome(),
    );
  }
}

/// ---------------------------- Admin Home (degree-level) ----------------------------
class AdminHome extends StatefulWidget {
  const AdminHome({Key? key}) : super(key: key);

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  final _db = FirebaseFirestore.instance;
  final TextEditingController _degreeController = TextEditingController();

  Future<void> _addDegree() async {
    final ctrl = _degreeController;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Degree Level'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Degree id (e.g. UG or PG)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Create'),
          )
        ],
      ),
    );
    if (ok != true) return;
    final id = ctrl.text.trim();
    try {
      await _db.collection('degree-level').doc(id).set({
        'displayName': id,
        'createdAt': FieldValue.serverTimestamp(),
      });
      ctrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Degree created')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _deleteDegree(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Delete $id?'),
        content: const Text('This will delete the degree-level document (subcollections must be removed separately). Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _db.collection('degree-level').doc(id).delete();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream = _db.collection('degree-level').snapshots();
    return Column(
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Expanded(child: Text('Manage degree levels (e.g. UG, PG)', style: TextStyle(fontWeight: FontWeight.bold))),
              ElevatedButton.icon(onPressed: _addDegree, icon: const Icon(Icons.add), label: const Text('Add')),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: stream,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
              final docs = snap.data!.docs;
              if (docs.isEmpty) return const Center(child: Text('No degree levels found'));
              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final d = docs[i];
                  final id = d.id;
                  final display = (d.data()['displayName'] ?? id).toString();
                  return Card(
                    child: ListTile(
                      title: Text(display),
                      subtitle: Text('id: $id'),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                          icon: const Icon(Icons.open_in_new),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DepartmentList(degreeId: id))),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_forever, color: Colors.red),
                          onPressed: () => _deleteDegree(id),
                        ),
                      ]),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// ---------------------------- Department List ----------------------------
class DepartmentList extends StatefulWidget {
  final String degreeId;
  const DepartmentList({Key? key, required this.degreeId}) : super(key: key);

  @override
  State<DepartmentList> createState() => _DepartmentListState();
}

class _DepartmentListState extends State<DepartmentList> {
  final _db = FirebaseFirestore.instance;

  Future<void> _addDepartmentDialog() async {
    final nameCtrl = TextEditingController();
    final yearsCtrl = TextEditingController(text: '1'); // number of initial years
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Department'),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Display name (e.g. MBA)'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
            const SizedBox(height: 8),
            TextFormField(controller: yearsCtrl, decoration: const InputDecoration(labelText: 'Number of years (e.g. 1,2,3)'), keyboardType: TextInputType.number, validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              final n = int.tryParse(v.trim());
              return (n == null || n <= 0) ? 'Enter a positive integer' : null;
            }),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () {
            if (formKey.currentState?.validate() != true) return;
            Navigator.pop(ctx, true);
          }, child: const Text('Create')),
        ],
      ),
    );

    if (ok != true) return;
    final displayName = nameCtrl.text.trim();
    final yearsCount = int.tryParse(yearsCtrl.text.trim()) ?? 1;
    final deptId = displayName.replaceAll(' ', '_'); // simple id
    final deptRef = _db.collection('degree-level').doc(widget.degreeId).collection('department').doc(deptId);

    try {
      await deptRef.set({'displayName': displayName, 'createdAt': FieldValue.serverTimestamp()});
      // create year documents if specified
      for (var y = 1; y <= yearsCount; y++) {
        final yearId = y.toString();
        final yearRef = deptRef.collection('year').doc(yearId);
        await yearRef.set({'displayName': '$y', 'value': y, 'createdAt': FieldValue.serverTimestamp()});
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Department created')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Create failed: $e')));
    } finally {
      nameCtrl.dispose();
      yearsCtrl.dispose();
    }
  }

  Future<void> _deleteDepartment(String deptId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete department'),
        content: const Text('This will delete the department doc (subcollections not deleted automatically). Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _db.collection('degree-level').doc(widget.degreeId).collection('department').doc(deptId).delete();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream = _db.collection('degree-level').doc(widget.degreeId).collection('department').snapshots();
    return Scaffold(
      appBar: AppBar(title: Text('${widget.degreeId} departments')),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Departments', style: TextStyle(fontWeight: FontWeight.bold)),
          ElevatedButton.icon(onPressed: _addDepartmentDialog, icon: const Icon(Icons.add), label: const Text('Add dept')),
        ])),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: stream,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
              final docs = snap.data!.docs;
              if (docs.isEmpty) return const Center(child: Text('No departments'));
              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final d = docs[i];
                  final id = d.id;
                  final display = (d.data()['displayName'] ?? id).toString();
                  return Card(
                    child: ListTile(
                      title: Text(display),
                      subtitle: Text('id: $id'),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(icon: const Icon(Icons.open_in_new), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => YearList(degreeId: widget.degreeId, departmentId: id)))),
                        IconButton(icon: const Icon(Icons.delete_forever, color: Colors.red), onPressed: () => _deleteDepartment(id)),
                      ]),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}

/// ---------------------------- Year List ----------------------------
class YearList extends StatefulWidget {
  final String degreeId;
  final String departmentId;
  const YearList({Key? key, required this.degreeId, required this.departmentId}) : super(key: key);

  @override
  State<YearList> createState() => _YearListState();
}

class _YearListState extends State<YearList> {
  final _db = FirebaseFirestore.instance;
  final TextEditingController _yearCtrl = TextEditingController();

  Future<void> _addYear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Year'),
        content: TextField(controller: _yearCtrl, decoration: const InputDecoration(labelText: 'Year id (e.g. 1)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () {
            if (_yearCtrl.text.trim().isEmpty) return;
            Navigator.pop(ctx, true);
          }, child: const Text('Create')),
        ],
      ),
    );
    if (ok != true) return;
    final id = _yearCtrl.text.trim();
    try {
      final ref = _db.collection('degree-level').doc(widget.degreeId).collection('department').doc(widget.departmentId).collection('year').doc(id);
      await ref.set({'displayName': id, 'value': id, 'createdAt': FieldValue.serverTimestamp()});
      _yearCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Year created')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _deleteYear(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete year'),
        content: const Text('This will delete the year doc (subcollections not deleted automatically). Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _db.collection('degree-level').doc(widget.degreeId).collection('department').doc(widget.departmentId).collection('year').doc(id).delete();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream = _db.collection('degree-level').doc(widget.degreeId).collection('department').doc(widget.departmentId).collection('year').snapshots();
    return Scaffold(
      appBar: AppBar(title: Text('${widget.departmentId} - years')),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Years', style: TextStyle(fontWeight: FontWeight.bold)),
          ElevatedButton.icon(onPressed: _addYear, icon: const Icon(Icons.add), label: const Text('Add year')),
        ])),
        Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: stream, builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No years'));
          return ListView.separated(padding: const EdgeInsets.all(12), itemCount: docs.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (context, i) {
            final d = docs[i];
            final id = d.id;
            final display = (d.data()['displayName'] ?? id).toString();
            return Card(child: ListTile(
              title: Text(display),
              subtitle: Text('id: $id'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(icon: const Icon(Icons.open_in_new), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SemesterList(degreeId: widget.degreeId, departmentId: widget.departmentId, yearId: id)))),
                IconButton(icon: const Icon(Icons.delete_forever, color: Colors.red), onPressed: () => _deleteYear(id)),
              ]),
            ));
          });
        })),
      ]),
    );
  }
}

/// ---------------------------- Semester List ----------------------------
class SemesterList extends StatefulWidget {
  final String degreeId;
  final String departmentId;
  final String yearId;
  const SemesterList({Key? key, required this.degreeId, required this.departmentId, required this.yearId}) : super(key: key);

  @override
  State<SemesterList> createState() => _SemesterListState();
}

class _SemesterListState extends State<SemesterList> {
  final _db = FirebaseFirestore.instance;
  final _semCtrl = TextEditingController();

  Future<void> _addSemester() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Semester'),
        content: TextField(controller: _semCtrl, decoration: const InputDecoration(labelText: 'Semester id (e.g. 1)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () {
            if (_semCtrl.text.trim().isEmpty) return;
            Navigator.pop(ctx, true);
          }, child: const Text('Create')),
        ],
      ),
    );
    if (ok != true) return;
    final id = _semCtrl.text.trim();
    try {
      final ref = _db.collection('degree-level').doc(widget.degreeId).collection('department').doc(widget.departmentId).collection('year').doc(widget.yearId).collection('semester').doc(id);
      await ref.set({'displayName': 'Semester $id', 'value': id, 'createdAt': FieldValue.serverTimestamp()});
      _semCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semester created')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _deleteSemester(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete semester'),
        content: const Text('This will delete the semester doc (subcollections not deleted automatically). Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _db.collection('degree-level').doc(widget.degreeId).collection('department').doc(widget.departmentId).collection('year').doc(widget.yearId).collection('semester').doc(id).delete();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream = _db.collection('degree-level').doc(widget.degreeId).collection('department').doc(widget.departmentId).collection('year').doc(widget.yearId).collection('semester').snapshots();
    return Scaffold(
      appBar: AppBar(title: Text('${widget.departmentId} • Year ${widget.yearId} • Semesters')),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Semesters', style: TextStyle(fontWeight: FontWeight.bold)),
          ElevatedButton.icon(onPressed: _addSemester, icon: const Icon(Icons.add), label: const Text('Add sem')),
        ])),
        Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: stream, builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No semesters'));
          return ListView.separated(padding: const EdgeInsets.all(12), itemCount: docs.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (context, i) {
            final d = docs[i];
            final id = d.id;
            final display = (d.data()['displayName'] ?? id).toString();
            return Card(child: ListTile(
              title: Text(display),
              subtitle: Text('id: $id'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(icon: const Icon(Icons.open_in_new), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SubjectList(
                  degreeId: widget.degreeId,
                  departmentId: widget.departmentId,
                  yearId: widget.yearId,
                  semesterId: id,
                )))),
                IconButton(icon: const Icon(Icons.delete_forever, color: Colors.red), onPressed: () => _deleteSemester(id)),
              ]),
            ));
          });
        })),
      ]),
    );
  }
}

/// ---------------------------- Subject List ----------------------------
class SubjectList extends StatefulWidget {
  final String degreeId;
  final String departmentId;
  final String yearId;
  final String semesterId;
  const SubjectList({Key? key, required this.degreeId, required this.departmentId, required this.yearId, required this.semesterId}) : super(key: key);

  @override
  State<SubjectList> createState() => _SubjectListState();
}

class _SubjectListState extends State<SubjectList> {
  final _db = FirebaseFirestore.instance;

  Future<void> _addOrEditSubject({DocumentSnapshot<Map<String, dynamic>>? doc}) async {
    final display = TextEditingController(text: doc?.data()?['displayName']?.toString() ?? '');
    final desc = TextEditingController(text: doc?.data()?['description']?.toString() ?? '');
    final credits = TextEditingController(text: doc?.data()?['credits']?.toString() ?? '');
    final formKey = GlobalKey<FormState>();
    final isNew = doc == null;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isNew ? 'Add Subject' : 'Edit Subject'),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: display, decoration: const InputDecoration(labelText: 'Display name'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
            const SizedBox(height: 8),
            TextFormField(controller: desc, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
            const SizedBox(height: 8),
            TextFormField(controller: credits, decoration: const InputDecoration(labelText: 'Credits'), keyboardType: TextInputType.number),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () {
            if (formKey.currentState?.validate() != true) return;
            Navigator.pop(ctx, true);
          }, child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final base = _db.collection('degree-level').doc(widget.degreeId)
        .collection('department').doc(widget.departmentId)
        .collection('year').doc(widget.yearId)
        .collection('semester').doc(widget.semesterId)
        .collection('subjects');
      if (isNew) {
        final ref = base.doc(); // auto id
        await ref.set({
          'displayName': display.text.trim(),
          'description': desc.text.trim(),
          'credits': int.tryParse(credits.text.trim()) ?? 0,
          'degreeId': widget.degreeId,
          'departmentId': widget.departmentId,
          'yearId': widget.yearId,
          'semesterId': widget.semesterId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await doc!.reference.update({
          'displayName': display.text.trim(),
          'description': desc.text.trim(),
          'credits': int.tryParse(credits.text.trim()) ?? doc.data()?['credits'] ?? 0,
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      display.dispose();
      desc.dispose();
      credits.dispose();
    }
  }

  Future<void> _deleteSubject(DocumentSnapshot<Map<String, dynamic>> doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete subject'),
        content: const Text('This will delete subject doc (units not deleted automatically). Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await doc.reference.delete();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream = _db.collection('degree-level').doc(widget.degreeId)
      .collection('department').doc(widget.departmentId)
      .collection('year').doc(widget.yearId)
      .collection('semester').doc(widget.semesterId)
      .collection('subjects').snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Subjects')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditSubject(),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No subjects'));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final d = docs[i];
              final name = (d.data()['displayName'] ?? d.data()['title'] ?? d.id).toString();
              return Card(
                child: ListTile(
                  title: Text(name),
                  subtitle: Text(d.reference.path, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(icon: const Icon(Icons.menu_book), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UnitList(subjectRef: d.reference)))),
                    IconButton(icon: const Icon(Icons.edit), onPressed: () => _addOrEditSubject(doc: d)),
                    IconButton(icon: const Icon(Icons.delete_forever, color: Colors.red), onPressed: () => _deleteSubject(d)),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// ---------------------------- Unit List ----------------------------
class UnitList extends StatefulWidget {
  final DocumentReference<Map<String, dynamic>> subjectRef;
  const UnitList({Key? key, required this.subjectRef}) : super(key: key);

  @override
  State<UnitList> createState() => _UnitListState();
}

class _UnitListState extends State<UnitList> {
  final _db = FirebaseFirestore.instance;

  Future<void> _addOrEditUnit({DocumentSnapshot<Map<String, dynamic>>? doc}) async {
    final d = doc?.data() ?? <String, dynamic>{};
    final display = TextEditingController(text: d['displayName']?.toString() ?? '');
    final unitIdCtrl = TextEditingController(text: d['unit']?.toString() ?? '');
    final hoursCtrl = TextEditingController(text: d['hours']?.toString() ?? '');
    final contentCtrl = TextEditingController(text: d['content']?.toString() ?? '');
    final formKey = GlobalKey<FormState>();
    final isNew = doc == null;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isNew ? 'Add Unit' : 'Edit Unit'),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: display, decoration: const InputDecoration(labelText: 'Display name (UNIT I)'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
            const SizedBox(height: 8),
            TextFormField(controller: unitIdCtrl, decoration: const InputDecoration(labelText: 'Unit id (e.g. UNIT I)'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
            const SizedBox(height: 8),
            TextFormField(controller: hoursCtrl, decoration: const InputDecoration(labelText: 'Hours'), keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            TextFormField(controller: contentCtrl, decoration: const InputDecoration(labelText: 'Content'), maxLines: 3),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () {
            if (formKey.currentState?.validate() != true) return;
            Navigator.pop(ctx, true);
          }, child: const Text('Save')),
        ],
      ),
    );

    if (ok != true) {
      display.dispose();
      unitIdCtrl.dispose();
      hoursCtrl.dispose();
      contentCtrl.dispose();
      return;
    }

    try {
      final unitsCol = widget.subjectRef.collection('units');
      if (isNew) {
        final docRef = unitsCol.doc(); // auto id
        await docRef.set({
          'displayName': display.text.trim(),
          'unit': unitIdCtrl.text.trim(),
          'hours': hoursCtrl.text.trim(),
          'content': contentCtrl.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await doc!.reference.update({
          'displayName': display.text.trim(),
          'unit': unitIdCtrl.text.trim(),
          'hours': hoursCtrl.text.trim(),
          'content': contentCtrl.text.trim(),
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      display.dispose();
      unitIdCtrl.dispose();
      hoursCtrl.dispose();
      contentCtrl.dispose();
    }
  }

  Future<void> _deleteUnit(DocumentSnapshot<Map<String, dynamic>> doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete unit'),
        content: const Text('This will delete the unit doc. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await doc.reference.delete();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream = widget.subjectRef.collection('units').snapshots();
    return Scaffold(
      appBar: AppBar(title: const Text('Units')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditUnit(),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No units'));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final d = docs[i];
              final map = d.data();
              final name = (map['displayName'] ?? d.id).toString();
              return Card(child: ListTile(
                title: Text(name),
                subtitle: Text(map['unit']?.toString() ?? ''),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.edit), onPressed: () => _addOrEditUnit(doc: d)),
                  IconButton(icon: const Icon(Icons.delete_forever, color: Colors.red), onPressed: () => _deleteUnit(d)),
                ]),
              ));
            },
          );
        },
      ),
    );
  }
}
