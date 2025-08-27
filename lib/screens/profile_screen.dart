// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syllabuddy/screens/landingScreen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  String? _name;
  String? _email;
  String? _memberSince;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    _logout(context);
    return;
  }

  try {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();

    setState(() {
      _user = user;
      _email = user.email;
      if (data != null) {
        final firstName = data['firstName'] ?? '';
        final lastName = data['lastName'] ?? '';
        _name = "$firstName $lastName".trim();
      } else {
        _name = 'Unknown';
      }

      final ts = data?['createdAt'];
      if (ts != null && ts is Timestamp) {
        final dt = ts.toDate();
        _memberSince = "${dt.day}/${dt.month}/${dt.year}";
      } else {
        _memberSince = "Unknown";
      }

      _loading = false;
    });
  } catch (e) {
    debugPrint('Failed to fetch profile: $e');
    setState(() {
      _user = user;
      _email = user.email;
      _name = 'Unknown';
      _memberSince = "Unknown";
      _loading = false;
    });
  }
}


  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LandingScreen()),
      (route) => false,
    );
  }

  Future<void> _confirmAndDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account'),
        content: const Text(
            'This will permanently delete your account. This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final uid = _user?.uid;
        // Delete Firestore user doc
        if (uid != null) {
          await FirebaseFirestore.instance.collection('users').doc(uid).delete();
        }
        // Delete auth account
        await _user?.delete();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account deleted successfully.')));
        _logout(context);
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        if (e.code == 'requires-recent-login') {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Please log in again to delete your account (security requirement).')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete account: ${e.message}')));
        }
      } catch (e) {
        debugPrint('Delete account error: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unexpected error deleting account.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top curved banner
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40)),
                  child: Container(
                    width: double.infinity,
                    color: primary,
                    padding: const EdgeInsets.only(top: 80, bottom: 40),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 4,
                          top: 0,
                          bottom: 0,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Text('Profile',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white.withOpacity(0.95))),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Avatar and name
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 46,
                        child: Icon(Icons.person, size: 48),
                      ),
                      const SizedBox(height: 12),
                      Text(_name ?? '',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: primary)),
                      const SizedBox(height: 6),
                      Text(_email ?? '',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[700])),
                      const SizedBox(height: 20),

                      // Info card
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Icon(Icons.school),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                    'Member since $_memberSince\nSyllabuddy user',
                                    style: TextStyle(color: Colors.grey[800])),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Logout button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.logout),
                          label: const Text('Logout'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () => _logout(context),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Delete account
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.delete_forever),
                          label: const Text('Delete Account'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () => _confirmAndDelete(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
