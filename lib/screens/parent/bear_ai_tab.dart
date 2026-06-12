import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/bear_ai_message.dart';
import '../../models/subject.dart';
import '../../providers/bear_ai_provider.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/parent/radar_chart_widget.dart';
import '../../widgets/parent/typing_indicator.dart';

class BearAITab extends ConsumerStatefulWidget {
  final String childId;
  const BearAITab({super.key, required this.childId});

  @override
  ConsumerState<BearAITab> createState() => _BearAITabState();
}

class _BearAITabState extends ConsumerState<BearAITab> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(bearAiProvider);
    final subjectsAsync = ref.watch(subjectProgressProvider(widget.childId));
    final childProfileAsync = ref.watch(userProfileProvider(widget.childId));

    // Listen to profile changes to trigger insight generation if needed
    ref.listen(userProfileProvider(widget.childId), (previous, next) {
      if (next.hasValue && !aiState.hasGeneratedInsight && !aiState.isInsightLoading) {
        final profile = next.value!;
        ref
            .read(bearAiProvider.notifier)
            .generateInsightIfNeeded(
              widget.childId,
              existingInsight: profile.lastAiInsight,
              lastDate: profile.lastAiInsightDate,
            );
      }
    });

    return Column(
      children: [
        const SizedBox(height: AppSpacing.md), // Space below TabBar
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            controller: _scrollController,
            children: [
              // AI Insight Card
              _buildInsightCard(aiState, subjectsAsync, childProfileAsync),
              const SizedBox(height: AppSpacing.lg),

              // Chat Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: AppRadius.r(AppRadius.xl),
                  boxShadow: AppShadows.card,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        const Text('Ask BearAI', style: AppTextStyles.bodyBold),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Chat Messages
                    ...aiState.messages.map(
                      (msg) => _ChatMessageBubble(
                        message: msg,
                        onRetry: () => ref
                            .read(bearAiProvider.notifier)
                            .sendMessage(
                              widget.childId,
                              msg.retryData as String,
                              isRetry: true,
                            ),
                      ),
                    ),

                    if (aiState.isChatLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: TypingIndicator(),
                        ),
                      ),

                    const SizedBox(height: AppSpacing.md),

                    // Suggestion Chips
                    if (!aiState.isChatLoading)
                      _buildSuggestionChips(childProfileAsync, subjectsAsync),

                    const SizedBox(height: AppSpacing.lg),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: AppSpacing.md),

                    // Chat Input (Inside Card)
                    _buildChatInput(aiState, childProfileAsync),
                    const SizedBox(height: AppSpacing.sm),
                    childProfileAsync.when(
                      data: (child) => Center(
                        child: Text(
                          "BearAI analyzes ${child.name}'s activity data using secure AI processing. No names or private IDs are shared.",
                          style: AppTextStyles.tiny.copyWith(
                            color: AppColors.mutedText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      loading: () => const SizedBox(),
                      error: (e, st) => const SizedBox(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard(
    BearAiState aiState,
    AsyncValue<List<Subject>> subjectsAsync,
    AsyncValue childProfileAsync,
  ) {
    final profile = childProfileAsync.value;
    final displayInsight = aiState.insight ?? profile?.lastAiInsight;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.r(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text('AI Insight', style: AppTextStyles.bodyBold),
              const Spacer(),
              if (aiState.isInsightLoading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (aiState.insightError != null)
            Text(
              aiState.insightError!,
              style: AppTextStyles.body.copyWith(color: Colors.red.shade700),
            )
          else if (displayInsight != null)
            Text(displayInsight, style: AppTextStyles.body)
          else if (!aiState.isInsightLoading)
            const Text(
              'Generating weekly insight...',
              style: AppTextStyles.body,
            )
          else
            const Text('Connecting to BearAI...', style: AppTextStyles.body),

          const SizedBox(height: AppSpacing.lg),

          subjectsAsync.when(
            data: (subjects) {
              final Map<String, double> scores = {};
              for (var s in subjects) {
                scores[s.id] = s.progress.toDouble() / 100;
              }
              return Column(
                children: [
                  const Text('Weekly Progress', style: AppTextStyles.bodyBold),
                  const SizedBox(height: AppSpacing.sm),
                  SubjectRadarChart(subjectScores: scores),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error loading chart: $e'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChips(
    AsyncValue childProfileAsync,
    AsyncValue<List<Subject>> subjectsAsync,
  ) {
    return childProfileAsync.when(
      data: (child) {
        return subjectsAsync.when(
          data: (subjects) {
            final chips = _generateDynamicChips(child, subjects);
            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: chips
                  .map(
                    (s) => ActionChip(
                      label: Text(s, style: AppTextStyles.tiny),
                      backgroundColor: AppColors.primaryLight,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.r(AppRadius.lg),
                      ),
                      onPressed: () {
                        ref
                            .read(bearAiProvider.notifier)
                            .sendMessage(widget.childId, s);
                        _scrollToBottom();
                      },
                    ),
                  )
                  .toList(),
            );
          },
          loading: () => const SizedBox(),
          error: (_, _) => const SizedBox(),
        );
      },
      loading: () => const SizedBox(),
      error: (e, st) => const SizedBox(),
    );
  }

  List<String> _generateDynamicChips(dynamic child, List<Subject> subjects) {
    final chips = <String>[];

    chips.add("📊 This week's summary");

    // Issue 9: Empty check to prevent crash
    if (subjects.isNotEmpty) {
      // Sort to find weakest
      final sorted = List<Subject>.from(subjects)
        ..sort((a, b) => a.progress.compareTo(b.progress));
      final weakest = sorted.first;

      if (weakest.progress < 50) {
        chips.add("⚠️ Why is ${weakest.id.toUpperCase()} low?");
      }
    }

    chips.add("🎯 Suggest a daily goal");

    if (child.streakCount > 3) {
      chips.add("🔥 Streak tips");
    }

    chips.add("🔁 Repeated mistakes");

    return chips;
  }

  Widget _buildChatInput(BearAiState aiState, AsyncValue childProfileAsync) {
    final childName = childProfileAsync.when(
      data: (child) => child.name,
      loading: () => "child",
      error: (_, _) => "child",
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: AppRadius.r(AppRadius.xl),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: "Ask about $childName's progress...",
                border: InputBorder.none,
                hintStyle: AppTextStyles.small,
              ),
              style: AppTextStyles.small,
              onSubmitted: (text) {
                ref
                    .read(bearAiProvider.notifier)
                    .sendMessage(widget.childId, text);
                _messageController.clear();
                _scrollToBottom();
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: AppColors.primary),
            onPressed: aiState.isChatLoading
                ? null
                : () {
                    ref
                        .read(bearAiProvider.notifier)
                        .sendMessage(widget.childId, _messageController.text);
                    _messageController.clear();
                    _scrollToBottom();
                  },
          ),
        ],
      ),
    );
  }
}

class _ChatMessageBubble extends StatelessWidget {
  final BearAiMessage message;
  final VoidCallback onRetry;

  const _ChatMessageBubble({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final isError = message.role == MessageRole.error;

    return GestureDetector(
      onLongPress: isUser || isError
          ? null
          : () {
              Clipboard.setData(ClipboardData(text: message.content));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Copied to clipboard")),
              );
            },
      onTap: isError ? onRetry : null,
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isError
                ? Colors.red.withValues(alpha: 0.1)
                : (isUser ? AppColors.primary : AppColors.card),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isUser ? 16 : 0),
              bottomRight: Radius.circular(isUser ? 0 : 16),
            ),
            border: isError
                ? Border.all(color: Colors.red.withValues(alpha: 0.3))
                : null,
            boxShadow: isUser || isError ? null : AppShadows.card,
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.content,
                style: AppTextStyles.small.copyWith(
                  color: isError
                      ? Colors.red.shade700
                      : (isUser ? Colors.white : AppColors.foreground),
                  fontWeight: isError ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (isError)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, size: 12, color: Colors.red.shade700),
                      const SizedBox(width: 4),
                      Text(
                        "Tap to retry",
                        style: AppTextStyles.tiny.copyWith(
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
