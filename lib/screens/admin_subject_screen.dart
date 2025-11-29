import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_unit_screen.dart';

class AdminSubjectList extends StatefulWidget {
  final String degreeId;
  final String departmentId;
  final String yearId;
  final String semesterId;
  const AdminSubjectList({
    Key? key,
    required this.degreeId,
    required this.departmentId,
    required this.yearId,
    required this.semesterId,
  }) : super(key: key);

  @override
  State<AdminSubjectList> createState() => _AdminSubjectListState();
}

class _AdminSubjectListState extends State<AdminSubjectList> {
  final _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final stream = _db.collection('degree-level')
        .doc(widget.degreeId)
        .collection('department')
        .doc(widget.departmentId)
        .collection('year')
        .doc(widget.yearId)
        .collection('semester')
        .doc(widget.semesterId)
        .collection('subjects')
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text('Semester ${widget.semesterId} Subjects', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateSubjectDialog,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No subjects found'));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final d = docs[i];
              final id = d.id;
              final data = d.data();
              final display = (data['displayName'] ?? id).toString();
              final code = data['code']?.toString() ?? '';
              final hours = data['hours']?.toString() ?? '';
              return AdminSubjectCard(
                subjectId: id,
                displayName: display,
                code: code,
                hours: hours,
                onEdit: () => _showEditSubjectDialog(d),
                onDelete: () => _deleteSubject(d),
                onManage: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => AdminUnitList(
                    degreeId: widget.degreeId,
                    departmentId: widget.departmentId,
                    yearId: widget.yearId,
                    semesterId: widget.semesterId,
                    subjectId: id,
                  )
                )),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showCreateSubjectDialog() async {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final subjectNumCtrl = TextEditingController();
    final unitsCtrl = TextEditingController(text: '5');
    final hoursCtrl = TextEditingController(text: '40');
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Subject'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Subject Name'),
                validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: subjectNumCtrl,
                decoration: const InputDecoration(labelText: 'Subject Number (e.g. 11 for IT111)'),
                keyboardType: TextInputType.number,
                validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: codeCtrl,
                decoration: const InputDecoration(labelText: 'Subject Code (optional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: hoursCtrl,
                decoration: const InputDecoration(labelText: 'Total Hours'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: unitsCtrl,
                decoration: const InputDecoration(labelText: 'Number of Units (optional)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.pop(ctx, {
                  'name': nameCtrl.text.trim(),
                  'subjectNum': subjectNumCtrl.text.trim(),
                  'code': codeCtrl.text.trim(),
                  'hours': hoursCtrl.text.trim(),
                  'units': int.tryParse(unitsCtrl.text.trim()) ?? 0,
                });
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _createSubjectWithUnits(result);
    }
  }

  Future<void> _createSubjectWithUnits(Map<String, dynamic> config) async {
    final name = config['name'] as String;
    final subjectNum = config['subjectNum'] as String;
    final code = config['code'] as String;
    final hours = config['hours'] as String;
    final units = config['units'] as int;
    
    // Generate subject ID like "IT111" (department + year + semester + subject number)
    final deptCode = widget.departmentId.toUpperCase();
    final subjectId = '$deptCode${widget.yearId}${widget.semesterId}$subjectNum';

    try {
      final subjectRef = _db.collection('degree-level')
          .doc(widget.degreeId)
          .collection('department')
          .doc(widget.departmentId)
          .collection('year')
          .doc(widget.yearId)
          .collection('semester')
          .doc(widget.semesterId)
          .collection('subjects')
          .doc(subjectId);

      await subjectRef.set({
        'displayName': name,
        'code': code.isNotEmpty ? code : subjectId,
        'subjectNumber': subjectNum,
        'hours': hours,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create units if specified
      if (units > 0) {
        for (int u = 1; u <= units; u++) {
          final unitRef = subjectRef.collection('units').doc(u.toString());
          await unitRef.set({
            'displayName': 'Unit $u',
            'value': u,
            'hours': '10',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subject created successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _showEditSubjectDialog(DocumentSnapshot<Map<String, dynamic>> doc) async {
    final data = doc.data() ?? {};
    final nameCtrl = TextEditingController(text: data['displayName'] ?? doc.id);
    final codeCtrl = TextEditingController(text: data['code'] ?? '');
    final hoursCtrl = TextEditingController(text: data['hours']?.toString() ?? '40');
    
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Subject'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Subject Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeCtrl,
              decoration: const InputDecoration(labelText: 'Subject Code'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: hoursCtrl,
              decoration: const InputDecoration(labelText: 'Total Hours'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (ok == true) {
      try {
        await doc.reference.update({
          'displayName': nameCtrl.text.trim(),
          'code': codeCtrl.text.trim(),
          'hours': hoursCtrl.text.trim(),
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subject updated')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
      }
    }
  }

  Future<void> _deleteSubject(DocumentSnapshot<Map<String, dynamic>> doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text('Are you sure you want to delete "${doc.data()?['displayName'] ?? doc.id}"? This will delete all units within this subject.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await doc.reference.delete();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subject deleted')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }
}

class AdminSubjectCard extends StatelessWidget {
  final String subjectId;
  final String displayName;
  final String code;
  final String hours;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onManage;

  const AdminSubjectCard({
    Key? key,
    required this.subjectId,
    required this.displayName,
    required this.code,
    required this.hours,
    required this.onEdit,
    required this.onDelete,
    required this.onManage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      if (code.isNotEmpty) Text('Code: $code', style: TextStyle(color: Colors.grey[600])),
                      if (hours.isNotEmpty) Text('Hours: $hours', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onManage,
                icon: const Icon(Icons.menu_book),
                label: const Text('Manage Units'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}











