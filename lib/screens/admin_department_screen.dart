import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_year_screen.dart';

class AdminDepartmentList extends StatefulWidget {
  final String degreeId;
  const AdminDepartmentList({Key? key, required this.degreeId}) : super(key: key);

  @override
  State<AdminDepartmentList> createState() => _AdminDepartmentListState();
}

class _AdminDepartmentListState extends State<AdminDepartmentList> {
  final _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final stream = _db.collection('degree-level').doc(widget.degreeId).collection('department').snapshots();
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.degreeId} Departments', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDepartmentDialog,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No departments found'));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final d = docs[i];
              final id = d.id;
              final display = (d.data()['displayName'] ?? id).toString();
              return AdminDepartmentCard(
                departmentId: id,
                displayName: display,
                onEdit: () => _showEditDepartmentDialog(d),
                onDelete: () => _deleteDepartment(d),
                onManage: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => AdminYearList(degreeId: widget.degreeId, departmentId: id)
                )),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showCreateDepartmentDialog() async {
    final nameCtrl = TextEditingController();
    final yearsCtrl = TextEditingController(text: '1');
    final semestersCtrl = TextEditingController(text: '2');
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Department'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Department Name'),
                validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: yearsCtrl,
                decoration: const InputDecoration(labelText: 'Number of Years'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return (n == null || n <= 0) ? 'Enter positive number' : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: semestersCtrl,
                decoration: const InputDecoration(labelText: 'Semesters per Year'),
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
                  'years': int.parse(yearsCtrl.text.trim()),
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
      await _createDepartmentWithStructure(result);
    }
  }

  Future<void> _createDepartmentWithStructure(Map<String, dynamic> config) async {
    final name = config['name'] as String;
    final years = config['years'] as int;
    final semesters = config['semesters'] as int;
    final deptId = name.replaceAll(' ', '_').toLowerCase();

    try {
      final deptRef = _db.collection('degree-level').doc(widget.degreeId).collection('department').doc(deptId);
      await deptRef.set({
        'displayName': name,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create year and semester structure
      for (int y = 1; y <= years; y++) {
        final yearRef = deptRef.collection('year').doc(y.toString());
        await yearRef.set({
          'displayName': 'Year $y',
          'value': y,
          'createdAt': FieldValue.serverTimestamp(),
        });

        for (int s = 1; s <= semesters; s++) {
          final semRef = yearRef.collection('semester').doc(s.toString());
          await semRef.set({
            'displayName': 'Semester $s',
            'value': s,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Department created successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _showEditDepartmentDialog(DocumentSnapshot<Map<String, dynamic>> doc) async {
    final nameCtrl = TextEditingController(text: doc.data()?['displayName'] ?? doc.id);
    
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Department'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Department Name'),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Department updated')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
      }
    }
  }

  Future<void> _deleteDepartment(DocumentSnapshot<Map<String, dynamic>> doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Department'),
        content: Text('Are you sure you want to delete "${doc.data()?['displayName'] ?? doc.id}"? This will delete all years, semesters, and subjects within this department.'),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Department deleted')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }
}

class AdminDepartmentCard extends StatelessWidget {
  final String departmentId;
  final String displayName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onManage;

  const AdminDepartmentCard({
    Key? key,
    required this.departmentId,
    required this.displayName,
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
                      Text('ID: $departmentId', style: TextStyle(color: Colors.grey[600])),
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
                icon: const Icon(Icons.school),
                label: const Text('Manage Years'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
