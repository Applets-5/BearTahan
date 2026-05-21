import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../router/app_router.dart';
import '../../services/parent_account_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/primary_button.dart';

// Changed from StatelessWidget to StatefulWidget
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  final _parentAccountService = ParentAccountService();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 3. Create the Email/Password login function
  Future<void> _signInWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both email and password.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged in successfully!')),
        );
        context.go(AppRouter.selectProfile);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Sign in failed. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Handles Direct Google Login
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final UserCredential userCredential;

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
        final googleProvider = GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile');

        userCredential = await FirebaseAuth.instance.signInWithProvider(
          googleProvider,
        );
      } else {
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
        userCredential = await FirebaseAuth.instance.signInWithCredential(
          credential,
        );
      }
      User? user = userCredential.user;

      if (user != null) {
        await _parentAccountService.createParentDocumentIfMissing(user);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logged in successfully!')),
          );
          // Route them straight to the parent dashboard!
          context.go(AppRouter.selectProfile);
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
                  const _LoginAppIcon(),
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
                  TextField(
                    controller: _emailController, // Attach controller
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person),
                      hintText: 'Email or Child name',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Update the Password Field
                  TextField(
                    controller: _passwordController, // Attach controller
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.lock),
                      hintText: 'Password or Parent PIN',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Update the Login Action Button
                  _isLoading
                      ? const CircularProgressIndicator() // Show loader for email login too
                      : PrimaryButton(
                          label: 'Log In / Start Learning',
                          icon: Icons.play_arrow_rounded,
                          onPressed:
                              _signInWithEmail, // Link the new function here!
                        ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: () => context.push(AppRouter.forgotPassword),
                    child: const Text('Forgot Password?'),
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

class _LoginAppIcon extends StatelessWidget {
  const _LoginAppIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 116,
      height: 116,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: AppRadius.r(AppRadius.xxl),
      ),
      child: const Icon(
        Icons.school_rounded,
        color: AppColors.primary,
        size: 56,
      ),
    );
  }
}
