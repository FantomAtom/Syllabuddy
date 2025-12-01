// lib/screens/admin_semester_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_subject_screen.dart';

// shared styles & widgets
import '../styles/app_styles.dart';
import '../theme.dart';
import '../widgets/app_primary_button.dart';

class AdminSemesterList extends StatefulWidget {
  final String degreeId;
  final String departmentId;
  final String yearId;
  const AdminSemesterList({Key? key, required this.degreeId, required this.departmentId, required this.yearId}) : super(key: key);

  @override
  State<AdminSemesterList> createState() => _AdminSemesterListState();
}

class _AdminSemesterListState extends State<AdminSemesterList> {
  final _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final stream = _db
        .collection('degree-level')
        .doc(widget.degreeId)
        .collection('department')
        .doc(widget.departmentId)
        .collection('year')
        .doc(widget.yearId)
        .collection('semester')
        .orderBy('value')
        .snapshots();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Year ${widget.yearId} Semesters', style: TextStyle(color: theme.colorScheme.onPrimary)),
        backgroundColor: theme.primaryColor,
        iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateSemesterDialog,
        backgroundColor: theme.primaryColor,
        child: Icon(Icons.add, color: theme.colorScheme.onPrimary),
        tooltip: 'Create semester',
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return Center(child: Text('No semesters found', style: TextStyle(color: theme.textTheme.bodySmall?.color)));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final d = docs[i];
              final id = d.id;
              final display = (d.data()['displayName'] ?? 'Semester $id').toString();
              final value = d.data()['value'] ?? int.tryParse(id) ?? 0;
              return AdminSemesterCard(
                semesterId: id,
                displayName: display,
                value: value,
                onEdit: () => _showEditSemesterDialog(d),
                onDelete: () => _deleteSemester(d),
                onManage: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminSubjectList(
                      degreeId: widget.degreeId,
                      departmentId: widget.departmentId,
                      yearId: widget.yearId,
                      semesterId: id,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showCreateSemesterDialog() async {
    final nameCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Semester'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Display Name (e.g. Semester 1)'),
                validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: valueCtrl,
                decoration: const InputDecoration(labelText: 'Semester Number'),
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
                });
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _createSemester(result);
    }
  }

  Future<void> _createSemester(Map<String, dynamic> config) async {
    final name = config['name'] as String;
    final value = config['value'] as int;

    try {
      final semRef = _db
          .collection('degree-level')
          .doc(widget.degreeId)
          .collection('department')
          .doc(widget.departmentId)
          .collection('year')
          .doc(widget.yearId)
          .collection('semester')
          .doc(value.toString());

      await semRef.set({
        'displayName': name,
        'value': value,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semester created successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _showEditSemesterDialog(DocumentSnapshot<Map<String, dynamic>> doc) async {
    final nameCtrl = TextEditingController(text: doc.data()?['displayName'] ?? 'Semester ${doc.id}');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Semester'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semester updated')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
      }
    }
  }

  Future<void> _deleteSemester(DocumentSnapshot<Map<String, dynamic>> doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Semester'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text('Are you sure you want to delete "${doc.data()?['displayName'] ?? doc.id}"? This will delete all subjects within this semester.'),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semester deleted')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }
}

/// Themed semester card
class AdminSemesterCard extends StatelessWidget {
  final String semesterId;
  final String displayName;
  final int value;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onManage;

  const AdminSemesterCard({
    Key? key,
    required this.semesterId,
    required this.displayName,
    required this.value,
    required this.onEdit,
    required this.onDelete,
    required this.onManage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        boxShadow: [AppStyles.shadow(context)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // left badge
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppStyles.primaryGradient(context),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 3))],
                      ),
                      child: Center(child: Text('$value', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(displayName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: theme.colorScheme.primaryText)),
                          const SizedBox(height: 4),
                          Text('Semester $value', style: TextStyle(color: theme.textTheme.bodySmall?.color)),
                        ],
                      ),
                    ),
                    IconButton(onPressed: onEdit, icon: Icon(Icons.edit, color: theme.primaryColor)),
                    IconButton(onPressed: onDelete, icon: const Icon(Icons.delete, color: Colors.red)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: AppPrimaryButton(text: 'Manage Subjects', icon: Icons.book, onPressed: onManage)),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
