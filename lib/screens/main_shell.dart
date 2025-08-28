// lib/screens/main_shell.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'degree_screen.dart';
import 'profile_screen.dart';
import 'admin_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({Key? key}) : super(key: key);

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  /// showAdminTab => whether we show the Admin tab at all (exists in staff_emails
  /// or users role == 'staff'). AdminConsole will decide whether the user can edit.
  bool _showAdminTab = false;

  /// whether the staff request is verified (useful for debug or future use)
  bool _isVerified = false;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _staffSub;
  late Future<void> _roleLoaded;

  @override
  void initState() {
    super.initState();
    _roleLoaded = _fetchRoleOnce();
  }

  Future<void> _fetchRoleOnce() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final db = FirebaseFirestore.instance;

    // Try staff_emails doc first
    try {
      final staffDoc = await db.collection('staff_emails').doc(uid).get();
      if (staffDoc.exists) {
        final status = staffDoc.data()?['status']?.toString() ?? 'unverified';
        _showAdminTab = true;
        _isVerified = status.toLowerCase() == 'verified';
      } else {
        // fallback: check 'users' doc (legacy or alternate)
        final userDoc = await db.collection('users').doc(uid).get();
        if (userDoc.exists) {
          final role = userDoc.data()?['role']?.toString() ?? '';
          _showAdminTab = role.toLowerCase() == 'staff';
          _isVerified = _showAdminTab; // if someone is marked 'staff' in users, treat as allowed.
        } else {
          _showAdminTab = false;
          _isVerified = false;
        }
      }
    } catch (e) {
      debugPrint('Failed initial role check: $e');
      _showAdminTab = false;
      _isVerified = false;
    }

    // Subscribe to staff_emails doc so verification updates reflect live
    // (if doc does not exist this subscription will still get an initial non-existence snapshot)
    _staffSub?.cancel();
    _staffSub = db.collection('staff_emails').doc(uid).snapshots().listen((snap) {
      final exists = snap.exists;
      final status = snap.data()?['status']?.toString() ?? 'unverified';
      setState(() {
        _showAdminTab = exists || _showAdminTab; // once true via users doc, keep it true
        _isVerified = (status.toLowerCase() == 'verified');
      });
    }, onError: (err) {
      debugPrint('staff_emails subscription error: $err');
    });
  }

  @override
  void dispose() {
    _staffSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _roleLoaded,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final pages = _showAdminTab
            ? [const CoursesScreen(), const AdminConsole(), const ProfileScreen()]
            : [const CoursesScreen(), const ProfileScreen()];

        final bottomItems = _showAdminTab
            ? [
                const BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Syllabus'),
                const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
                const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
              ]
            : [
                const BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Syllabus'),
                const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
              ];

        final safeIndex = (_showAdminTab ? _index : (_index > 1 ? 1 : _index));

        return Scaffold(
          body: IndexedStack(index: safeIndex, children: pages),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: safeIndex,
            items: bottomItems,
            onTap: (i) => setState(() => _index = i),
            selectedItemColor: Theme.of(context).primaryColor,
          ),
        );
      },
    );
  }
}
