// lib/screens/admin_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// small imports that point to the other admin screens you already created
import 'admin_department_screen.dart';
import 'admin_exam_screen.dart';

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
      _email = user.email;
      final doc = await FirebaseFirestore.instance.collection('staff_emails').doc(user.uid).get();
      if (!doc.exists) {
        setState(() {
          _verified = false;
          _loading = false;
        });
        return;
      }
      final status = doc.data()?['status']?.toString() ?? 'unverified';
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

  AppBar _primaryAppBar(BuildContext context, String title) {
    final theme = Theme.of(context);
    return AppBar(
      title: Text(title, style: TextStyle(color: theme.colorScheme.onPrimary)),
      backgroundColor: theme.primaryColor,
      iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (_error != null) {
      return Scaffold(
        appBar: _primaryAppBar(context, 'Admin Console'),
        body: Center(child: Text('Error: $_error')),
      );
    }

    if (!_verified) {
      return Scaffold(
        appBar: _primaryAppBar(context, 'Admin Console'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.lock_outline, size: 64, color: Theme.of(context).primaryColor),
              const SizedBox(height: 16),
              Text('Admin Access Pending',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
              const SizedBox(height: 12),
              Text(
                'Your account (${_email ?? "unknown"}) is registered as staff but not verified yet. An administrator must verify your email to enable admin features.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _checkVerification, child: const Text('Refresh Status'))),
              const SizedBox(height: 8),
              const Text('If you believe this is an error, contact the system administrator.'),
            ]),
          ),
        ),
      );
    }

    // Verified
    return Scaffold(
      appBar: _primaryAppBar(context, 'Admin Console'),
      body: const AdminHome(),
    );
  }
}

/// ---------------------------- Admin Home (degree-level) ----------------------------
/// This widget is compact: it lists degree-level docs and links to the separate screens
class AdminHome extends StatefulWidget {
  const AdminHome({Key? key}) : super(key: key);

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  final _db = FirebaseFirestore.instance;

  Future<void> _addDegree(BuildContext context) async {
    final ctrl = TextEditingController();
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
      await _db.collection('degree-level').doc(id).set({'displayName': id, 'createdAt': FieldValue.serverTimestamp()});
      ctrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Degree created')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
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
              IconButton(onPressed: () => _addDegree(context), icon: const Icon(Icons.add)),
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
                itemCount: docs.length + 1, // +1 for the exam schedules card at bottom
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  // last item is the exam schedules card
                  if (i == docs.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Exam schedules', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminExamScreen())),
                                  icon: const Icon(Icons.calendar_month),
                                  label: const Text('Manage Exam Sets'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }


                  final d = docs[i];
                  final id = d.id;
                  final display = (d.data()['displayName'] ?? id).toString();
                  return AdminDegreeCard(
                    degreeId: id,
                    displayName: display,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminDepartmentList(degreeId: id))),
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

/// Clickable degree card component
class AdminDegreeCard extends StatelessWidget {
  final String degreeId;
  final String displayName;
  final VoidCallback onTap;

  const AdminDegreeCard({
    Key? key,
    required this.degreeId,
    required this.displayName,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isPg = degreeId.toUpperCase().contains('PG');
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(isPg ? Icons.workspace_premium : Icons.school, size: 32, color: Theme.of(context).primaryColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(displayName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('ID: $degreeId', style: TextStyle(color: Colors.grey[600])),
                ]),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
