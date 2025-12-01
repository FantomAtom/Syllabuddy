// lib/screens/verify_email_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syllabuddy/screens/main_shell.dart';
import 'package:syllabuddy/services/user_service.dart';
import 'login.dart';
import 'package:syllabuddy/services/pending_signup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VerifyEmailPage extends StatefulWidget {
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String? studentId;

  const VerifyEmailPage({
    Key? key,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.studentId,
  }) : super(key: key);

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool _isChecking = false;
  bool _isSending = false;
  Timer? _pollTimer;
  int _cooldown = 0;
  String? _message;

  @override
  void initState() {
    super.initState();
    // start polling every 5s to auto-detect verification
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkEmailVerified();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerified() async {
    if (_isChecking) return;

    setState(() => _isChecking = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // no signed-in user; nothing to check
        return;
      }

      await user.reload();
      final refreshed = FirebaseAuth.instance.currentUser;

      if (refreshed != null && refreshed.emailVerified) {
        _pollTimer?.cancel();

        // WRITE DATA TO FIRESTORE NOW (finalize)
        try {
          await _finalizeAccount(refreshed.uid);
        } catch (e) {
          debugPrint('Finalize failed: $e');
          // If finalization fails, don't navigate into the app.
          if (mounted) {
            setState(() => _message = 'Failed to finalize account: $e');
          }
          return;
        }

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainShell()),
          (_) => false,
        );
      }
    } catch (e) {
      debugPrint("Verify check failed: $e");
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _finalizeAccount(String uid) async {
    try {
      if (widget.role == "student") {
        await UserService.createStudent(uid, {
          "firstName": widget.firstName,
          "lastName": widget.lastName,
          "email": widget.email,
          "studentId": widget.studentId,
        });
      } else {
        await UserService.createStaff(uid, {
          "firstName": widget.firstName,
          "lastName": widget.lastName,
          "email": widget.email,
        });
      }

      // Clear local pending state
      await PendingSignupService.clearPending();

      // Set logged-in flag so root decider / prefs logic knows user is onboarded
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
    } catch (e) {
      debugPrint("Firestore finalization failed: $e");
      // bubble up so caller can decide not to navigate
      rethrow;
    }
  }

  Future<void> _resend() async {
    if (_cooldown > 0) return;
    setState(() => _isSending = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
      }

      setState(() {
        _message = "Verification email resent!";
        _cooldown = 30;
      });

      Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() => _cooldown--);

        if (_cooldown <= 0) timer.cancel();
      });
    } catch (e) {
      debugPrint("Resend failed: $e");
      setState(() => _message = "Failed to resend email.");
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _cancel() async {
    try {
      // clear any saved pending signup data
      await PendingSignupService.clearPending();

      // attempt to delete the auth user we created (may require recent login)
      await FirebaseAuth.instance.currentUser?.delete();
    } catch (_) {
      // ignore - may fail if requires recent auth
    }

    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    double imgSize = MediaQuery.of(context).size.width * 0.24;
    imgSize = imgSize.clamp(64, 140);

    return Scaffold(
      body: Column(
        children: [
          // HEADER
          ClipRRect(
            borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40)),
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.only(top: 80, bottom: 36, left: 20, right: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColorDark,
                    primary,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Verify your email",
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  Container(
                    width: imgSize,
                    height: imgSize,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF79C296),
                    ),
                    child: ClipOval(
                      child: Image.asset("assets/logo-transparent.png"),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("A verification email has been sent to:"),
                          const SizedBox(height: 8),
                          Text(widget.email,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 16),
                          Text(
                              "Tap the link in your email, then return and press \"I verified — continue\".",
                              style: TextStyle(color: Colors.grey[700])),

                          if (_message != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child:
                                  Text(_message!, style: const TextStyle(fontSize: 14)),
                            ),
                          ],

                          const SizedBox(height: 20),

                          // BUTTONS
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Theme.of(context).primaryColorDark,
                                        primary,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isChecking
                                        ? null
                                        : () => _checkEmailVerified(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: _isChecking
                                        ? const CircularProgressIndicator(
                                            color: Colors.white, strokeWidth: 2)
                                        : const Text("I verified — continue"),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 130,
                                child: ElevatedButton(
                                  onPressed: (_isSending || _cooldown > 0)
                                      ? null
                                      : _resend,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[200],
                                    foregroundColor: primary,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  child: _isSending
                                      ? const CircularProgressIndicator(
                                          strokeWidth: 2)
                                      : Text(_cooldown > 0
                                          ? "Resend (${_cooldown}s)"
                                          : "Resend"),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),
                          Center(
                            child: TextButton(
                              onPressed: _cancel,
                              child: const Text("Cancel and delete account",
                                  style: TextStyle(
                                      decoration: TextDecoration.underline)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),
                  Text(
                    "Tip: Check your spam/promotions folder.",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
