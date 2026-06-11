import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/bear_ai_message.dart';
import '../../providers/bear_ai_provider.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/parent/radar_chart_widget.dart';

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
      if (next.hasValue && !aiState.hasGeneratedInsight && !aiState.isLoading) {
        final profile = next.value!;
        ref.read(bearAiProvider.notifier).generateInsightIfNeeded(
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
                    ...aiState.messages.map((msg) => _ChatMessageBubble(message: msg)),
                    
                    if (aiState.isLoading && aiState.hasGeneratedInsight)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                    
                    const SizedBox(height: AppSpacing.md),
                    
                    // Suggestion Chips
                    if (!aiState.isLoading)
                      _buildSuggestionChips(childProfileAsync),
                    
                    const SizedBox(height: AppSpacing.lg),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: AppSpacing.md),
                    
                    // Chat Input (Inside Card)
                    _buildChatInput(aiState),
                    const SizedBox(height: AppSpacing.sm),
                    childProfileAsync.when(
                      data: (child) => Center(
                        child: Text(
                          "BearAI uses ${child.name}'s in-app activity data only.",
                          style: AppTextStyles.tiny.copyWith(color: AppColors.mutedText),
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
    AsyncValue subjectsAsync,
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
              const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              const Text('AI Insight', style: AppTextStyles.bodyBold),
              const Spacer(),
              if (aiState.isLoading && !aiState.hasGeneratedInsight)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (displayInsight != null)
            Text(displayInsight, style: AppTextStyles.body),
          if (displayInsight == null && !aiState.isLoading)
            const Text('Generating weekly insight...', style: AppTextStyles.body),
          if (displayInsight == null && aiState.isLoading)
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

  Widget _buildSuggestionChips(AsyncValue childProfileAsync) {
    return childProfileAsync.when(
      data: (child) {
        final suggestions = [
          "How is ${child.name} doing this week?",
          "Suggest a reward amount",
          "What daily goal should I set?",
          "Which subject needs more focus?",
        ];
        
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: suggestions.map((s) => ActionChip(
            label: Text(s, style: AppTextStyles.tiny),
            backgroundColor: AppColors.primaryLight,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.r(AppRadius.lg)),
            onPressed: () {
              ref.read(bearAiProvider.notifier).sendMessage(widget.childId, s);
              _scrollToBottom();
            },
          )).toList(),
        );
      },
      loading: () => const SizedBox(),
      error: (e, st) => const SizedBox(),
    );
  }

  Widget _buildChatInput(BearAiState aiState) {
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
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
                hintStyle: AppTextStyles.small,
              ),
              style: AppTextStyles.small,
              onSubmitted: (text) {
                ref.read(bearAiProvider.notifier).sendMessage(widget.childId, text);
                _messageController.clear();
                _scrollToBottom();
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: AppColors.primary),
            onPressed: aiState.isLoading ? null : () {
              ref.read(bearAiProvider.notifier).sendMessage(
                widget.childId, 
                _messageController.text,
              );
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
  const _ChatMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
          boxShadow: isUser ? null : AppShadows.card,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Text(
          message.content,
          style: AppTextStyles.small.copyWith(
            color: isUser ? Colors.white : AppColors.foreground,
          ),
        ),
      ),
    );
  }
}
