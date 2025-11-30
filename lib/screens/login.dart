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

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      final current = credential.user;
      if (current == null) {
        throw FirebaseAuthException(code: 'user-not-found', message: 'Sign-in failed.');
      }

      String role = 'student';
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(current.uid).get();
        if (doc.exists) {
          final data = doc.data();
          final fetchedRole = data?['role'];
          if (fetchedRole is String && fetchedRole.isNotEmpty) role = fetchedRole;
        }
      } catch (fsErr) {
        debugPrint('Firestore read failed: $fsErr — continuing as student.');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signed in as ${current.email}')),
      );

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

  /// Improved reset flow:
  /// 1) Try Firestore lookup for email
  /// 2) If lookup finds user -> send password reset email
  /// 3) If lookup finds no user -> show explicit "No account found"
  /// 4) If lookup fails (network/permission), FALLBACK to sendPasswordResetEmail
  ///    but show a privacy-preserving message ("If an account exists...") to avoid
  ///    revealing whether the email is registered.
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
        // attempt Firestore lookup
        query = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        debugPrint('Firestore lookup succeeded. docs=${query.docs.length}');
      } on FirebaseException catch (fe) {
        // Firestore-specific issue (permission-denied, unavailable, network, etc)
        debugPrint('Firestore lookup failed with FirebaseException: ${fe.code} ${fe.message}');
        // Fallback: attempt to send reset email using FirebaseAuth but show generic message
        try {
          await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
          // privacy-preserving message: don't reveal existence
          _setError('If an account exists for that email, a password reset link was sent. Check your inbox (and spam).');
        } on FirebaseAuthException catch (ae) {
          debugPrint('sendPasswordResetEmail failed after Firestore error: ${ae.code} ${ae.message}');
          // Map auth exceptions where appropriate
          _setError(_mapAuthException(ae));
        } catch (e) {
          debugPrint('Unexpected error sending reset email after Firestore failure: $e');
          _setError('Unable to send reset email right now. Try again later.');
        } finally {
          if (mounted) setState(() => _isSendingReset = false);
        }
        return; // finished fallback path
      }

      // If query succeeded: check results
      if (query.docs.isEmpty) {
        // No user doc found -> show explicit message
        _setError('No account found with that email.');
        return;
      }

      // User doc exists -> now call FirebaseAuth to send the reset email
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
      // Generic fallback for any other unexpected error
      debugPrint('Unexpected error in reset flow: $e\n$st');
      _setError('Unable to verify user right now. Try again later.');
    } finally {
      if (mounted) setState(() => _isSendingReset = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Welcome back!',
                          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Login',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: imgSize,
                    height: imgSize,
                    margin: const EdgeInsets.only(left: 16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 8, offset: const Offset(0, 4))],
                      color: const Color.fromARGB(255, 121, 194, 150),
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Image.asset('assets/logo-transparent.png', fit: BoxFit.cover),
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
                        onPressed: _isSendingReset ? null : _sendPasswordResetEmail,
                        style: TextButton.styleFrom(foregroundColor: primary),
                        child: _isSendingReset
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Forgot Password?'),
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
                            stops: const [0.0, 0.5],
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
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Login', style: TextStyle(fontSize: 16)),
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
