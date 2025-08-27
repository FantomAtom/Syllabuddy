// lib/screens/signup.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'login.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _studentIdCtrl = TextEditingController();

  static const double _mobileBreakpoint = 600;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _studentIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < _mobileBreakpoint) {
        return _mobileView(context, primary);
      } else {
        return _desktopView(context, primary, constraints.maxWidth);
      }
    });
  }

  Widget _mobileView(BuildContext context, Color primary) {
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
                  const SizedBox(height: 16),
                  Text('Sign up', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.95))),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(children: [
                      Expanded(child: _textField(_firstNameCtrl, 'First Name', primary)),
                      const SizedBox(width: 12),
                      Expanded(child: _textField(_lastNameCtrl, 'Last Name', primary)),
                    ]),
                    const SizedBox(height: 16),
                    _textField(_emailCtrl, 'Email', primary, prefix: Icons.email, keyboard: TextInputType.emailAddress),
                    const SizedBox(height: 16),
                    _passwordField(_passwordCtrl, 'Password', primary),
                    const SizedBox(height: 16),
                    _textField(_studentIdCtrl, 'Student ID (optional)', primary, prefix: Icons.perm_identity),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _onCreateAccount,
                        style: ElevatedButton.styleFrom(backgroundColor: primary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text('Create Account'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Text('Already have an account? '),
                      GestureDetector(onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage())), child: Text('Login', style: TextStyle(color: primary, fontWeight: FontWeight.bold))),
                    ]),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _desktopView(BuildContext context, Color primary, double width) {
    final double screenH = MediaQuery.of(context).size.height;
    final double fullHeight = screenH;

    return Scaffold(
      body: SizedBox(
        height: fullHeight,
        child: Row(
          children: [
            // left hero
            Expanded(
              flex: 5,
              child: Container(
                color: primary,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 48),
                child: Column(
                  children: [
                    Align(alignment: Alignment.topLeft, child: Text('Syllabuddy', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 18),
                    Expanded(
                      child: Center(
                        child: FractionallySizedBox(
                          widthFactor: 0.9,
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Image.asset('assets/landing.png', height: 320, fit: BoxFit.contain),
                            const SizedBox(height: 20),
                            Text('Join thousands of students staying organized', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 18)),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Free for students', style: TextStyle(color: Colors.white.withOpacity(0.85))),
                  ],
                ),
              ),
            ),

             Expanded(
              flex: 6,
              child: Container(
                color: Colors.grey[50],
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 56),
                child: Align( // 👈 added
                  alignment: const Alignment(0, 5.0), // 👈 pushes form down a bit
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: SizedBox(
                      height: fullHeight - kToolbarHeight - 80,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Create your account', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text('Sign up and get started with Syllabuddy', style: TextStyle(color: Colors.grey[700])),
                            const SizedBox(height: 20),
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  Row(children: [
                                    Expanded(child: _textField(_firstNameCtrl, 'First Name', primary)),
                                    const SizedBox(width: 12),
                                    Expanded(child: _textField(_lastNameCtrl, 'Last Name', primary)),
                                  ]),
                                  const SizedBox(height: 16),
                                  _textField(_emailCtrl, 'Email', primary, prefix: Icons.email, keyboard: TextInputType.emailAddress),
                                  const SizedBox(height: 16),
                                  _passwordField(_passwordCtrl, 'Password', primary),
                                  const SizedBox(height: 16),
                                  _textField(_studentIdCtrl, 'Student ID (optional)', primary, prefix: Icons.perm_identity),
                                  const SizedBox(height: 22),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _onCreateAccount,
                                      style: ElevatedButton.styleFrom(backgroundColor: primary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                      child: const Text('Create Account'),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    const Text('Already have an account? '),
                                    GestureDetector(onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage())), child: Text('Login', style: TextStyle(color: primary, fontWeight: FontWeight.bold))),
                                  ]),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // small helpers
  Widget _textField(TextEditingController ctrl, String hint, Color primary, {IconData? prefix, TextInputType? keyboard}) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.black.withOpacity(0.45)),
        filled: true,
        fillColor: Colors.grey[100],
        prefixIcon: prefix != null ? Icon(prefix, color: primary) : null,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      keyboardType: keyboard,
      validator: (v) {
        if (hint == 'Student ID (optional)') return null;
        return (v == null || v.isEmpty) ? 'Enter ${hint.toLowerCase()}' : null;
      },
    );
  }

  Widget _passwordField(TextEditingController ctrl, String hint, Color primary) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.black.withOpacity(0.45)),
        filled: true,
        fillColor: Colors.grey[100],
        prefixIcon: Icon(Icons.lock, color: primary),
        suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      obscureText: _obscurePassword,
      validator: (v) => (v == null || v.isEmpty) ? 'Enter password' : null,
    );
  }

  void _onCreateAccount() {
    if (_formKey.currentState?.validate() == true) {
      // TODO: actual signup logic
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
    }
  }
}
