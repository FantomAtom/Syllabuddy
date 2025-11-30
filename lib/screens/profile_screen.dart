import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syllabuddy/screens/landingScreen.dart';
import 'package:syllabuddy/services/user_service.dart';
import 'package:syllabuddy/screens/subject_syllabus_screen.dart';
import 'package:syllabuddy/screens/bookmarks_screen.dart';

/// ProfileScreen: simplified — no back/close handling or onClose callback.
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
      if (mounted) {
        setState(() {
          _loading = false;
          _user = null;
          _email = null;
          _name = null;
          _memberSince = null;
        });
      }
      return;
    }

    try {
      final data = await UserService.getCurrentUserData();
      final first = data?['firstName'] ?? '';
      final last = data?['lastName'] ?? '';
      final ts = data?['createdAt'];

      if (!mounted) return;
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
      if (!mounted) return;
      setState(() {
        _user = currentUser;
        _email = currentUser?.email;
        _name = 'Unknown';
        _memberSince = "Unknown";
        _loading = false;
      });
    }
  }

  /// Logout: sign out, clear prefs, and force root navigator -> LandingScreen
  Future<void> _logout(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LandingScreen()),
          (route) => false,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signed out')));
    } catch (e) {
      debugPrint('Logout failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign out failed: $e')));
    }
  }

  /// Reauthenticate email/password users by asking for password.
  Future<bool> _reauthenticateWithPassword(BuildContext context) async {
    final pwController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Re-authenticate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('For security, please enter your password to confirm account deletion.'),
            const SizedBox(height: 12),
            TextField(
              controller: pwController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      pwController.dispose();
      return false;
    }
    final password = pwController.text.trim();
    pwController.dispose();
    if (password.isEmpty) return false;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) return false;

      final cred = EmailAuthProvider.credential(email: user.email!, password: password);
      await user.reauthenticateWithCredential(cred);
      debugPrint('Reauthentication successful');
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Reauth failed: ${e.code} ${e.message}');
      if (!mounted) return false;
      if (e.code == 'wrong-password') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incorrect password.')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Re-authentication failed: ${e.message}')));
      }
      return false;
    } catch (e) {
      debugPrint('Unexpected reauth error: $e');
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to re-authenticate. Try again.')));
      return false;
    }
  }

  Future<void> _confirmAndDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account'),
        content: const Text(
            'This will permanently delete your account and all associated profile data. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed != true) return;

    final userBefore = FirebaseAuth.instance.currentUser;
    final uidBefore = userBefore?.uid;
    debugPrint('Starting delete flow for uid=${uidBefore ?? 'null'}');

    // Optional loading state here...

    try {
      // 1) Delete Firestore/application data first (via your service).
      // If your UserService.deleteAccount() also deletes Auth user, it's fine;
      // this function will proceed to cleanup and navigate regardless.
      await UserService.deleteAccount();
      debugPrint('UserService.deleteAccount() completed');
    } catch (e, st) {
      debugPrint('UserService.deleteAccount() threw: $e\n$st');
      // If Firestore deletion fails, show a helpful message and abort
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete account data: $e')));
      return;
    }

    // 2) Try to delete Auth user if still present. This is best-effort.
    try {
      final current = FirebaseAuth.instance.currentUser;
      if (current != null) {
        try {
          await current.delete();
          debugPrint('Auth user deleted successfully.');
        } on FirebaseAuthException catch (e) {
          debugPrint('Auth delete failed: ${e.code} ${e.message}');
          if (e.code == 'requires-recent-login') {
            final reauthOk = await _reauthenticateWithPassword(context);
            if (reauthOk) {
              try {
                final after = FirebaseAuth.instance.currentUser;
                if (after != null) {
                  await after.delete();
                  debugPrint('Auth user deleted after reauth.');
                } else {
                  debugPrint('No current user after reauth; cannot delete auth user.');
                }
              } on FirebaseAuthException catch (e2) {
                debugPrint('Auth delete after reauth failed: ${e2.code} ${e2.message}');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete auth account: ${e2.message}')));
                }
              }
            } else {
              // Reauth cancelled/failed. We'll continue to cleanup and navigate anyway.
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please sign in again (recent login required) and retry account deletion.')),
                );
              }
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete account: ${e.message}')));
            }
          }
        }
      } else {
        debugPrint('No current user present when attempting auth delete (already signed out).');
      }
    } catch (e) {
      debugPrint('Unexpected error while attempting auth delete: $e');
    }

    // 3) Local cleanup: prefs + signOut (safe even if already signed out)
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');
    } catch (e) {
      debugPrint('Failed to clear prefs: $e');
    }

    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('signOut threw (ignored): $e');
    }

    // 4) Always navigate to landing screen (deferred to next frame for navigator stability)
    if (!mounted) return;
    debugPrint('Navigating to LandingScreen (mounted=${mounted})');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('Performing navigation to LandingScreen now');
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LandingScreen()),
        (route) => false,
      );
    });

    // Feedback for user
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account deletion process completed.')));
    }
  }

  // open bookmarks screen
  void _openBookmarks() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BookmarksScreen()),
    );
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
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
                } on FirebaseException catch (e) {
                  Navigator.pop(context);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update profile: ${e.message}')));
                } catch (e) {
                  Navigator.pop(context);
                  if (!mounted) return;
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
      body: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
            child: Container(
              width: double.infinity,
              color: primary,
              padding: const EdgeInsets.only(top: 80, bottom: 40),
              child: Center(
                child: Text(
                  'Profile',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.95)),
                ),
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
                        Expanded(child: Text('Member since ${_memberSince ?? "Unknown"}\nSyllabuddy user', style: TextStyle(color: Colors.grey[800]))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // New: View Bookmarked Subjects
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.bookmark),
                    label: const Text('Bookmarked subjects'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade600, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: _openBookmarks,
                  ),
                ),

                const SizedBox(height: 12),
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
                    style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 3, 45, 99), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 16)),
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
