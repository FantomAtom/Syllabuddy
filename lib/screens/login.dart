// lib/screens/login.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:syllabuddy/screens/degree_screen.dart';
import 'signup.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  static const double _mobileBreakpoint = 600;

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

  // ---------------- Mobile: keep your original curved banner look ----------------
  Widget _mobileView(BuildContext context, Color primary) {
    return Scaffold(
      body: Column(
        children: [
          // Curved banner (unchanged look)
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
            child: Container(
              width: double.infinity,
              color: primary,
              padding: const EdgeInsets.only(top: 80, bottom: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/icon.png', height: 100),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome back!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.95),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _emailField(primary),
                    const SizedBox(height: 16),
                    _passwordField(primary),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(foregroundColor: primary),
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _onLoginPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Login'),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? "),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const SignUpPage()),
                          ),
                          child: Text(
                            'Register Now',
                            style: TextStyle(color: primary, fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Desktop / Web: full page layout ----------------
  Widget _desktopView(BuildContext context, Color primary, double width) {
    final double screenH = MediaQuery.of(context).size.height;
    final double fullHeight = screenH; // use full viewport height

    // left-right split; left: hero, right: form (full-height)
    return Scaffold(
      body: SizedBox(
        height: fullHeight, // content fills remaining viewport
        width: double.infinity,
        child: Row(
          children: [
            // LEFT: hero panel (strong color, tagline)
            Expanded(
              flex: 5,
              child: Container(
                color: primary,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // top-left small title repeated (subtle)
                    Text('Syllabuddy',
                        style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 18),
                    Expanded(
                      child: Center(
                        child: FractionallySizedBox(
                          widthFactor: 0.9,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset('assets/landing.png', fit: BoxFit.contain, height: 320),
                              const SizedBox(height: 20),
                              Text(
                                'Organize. Study. Succeed.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 18),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // optional footer / small note
                    Text('Built for students', style: TextStyle(color: Colors.white.withOpacity(0.85))),
                  ],
                ),
              ),
            ),

            // RIGHT: form panel (full-height, neat website form)
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
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Welcome back', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text('Sign in to continue to your dashboard', style: TextStyle(color: Colors.grey[700])),
                            const SizedBox(height: 24),
                            Form(key: _formKey, child: Column(children: [
                              _emailField(primary, large: true),
                              const SizedBox(height: 16),
                              _passwordField(primary, large: true),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(foregroundColor: primary),
                                  child: const Text('Forgot Password?'),
                                ),
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _onLoginPressed,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text('Sign in', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ])),
                            const SizedBox(height: 22),
                            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              const Text("Don't have an account? "),
                              GestureDetector(
                                onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SignUpPage())),
                                child: Text('Register now', style: TextStyle(color: primary, fontWeight: FontWeight.bold)),
                              ),
                            ]),
                            const SizedBox(height: 8),
                            // optional small footer links
                            Center(
                              child: Text('Terms • Privacy', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Email input builder
  Widget _emailField(Color primary, {bool large = false}) {
    return TextFormField(
      decoration: InputDecoration(
        hintText: 'Enter your email',
        hintStyle: TextStyle(color: Colors.black.withOpacity(0.45)),
        filled: true,
        fillColor: Colors.grey[100],
        prefixIcon: Icon(Icons.email, color: primary),
        contentPadding: EdgeInsets.symmetric(vertical: large ? 18 : 14, horizontal: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (v) => (v == null || v.isEmpty) ? 'Enter your email' : null,
    );
  }

  // Password input builder
  Widget _passwordField(Color primary, {bool large = false}) {
    return TextFormField(
      decoration: InputDecoration(
        hintText: 'Enter your password',
        hintStyle: TextStyle(color: Colors.black.withOpacity(0.45)),
        filled: true,
        fillColor: Colors.grey[100],
        prefixIcon: Icon(Icons.lock, color: primary),
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey[600]),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: large ? 18 : 14, horizontal: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      obscureText: _obscurePassword,
      validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
    );
  }

  void _onLoginPressed() {
    if (_formKey.currentState?.validate() == true) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CoursesScreen()));
    }
  }
}
