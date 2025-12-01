// lib/services/pending_signup_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class PendingSignupService {
  static const _kEmail = 'pending_signup_email';
  static const _kFirst = 'pending_signup_first';
  static const _kLast = 'pending_signup_last';
  static const _kStudent = 'pending_signup_student';
  static const _kRole = 'pending_signup_role';

  /// Save the pending signup details locally (used until email is verified).
  static Future<void> savePending({
    required String email,
    required String firstName,
    required String lastName,
    String? studentId,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kEmail, email);
    await prefs.setString(_kFirst, firstName);
    await prefs.setString(_kLast, lastName);
    if (studentId != null && studentId.isNotEmpty) {
      await prefs.setString(_kStudent, studentId);
    } else {
      await prefs.remove(_kStudent);
    }
    await prefs.setString(_kRole, role);
  }

  /// Return the saved pending details (or null if none).
  static Future<Map<String, dynamic>?> readPending() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_kEmail);
    if (email == null || email.isEmpty) return null;
    return {
      'email': email,
      'firstName': prefs.getString(_kFirst) ?? '',
      'lastName': prefs.getString(_kLast) ?? '',
      'studentId': prefs.getString(_kStudent),
      'role': prefs.getString(_kRole) ?? 'student',
    };
  }

  /// Convenience: check whether a pending signup exists.
  static Future<bool> hasPending() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_kEmail);
    return email != null && email.isNotEmpty;
  }

  /// Remove pending signup data.
  static Future<void> clearPending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kEmail);
    await prefs.remove(_kFirst);
    await prefs.remove(_kLast);
    await prefs.remove(_kStudent);
    await prefs.remove(_kRole);
  }
}
