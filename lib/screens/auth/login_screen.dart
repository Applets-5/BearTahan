import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/mascot_widget.dart';
import '../../widgets/common/primary_button.dart';

// Changed from StatelessWidget to StatefulWidget
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  /// Handles Direct Google Login
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      // 1. Initialize GoogleSignIn
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // 2. Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      // 3. Obtain auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 4. Create a new Firebase credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 5. Sign in to Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        // 6. Check if user exists in the database. If not, create them (handles both Login & Register seamlessly!)
        DocumentSnapshot parentDoc = await FirebaseFirestore.instance
            .collection('parents')
            .doc(user.uid)
            .get();

        if (!parentDoc.exists) {
          await FirebaseFirestore.instance
              .collection('parents')
              .doc(user.uid)
              .set({
                'uid': user.uid,
                'name': user.displayName ?? 'Parent',
                'email': user.email,
                'role': 'parent',
                'createdAt': FieldValue.serverTimestamp(),
              });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logged in successfully!')),
          );
          // Route them straight to the parent dashboard!
          context.go(AppRouter.parentDashboard);
        }
      }
    } catch (e) {
      if (!e.toString().toLowerCase().contains('canceled')) {
        debugPrint('Google Sign-In failed: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sign in failed. Please try again.')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.maxPhoneWidth,
              ),
              child: Column(
                children: [
                  const MascotWidget(size: 116),
                  const SizedBox(height: AppSpacing.xxl),
                  const Text('BearTahan', style: AppTextStyles.title),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Fun lessons, quests, and star rewards for young learners.',
                    style: AppTextStyles.body,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Login Fields
                  const TextField(
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.person),
                      hintText: 'Email or Child name',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const TextField(
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.lock),
                      hintText: 'Password or Parent PIN',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Login Action
                  PrimaryButton(
                    label: 'Log In / Start Learning',
                    icon: Icons.play_arrow_rounded,
                    onPressed: () => context.go(AppRouter.childHome),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: () => context.go(AppRouter.parentDashboard),
                    child: const Text('Parent Mode (Bypass for now)'),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  _isLoading
                      ? const CircularProgressIndicator() // Show a loading spinner when clicked!
                      : OutlinedButton.icon(
                          onPressed:
                              _signInWithGoogle, // The function is now linked!
                          icon: Image.asset(
                            'assets/images/google.webp',
                            height: 24,
                            width: 24,
                          ),
                          label: const Text(
                            'Sign in with Google',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Roboto',
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            side: BorderSide(color: Colors.grey.shade300),
                            elevation: 0,
                          ),
                        ),

                  const SizedBox(height: AppSpacing.xl),

                  // Registration Section
                  Divider(color: Colors.grey.shade300),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'New to BearTahan?',
                        style: TextStyle(color: Colors.grey),
                      ),
                      TextButton(
                        onPressed: () => context.push(AppRouter.parentRegister),
                        child: const Text(
                          'Create Master Account',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
