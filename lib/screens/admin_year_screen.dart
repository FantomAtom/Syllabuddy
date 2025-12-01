// lib/screens/admin_year_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_semester_screen.dart';

// shared app styles & widgets
import '../styles/app_styles.dart';
import '../theme.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_section_title.dart';

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
    final deptDocRef = _db.collection('degree-level').doc(widget.degreeId).collection('department').doc(widget.departmentId);
    final yearsStream = deptDocRef.collection('year').orderBy('value').snapshots();
    final theme = Theme.of(context);

    // Use a StreamBuilder to fetch department displayName for the header
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: deptDocRef.snapshots(),
      builder: (context, deptSnap) {
        final deptData = deptSnap.data?.data();
        final deptDisplay = deptData != null && deptData['displayName'] != null
            ? '${deptData['displayName']} Years'
            : '${widget.departmentId} Years';

        return Scaffold(
          appBar: AppBar(
            title: Text(deptDisplay, style: TextStyle(color: theme.colorScheme.onPrimary)),
            backgroundColor: theme.primaryColor,
            iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
            elevation: 0,
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _showCreateYearDialog,
            backgroundColor: theme.primaryColor,
            child: Icon(Icons.add, color: theme.colorScheme.onPrimary),
            tooltip: 'Create year',
          ),
          body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: yearsStream,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) return Center(child: Text('No years found', style: TextStyle(color: theme.textTheme.bodySmall?.color)));

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
      },
    );
  }

  Future<void> _showCreateYearDialog() async {
    final nameCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    final semestersCtrl = TextEditingController(text: '2');
    final formKey = GlobalKey<FormState>();
    final theme = Theme.of(context);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Year'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  /// Create a year and its semesters. Semesters are numbered continuously across department.
  /// This computes the current max overall semester and then creates exactly `semesters` new ones.
  Future<void> _createYearWithSemesters(Map<String, dynamic> config) async {
    final name = config['name'] as String;
    final value = config['value'] as int;
    final semesters = config['semesters'] as int;

    try {
      final deptRef = _db.collection('degree-level').doc(widget.degreeId).collection('department').doc(widget.departmentId);
      final yearRef = deptRef.collection('year').doc(value.toString());

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
      final totalToCreate = semesters; // exactly this many new semesters
      int created = 0;

      // 2) create the semesters with consecutive overall numbers start..start+totalToCreate-1
      for (int idx = 0; idx < totalToCreate; idx++) {
        final overall = startOverall + idx;
        final semesterInYear = idx + 1; // 1..semesters
        // create the year doc (merge) before writing sems
        await yearRef.set({
          'displayName': name,
          'value': value,
          'semestersCount': semesters,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        final semRef = yearRef.collection('semester').doc(overall.toString());
        final exists = await semRef.get();
        if (exists.exists) {
          await semRef.set({
            'displayName': 'Semester $overall',
            'value': overall,
            'yearNumber': value,
            'semesterInYear': semesterInYear,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } else {
          await semRef.set({
            'displayName': 'Semester $overall',
            'value': overall,
            'yearNumber': value,
            'semesterInYear': semesterInYear,
            'createdAt': FieldValue.serverTimestamp(),
          });
          created++;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Year created — $created new semesters.')));
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

/// Themed year card
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
                      width: 48,
                      height: 48,
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
                          Text('Year $value', style: TextStyle(color: theme.textTheme.bodySmall?.color)),
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
                    Expanded(child: AppPrimaryButton(text: 'Manage Semesters', icon: Icons.calendar_month, onPressed: onManage)),
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
