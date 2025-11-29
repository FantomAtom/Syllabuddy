// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syllabuddy/screens/landingScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syllabuddy/services/user_service.dart';
import 'package:syllabuddy/screens/subject_syllabus_screen.dart';

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
        _email = currentUser?.email;
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
            'This will permanently delete your account and all associated profile data. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed != true) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return _logout(context);

    try {
      await UserService.deleteAccount();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account deleted successfully.')));
      _logout(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'requires-recent-login') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in again (recent login required) and retry account deletion.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete account: ${e.message}')));
      }
    } on FirebaseException catch (e) {
      if (!mounted) return;
      if (e.code == 'permission-denied') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed due to Firestore security rules: ${e.message}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete account: ${e.message}')));
      }
    } catch (e) {
      debugPrint('Delete account error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unexpected error deleting account: $e')));
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
                        Expanded(child: Text('Member since $_memberSince\nSyllabuddy user', style: TextStyle(color: Colors.grey[800]))),
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

/// BookmarksScreen - shows list of bookmarked subject doc paths, resolves titles and navigates
class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({Key? key}) : super(key: key);

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final _db = FirebaseFirestore.instance;
  bool _loading = true;
  List<String> _bookmarks = [];
  List<Map<String, dynamic>> _resolved = [];

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    setState(() {
      _loading = true;
      _bookmarks = [];
      _resolved = [];
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
      });
      return;
    }

    try {
      final userSnap = await _db.collection('users').doc(user.uid).get();
      Map<String, dynamic>? data;
      if (userSnap.exists) {
        data = userSnap.data();
      } else {
        final staffSnap = await _db.collection('staff_emails').doc(user.uid).get();
        if (staffSnap.exists) data = staffSnap.data();
      }

      final List<dynamic>? b = data?['bookmarks'] as List<dynamic>?;
      if (b == null || b.isEmpty) {
        setState(() {
          _bookmarks = [];
          _resolved = [];
          _loading = false;
        });
        return;
      }

      _bookmarks = b.map((e) => e.toString()).toList();

      final futures = _bookmarks.map((p) async {
        try {
          final docSnap = await _db.doc(p).get();
          if (docSnap.exists) {
            final d = docSnap.data() as Map<String, dynamic>? ?? {};
            final title = (d['displayName'] ?? d['title'] ?? docSnap.id).toString();
            final segs = p.split('/');
            String courseLevel = '';
            String department = '';
            String year = '';
            String semester = '';
            String subjectId = '';
            for (var i = 0; i + 1 < segs.length; i += 2) {
              final key = segs[i];
              final val = segs[i + 1];
              if (key == 'degree-level') courseLevel = val;
              if (key == 'department') department = val;
              if (key == 'year') year = val;
              if (key == 'semester') semester = val;
              if (key == 'subjects') subjectId = val;
            }
            return {
              'path': p,
              'title': title,
              'courseLevel': courseLevel,
              'department': department,
              'year': year,
              'semester': semester,
              'subjectId': subjectId,
            };
          } else {
            return {
              'path': p,
              'title': '(missing subject)',
              'courseLevel': '',
              'department': '',
              'year': '',
              'semester': '',
              'subjectId': '',
            };
          }
        } catch (e) {
          return {
            'path': p,
            'title': '(error)',
            'courseLevel': '',
            'department': '',
            'year': '',
            'semester': '',
            'subjectId': '',
          };
        }
      }).toList();

      final results = await Future.wait(futures);
      setState(() {
        _resolved = results;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Failed to load bookmarks: $e');
      setState(() {
        _bookmarks = [];
        _resolved = [];
        _loading = false;
      });
    }
  }

  void _openSubject(Map<String, dynamic> r) {
    if (r['courseLevel'] == '' || r['subjectId'] == '') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot open missing subject.')));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubjectSyllabusScreen(
          courseLevel: r['courseLevel'] as String,
          department: r['department'] as String,
          year: r['year'] as String,
          semester: r['semester'] as String,
          subjectId: r['subjectId'] as String,
          subjectName: r['title'] as String,
        ),
      ),
    );
  }

  Future<void> _removeBookmark(String path) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = _db.collection('users').doc(user.uid);
    final staffRef = _db.collection('staff_emails').doc(user.uid);

    try {
      final userSnap = await userRef.get();
      if (userSnap.exists) {
        await userRef.update({'bookmarks': FieldValue.arrayRemove([path])});
      } else {
        final staffSnap = await staffRef.get();
        if (staffSnap.exists) {
          await staffRef.update({'bookmarks': FieldValue.arrayRemove([path])});
        } else {
          // nothing
        }
      }
      await _loadBookmarks();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed from bookmarks')));
    } catch (e) {
      debugPrint('Failed to remove bookmark: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to remove bookmark: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarked subjects'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _resolved.isEmpty
              ? const Center(child: Text('No bookmarks yet'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _resolved.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final r = _resolved[i];
                    return Card(
                      child: ListTile(
                        title: Text(r['title'] ?? ''),
                        subtitle: Text(r['path'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _removeBookmark(r['path'] as String),
                        ),
                        onTap: () => _openSubject(r),
                      ),
                    );
                  },
                ),
    );
  }
}
