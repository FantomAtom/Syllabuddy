import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';
import 'degree_screen.dart';

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

  UserCredential? createdUser;
  try {
    // Attempt to create user (this may THROW the pigeon type error even after auth succeeds)
    try {
      createdUser = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
    } catch (innerErr, innerStack) {
      // log and continue — we'll check currentUser below
      debugPrint('createUserWithEmail error (inner): $innerErr');
      debugPrint('$innerStack');
    }

    // IMPORTANT: check currentUser as definitive sign of success
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) {
      // Auth did NOT succeed
      throw Exception('Authentication failed (no currentUser).');
    }

    final uid = current.uid;
    debugPrint('Auth succeeded for uid=$uid (using currentUser fallback).');

    // Write profile to Firestore
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    await userRef.set({
      'firstName': _firstNameCtrl.text.trim(),
      'lastName': _lastNameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'studentId': _studentIdCtrl.text.trim().isEmpty ? null : _studentIdCtrl.text.trim(),
      'role': _role,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Account created: ${current.email}')));

    if (_role == 'student') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CoursesScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff account created — add staff page.')));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
    }
  } on FirebaseAuthException catch (e) {
    _setError(_mapSignUpException(e));
  } catch (e, st) {
    debugPrint('Unexpected error during signup: $e');
    debugPrint('$st');
    _setError('Unexpected error: $e');
    // Attempt rollback: delete created auth user if any
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
                  Text('Create an Account!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.9))),
                  const SizedBox(height: 20),
                  Text('Sign up', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.9))),
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
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameCtrl,
                            decoration: InputDecoration(hintText: 'First Name', filled: true, fillColor: Colors.grey[100], contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                            validator: (v) => (v == null || v.isEmpty) ? 'Enter first name' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameCtrl,
                            decoration: InputDecoration(hintText: 'Last Name', filled: true, fillColor: Colors.grey[100], contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                            validator: (v) => (v == null || v.isEmpty) ? 'Enter last name' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(hintText: 'Email', filled: true, fillColor: Colors.grey[100], prefixIcon: Icon(Icons.email, color: primary), contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter email';
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(hintText: 'Password (min 6 chars)', filled: true, fillColor: Colors.grey[100], prefixIcon: Icon(Icons.lock, color: primary), suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)), contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter password';
                        if (v.length < 6) return 'Password must be at least 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _studentIdCtrl,
                      decoration: InputDecoration(hintText: 'Student ID (optional)', filled: true, fillColor: Colors.grey[100], prefixIcon: Icon(Icons.perm_identity, color: primary), contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _role,
                      decoration: InputDecoration(filled: true, fillColor: Colors.grey[100], contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                      items: const [
                        DropdownMenuItem(value: 'student', child: Text('Student')),
                        DropdownMenuItem(value: 'staff', child: Text('Staff')),
                      ],
                      onChanged: (v) => setState(() => _role = v ?? 'student'),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signUp,
                        style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: _isLoading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Create Account'),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have an account? "),
                        GestureDetector(onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage())), child: Text('Login', style: TextStyle(color: primary, fontWeight: FontWeight.bold))),
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
