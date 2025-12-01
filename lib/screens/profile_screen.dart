// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syllabuddy/screens/landingScreen.dart';
import 'package:syllabuddy/services/user_service.dart';
import 'package:syllabuddy/screens/subject_syllabus_screen.dart';
import 'package:syllabuddy/screens/bookmarks_screen.dart';
import 'package:syllabuddy/theme_service.dart';
import 'package:syllabuddy/theme.dart';

import 'package:syllabuddy/widgets/app_header.dart';
import 'package:syllabuddy/styles/app_styles.dart';

/// ProfileScreen: simplified — no back/close handling or onClose callback.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  String? _name;
  String? _email;
  String? _memberSince;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _user = null;
          _email = null;
          _name = null;
          _memberSince = null;
        });
      }
      return;
    }

    try {
      final data = await UserService.getCurrentUserData();
      final first = data?['firstName'] ?? '';
      final last = data?['lastName'] ?? '';
      final ts = data?['createdAt'];

      if (!mounted) return;
      setState(() {
        _user = currentUser;
        _email = currentUser.email;
        _name = "$first $last".trim().isEmpty ? 'Unknown' : "$first $last".trim();

        if (ts != null && ts is Timestamp) {
          final dt = ts.toDate();
          _memberSince = "${dt.day}/${dt.month}/${dt.year}";
        } else {
          _memberSince = "Unknown";
        }

        _loading = false;
      });
    } catch (e) {
      debugPrint('Failed to fetch profile: $e');
      if (!mounted) return;
      setState(() {
        _user = currentUser;
        _email = currentUser?.email;
        _name = 'Unknown';
        _memberSince = "Unknown";
        _loading = false;
      });
    }
  }

  /// Logout: sign out, clear prefs, and force root navigator -> LandingScreen
  Future<void> _logout(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LandingScreen()),
          (route) => false,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signed out')));
    } catch (e) {
      debugPrint('Logout failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign out failed: $e')));
    }
  }

  /// Reauthenticate email/password users by asking for password.
  Future<bool> _reauthenticateWithPassword(BuildContext context) async {
    final pwController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Re-authenticate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('For security, please enter your password to confirm account deletion.'),
            const SizedBox(height: 12),
            TextField(
              controller: pwController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      pwController.dispose();
      return false;
    }
    final password = pwController.text.trim();
    pwController.dispose();
    if (password.isEmpty) return false;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) return false;

      final cred = EmailAuthProvider.credential(email: user.email!, password: password);
      await user.reauthenticateWithCredential(cred);
      debugPrint('Reauthentication successful');
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Reauth failed: ${e.code} ${e.message}');
      if (!mounted) return false;
      if (e.code == 'wrong-password') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incorrect password.')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Re-authentication failed: ${e.message}')));
      }
      return false;
    } catch (e) {
      debugPrint('Unexpected reauth error: $e');
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to re-authenticate. Try again.')));
      return false;
    }
  }

  Future<void> _confirmAndDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account'),
        content: const Text(
            'This will permanently delete your account and all associated profile data. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await UserService.deleteAccount();
      debugPrint('UserService.deleteAccount() completed');
    } catch (e, st) {
      debugPrint('UserService.deleteAccount() threw: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete account data: $e')));
      return;
    }

    try {
      final current = FirebaseAuth.instance.currentUser;
      if (current != null) {
        try {
          await current.delete();
          debugPrint('Auth user deleted successfully.');
        } on FirebaseAuthException catch (e) {
          debugPrint('Auth delete failed: ${e.code} ${e.message}');
          if (e.code == 'requires-recent-login') {
            final reauthOk = await _reauthenticateWithPassword(context);
            if (reauthOk) {
              try {
                final after = FirebaseAuth.instance.currentUser;
                if (after != null) {
                  await after.delete();
                  debugPrint('Auth user deleted after reauth.');
                }
              } on FirebaseAuthException catch (e2) {
                debugPrint('Auth delete after reauth failed: ${e2.code} ${e2.message}');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete auth account: ${e2.message}')));
                }
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please sign in again (recent login required) and retry account deletion.')),
                );
              }
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete account: ${e.message}')));
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Unexpected error while attempting auth delete: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');
    } catch (e) {
      debugPrint('Failed to clear prefs: $e');
    }

    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('signOut threw (ignored): $e');
    }

    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LandingScreen()),
        (route) => false,
      );
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account deletion process completed.')));
    }
  }

  // helper that returns a two-tone gradient based on primary color
  LinearGradient primaryGradientFrom(Color primary) {
    final hsl = HSLColor.fromColor(primary);
    final darker = hsl.withLightness((hsl.lightness - 0.12).clamp(0.0, 1.0)).toColor();
    return LinearGradient(colors: [darker, primary], stops: const [0.0, 0.5], begin: Alignment.bottomCenter, end: Alignment.topCenter);
  }

  // red gradient used for delete action
  LinearGradient redGradient() {
    final base = Colors.red.shade600;
    final hsl = HSLColor.fromColor(base);
    final darker = hsl.withLightness((hsl.lightness - 0.14).clamp(0.0, 1.0)).toColor();
    return LinearGradient(colors: [darker, base], stops: const [0.0, 0.5], begin: Alignment.bottomCenter, end: Alignment.topCenter);
  }

  // generic colored action button (keeps shape/padding consistent)
  Widget buildActionButton({
    required BuildContext ctx,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    LinearGradient? gradient,
    Color? solidColor,
    Color? foreground,
  }) {
    final borderRadius = BorderRadius.circular(AppStyles.radiusMedium);
    final fg = foreground ?? Colors.white;

    if (gradient != null) {
      return Container(
        decoration: BoxDecoration(gradient: gradient, borderRadius: borderRadius),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: borderRadius,
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: fg),
                  const SizedBox(width: 10),
                  Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final bg = solidColor ?? Theme.of(ctx).primaryColor;
    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: borderRadius),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: fg),
                const SizedBox(width: 10),
                Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -----------------------
  // Missing helpers re-added
  // -----------------------

  // open bookmarks screen
  void _openBookmarks() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BookmarksScreen()),
    );
  }

  // edit profile flow (re-implemented from your original)
  Future<void> _editProfile(BuildContext context) async {
    if (_isEditing) return;
    _isEditing = true;

    final parts = (_name ?? "").split(" ");
    final firstName = parts.isNotEmpty ? parts.first : "";
    final lastName = parts.length > 1 ? parts.sublist(1).join(" ") : "";

    final firstNameController = TextEditingController(text: firstName);
    final lastNameController = TextEditingController(text: lastName);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Edit Profile"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: firstNameController, decoration: const InputDecoration(labelText: "First Name", border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: lastNameController, decoration: const InputDecoration(labelText: "Last Name", border: OutlineInputBorder())),
            ],
          ),
          actions: [
            TextButton(child: const Text("Cancel"), onPressed: () => Navigator.pop(context)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
              child: const Text("Save"),
              onPressed: () async {
                try {
                  await UserService.updateName(firstNameController.text.trim(), lastNameController.text.trim());
                  Navigator.pop(context);
                  await _fetchProfile();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
                } on FirebaseException catch (e) {
                  Navigator.pop(context);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update profile: ${e.message}')));
                } catch (e) {
                  Navigator.pop(context);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
                }
              },
            ),
          ],
        );
      },
    );

    _isEditing = false;
  }

  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final primaryGradient = primaryGradientFrom(primary);
    final isDark = theme.brightness == Brightness.dark;

    // Name/Member text colors: black in light, white in dark (per your request)
    final nameAndMemberColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white70 : Colors.grey[700];

    // Switch button "dark" solid color: derive a darker variant from primary so it contrasts in dark mode.
    final h = HSLColor.fromColor(primary);
    final switchSolidColor = isDark
        ? h.withLightness((h.lightness - 0.32).clamp(0.0, 1.0)).toColor()
        : const Color.fromARGB(255, 153, 215, 196);

    final switchForeground = isDark ? Colors.white : Colors.black87;

    // Icon for the switch button: show moon when currently light (action = switch to dark),
    // show sun when currently dark (action = switch to light).
    final switchIcon = ThemeService.notifier.value == ThemeMode.dark ? Icons.wb_sunny : Icons.nights_stay;
    final switchLabel = ThemeService.notifier.value == ThemeMode.dark ? 'Switch to Light' : 'Switch to Dark';

    return Scaffold(
      body: Column(
        children: [
          // shared header for consistent look
          AppHeader(title: 'Profile', showBack: true),

          const SizedBox(height: 20),

          // profile info + member since card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // name & email
                Text(_name ?? '', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: nameAndMemberColor)),
                const SizedBox(height: 6),
                Text(_email ?? '', style: TextStyle(fontSize: 14, color: subtitleColor)),
                const SizedBox(height: 18),

                // Member since card — use AppStyles styling
                Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                    boxShadow: [AppStyles.shadow(context)],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.school, color: nameAndMemberColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Member since ${_memberSince ?? "Unknown"}\nSyllabuddy user',
                          style: TextStyle(color: nameAndMemberColor.withOpacity(0.95)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // Action buttons (kept your buildActionButton API but styled to match app)
                SizedBox(
                  width: double.infinity,
                  child: buildActionButton(
                    ctx: context,
                    icon: Icons.bookmark,
                    label: 'Bookmarked subjects',
                    gradient: primaryGradient,
                    onPressed: _openBookmarks,
                    foreground: Colors.white,
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: buildActionButton(
                    ctx: context,
                    icon: Icons.edit,
                    label: 'Edit Profile',
                    gradient: primaryGradient,
                    onPressed: () => _editProfile(context),
                    foreground: Colors.white,
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: buildActionButton(
                    ctx: context,
                    icon: switchIcon,
                    label: switchLabel,
                    solidColor: switchSolidColor,
                    foreground: switchForeground,
                    onPressed: () async {
                      await ThemeService.toggle();
                      if (mounted) {
                        setState(() {}); // refresh icon/label
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(ThemeService.notifier.value == ThemeMode.dark ? 'Dark mode on' : 'Light mode on')),
                        );
                      }
                    },
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: buildActionButton(
                    ctx: context,
                    icon: Icons.logout,
                    label: 'Logout',
                    gradient: primaryGradient,
                    onPressed: () => _logout(context),
                    foreground: Colors.white,
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: buildActionButton(
                    ctx: context,
                    icon: Icons.delete_forever,
                    label: 'Delete Account',
                    gradient: redGradient(),
                    onPressed: () => _confirmAndDelete(context),
                    foreground: Colors.white,
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
