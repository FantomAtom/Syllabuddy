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

    return Scaffold(
      body: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
            child: Container(
              width: double.infinity,
              color: primary,
              padding: const EdgeInsets.only(top: 80, bottom: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/icon.png', height: 100),
                  const SizedBox(height: 16),
                  Text('Welcome back!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.9))),
                  const SizedBox(height: 20),
                  Text('Login', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.9))),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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

                    const SizedBox(height: 8),

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
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Login'),
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
