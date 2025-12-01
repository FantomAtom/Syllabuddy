// lib/screens/verify_email_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syllabuddy/screens/main_shell.dart';
import 'package:syllabuddy/services/user_service.dart';
import 'login.dart';
import 'package:syllabuddy/services/pending_signup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// shared widgets / styles
import 'package:syllabuddy/theme.dart';
import 'package:syllabuddy/widgets/app_primary_button.dart';
import 'package:syllabuddy/styles/app_styles.dart';
import 'package:syllabuddy/widgets/starting_screens_header.dart';

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
      if (mounted) setState(() => _isSending = false);
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
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final headerGradient = AppStyles.primaryGradient(context);

    // responsive logo sizing
    double imgSize = MediaQuery.of(context).size.width * 0.24;
    imgSize = imgSize.clamp(64.0, 140.0);

    // use themed bright background for logo
    final logoBg = theme.logoBackground;

    return Scaffold(
      body: Column(
        children: [
          AppStartingHeader(
            title: 'Verify your email to proceed further',
            imgSize: imgSize,
          ),

          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Info card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("A verification email has been sent to:"),
                          const SizedBox(height: 8),
                          Text(widget.email, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 16),
                          Text(
                            "Tap the link in your email, then return and press \"I verified\".",
                            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8)),
                          ),

                          if (_message != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [primary.withOpacity(0.06), primary.withOpacity(0.02)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(_message!, style: const TextStyle(fontSize: 14)),
                            ),
                          ],

                          const SizedBox(height: 20),

                          // Buttons row
                          Row(
                            children: [
                              // Primary: I verified
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: AppPrimaryButton(
                                    text: _isChecking ? 'Checking…' : 'I verified',
                                    onPressed: _isChecking ? () {} : _checkEmailVerified,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Secondary: Resend
                              SizedBox(
                                width: 140,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: (_isSending || _cooldown > 0) ? null : _resend,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).cardColor,
                                    foregroundColor: primary,
                                    elevation: 0,
                                    side: BorderSide(color: primary.withOpacity(0.06)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: _isSending
                                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                      : Text(_cooldown > 0 ? "Resend (${_cooldown}s)" : "Resend"),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          Center(
                            child: TextButton(
                              onPressed: _cancel,
                              child: Text("Cancel and delete account", style: TextStyle(decoration: TextDecoration.underline, color: Theme.of(context).textTheme.bodyMedium?.color)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.center,
                    child: Text("Tip: Check your spam/promotions folder.", style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7))),
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
