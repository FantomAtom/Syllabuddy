// lib/screens/admin_department_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_year_screen.dart';

// app shared widgets / styles
import '../widgets/app_primary_button.dart';
import '../widgets/app_section_title.dart';
import '../styles/app_styles.dart';
import '../theme.dart';

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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.degreeId} Departments', style: TextStyle(color: theme.colorScheme.onPrimary)),
        backgroundColor: theme.primaryColor,
        iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return Center(child: Text('No departments found', style: TextStyle(color: theme.textTheme.bodySmall?.color)));

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
                onManage: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AdminYearList(degreeId: widget.degreeId, departmentId: id)),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDepartmentDialog,
        backgroundColor: theme.primaryColor,
        child: Icon(Icons.add, color: theme.colorScheme.onPrimary),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  /// Creates exactly years * semestersPerYear new semester docs starting after the current max.
  Future<void> _createDepartmentWithStructure(Map<String, dynamic> config) async {
    final name = config['name'] as String;
    final years = config['years'] as int;
    final semestersPerYear = config['semesters'] as int;
    final deptId = name.replaceAll(' ', '_').toLowerCase();

    try {
      final deptRef = _db.collection('degree-level').doc(widget.degreeId).collection('department').doc(deptId);

      // Department meta
      await deptRef.set({
        'displayName': name,
        'createdAt': FieldValue.serverTimestamp(),
        'defaultSemestersPerYear': semestersPerYear,
        'yearsCount': years,
      });

      // 1) Collect existing semester values across all years (one pass)
      final existingValues = <int>{};
      final yearsSnap = await deptRef.collection('year').get();
      for (final ydoc in yearsSnap.docs) {
        final semSnap = await ydoc.reference.collection('semester').get();
        for (final sdoc in semSnap.docs) {
          final v = sdoc.data()['value'];
          if (v is int) existingValues.add(v);
        }
      }

      final maxExisting = existingValues.isEmpty ? 0 : existingValues.reduce((a, b) => a > b ? a : b);
      final startOverall = maxExisting + 1;
      final totalToCreate = years * semestersPerYear;
      int created = 0;

      // 2) Build and create the exact desired overall numbers (start..start+totalToCreate-1)
      for (int idx = 0; idx < totalToCreate; idx++) {
        final overall = startOverall + idx;
        // map overall -> yearNumber and semesterInYear (deterministic)
        final yearNumber = (idx ~/ semestersPerYear) + 1; // 0.. -> 1..
        final semesterInYear = (idx % semestersPerYear) + 1;

        final yearRef = deptRef.collection('year').doc(yearNumber.toString());
        // Ensure year doc exists (set if not)
        await yearRef.set({
          'displayName': 'Year $yearNumber',
          'value': yearNumber,
          'semestersCount': semestersPerYear,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        final semRef = yearRef.collection('semester').doc(overall.toString());

        // Only create if not already present (idempotent)
        final exists = await semRef.get();
        if (exists.exists) {
          // ensure fields are up-to-date
          await semRef.set({
            'displayName': 'Semester $overall',
            'value': overall,
            'yearNumber': yearNumber,
            'semesterInYear': semesterInYear,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } else {
          await semRef.set({
            'displayName': 'Semester $overall',
            'value': overall,
            'yearNumber': yearNumber,
            'semesterInYear': semesterInYear,
            'createdAt': FieldValue.serverTimestamp(),
          });
          created++;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Department created — $created new semesters.')));
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
            'Are you sure you want to delete "${doc.data()?['displayName'] ?? doc.id}"? This will delete all years, semesters, and subjects within this department.'),
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

/// The department card — themed & consistent with Admin UI
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
          child: InkWell(
            splashFactory: InkRipple.splashFactory,
            onTap: onManage,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // left avatar/icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppStyles.primaryGradient(context),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 3))],
                        ),
                        child: Icon(Icons.apartment, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(displayName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: theme.colorScheme.primaryText)),
                            const SizedBox(height: 4),
                            Text('ID: $departmentId', style: TextStyle(color: theme.textTheme.bodySmall?.color)),
                          ],
                        ),
                      ),
                      // actions
                      IconButton(
                        onPressed: onEdit,
                        icon: Icon(Icons.edit, color: theme.primaryColor),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppPrimaryButton(
                          text: 'Manage Years',
                          icon: Icons.school,
                          onPressed: onManage,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
