// lib/screens/login.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syllabuddy/screens/main_shell.dart';
import 'signup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syllabuddy/theme.dart';   // REQUIRED for logoBackground
import 'verify_email_page.dart';
import 'package:syllabuddy/services/pending_signup_service.dart';
import 'package:syllabuddy/services/user_service.dart';

// shared widgets / styles
import 'package:syllabuddy/widgets/app_primary_button.dart';
import 'package:syllabuddy/styles/app_styles.dart';
import 'package:syllabuddy/widgets/starting_screens_header.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isSendingReset = false;
  String? _errorMessage;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _setError(String? msg) {
    if (!mounted) return;
    setState(() => _errorMessage = msg);
    if (msg != null && msg.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  String _mapAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with that email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'That email address is invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return e.message ?? 'Login failed. Try again.';
    }
  }

  Future<void> _login() async {
    _setError(null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );

      final current = credential.user;
      if (current == null) {
        throw FirebaseAuthException(code: 'user-not-found', message: 'Sign-in failed.');
      }

      // reload to ensure we have latest emailVerified state
      await current.reload();
      final refreshed = FirebaseAuth.instance.currentUser;

      // If email not verified -> redirect to verify flow (do not go to MainShell)
      if (refreshed != null && !refreshed.emailVerified) {
        final pending = await PendingSignupService.readPending();

        if (!mounted) return;
        if (pending != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => VerifyEmailPage(
                email: pending['email'] as String,
                firstName: pending['firstName'] as String,
                lastName: pending['lastName'] as String,
                studentId: pending['studentId'] as String?,
                role: pending['role'] as String,
              ),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => VerifyEmailPage(
                email: refreshed.email ?? '',
                firstName: '',
                lastName: '',
                studentId: null,
                role: 'student',
              ),
            ),
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please verify your email before continuing.')));
        }
        return;
      }

      // At this point user is signed in and emailVerified == true.
      // Ensure Firestore profile exists; if not, try to create from pending signup.
      String role = 'student';
      final uid = current.uid;
      final db = FirebaseFirestore.instance;

      try {
        final userDocSnap = await db.collection('users').doc(uid).get();
        final staffDocSnap = await db.collection('staff_emails').doc(uid).get();

        if (userDocSnap.exists) {
          final data = userDocSnap.data();
          final fetchedRole = data?['role'];
          if (fetchedRole is String && fetchedRole.isNotEmpty) role = fetchedRole;
        } else if (staffDocSnap.exists) {
          final data = staffDocSnap.data();
          final fetchedRole = data?['role'];
          if (fetchedRole is String && fetchedRole.isNotEmpty) role = fetchedRole;
        } else {
          // No profile in Firestore — attempt to create from local pending signup if present
          final pending = await PendingSignupService.readPending();
          if (pending != null) {
            final pendingRole = (pending['role'] as String?) ?? 'student';
            if (pendingRole == 'student') {
              try {
                await UserService.createStudent(uid, {
                  'firstName': pending['firstName'] as String? ?? '',
                  'lastName': pending['lastName'] as String? ?? '',
                  'email': pending['email'] as String? ?? current.email,
                  'studentId': pending['studentId'] as String? ?? null,
                });
                role = 'student';
                await PendingSignupService.clearPending();
              } catch (e) {
                debugPrint('Failed to create student doc from pending: $e');
              }
            } else {
              try {
                await UserService.createStaff(uid, {
                  'firstName': pending['firstName'] as String? ?? '',
                  'lastName': pending['lastName'] as String? ?? '',
                  'email': pending['email'] as String? ?? current.email,
                });
                role = 'staff';
                await PendingSignupService.clearPending();
              } catch (e) {
                debugPrint('Failed to create staff doc from pending: $e');
              }
            }
          } else {
            // No pending data — create a minimal student profile so the app has something.
            try {
              await UserService.createStudent(uid, {
                'firstName': '',
                'lastName': '',
                'email': current.email ?? '',
                'studentId': null,
              });
              role = 'student';
            } catch (e) {
              debugPrint('Failed to create fallback minimal user doc: $e');
            }
          }
        }
      } catch (fsErr) {
        debugPrint('Firestore read/create failed: $fsErr — continuing to MainShell.');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Signed in as ${current.email}')));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } on FirebaseAuthException catch (e) {
      _setError(_mapAuthException(e));
    } catch (e, st) {
      debugPrint('Unexpected error during login: $e');
      debugPrint('$st');
      _setError('Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Improved reset flow (keeps your logic as-is)
  Future<void> _sendPasswordResetEmail() async {
    _setError(null);
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _setError('Enter your email to reset password.');
      return;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      _setError('Enter a valid email.');
      return;
    }

    setState(() => _isSendingReset = true);
    try {
      QuerySnapshot<Map<String, dynamic>> query;
      try {
        query = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: email).limit(1).get();
        debugPrint('Firestore lookup succeeded. docs=${query.docs.length}');
      } on FirebaseException catch (fe) {
        debugPrint('Firestore lookup failed with FirebaseException: ${fe.code} ${fe.message}');
        try {
          await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
          _setError('If an account exists for that email, a password reset link was sent. Check your inbox (and spam).');
        } on FirebaseAuthException catch (ae) {
          debugPrint('sendPasswordResetEmail failed after Firestore error: ${ae.code} ${ae.message}');
          _setError(_mapAuthException(ae));
        } catch (e) {
          debugPrint('Unexpected error sending reset email after Firestore failure: $e');
          _setError('Unable to send reset email right now. Try again later.');
        } finally {
          if (mounted) setState(() => _isSendingReset = false);
        }
        return;
      }

      if (query.docs.isEmpty) {
        _setError('No account found with that email.');
        return;
      }

      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
        _setError('Password reset email sent to $email. Check your inbox (and spam).');
      } on FirebaseAuthException catch (e) {
        debugPrint('sendPasswordResetEmail FirebaseAuthException: ${e.code} ${e.message}');
        _setError(_mapAuthException(e));
      } catch (e) {
        debugPrint('Unexpected error when sending reset email: $e');
        _setError('Failed to send reset email. Try again later.');
      }
    } catch (e, st) {
      debugPrint('Unexpected error in reset flow: $e\n$st');
      _setError('Unable to verify user right now. Try again later.');
    } finally {
      if (mounted) setState(() => _isSendingReset = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final headerGradient = AppStyles.primaryGradient(context);

    // responsive logo sizing
    double imgSize = MediaQuery.of(context).size.width * 0.28;
    if (imgSize < 80) imgSize = 80;
    if (imgSize > 160) imgSize = 160;

    // modern, safe text styles
    final titleStyle = theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold) ??
        const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white);
    final subtitleStyle = theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600) ??
        const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white);

    return Scaffold(
      body: Column(
        children: [
          // header
          AppStartingHeader(
            title: 'Welcome back!',
            subtitle: 'Login',
            imgSize: imgSize,
          ),

          // inline error message bar (if any)
          if (_errorMessage != null && _errorMessage!.isNotEmpty)
            Container(
              width: double.infinity,
              color: Colors.red.withOpacity(0.06),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
            ),

          // Form area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Email
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Enter your email',
                        filled: true,
                        fillColor: theme.inputDecorationTheme.fillColor,
                        prefixIcon: Icon(Icons.email, color: primary),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter your email';
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        filled: true,
                        fillColor: theme.inputDecorationTheme.fillColor,
                        prefixIcon: Icon(Icons.lock, color: primary),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey[600]),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
                    ),

                    const SizedBox(height: 10),

                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isSendingReset ? null : _sendPasswordResetEmail,
                        style: TextButton.styleFrom(foregroundColor: primary),
                        child: _isSendingReset
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Forgot Password?'),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Login primary button (AppPrimaryButton) - keeps your preferred sizing
                    SizedBox(
                      width: double.infinity,
                      child: AppPrimaryButton(
                        text: _isLoading ? 'Signing in...' : 'Login',
                        onPressed: _isLoading ? () {} : _login,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Register link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? "),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SignUpPage())),
                          child: Text('Register Now', style: TextStyle(color: primary, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
