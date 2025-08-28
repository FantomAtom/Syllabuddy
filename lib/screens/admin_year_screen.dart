import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_semester_screen.dart';

class AdminYearList extends StatefulWidget {
  final String degreeId;
  final String departmentId;
  const AdminYearList({Key? key, required this.degreeId, required this.departmentId}) : super(key: key);

  @override
  State<AdminYearList> createState() => _AdminYearListState();
}

class _AdminYearListState extends State<AdminYearList> {
  final _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final stream = _db.collection('degree-level')
        .doc(widget.degreeId)
        .collection('department')
        .doc(widget.departmentId)
        .collection('year')
        .orderBy('value')
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: Text('${widget.departmentId} Years')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateYearDialog,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No years found'));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final d = docs[i];
              final id = d.id;
              final display = (d.data()['displayName'] ?? 'Year $id').toString();
              final value = d.data()['value'] ?? int.tryParse(id) ?? 0;
              return AdminYearCard(
                yearId: id,
                displayName: display,
                value: value,
                onEdit: () => _showEditYearDialog(d),
                onDelete: () => _deleteYear(d),
                onManage: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => AdminSemesterList(
                    degreeId: widget.degreeId,
                    departmentId: widget.departmentId,
                    yearId: id,
                  )
                )),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showCreateYearDialog() async {
    final nameCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    final semestersCtrl = TextEditingController(text: '2');
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Year'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Display Name (e.g. Year 1)'),
                validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: valueCtrl,
                decoration: const InputDecoration(labelText: 'Year Number'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return (n == null || n <= 0) ? 'Enter positive number' : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: semestersCtrl,
                decoration: const InputDecoration(labelText: 'Number of Semesters'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return (n == null || n <= 0) ? 'Enter positive number' : null;
                },
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
                  'value': int.parse(valueCtrl.text.trim()),
                  'semesters': int.parse(semestersCtrl.text.trim()),
                });
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _createYearWithSemesters(result);
    }
  }

  Future<void> _createYearWithSemesters(Map<String, dynamic> config) async {
    final name = config['name'] as String;
    final value = config['value'] as int;
    final semesters = config['semesters'] as int;

    try {
      final yearRef = _db.collection('degree-level')
          .doc(widget.degreeId)
          .collection('department')
          .doc(widget.departmentId)
          .collection('year')
          .doc(value.toString());

      await yearRef.set({
        'displayName': name,
        'value': value,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create semesters
      for (int s = 1; s <= semesters; s++) {
        final semRef = yearRef.collection('semester').doc(s.toString());
        await semRef.set({
          'displayName': 'Semester $s',
          'value': s,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Year created successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _showEditYearDialog(DocumentSnapshot<Map<String, dynamic>> doc) async {
    final nameCtrl = TextEditingController(text: doc.data()?['displayName'] ?? 'Year ${doc.id}');
    
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Year'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Display Name'),
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
        await doc.reference.update({'displayName': nameCtrl.text.trim()});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Year updated')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
      }
    }
  }

  Future<void> _deleteYear(DocumentSnapshot<Map<String, dynamic>> doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Year'),
        content: Text('Are you sure you want to delete "${doc.data()?['displayName'] ?? doc.id}"? This will delete all semesters and subjects within this year.'),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Year deleted')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }
}

class AdminYearCard extends StatelessWidget {
  final String yearId;
  final String displayName;
  final int value;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onManage;

  const AdminYearCard({
    Key? key,
    required this.yearId,
    required this.displayName,
    required this.value,
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
                      Text('Year $value', style: TextStyle(color: Colors.grey[600])),
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
                icon: const Icon(Icons.calendar_month),
                label: const Text('Manage Semesters'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


