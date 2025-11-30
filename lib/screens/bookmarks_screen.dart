// lib/screens/bookmarks_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syllabuddy/screens/subject_syllabus_screen.dart';

/// BookmarksScreen extracted from profile_screen.dart.
/// Uses the same header style as Profile (rounded bottom, primary color).
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
      if (!mounted) return;
      setState(() {
        _resolved = results;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Failed to load bookmarks: $e');
      if (!mounted) return;
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed from bookmarks')));
    } catch (e) {
      debugPrint('Failed to remove bookmark: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to remove bookmark: $e')));
    }
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
              padding: const EdgeInsets.only(top: 80, bottom: 24),
              child: Stack(
                children: [
                  // Back button on the left
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),

                  // Title centered
                  Center(
                    child: Text(
                      'Bookmarks',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.95)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _loading
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
                                subtitle: Text(
                                  "${r['department'].toString().toUpperCase()} • Year ${r['year']} • Sem ${r['semester']}",
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                                trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _removeBookmark(r['path'] as String),
                              ),
                              onTap: () => _openSubject(r),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
