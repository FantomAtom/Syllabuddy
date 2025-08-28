import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
        .doc(widget.subjectId)
        .collection('units')
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: Text('${widget.subjectId} Units')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateUnitDialog,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No units found'));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final d = docs[i];
              final id = d.id;
              final data = d.data();
              final display = (data['displayName'] ?? 'Unit $id').toString();
              final value = data['value'] ?? int.tryParse(id) ?? i + 1; // fallback to index + 1
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
      ),
    );
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
      final unitRef = _db.collection('degree-level')
          .doc(widget.degreeId)
          .collection('department')
          .doc(widget.departmentId)
          .collection('year')
          .doc(widget.yearId)
          .collection('semester')
          .doc(widget.semesterId)
          .collection('subjects')
          .doc(widget.subjectId)
          .collection('units')
          .doc(value.toString());

      await unitRef.set({
        'displayName': name,
        'value': value,
        'hours': hours,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unit created successfully')));
    } catch (e) {
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unit updated')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
      }
    }
  }

  Future<void> _deleteUnit(DocumentSnapshot<Map<String, dynamic>> doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Unit'),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unit deleted')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }
}

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
                      Text('Unit $value', style: TextStyle(color: Colors.grey[600])),
                      if (hours.isNotEmpty) Text('Hours: $hours', style: TextStyle(color: Colors.grey[600])),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(description, style: const TextStyle(fontSize: 14)),
                      ],
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
          ],
        ),
      ),
    );
  }
}
