import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

class ProfileSelectionScreen extends StatelessWidget {
  const ProfileSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('parents')
            .doc(user?.uid)
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
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
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

                      // Use Wrap instead of GridView for automatic row centering
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xxl,
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // Calculate width for 2 columns minus spacing
                            final cardWidth =
                                (constraints.maxWidth - AppSpacing.xl) / 2;

                            return Wrap(
                              spacing: AppSpacing.xl,
                              runSpacing: AppSpacing.xl,
                              alignment: WrapAlignment
                                  .center, // THIS CENTERS THE LAST ITEM
                              children: [
                                ...children.map((doc) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  return SizedBox(
                                    width: cardWidth,
                                    child: _ChildCard(
                                      name: data['name'] ?? 'Kid',
                                      avatar: data['avatar'] ?? '🐻',
                                      onTap: () =>
                                          context.go(AppRouter.childHome),
                                    ),
                                  );
                                }),

                                // The Add Child card
                                SizedBox(
                                  width: cardWidth,
                                  child: _AddChildCard(
                                    // If empty, we make it larger/centered as per your existing logic
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
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  final String name;
  final String avatar;
  final VoidCallback onTap;

  const _ChildCard({
    required this.name,
    required this.avatar,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.8, // Maintains the card shape
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.r(AppRadius.lg),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: AppRadius.r(AppRadius.lg),
            border: Border.all(color: AppColors.primary, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: AppRadius.r(AppRadius.md),
                ),
                child: Center(
                  child: Text(avatar, style: const TextStyle(fontSize: 32)),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(name, style: AppTextStyles.bodyBold),
            ],
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
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.r(AppRadius.lg),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: AppRadius.r(AppRadius.lg),
            border: Border.all(
              color: AppColors.border,
              width: 1.5,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, size: 36, color: AppColors.mutedText),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Add child',
                style: AppTextStyles.body.copyWith(color: AppColors.mutedText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
