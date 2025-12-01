// lib/screens/signup.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syllabuddy/screens/VerifyEmailPage.dart';
import 'login.dart';
import 'package:syllabuddy/services/pending_signup_service.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
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
      // This ensures we can finish profile creation after verification,
      // even if the app is closed and reopened.
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
        // not fatal; user can press resend from verify screen
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

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    double imgSize = MediaQuery.of(context).size.width * 0.28;
    imgSize = imgSize.clamp(80, 160);

    return Scaffold(
      body: Column(
        children: [
          // HEADER
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.only(top: 80, bottom: 40, left: 20, right: 20),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Create an Account!",
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Sign up",
                          style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: imgSize,
                    height: imgSize,
                    decoration: BoxDecoration(
                        color: const Color(0xFF79C296),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 8,
                              offset: const Offset(0, 4))
                        ]),
                    child: ClipOval(
                      child: Image.asset("assets/logo-transparent.png"),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_errorMessage != null)
            Container(
              color: Colors.red.withOpacity(0.08),
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w600),
              ),
            ),

          // FORM
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Names
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameCtrl,
                            decoration: _input("First Name"),
                            validator: (v) =>
                                v!.isEmpty ? "Enter first name" : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameCtrl,
                            decoration: _input("Last Name"),
                            validator: (v) =>
                                v!.isEmpty ? "Enter last name" : null,
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
                        if (v!.isEmpty) return "Enter email";
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                          return "Enter a valid email";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      decoration: _input("Password (min 6 chars)",
                          icon: Icons.lock,
                          suffix: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                          )),
                      validator: (v) =>
                          v!.length < 6 ? "Password too short" : null,
                    ),
                    const SizedBox(height: 16),

                    // Student ID
                    TextFormField(
                      controller: _studentIdCtrl,
                      decoration: _input("Student ID (optional)",
                          icon: Icons.perm_identity),
                    ),
                    const SizedBox(height: 16),

                    // Role dropdown
                    DropdownButtonFormField<String>(
                      value: _role,
                      items: const [
                        DropdownMenuItem(
                            value: "student", child: Text("Student")),
                        DropdownMenuItem(value: "staff", child: Text("Staff")),
                      ],
                      onChanged: (v) => setState(() => _role = v!),
                      decoration: _input("Role"),
                    ),
                    const SizedBox(height: 32),

                    // SIGN UP BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).primaryColorDark,
                              primary
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signUp,
                          style: ElevatedButton.styleFrom(
                            shadowColor: Colors.transparent,
                            backgroundColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2)
                              : const Text("Create Account",
                                  style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have an account? "),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginPage()),
                          ),
                          child: Text("Login",
                              style: TextStyle(
                                  color: primary, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  InputDecoration _input(String hint, {IconData? icon, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[100],
      prefixIcon: icon != null
          ? Icon(icon, color: Theme.of(context).primaryColor)
          : null,
      suffixIcon: suffix,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}
