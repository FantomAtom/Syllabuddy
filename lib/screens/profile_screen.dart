// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syllabuddy/screens/landingScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syllabuddy/services/user_service.dart';

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
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _logout(context);
      return;
    }

    try {
      final data = await UserService.getCurrentUserData();
      final first = data?['firstName'] ?? '';
      final last = data?['lastName'] ?? '';
      final ts = data?['createdAt'];

      setState(() {
        _user = currentUser;
        _email = currentUser.email;
        _name = "$first $last".trim().isEmpty ? 'Unknown' : "$first $last".trim();

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
        _user = currentUser;
        _email = currentUser.email;
        _name = 'Unknown';
        _memberSince = "Unknown";
        _loading = false;
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    // Clear login state
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');

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
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await UserService.deleteAccount();

        // Clear login state
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('isLoggedIn');

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account deleted successfully.')));
        _logout(context);
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        if (e.code == 'requires-recent-login') {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Please log in again to delete your account (security requirement).')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete account: ${e.message}')));
        }
      } catch (e) {
        debugPrint('Delete account error: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unexpected error deleting account.')));
      }
    }
  }

  bool _isEditing = false;

  Future<void> _editProfile(BuildContext context) async {
    if (_isEditing) return;
    _isEditing = true;

    final parts = (_name ?? "").split(" ");
    final firstName = parts.isNotEmpty ? parts.first : "";
    final lastName = parts.length > 1 ? parts.sublist(1).join(" ") : "";

    final firstNameController = TextEditingController(text: firstName);
    final lastNameController = TextEditingController(text: lastName);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Edit Profile"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: firstNameController, decoration: const InputDecoration(labelText: "First Name", border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: lastNameController, decoration: const InputDecoration(labelText: "Last Name", border: OutlineInputBorder())),
            ],
          ),
          actions: [
            TextButton(child: const Text("Cancel"), onPressed: () => Navigator.pop(context)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
              child: const Text("Save"),
              onPressed: () async {
                try {
                  await UserService.updateName(firstNameController.text.trim(), lastNameController.text.trim());
                  Navigator.pop(context);
                  await _fetchProfile();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
                } on FirebaseException catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update profile: ${e.message}')));
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
                }
              },
            ),
          ],
        );
      },
    );

    _isEditing = false;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
                  child: Container(
                    width: double.infinity,
                    color: primary,
                    padding: const EdgeInsets.only(top: 80, bottom: 40),
                    child: Stack(
                      children: [
                        Positioned(left: 4, top: 0, bottom: 0, child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.of(context).pop())),
                        Align(alignment: Alignment.center, child: Text('Profile', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.95)))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Text(_name ?? '', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primary)),
                      const SizedBox(height: 6),
                      Text(_email ?? '', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                      const SizedBox(height: 20),
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Icon(Icons.school),
                              const SizedBox(width: 12),
                              Expanded(child: Text('Member since $_memberSince\nSyllabuddy user', style: TextStyle(color: Colors.grey[800]))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Profile'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade600, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 16)),
                          onPressed: () => _editProfile(context),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.dark_mode),
                          label: const Text('Toggle Dark/Light Mode'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade600, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 16)),
                          onPressed: () {
                            // TODO: add dark mode toggle
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.logout),
                          label: const Text('Logout'),
                          style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 16)),
                          onPressed: () => _logout(context),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.delete_forever),
                          label: const Text('Delete Account'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 16)),
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
