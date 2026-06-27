import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../router/app_router.dart';
import '../../services/parent_account_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  final _parentAccountService = ParentAccountService();
  late TabController _tabController;

  bool _obscureLoginPassword = true;
  bool _obscureRegPassword = true;
  bool _obscureRegConfirmPassword = true;

  // Login Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Sign Up Controllers
  final TextEditingController _regNameController = TextEditingController();
  final TextEditingController _regEmailController = TextEditingController();
  final TextEditingController _regPasswordController = TextEditingController();
  final TextEditingController _regConfirmPasswordController =
      TextEditingController();

  final _signUpFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _regNameController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    _regConfirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Please enter both email and password.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (mounted) {
        _showSnackBar('Logged in successfully!');
        context.go(AppRouter.selectProfile);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _showSnackBar(e.message ?? 'Sign in failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _registerWithEmailAndPassword() async {
    if (!_signUpFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _regEmailController.text.trim(),
            password: _regPasswordController.text.trim(),
          );

      User? user = userCredential.user;

      if (user != null) {
        await _parentAccountService.createOrUpdateParentDocument(
          user,
          name: _regNameController.text.trim(),
          extraData: {
            'passwordLength': _regPasswordController.text.trim().length,
          },
        );

        if (mounted) {
          _showSnackBar('Parent Account created successfully!');
          context.go(AppRouter.parentDashboard);
        }
      }
    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? 'An error occurred during registration.');
    } catch (e) {
      _showSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

        if (googleUser == null) {
          setState(() => _isLoading = false);
          return;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await FirebaseAuth.instance.signInWithCredential(
          credential,
        );
      }
      User? user = userCredential.user;

      if (user != null) {
        await _parentAccountService.createParentDocumentIfMissing(user);

        if (mounted) {
          _showSnackBar('Logged in successfully!');
          context.go(AppRouter.selectProfile);
        }
      }
    } catch (e) {
      if (!e.toString().toLowerCase().contains('canceled')) {
        debugPrint('Google Sign-In failed: $e');
        if (mounted) _showSnackBar('Sign in failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset:
          false, // Prevent keyboard from shifting background/logo
      body: Stack(
        children: [
          Image.asset(
            _tabController.index == 0
                ? 'assets/images/login.png'
                : 'assets/images/signup.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          SafeArea(
            child: Stack(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: EdgeInsets.only(
                        left: AppSpacing.xxl,
                        right: AppSpacing.xxl,
                        bottom:
                            MediaQuery.of(context).viewInsets.bottom +
                            AppSpacing.md,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Align(
                          alignment: Alignment.center,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: AppSpacing.maxPhoneWidth,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Card(
                                  elevation: 8,
                                  shadowColor: Colors.black12,
                                  color: const Color(0xFFFAEEDA),
                                  surfaceTintColor: Colors.transparent,
                                  clipBehavior: Clip.antiAlias,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppRadius.r(AppRadius.xl),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        color: const Color(0xFFFAEEDA),
                                        child: TabBar(
                                          controller: _tabController,
                                          labelColor: AppColors.secondaryText,
                                          unselectedLabelColor:
                                              Colors.grey.shade600,
                                          indicatorColor:
                                              AppColors.secondaryText,
                                          indicatorWeight: 4,
                                          indicatorSize:
                                              TabBarIndicatorSize.tab,
                                          labelStyle: AppTextStyles.bodyBold,
                                          dividerColor: Colors.grey.shade300,
                                          tabs: const [
                                            Tab(text: 'Log In'),
                                            Tab(text: 'Sign Up'),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(
                                          AppSpacing.xl,
                                        ),
                                        child: Theme(
                                          data: Theme.of(context).copyWith(
                                            inputDecorationTheme:
                                                Theme.of(
                                                  context,
                                                ).inputDecorationTheme.copyWith(
                                                  fillColor: const Color(
                                                    0xFFFAC775,
                                                  ),
                                                  prefixIconColor: AppColors
                                                      .secondaryText
                                                      .withValues(alpha: 0.7),
                                                  hintStyle: AppTextStyles.body
                                                      .copyWith(
                                                        color: AppColors
                                                            .secondaryText
                                                            .withValues(
                                                              alpha: 0.5,
                                                            ),
                                                      ),
                                                ),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              _tabController.index == 0
                                                  ? _buildLoginTab()
                                                  : _buildSignUpTab(),
                                              const SizedBox(
                                                height: AppSpacing.xl,
                                              ),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Divider(
                                                      color: AppColors
                                                          .secondaryText
                                                          .withValues(
                                                            alpha: 0.2,
                                                          ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal:
                                                              AppSpacing.md,
                                                        ),
                                                    child: Text(
                                                      'OR',
                                                      style: AppTextStyles.tiny
                                                          .copyWith(
                                                            color: AppColors
                                                                .secondaryText
                                                                .withValues(
                                                                  alpha: 0.6,
                                                                ),
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Divider(
                                                      color: AppColors
                                                          .secondaryText
                                                          .withValues(
                                                            alpha: 0.2,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(
                                                height: AppSpacing.xl,
                                              ),
                                              _isLoading
                                                  ? const CircularProgressIndicator(
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(
                                                            AppColors
                                                                .secondaryText,
                                                          ),
                                                    )
                                                  : SizedBox(
                                                      width: double.infinity,
                                                      child: OutlinedButton.icon(
                                                        onPressed:
                                                            _signInWithGoogle,
                                                        icon: Image.asset(
                                                          'assets/images/google.webp',
                                                          height: 24,
                                                          width: 24,
                                                        ),
                                                        label: const Text(
                                                          'Sign in with Google',
                                                          style: TextStyle(
                                                            color: AppColors
                                                                .secondaryText,
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontFamily:
                                                                'Roboto',
                                                          ),
                                                        ),
                                                        style: OutlinedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.white
                                                                  .withValues(
                                                                    alpha: 0.5,
                                                                  ),
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                vertical:
                                                                    AppSpacing
                                                                        .md,
                                                                horizontal:
                                                                    AppSpacing
                                                                        .md,
                                                              ),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                                borderRadius:
                                                                    AppRadius.r(
                                                                      AppRadius
                                                                          .lg,
                                                                    ),
                                                              ),
                                                          side: BorderSide(
                                                            color: AppColors
                                                                .secondaryText
                                                                .withValues(
                                                                  alpha: 0.2,
                                                                ),
                                                          ),
                                                          elevation: 0,
                                                        ),
                                                      ),
                                                    ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Image.asset(
                      'assets/images/beartahan.png',
                      width: 180,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginTab() {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.person),
            hintText: 'Email',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _passwordController,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock),
            hintText: 'Password',
            suffixIcon: IconButton(
              icon: _PawIcon(
                key: ValueKey(_obscureLoginPassword),
                isFilled: !_obscureLoginPassword,
                color: AppColors.secondaryText,
              ),
              onPressed: () => setState(
                () => _obscureLoginPassword = !_obscureLoginPassword,
              ),
            ),
          ),
          obscureText: _obscureLoginPassword,
        ),
        const SizedBox(height: AppSpacing.xs),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.push(AppRouter.forgotPassword),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Forgot Password?',
              style: AppTextStyles.tiny.copyWith(
                color: AppColors.secondaryText,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: 'Log In',
          icon: Icons.play_arrow_rounded,
          backgroundColor: AppColors.secondaryText,
          isLoading: _isLoading,
          onPressed: _signInWithEmail,
        ),
      ],
    );
  }

  Widget _buildSignUpTab() {
    return Form(
      key: _signUpFormKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextFormField(
              controller: _regNameController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_outline),
                hintText: 'Full Name',
              ),
              validator: (v) => v == null || v.isEmpty ? 'Enter name' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _regEmailController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.email_outlined),
                hintText: 'Email',
              ),
              validator: (v) =>
                  v == null || !v.contains('@') ? 'Enter valid email' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _regPasswordController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outline),
                hintText: 'Password',
                suffixIcon: IconButton(
                  icon: _PawIcon(
                    key: ValueKey(_obscureRegPassword),
                    isFilled: !_obscureRegPassword,
                    color: AppColors.secondaryText,
                  ),
                  onPressed: () => setState(
                    () => _obscureRegPassword = !_obscureRegPassword,
                  ),
                ),
              ),
              obscureText: _obscureRegPassword,
              validator: (v) =>
                  v == null || v.length < 6 ? 'Min 6 chars' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _regConfirmPasswordController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outline),
                hintText: 'Confirm Password',
                suffixIcon: IconButton(
                  icon: _PawIcon(
                    key: ValueKey(_obscureRegConfirmPassword),
                    isFilled: !_obscureRegConfirmPassword,
                    color: AppColors.secondaryText,
                  ),
                  onPressed: () => setState(
                    () => _obscureRegConfirmPassword =
                        !_obscureRegConfirmPassword,
                  ),
                ),
              ),
              obscureText: _obscureRegConfirmPassword,
              validator: (v) =>
                  v != _regPasswordController.text ? 'No match' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Create Account',
              icon: Icons.person_add_rounded,
              backgroundColor: AppColors.secondaryText,
              isLoading: _isLoading,
              onPressed: _registerWithEmailAndPassword,
            ),
          ],
        ),
      ),
    );
  }
}

