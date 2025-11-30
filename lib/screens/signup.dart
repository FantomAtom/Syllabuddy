// lib/screens/signup.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syllabuddy/screens/main_shell.dart';
import 'login.dart';
import 'package:syllabuddy/services/user_service.dart';

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

  String _role = 'student';

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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
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
      case 'operation-not-allowed':
        return 'This operation is not allowed. Contact support.';
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

    final roleToWrite = _role; // student or staff

    try {
      // create auth user
      final userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // get the user (might be immediately available)
      var user = userCred.user ?? FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Authentication did not return a user.');

      // force token refresh / reload to avoid the auth -> firestore race
      await user.reload();
      user = FirebaseAuth.instance.currentUser;
      await user?.getIdToken(true);

      final uid = user!.uid;

      // Use UserService so we always write to the correct collection/shape
      if (roleToWrite == 'student') {
        await UserService.createStudent(uid, {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'studentId': studentId,
        });
      } else {
        await UserService.createStaff(uid, {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          // status default 'unverified' will be applied by createStaff if omitted
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account created: ${user.email}')));

      // navigate into MainShell
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      _setError(_mapSignUpException(e));
    } catch (e, st) {
      debugPrint('Unexpected error during signup: $e');
      debugPrint('$st');
      _setError('Unexpected error: $e');

      // rollback created auth user if exists
      try {
        final cur = FirebaseAuth.instance.currentUser;
        if (cur != null) {
          await cur.delete();
          debugPrint('Rolled back created auth user due to error.');
        }
      } catch (rbErr) {
        debugPrint('Rollback failed: $rbErr');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    // small, responsive image size: proportional to screen but clamped
    double imgSize = MediaQuery.of(context).size.width * 0.28;
    if (imgSize < 80) imgSize = 80;
    if (imgSize > 160) imgSize = 160;

    return Scaffold(
      body: Column(
        children: [
          // Header (gradient + text left, icon right)
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 80, bottom: 40, left: 20, right: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColorDark,
                    Theme.of(context).primaryColor,
                  ],
                  stops: const [0.0, 0.8],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Text block on the left
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Create an Account!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Sign up',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Icon on the right with circular border + shadow (matching login)
                  Container(
                    width: imgSize,
                    height: imgSize,
                    margin: const EdgeInsets.only(left: 16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                      color: Colors.white,
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Image.asset(
                          'assets/icon.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_errorMessage != null && _errorMessage!.isNotEmpty)
            Container(
              width: double.infinity,
              color: Colors.red.withOpacity(0.06),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Text(_errorMessage!,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
            ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameCtrl,
                            decoration: InputDecoration(
                                hintText: 'First Name',
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none)),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Enter first name' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameCtrl,
                            decoration: InputDecoration(
                                hintText: 'Last Name',
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none)),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Enter last name' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                          hintText: 'Email',
                          filled: true,
                          fillColor: Colors.grey[100],
                          prefixIcon: Icon(Icons.email, color: primary),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none)),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter email';
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                          hintText: 'Password (min 6 chars)',
                          filled: true,
                          fillColor: Colors.grey[100],
                          prefixIcon: Icon(Icons.lock, color: primary),
                          suffixIcon: IconButton(
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () => setState(() =>
                                  _obscurePassword = !_obscurePassword)),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none)),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter password';
                        if (v.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _studentIdCtrl,
                      decoration: InputDecoration(
                          hintText: 'Student ID (optional)',
                          filled: true,
                          fillColor: Colors.grey[100],
                          prefixIcon: Icon(Icons.perm_identity, color: primary),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none)),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _role,
                      items: const [
                        DropdownMenuItem(value: 'student', child: Text('Student')),
                        DropdownMenuItem(value: 'staff', child: Text('Staff')),
                      ],
                      onChanged: (v) => setState(() => _role = v ?? 'student'),
                      decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none)),
                    ),
                    const SizedBox(height: 32),

                    // Gradient button (matches login)
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).primaryColorDark,
                              Theme.of(context).primaryColor,
                            ],
                            stops: const [0.0, 0.6],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Create Account'),
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
                                MaterialPageRoute(builder: (_) => const LoginPage())),
                            child: Text('Login',
                                style: TextStyle(
                                    color: primary,
                                    fontWeight: FontWeight.bold))),
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
