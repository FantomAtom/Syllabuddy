// lib/screens/main_shell.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'degree_screen.dart';
import 'profile_screen.dart';
import 'admin_screen.dart';
import 'exams_screen.dart';

// new imports for verify redirect
import 'package:syllabuddy/screens/verify_email_page.dart';
import 'package:syllabuddy/services/pending_signup_service.dart';

class MainShell extends StatefulWidget {
  final int initialTab;
  const MainShell({Key? key, this.initialTab = 0}) : super(key: key);

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  bool _showAdminTab = false;
  bool _isVerified = false;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _staffSub;
  late Future<void> _roleLoaded;
  List<GlobalKey<NavigatorState>> _navigatorKeys = [];

  @override
  void initState() {
    super.initState();
    _index = widget.initialTab;
    _roleLoaded = _fetchRoleOnce();
  }

  Future<void> _fetchRoleOnce() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // ensure latest auth state
    try {
      await user.reload();
    } catch (e) {
      debugPrint('User reload failed: $e');
    }

    // If user not verified — redirect them to VerifyEmailPage and stop initialization
    if (!(FirebaseAuth.instance.currentUser?.emailVerified ?? false)) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        final pending = await PendingSignupService.readPending();
        if (pending != null) {
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => VerifyEmailPage(
                // using saved pending values
                email: pending['email'] as String,
                firstName: pending['firstName'] as String,
                lastName: pending['lastName'] as String,
                studentId: pending['studentId'] as String?,
                role: pending['role'] as String,
              ),
            ),
            (route) => false,
          );
        } else {
          // fallback: pass at least email and default strings so constructor receives required args
          final email = FirebaseAuth.instance.currentUser?.email ?? '';
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => VerifyEmailPage(
                email: email,
                firstName: '',
                lastName: '',
                studentId: null,
                role: 'student',
              ),
            ),
            (route) => false,
          );
        }
      });

      // stop further initialization here — VerifyEmailPage will be shown
      return;
    }

    final uid = user.uid;
    final db = FirebaseFirestore.instance;

    try {
      final staffDoc = await db.collection('staff_emails').doc(uid).get();
      if (staffDoc.exists) {
        final status = staffDoc.data()?['status']?.toString() ?? 'unverified';
        _showAdminTab = true;
        _isVerified = status.toLowerCase() == 'verified';
      } else {
        final userDoc = await db.collection('users').doc(uid).get();
        if (userDoc.exists) {
          final role = userDoc.data()?['role']?.toString() ?? '';
          _showAdminTab = role.toLowerCase() == 'staff';
          _isVerified = _showAdminTab;
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

    _buildNavigatorKeys();

    _staffSub?.cancel();
    _staffSub = db.collection('staff_emails').doc(uid).snapshots().listen((snap) {
      final exists = snap.exists;
      final status = snap.data()?['status']?.toString() ?? 'unverified';

      if (!mounted) return;
      setState(() {
        _showAdminTab = exists || _showAdminTab;
        _isVerified = (status.toLowerCase() == 'verified');
        _buildNavigatorKeys();
      });
    }, onError: (err) {
      debugPrint('staff_emails subscription error: $err');
    });
  }

  void _buildNavigatorKeys() {
    final count = _showAdminTab ? 4 : 3;
    if (_navigatorKeys.length != count) {
      _navigatorKeys = List.generate(count, (_) => GlobalKey<NavigatorState>());
      if (_index >= _navigatorKeys.length) _index = 0;
    }
  }

  @override
  void dispose() {
    _staffSub?.cancel();
    super.dispose();
  }

  void _selectTab(int i) {
    if (i == _index) {
      _navigatorKeys[i].currentState?.popUntil((r) => r.isFirst);
    } else {
      setState(() => _index = i);
    }
  }

  Future<bool> _onWillPop() async {
    if (_navigatorKeys.isEmpty) return true;
    final currentNav = _navigatorKeys[_index];
    if (currentNav.currentState == null) return true;
    if (currentNav.currentState!.canPop()) {
      currentNav.currentState!.pop();
      return false;
    }
    if (_index != 0) {
      setState(() => _index = 0);
      return false;
    }
    return true;
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
            ? [
                const CoursesScreen(),
                const ExamsScreen(),
                const ProfileScreen(),
                const AdminConsole(),
              ]
            : [
                const CoursesScreen(),
                const ExamsScreen(),
                const ProfileScreen(),
              ];

        final bottomItems = _showAdminTab
            ? [
                const BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Syllabus'),
                const BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Exams'),
                const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
                const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
              ]
            : [
                const BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Syllabus'),
                const BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Exams'),
                const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
              ];

        _buildNavigatorKeys();

        final navigators = List<Widget>.generate(
          pages.length,
          (i) => Offstage(
            offstage: _index != i,
            child: Navigator(
              key: _navigatorKeys[i],
              onGenerateRoute: (settings) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (ctx) => pages[i],
                );
              },
            ),
          ),
        );

        return WillPopScope(
          onWillPop: _onWillPop,
          child: Scaffold(
            body: Stack(children: navigators),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _index,
              items: bottomItems,
              onTap: (i) => _selectTab(i),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Theme.of(context).colorScheme.surface,
              selectedItemColor: Theme.of(context).primaryColor,
              unselectedItemColor: Colors.grey[600],
              showUnselectedLabels: true,
            ),
          ),
        );
      },
    );
  }
}
