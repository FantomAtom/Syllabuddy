// lib/screens/admin_unit_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// shared styles & widgets
import '../styles/app_styles.dart';
import '../theme.dart';
import '../widgets/app_primary_button.dart';

class AdminUnitList extends StatefulWidget {
  final String degreeId;
  final String departmentId;
  final String yearId;
  final String semesterId;
  final String subjectId;
  const AdminUnitList({
    Key? key,
    required this.degreeId,
    required this.departmentId,
    required this.yearId,
    required this.semesterId,
    required this.subjectId,
  }) : super(key: key);

  @override
  State<AdminUnitList> createState() => _AdminUnitListState();
}

class _AdminUnitListState extends State<AdminUnitList> {
  final _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _subjectDocRef {
    return _db
        .collection('degree-level')
        .doc(widget.degreeId)
        .collection('department')
        .doc(widget.departmentId)
        .collection('year')
        .doc(widget.yearId)
        .collection('semester')
        .doc(widget.semesterId)
        .collection('subjects')
        .doc(widget.subjectId);
  }

  CollectionReference<Map<String, dynamic>> get _unitsCollection {
    return _subjectDocRef.collection('units');
  }

  @override
  Widget build(BuildContext context) {
    // Stream the subject doc so the title updates if displayName changes
    final theme = Theme.of(context);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _subjectDocRef.snapshots(),
      builder: (context, subjectSnap) {
        final subjectData = subjectSnap.data?.data();
        final subjectDisplay = subjectData != null && subjectData['displayName'] != null
            ? subjectData['displayName'].toString()
            : widget.subjectId;

        return Scaffold(
          appBar: AppBar(
            title: Text('${subjectDisplay} Units', style: TextStyle(color: theme.colorScheme.onPrimary)),
            backgroundColor: theme.primaryColor,
            iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
            elevation: 0,
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _showCreateUnitDialog,
            backgroundColor: theme.primaryColor,
            child: Icon(Icons.add, color: theme.colorScheme.onPrimary),
            tooltip: 'Create unit',
          ),
          body: FutureBuilder<Query<Map<String, dynamic>>>(
            future: _pickUnitsQuery(),
            builder: (context, qSnap) {
              if (qSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (qSnap.hasError) {
                debugPrint('Units query pick failed: ${qSnap.error}');
                return Center(child: Text('Failed to build units query: ${qSnap.error}'));
              }

              final query = qSnap.data!;
              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: query.snapshots(),
                builder: (context, snap) {
                  if (snap.hasError) {
                    debugPrint('Units snapshot error: ${snap.error}');
                    return Center(child: Text('Error loading units: ${snap.error}'));
                  }
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snap.data?.docs ?? [];
                  debugPrint('Units fetched: ${docs.length}');

                  if (docs.isEmpty) {
                    return Center(child: Text('No units found', style: TextStyle(color: theme.textTheme.bodySmall?.color)));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final d = docs[i];
                      final id = d.id;
                      final data = d.data();
                      final display = (data['displayName'] ?? 'Unit $id').toString();
                      final value = (data['value'] is int) ? data['value'] as int : (int.tryParse(id) ?? (i + 1));
                      final hours = data['hours']?.toString() ?? '';
                      final description = data['content']?.toString() ?? data['description']?.toString() ?? '';
                      return AdminUnitCard(
                        unitId: id,
                        displayName: display,
                        value: value,
                        hours: hours,
                        description: description,
                        onEdit: () => _showEditUnitDialog(d),
                        onDelete: () => _deleteUnit(d),
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  /// Picks a Query for units. Tries to use orderBy('value') if it looks safe.
  /// Returns a Query<Map<String, dynamic>>.
  Future<Query<Map<String, dynamic>>> _pickUnitsQuery() async {
    final col = _unitsCollection;

    try {
      // Quick probe: fetch a small sample to inspect whether integer 'value' exists.
      final snap = await col.limit(5).get();
      bool hasIntValue = false;
      for (final d in snap.docs) {
        final v = d.data()['value'];
        if (v is int) {
          hasIntValue = true;
          break;
        }
      }

      if (hasIntValue) {
        // safe to order by value
        return col.orderBy('value');
      } else {
        // fallback to plain collection (no ordering)
        return col;
      }
    } catch (e) {
      // If probe fails (permissions / transient), fall back to plain collection
      debugPrint('Error probing units collection: $e');
      return col;
    }
  }

  Future<void> _showCreateUnitDialog() async {
    final nameCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final hoursCtrl = TextEditingController(text: '10');
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Unit'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Unit Name'),
                validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: valueCtrl,
                decoration: const InputDecoration(labelText: 'Unit Number'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return (n == null || n <= 0) ? 'Enter positive number' : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: hoursCtrl,
                decoration: const InputDecoration(labelText: 'Hours'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
                maxLines: 3,
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
                  'hours': hoursCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                });
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _createUnit(result);
    }
  }

  Future<void> _createUnit(Map<String, dynamic> config) async {
    final name = config['name'] as String;
    final value = config['value'] as int;
    final hours = config['hours'] as String;
    final description = config['description'] as String;

    try {
      final unitRef = _unitsCollection.doc(value.toString());

      await unitRef.set({
        'displayName': name,
        'value': value,
        'hours': hours,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unit created successfully')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _showEditUnitDialog(DocumentSnapshot<Map<String, dynamic>> doc) async {
    final data = doc.data() ?? {};
    final nameCtrl = TextEditingController(text: data['displayName'] ?? 'Unit ${doc.id}');
    final hoursCtrl = TextEditingController(text: data['hours']?.toString() ?? '10');

    // prefill from either 'content' (preferred) or 'description'
    final existingDesc = (data['content']?.toString() ?? data['description']?.toString() ?? '');
    final descCtrl = TextEditingController(text: existingDesc);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Unit'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Unit Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hoursCtrl,
                decoration: const InputDecoration(labelText: 'Hours'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),

              // <-- larger editable area for description
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                keyboardType: TextInputType.multiline,
                minLines: 6, // shows a larger box by default
                maxLines: 12,
              ),
            ],
          ),
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
        // Update both 'description' and 'content' to keep documents consistent
        await doc.reference.update({
          'displayName': nameCtrl.text.trim(),
          'hours': hoursCtrl.text.trim(),
          'description': descCtrl.text.trim(),
          'content': descCtrl.text.trim(),
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unit updated')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
      }
    }
  }

  Future<void> _deleteUnit(DocumentSnapshot<Map<String, dynamic>> doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Unit'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text('Are you sure you want to delete "${doc.data()?['displayName'] ?? doc.id}"?'),
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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unit deleted')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }
}

/// Themed unit card
class AdminUnitCard extends StatelessWidget {
  final String unitId;
  final String displayName;
  final int value;
  final String hours;
  final String description;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AdminUnitCard({
    Key? key,
    required this.unitId,
    required this.displayName,
    required this.value,
    required this.hours,
    required this.description,
    required this.onEdit,
    required this.onDelete,
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
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // badge
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
                    Text('Unit $value', style: TextStyle(color: theme.textTheme.bodySmall?.color)),
                    if (hours.isNotEmpty) Text('Hours: $hours', style: TextStyle(color: theme.textTheme.bodySmall?.color)),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(description, style: TextStyle(fontSize: 14, color: theme.textTheme.bodySmall?.color)),
                    ],
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(onPressed: onEdit, icon: Icon(Icons.edit, color: theme.primaryColor)),
                  IconButton(onPressed: onDelete, icon: const Icon(Icons.delete, color: Colors.red)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
