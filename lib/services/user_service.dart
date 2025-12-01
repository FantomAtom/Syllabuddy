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

  /// Delete user profile docs (users & staff_emails) then delete auth account.
  /// MUST be called after successful reauthentication (or when auth.delete won't throw).
  static Future<void> deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final userRef = _db.collection('users').doc(uid);
    final staffRef = _db.collection('staff_emails').doc(uid);

    // Get documents first so we know what to delete
    final userDoc = await userRef.get();
    final staffDoc = await staffRef.get();

    // Use a batch so deletes happen together
    final batch = _db.batch();
    if (userDoc.exists) batch.delete(userRef);
    if (staffDoc.exists) batch.delete(staffRef);

    // Commit batch (no-op if there are no deletes)
    if (userDoc.exists || staffDoc.exists) {
      await batch.commit();
    }

    // Now delete auth user
    // This will fail with requires-recent-login if user hasn't recently authenticated
    await user.delete();
  }

    /// Returns true if either users/{uid} or staff_emails/{uid} exists
  static Future<bool> profileExists(String uid) async {
    final userDoc = await _db.collection('users').doc(uid).get();
    if (userDoc.exists) return true;
    final staffDoc = await _db.collection('staff_emails').doc(uid).get();
    return staffDoc.exists;
  }

}