class _PawIcon extends StatelessWidget {
  const _PawIcon({required this.isFilled, required this.color, super.key});

  final bool isFilled;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(24.0, 24.0),
      painter: _PawPainter(isFilled: isFilled, color: color),
    );
  }
}

class _PawPainter extends CustomPainter {
  _PawPainter({required this.isFilled, required this.color});

  final bool isFilled;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = isFilled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;

    // Draw the 4 toes
    // Toe 1 (left-most)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.20, h * 0.42),
        width: w * 0.18,
        height: h * 0.24,
      ),
      paint,
    );

    // Toe 2 (middle-left)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.40, h * 0.26),
        width: w * 0.20,
        height: h * 0.28,
      ),
      paint,
    );

    // Toe 3 (middle-right)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.60, h * 0.26),
        width: w * 0.20,
        height: h * 0.28,
      ),
      paint,
    );

    // Toe 4 (right-most)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.80, h * 0.42),
        width: w * 0.18,
        height: h * 0.24,
      ),
      paint,
    );

    // Draw main pad
    final path = Path();
    path.moveTo(w * 0.5, h * 0.88);
    path.quadraticBezierTo(w * 0.18, h * 0.88, w * 0.24, h * 0.68);
    path.quadraticBezierTo(w * 0.5, w * 0.46, w * 0.76, h * 0.68);
    path.quadraticBezierTo(w * 0.82, h * 0.88, w * 0.5, h * 0.88);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PawPainter oldDelegate) {
    return oldDelegate.isFilled != isFilled || oldDelegate.color != color;
  }
}
