// lib/screens/signup.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syllabuddy/screens/verify_email_page.dart';
import 'login.dart';
import 'package:syllabuddy/services/pending_signup_service.dart';

// theming / shared widgets
import 'package:syllabuddy/theme.dart';
import 'package:syllabuddy/widgets/app_primary_button.dart';
import 'package:syllabuddy/styles/app_styles.dart';
import 'package:syllabuddy/widgets/starting_screens_header.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _studentIdCtrl = TextEditingController();

  String _role = "student";

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _studentIdCtrl.dispose();
    super.dispose();
  }

  void _setError(String? msg) {
    if (!mounted) return;
    setState(() => _errorMessage = msg);
    if (msg != null && msg.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  String _mapSignUpException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account with that email already exists.';
      case 'invalid-email':
        return 'That email address is invalid.';
      case 'weak-password':
        return 'Password is too weak (min 6 characters).';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return e.message ?? 'Sign up failed. Try again.';
    }
  }

  Future<void> _signUp() async {
    _setError(null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final studentId =
        _studentIdCtrl.text.trim().isEmpty ? null : _studentIdCtrl.text.trim();
    final roleToWrite = _role;

    try {
      // Save pending signup locally BEFORE creating auth user.
      await PendingSignupService.savePending(
        email: email,
        firstName: firstName,
        lastName: lastName,
        studentId: studentId,
        role: roleToWrite,
      );

      // Create Firebase Auth user only (do NOT write to Firestore here).
      final userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      var user = userCred.user ?? FirebaseAuth.instance.currentUser;

      if (user == null) throw Exception("No user returned from Firebase");

      // Reload to ensure fresh token/state
      await user.reload();
      user = FirebaseAuth.instance.currentUser;
      await user?.getIdToken(true);

      // Send verification email (best-effort)
      try {
        if (user != null && !user.emailVerified) {
          await user.sendEmailVerification();
        }
      } catch (e) {
        debugPrint("Verification email failed: $e");
      }

      if (!mounted) return;

      // Navigate to verify page WITH the pending info (so user can resend / continue)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyEmailPage(
            email: email,
            firstName: firstName,
            lastName: lastName,
            studentId: studentId,
            role: roleToWrite,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      // If auth creation failed, remove pending saved earlier to avoid staleness.
      try {
        await PendingSignupService.clearPending();
      } catch (_) {}
      _setError(_mapSignUpException(e));
    } catch (e, st) {
      debugPrint("Unexpected error: $e");
      debugPrint("$st");
      _setError("Unexpected error: $e");
      try {
        await PendingSignupService.clearPending();
      } catch (_) {}
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _input(String hint, {IconData? icon, Widget? suffix}) {
    final fill = Theme.of(context).inputDecorationTheme.fillColor;
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: fill,
      prefixIcon: icon != null ? Icon(icon, color: Theme.of(context).primaryColor) : null,
      suffixIcon: suffix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final headerGradient = AppStyles.primaryGradient(context);

    // responsive logo sizing (same logic as login)
    double imgSize = MediaQuery.of(context).size.width * 0.28;
    imgSize = imgSize.clamp(80.0, 160.0);

    // themed bright logo background (from theme extension)
    final logoBg = theme.logoBackground;

    return Scaffold(
      body: Column(
        children: [
          AppStartingHeader(
            title: 'Create an Account!',
            subtitle: 'Sign up',
            imgSize: imgSize,
          ),

          // inline error bar (if any)
          if (_errorMessage != null && _errorMessage!.isNotEmpty)
            Container(
              width: double.infinity,
              color: Colors.red.withOpacity(0.08),
              padding: const EdgeInsets.all(12),
              child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
            ),

          // FORM
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Names row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameCtrl,
                            decoration: _input("First Name"),
                            validator: (v) => v == null || v.isEmpty ? "Enter first name" : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameCtrl,
                            decoration: _input("Last Name"),
                            validator: (v) => v == null || v.isEmpty ? "Enter last name" : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _input("Email", icon: Icons.email),
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Enter email";
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return "Enter a valid email";
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      decoration: _input(
                        "Password (min 6 chars)",
                        icon: Icons.lock,
                        suffix: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6) ? "Password too short" : null,
                    ),
                    const SizedBox(height: 16),

                    // Student ID
                    TextFormField(
                      controller: _studentIdCtrl,
                      decoration: _input("Student ID (optional)", icon: Icons.perm_identity),
                    ),
                    const SizedBox(height: 16),

                    // Role dropdown
                    DropdownButtonFormField<String>(
                      value: _role,
                      items: const [
                        DropdownMenuItem(value: "student", child: Text("Student")),
                        DropdownMenuItem(value: "staff", child: Text("Staff")),
                      ],
                      onChanged: (v) => setState(() => _role = v ?? "student"),
                      decoration: _input("Role"),
                    ),
                    const SizedBox(height: 24),

                    // Primary CTA (AppPrimaryButton - keeps sizing consistent)
                    SizedBox(
                      width: double.infinity,
                      child: _isLoading
                          ? Container(
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: AppStyles.primaryGradient(context),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))),
                            )
                          : SizedBox(
                              height: 52,
                              child: AppPrimaryButton(
                                text: "Create Account",
                                onPressed: _signUp,
                              ),
                            ),
                    ),

                    const SizedBox(height: 20),

                    // Link to login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have an account? "),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage())),
                          child: Text("Login", style: TextStyle(color: primary, fontWeight: FontWeight.bold)),
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
