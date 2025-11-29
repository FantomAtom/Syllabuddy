import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'degree_screen.dart';
import 'profile_screen.dart';
import 'admin_screen.dart';
import 'exams_screen.dart';


class MainShell extends StatefulWidget {
  /// optional initialTab for cases where you want MainShell to open on a specific tab
  final int initialTab;
  const MainShell({Key? key, this.initialTab = 0}) : super(key: key);

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  /// keep track of last tab so Profile can go back to it
  int _lastIndex = 0;

  /// whether admin tab should be shown at all
  bool _showAdminTab = false;

  /// whether the staff request is verified (used by AdminConsole internally)
  bool _isVerified = false;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _staffSub;
  late Future<void> _roleLoaded;

  // Navigator keys for each tab (we maintain one navigator per tab to preserve stacks)
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

    // Build navigator keys for tabs based on whether admin tab is shown
    _buildNavigatorKeys();

    // Listen for changes to staff_emails doc (so verification updates are reflected)
    _staffSub?.cancel();
    _staffSub = db.collection('staff_emails').doc(uid).snapshots().listen((snap) {
      final exists = snap.exists;
      final status = snap.data()?['status']?.toString() ?? 'unverified';

      if (!mounted) return;
      setState(() {
        _showAdminTab = exists || _showAdminTab; // keep previously discovered staff true
        _isVerified = (status.toLowerCase() == 'verified');
        // Rebuild keys if needed when admin availability changes
        _buildNavigatorKeys();
      });
    }, onError: (err) {
      debugPrint('staff_emails subscription error: $err');
    });
  }

  void _buildNavigatorKeys() {
    final count = _showAdminTab ? 4 : 3;
    // If keys length differs, rebuild so each tab has its own navigator key.
    if (_navigatorKeys.length != count) {
      _navigatorKeys = List.generate(count, (_) => GlobalKey<NavigatorState>());
      // ensure `_index` is within range
      if (_index >= _navigatorKeys.length) _index = 0;
    }
  }

  @override
  void dispose() {
    _staffSub?.cancel();
    super.dispose();
  }

  // Helper: select a tab (switches the visible navigator)
  void _selectTab(int i) {
    if (i == _index) {
      // If tapping the active tab, pop to first route in that tab
      _navigatorKeys[i].currentState?.popUntil((r) => r.isFirst);
    } else {
      // remember last index before changing
      _lastIndex = _index;
      setState(() => _index = i);
    }
  }

  // Exposed helper so ProfileScreen can ask MainShell to switch back
  void _switchToLastTab() {
    // if lastIndex is out of range (e.g. admin tab toggled), clamp it
    final maxIndex = _navigatorKeys.length - 1;
    final target = (_lastIndex <= maxIndex) ? _lastIndex : 0;
    setState(() => _index = target);
  }

  // Handle system back button: try to pop inner navigator first
  Future<bool> _onWillPop() async {
    if (_navigatorKeys.isEmpty) return true;
    final currentNav = _navigatorKeys[_index];
    if (currentNav.currentState == null) return true;
    if (currentNav.currentState!.canPop()) {
      currentNav.currentState!.pop();
      return false; // handled
    }
    // if not on first tab, go to first tab
    if (_index != 0) {
      setState(() => _index = 0);
      return false;
    }
    // allow default (exit app)
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

        // Build list of tab root widgets (these are used as initial routes for each navigator)
        final pages = _showAdminTab
            ? [
                const CoursesScreen(),
                const ExamsScreen(), 
                ProfileScreen(onClose: _switchToLastTab),
                const AdminConsole(),
              ]
            : [
                const CoursesScreen(),
                const ExamsScreen(),     
                ProfileScreen(onClose: _switchToLastTab),
              ];

        // Bottom nav items
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


        // Safety: ensure navigator keys exist
        _buildNavigatorKeys();

        // Build Offstage navigators — one per tab — so each keeps its own navigation stack.
        final navigators = List<Widget>.generate(
          pages.length,
          (i) => Offstage(
            offstage: _index != i,
            child: Navigator(
              key: _navigatorKeys[i],
              onGenerateRoute: (settings) {
                // initial route simply shows the page at pages[i]
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
            // The body is the stack of offstage navigators; only the active one is interactive.
            body: Stack(children: navigators),
            bottomNavigationBar: BottomNavigationBar(
            currentIndex: _index,
            items: bottomItems,
            onTap: (i) => _selectTab(i),
            type: BottomNavigationBarType.fixed,                 // stable layout for 3-4 items
            backgroundColor: Theme.of(context).colorScheme.surface, // solid background (not transparent)
            selectedItemColor: Theme.of(context).primaryColor,  // highlight for active tab
            unselectedItemColor: Colors.grey[600],              // visible but muted for others
            showUnselectedLabels: true,
          ),

          ),
        );
      },
    );
  }
}
