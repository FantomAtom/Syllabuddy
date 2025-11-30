import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syllabuddy/screens/main_shell.dart';
import 'signup.dart';
import 'degree_screen.dart'; // CoursesScreen
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;
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

      // ✅ Save login state locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      final current = credential.user;
      if (current == null) {
        throw FirebaseAuthException(code: 'user-not-found', message: 'Sign-in failed.');
      }

      // Firestore profile read (non-fatal)
      String role = 'student';
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(current.uid).get();
        if (doc.exists) {
          final data = doc.data();
          final fetchedRole = data?['role'];
          if (fetchedRole is String && fetchedRole.isNotEmpty) role = fetchedRole;
        }
      } catch (fsErr) {
        debugPrint('Firestore read failed: $fsErr — will continue as student.');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signed in as ${current.email}')),
      );

      // ✅ Instead of CoursesScreen → go to MainShell
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
          ClipRRect(
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 80, bottom: 40, left: 20, right: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColorDark,  // darker (your 700)
                    Theme.of(context).primaryColor,      // main primary (your 500)
                  ],
                  stops: [0.0, 0.8],   // primary occupies from 0.0..0.7 -> appears larger
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              // Use a Row so text is left and icon is right (side-by-side)
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Text block on the left (takes remaining space)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Welcome back!',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Icon on the right with circular border + shadow
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
                          offset: const Offset(0, 4),
                        ),
                      ],
                      // fallback color while image loads
                      color: Colors.white,
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(2), // small padding between border and image
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
              child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
            ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Enter your email',
                        filled: true,
                        fillColor: Colors.grey[100],
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

                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        filled: true,
                        fillColor: Colors.grey[100],
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

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () async {
                          final email = _emailCtrl.text.trim();
                          if (email.isEmpty) {
                            _setError('Enter your email to reset password.');
                            return;
                          }
                          try {
                            await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                            _setError('Password reset email sent to $email');
                          } on FirebaseAuthException catch (e) {
                            _setError(e.message ?? 'Failed to send reset email.');
                          }
                        },
                        style: TextButton.styleFrom(foregroundColor: primary),
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).primaryColorDark,
                              Theme.of(context).primaryColor,
                            ],
                            stops: [0.0, 0.6],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
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
                              : Text(
                                  'Login',
                                  style: const TextStyle(
                                    fontSize: 16,   // change to your liking
                                  ),
                                ),        
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

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
