import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/data_providers.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/primary_button.dart';

class MemoryChallengeScreen extends ConsumerStatefulWidget {
  const MemoryChallengeScreen({super.key});

  @override
  ConsumerState<MemoryChallengeScreen> createState() =>
      _MemoryChallengeScreenState();
}

class _MemoryChallengeScreenState extends ConsumerState<MemoryChallengeScreen> {
  bool _isLoading = false;

  Future<void> _startChallenge(String childId) async {
    setState(() => _isLoading = true);

    try {
      final parentId = ref.read(parentIdProvider);
      final questions = await ref
          .read(firestoreServiceProvider)
          .getReviewQuestions(parentId, childId, limit: 15);

      if (mounted) {
        if (questions.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No questions to review!')),
          );
          context.pop();
          return;
        }

        context.push(
          Uri(
            path: AppRouter.levelSession,
            queryParameters: {
              'childId': childId,
              'levelId': 'review_session',
              'levelPrefix': 'review_',
            },
          ).toString(),
          extra: questions,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final childId =
        GoRouterState.of(context).uri.queryParameters['childId'] ?? '';
    final userProfileAsync = ref.watch(userProfileProvider(childId));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bear's Memory Challenge"),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
      body: userProfileAsync.when(
        data: (profile) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.psychology_rounded,
                  size: 100,
                  color: AppColors.secondary,
                ),
                const SizedBox(height: AppSpacing.xl),
                const Text(
                  "Review & Master!",
                  style: AppTextStyles.screenTitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  "Practice questions you got wrong to earn stars and strengthen your memory.",
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryLight.withValues(alpha: 0.2),
                    borderRadius: AppRadius.r(AppRadius.lg),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: AppColors.star),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        "Progress: ${profile.reviewQuestionCounter}/20",
                        style: AppTextStyles.bodyBold,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  PrimaryButton(
                    label: "Start Review Session",
                    onPressed: () => _startChallenge(childId),
                    backgroundColor: AppColors.secondary,
                  ),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text("Maybe Later"),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
