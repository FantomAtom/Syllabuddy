// lib/screens/admin_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// small imports that point to the other admin screens you already created
import 'admin_department_screen.dart';
import 'admin_exam_screen.dart';

// reuse app widgets & styles
import '../styles/app_styles.dart';
import '../theme.dart';
import '../widgets/app_section_title.dart';
import '../widgets/app_primary_button.dart';

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
      elevation: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(theme.primaryColor),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: _primaryAppBar(context, 'Admin Console'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Error: $_error', textAlign: TextAlign.center),
          ),
        ),
      );
    }

    if (!_verified) {
      // Locked state (friendly)
      return Scaffold(
        appBar: _primaryAppBar(context, 'Admin Console'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppStyles.primaryGradient(context),
                    boxShadow: [AppStyles.shadow(context)],
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Icon(Icons.lock_outline, size: 48, color: Colors.white),
                ),
                const SizedBox(height: 18),
                Text(
                  'Admin Access Pending',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primaryText,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your account (${_email ?? "unknown"}) is registered as staff but not verified yet. An administrator must verify your email to enable admin features.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: AppPrimaryButton(
                    text: 'Refresh Status',
                    onPressed: _checkVerification,
                    icon: Icons.refresh,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'If you believe this is an error, contact the system administrator.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.textTheme.bodySmall?.color),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Verified -> show admin home
    return Scaffold(
      appBar: _primaryAppBar(context, 'Admin Console'),
      body: const AdminHome(),
    );
  }
}

/// ---------------------------- Admin Home (degree-level) ----------------------------
/// This widget shows only two fixed degree levels: UG and PG
class AdminHome extends StatelessWidget {
  const AdminHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final degrees = const [
      {'id': 'UG', 'display': 'Undergraduate'},
      {'id': 'PG', 'display': 'Postgraduate'},
    ];

    return Column(
      children: [
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(child: AppSectionTitle(text: 'Manage degree levels')),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: degrees.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              if (i == degrees.length) {
                // exam schedules card
                return Card(
                  color: theme.cardColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppStyles.radiusMedium)),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Exam schedules', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primaryText)),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: AppPrimaryButton(
                            text: 'Manage Exam Sets',
                            icon: Icons.calendar_month,
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminExamScreen())),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final deg = degrees[i];
              final id = deg['id']!;
              final display = deg['display']!;

              return _DegreeCard(
                degreeId: id,
                displayName: display,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminDepartmentList(degreeId: id))),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DegreeCard extends StatelessWidget {
  final String degreeId;
  final String displayName;
  final VoidCallback onTap;

  const _DegreeCard({Key? key, required this.degreeId, required this.displayName, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPg = degreeId.toUpperCase().contains('PG');

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
            onTap: onTap,
            splashFactory: InkRipple.splashFactory,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 14.0),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppStyles.primaryGradient(context),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 3))],
                    ),
                    child: Icon(isPg ? Icons.workspace_premium : Icons.school, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(displayName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.colorScheme.primaryText)),
                      const SizedBox(height: 4),
                      Text('ID: $degreeId', style: TextStyle(color: theme.textTheme.bodySmall?.color)),
                    ]),
                  ),
                  Icon(Icons.arrow_forward_ios, color: theme.textTheme.bodySmall?.color, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
