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
  bool _isStaffRole = false;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;
  late Future<void> _roleLoaded;

  @override
  void initState() {
    super.initState();
    _roleLoaded = _fetchRoleOnce();
  }

  Future<void> _fetchRoleOnce() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // fetch initial role from Firestore
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final role = doc.data()?['role']?.toString() ?? '';
    _isStaffRole = role == 'staff';

    // subscribe to live updates for role changes
    _userSub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snap) {
      final role = snap.data()?['role']?.toString() ?? '';
      setState(() => _isStaffRole = role == 'staff');
    });
  }

  @override
  void dispose() {
    _userSub?.cancel();
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

        final pages = _isStaffRole
            ? [const CoursesScreen(), const AdminConsole(), const ProfileScreen()]
            : [const CoursesScreen(), const ProfileScreen()];

        final bottomItems = _isStaffRole
            ? [
                const BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Syllabus'),
                const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
                const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
              ]
            : [
                const BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Syllabus'),
                const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
              ];

        final safeIndex = (_isStaffRole ? _index : (_index > 1 ? 1 : _index));

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
