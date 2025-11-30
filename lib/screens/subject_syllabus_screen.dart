// lib/screens/subject_syllabus_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart'; // Clipboard
import 'package:firebase_auth/firebase_auth.dart';

// FIXED: use proper import for BookmarksScreen
import 'package:syllabuddy/screens/bookmarks_screen.dart';

class SubjectSyllabusScreen extends StatefulWidget {
  final String courseLevel;
  final String department;
  final String year;
  final String semester;
  final String subjectId;
  final String? subjectName;

  const SubjectSyllabusScreen({
    Key? key,
    required this.courseLevel,
    required this.department,
    required this.year,
    required this.semester,
    required this.subjectId,
    this.subjectName,
  }) : super(key: key);

  @override
  State<SubjectSyllabusScreen> createState() => _SubjectSyllabusScreenState();
}

class _SubjectSyllabusScreenState extends State<SubjectSyllabusScreen>
    with SingleTickerProviderStateMixin {
  bool _loadingBookmark = true;
  bool _bookmarked = false;
  final _db = FirebaseFirestore.instance;

  // scale animation controller
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack),
    );

    _loadBookmarkState();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  String get _subjectDocPath {
    return _db
        .collection('degree-level')
        .doc(widget.courseLevel)
        .collection('department')
        .doc(widget.department)
        .collection('year')
        .doc(widget.year)
        .collection('semester')
        .doc(widget.semester)
        .collection('subjects')
        .doc(widget.subjectId)
        .path;
  }

  DocumentReference<Map<String, dynamic>> get _subjectDocRef {
    return _db
        .collection('degree-level')
        .doc(widget.courseLevel)
        .collection('department')
        .doc(widget.department)
        .collection('year')
        .doc(widget.year)
        .collection('semester')
        .doc(widget.semester)
        .collection('subjects')
        .doc(widget.subjectId);
  }

  Future<void> _loadBookmarkState() async {
    setState(() => _loadingBookmark = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _bookmarked = false;
        _loadingBookmark = false;
      });
      return;
    }

    try {
      final path = _subjectDocPath;

      // Prefer users doc
      final userRef = _db.collection('users').doc(user.uid);
      final userSnap = await userRef.get();
      if (userSnap.exists) {
        final List<dynamic>? b = userSnap.data()?['bookmarks'] as List<dynamic>?;
        setState(() {
          _bookmarked = b?.contains(path) == true;
          _loadingBookmark = false;
        });
        return;
      }

      // fallback to staff_emails
      final staffRef = _db.collection('staff_emails').doc(user.uid);
      final staffSnap = await staffRef.get();
      if (staffSnap.exists) {
        final List<dynamic>? b = staffSnap.data()?['bookmarks'] as List<dynamic>?;
        setState(() {
          _bookmarked = b?.contains(path) == true;
          _loadingBookmark = false;
        });
        return;
      }

      setState(() {
        _bookmarked = false;
        _loadingBookmark = false;
      });
    } catch (e) {
      debugPrint('Failed to load bookmark state: $e');
      setState(() {
        _bookmarked = false;
        _loadingBookmark = false;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign in to bookmark subjects.')));
      return;
    }

    setState(() => _loadingBookmark = true);

    final subjectPath = _subjectDocPath;
    final userRef = _db.collection('users').doc(user.uid);
    final staffRef = _db.collection('staff_emails').doc(user.uid);

    try {
      final userSnap = await userRef.get();
      if (userSnap.exists) {
        if (_bookmarked) {
          await userRef.update({'bookmarks': FieldValue.arrayRemove([subjectPath])});
        } else {
          await userRef.update({'bookmarks': FieldValue.arrayUnion([subjectPath])});
        }
        _playAnim();
        setState(() {
          _bookmarked = !_bookmarked;
          _loadingBookmark = false;
        });
        _showBookmarkToast(_bookmarked);
        return;
      }

      final staffSnap = await staffRef.get();
      if (staffSnap.exists) {
        if (_bookmarked) {
          await staffRef.update({'bookmarks': FieldValue.arrayRemove([subjectPath])});
        } else {
          await staffRef.update({'bookmarks': FieldValue.arrayUnion([subjectPath])});
        }
        _playAnim();
        setState(() {
          _bookmarked = !_bookmarked;
          _loadingBookmark = false;
        });
        _showBookmarkToast(_bookmarked);
        return;
      }

      // No profile doc exists — create it
      await userRef.set({
        'createdAt': FieldValue.serverTimestamp(),
        'email': user.email,
        'bookmarks': [_subjectDocPath],
      }, SetOptions(merge: true));

      _playAnim();
      setState(() {
        _bookmarked = true;
        _loadingBookmark = false;
      });
      _showBookmarkToast(true);
    } catch (e) {
      setState(() => _loadingBookmark = false);
      debugPrint('Bookmark update failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update bookmark')));
    }
  }

  void _playAnim() {
    _animCtrl.forward().then((_) => _animCtrl.reverse());
  }

  void _showBookmarkToast(bool added) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(added ? 'Bookmarked' : 'Removed bookmark'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const BookmarksScreen()));
          },
        ),
      ),
    );
  }

  String _buildUnitTitle(String docId, Map<String, dynamic>? data) {
    final unitField = data != null && data['unit'] is String ? (data['unit'] as String).trim() : '';
    final hours = (data != null && data['hours'] != null) ? data['hours'].toString().trim() : '';

    if (unitField.isNotEmpty) {
      final lower = unitField.toLowerCase();
      if (hours.isNotEmpty && !lower.contains('hr') && !lower.contains('hrs')) {
        return '$unitField ($hours Hrs)';
      }
      return unitField;
    }

    final idNumeric = int.tryParse(docId);
    final idLabel = idNumeric != null ? 'Unit $docId' : docId;
    if (hours.isNotEmpty) return '$idLabel ($hours Hrs)';
    return idLabel;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    final subjectDocRef = _subjectDocRef;
    final unitsCollection = subjectDocRef.collection('units');

    return Scaffold(
      body: Column(
        children: [
          // Top banner
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
            child: Container(
              width: double.infinity,
              color: primary,
              padding: const EdgeInsets.only(top: 80, bottom: 40),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Center(
                    child: Text(
                      widget.subjectName != null && widget.subjectName!.trim().isNotEmpty
                          ? widget.subjectName!
                          : widget.subjectId,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.95),
                      ),
                    ),
                  ),

                  // Bookmark icon
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: _loadingBookmark
                          ? const SizedBox(
                              height: 44,
                              width: 44,
                              child: Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                ),
                              ),
                            )
                          : ScaleTransition(
                              scale: _scaleAnim,
                              child: IconButton(
                                icon: Icon(
                                  _bookmarked ? Icons.bookmark : Icons.bookmark_outline,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                onPressed: _toggleBookmark,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Units list below
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: subjectDocRef.get(),
                builder: (context, subjectSnapshot) {
                  if (subjectSnapshot.hasError) {
                    return Center(child: Text('Error: ${subjectSnapshot.error}'));
                  }

                  if (subjectSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final sdoc = subjectSnapshot.data;
                  if (sdoc == null || !sdoc.exists) {
                    return Center(child: Text('Subject not found.'));
                  }

                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: unitsCollection.snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error loading units.'));
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data?.docs ?? [];

                      if (docs.isEmpty) {
                        return const Center(child: Text('No units available.'));
                      }

                      // Sort unit IDs numerically where possible
                      docs.sort((a, b) {
                        final ai = int.tryParse(a.id);
                        final bi = int.tryParse(b.id);
                        if (ai != null && bi != null) return ai.compareTo(bi);
                        return a.id.compareTo(b.id);
                      });

                      return ListView.separated(
                        itemCount: docs.length,
                        padding: const EdgeInsets.only(bottom: 16),
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data();
                          final content = (data != null && data['content'] is String) ? (data['content'] as String) : '';
                          final title = _buildUnitTitle(doc.id, data);

                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ExpansionTile(
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 20),
                                    tooltip: 'Copy content',
                                    onPressed: content.isNotEmpty
                                        ? () {
                                            Clipboard.setData(ClipboardData(text: content));
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Copied to clipboard!')),
                                            );
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: content.isNotEmpty
                                      ? Text(content, style: const TextStyle(fontSize: 15, height: 1.5))
                                      : Text('No content.', style: TextStyle(color: Colors.grey.shade600)),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
