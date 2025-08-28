// lib/services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final _db = FirebaseFirestore.instance;

  /// Returns user data from either `users` (students) or `staff_emails` (staff).
  /// Adds a `collection` field to the returned map indicating where it came from.
  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    // Try users collection first
    final userDoc = await _db.collection('users').doc(user.uid).get();
    if (userDoc.exists) {
      return {...userDoc.data()!, 'collection': 'users'};
    }

    // Fallback to staff_emails
    final staffDoc = await _db.collection('staff_emails').doc(user.uid).get();
    if (staffDoc.exists) {
      return {...staffDoc.data()!, 'collection': 'staff_emails'};
    }

    return null;
  }

  /// Create a student document under /users/{uid}
  static Future<void> createStudent(String uid, Map<String, dynamic> data) {
    return _db.collection('users').doc(uid).set({
      ...data,
      'role': 'student',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Create a staff request/document under /staff_emails/{uid}
  static Future<void> createStaff(String uid, Map<String, dynamic> data) {
    return _db.collection('staff_emails').doc(uid).set({
      ...data,
      'role': 'staff',
      'status': data['status'] ?? 'unverified',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream the staff_emails doc (null if doc does not exist)
  static Stream<Map<String, dynamic>?> streamStaff(String uid) {
    return _db.collection('staff_emails').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return {...snap.data()!, 'collection': 'staff_emails'};
    });
  }

  /// Stream the users doc (null if doc does not exist)
  static Stream<Map<String, dynamic>?> streamUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return {...snap.data()!, 'collection': 'users'};
    });
  }

  /// Update name in whichever collection the user exists in.
  static Future<void> updateName(String first, String last) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Try users
    final userDoc = await _db.collection('users').doc(user.uid).get();
    if (userDoc.exists) {
      return _db.collection('users').doc(user.uid).update({
        'firstName': first,
        'lastName': last,
      });
    }

    // Try staff
    final staffDoc = await _db.collection('staff_emails').doc(user.uid).get();
    if (staffDoc.exists) {
      return _db.collection('staff_emails').doc(user.uid).update({
        'firstName': first,
        'lastName': last,
      });
    }
  }

  /// Remove documents from both collections (if present) and delete the auth user.
  static Future<void> deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _db.collection('users').doc(user.uid).delete().catchError((_) {});
    await _db.collection('staff_emails').doc(user.uid).delete().catchError((_) {});
    await user.delete();
  }
}
