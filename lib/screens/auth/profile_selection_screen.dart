import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';
import '../../widgets/common/mascot_widget.dart';
import '../../providers/data_providers.dart';

class ProfileSelectionScreen extends ConsumerStatefulWidget {
  const ProfileSelectionScreen({super.key});

  @override
  ConsumerState<ProfileSelectionScreen> createState() =>
      _ProfileSelectionScreenState();
}

class _ProfileSelectionScreenState
    extends ConsumerState<ProfileSelectionScreen> {
  bool showPin = false;

  Future<void> _enterParentMode() async {
    final settingsAsync = ref.read(parentSettingsProvider);
    final settings = settingsAsync.value ?? {};
    final biometricsEnabled = settings['biometricsEnabled'] ?? false;

    if (biometricsEnabled) {
      final security = ref.read(securityServiceProvider);
      final success = await security.authenticateWithBiometrics();
      if (success && mounted) {
        context.go(AppRouter.parentDashboard);
        return;
      }
    }

    if (mounted) {
      setState(() => showPin = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.account_circle_rounded,
                  size: 64,
                  color: AppColors.mutedText,
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Sign in before selecting a profile.',
                  style: AppTextStyles.cardTitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton.icon(
                  onPressed: () => context.go(AppRouter.login),
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Go to Login'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('parents')
                .doc(user.uid)
                .collection('children')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final children = snapshot.data?.docs ?? [];

              return SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xxxl,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppSpacing.maxPhoneWidth,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Who\'s going to BearTahan?',
                            style: AppTextStyles.title,
                          ),
                          const SizedBox(height: AppSpacing.xxxl),

                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xxl,
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final cardWidth =
                                    (constraints.maxWidth - AppSpacing.xl) / 2;

                                return Wrap(
                                  spacing: AppSpacing.xl,
                                  runSpacing: AppSpacing.xl,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    ...children.map((doc) {
                                      final data =
                                          doc.data() as Map<String, dynamic>;
                                      final hasSelectedMascot =
                                          data['hasSelectedStarterMascot'] ==
                                              true &&
                                          data['activeOutfitID'] != null;

                                      return SizedBox(
                                        width: cardWidth,
                                        child: _ChildCard(
                                          name: data['name'] ?? 'Kid',
                                          avatar: data['avatar'] ?? '🐻',
                                          activeOutfitId:
                                              data['activeOutfitID'] as String?,
                                          onTap: () {
                                            ref
                                                .read(childIdProvider.notifier)
                                                .update(doc.id);
                                            if (hasSelectedMascot) {
                                              context.go(
                                                AppRouter.childHomeFor(doc.id),
                                              );
                                            } else {
                                              context.go(
                                                AppRouter.mascotSelectionFor(
                                                  doc.id,
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      );
                                    }),

                                    SizedBox(
                                      width: cardWidth,
                                      child: _AddChildCard(
                                        isCentered: children.isEmpty,
                                        onTap: () =>
                                            context.go(AppRouter.createProfile),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxxl),
                          TextButton.icon(
                            onPressed: _enterParentMode,
                            icon: const Icon(Icons.dashboard),
                            label: const Text('Parent Dashboard'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (showPin)
            _PinModal(
              onClose: () => setState(() => showPin = false),
              onEnter: () => context.go(AppRouter.parentDashboard),
            ),
        ],
      ),
    );
  }
}

// Reuse the _PinModal logic from profile_screen.dart (ideally move it to common)
class _PinModal extends ConsumerStatefulWidget {
  const _PinModal({required this.onClose, required this.onEnter});
  final VoidCallback onClose;
  final VoidCallback onEnter;

  @override
  ConsumerState<_PinModal> createState() => _PinModalState();
}

class _PinModalState extends ConsumerState<_PinModal> {
  final _controller = TextEditingController();
  String? _error;

  void _verify() {
    final settingsAsync = ref.read(parentSettingsProvider);
    final storedPin = settingsAsync.value?['parentPin'];
    final security = ref.read(securityServiceProvider);

    if (security.verifyPin(_controller.text, storedPin)) {
      widget.onEnter();
    } else {
      setState(() => _error = 'Invalid PIN. Try again.');
      _controller.clear();
    }
  }

  Future<void> _tryBiometrics() async {
    final security = ref.read(securityServiceProvider);
    if (await security.authenticateWithBiometrics()) {
      widget.onEnter();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black38,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.xxl),
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: AppRadius.r(AppRadius.xl),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Parent Security', style: AppTextStyles.cardTitle),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _controller,
                obscureText: true,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: InputDecoration(
                  hintText: 'Enter 4-digit PIN',
                  errorText: _error,
                  counterText: '',
                ),
                onSubmitted: (_) => _verify(),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _verify,
                      child: const Text('Enter'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onClose,
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
              if (!kIsWeb) ...[
                const SizedBox(height: AppSpacing.md),
                TextButton.icon(
                  onPressed: _tryBiometrics,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Use Biometrics'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  final String name;
  final String avatar;
  final String? activeOutfitId;
  final VoidCallback onTap;

  const _ChildCard({
    required this.name,
    required this.avatar,
    required this.activeOutfitId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imagePath = activeOutfitId == null
        ? 'assets/images/bear1.png'
        : MascotWidget.outfitImages[activeOutfitId] ?? 'assets/images/bear1.png';

    return AspectRatio(
      aspectRatio: 0.8,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6, right: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFAEEDA),
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [
            BoxShadow(
              color: AppColors.primary,
              offset: Offset(6, 6),
              blurRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(32),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(32),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Text(
                            avatar,
                            style: const TextStyle(fontSize: 48),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    name,
                    style: AppTextStyles.bodyBold.copyWith(
                      color: AppColors.foreground,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddChildCard extends StatelessWidget {
  final VoidCallback onTap;
  final bool isCentered;
  const _AddChildCard({required this.onTap, this.isCentered = false});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.8,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6, right: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFAEEDA).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.8),
              offset: const Offset(6, 6),
              blurRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(32),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(32),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Icon(
                        Icons.add_circle_outline_rounded,
                        size: 56,
                        color: AppColors.primary.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Add child',
                    style: AppTextStyles.bodyBold.copyWith(
                      color: AppColors.mutedText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
