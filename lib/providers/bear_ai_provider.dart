import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bear_ai_message.dart';

class BearAiNotifier extends Notifier<BearAiState> {
  @override
  BearAiState build() {
    return BearAiState();
  }

  Future<void> generateInsightIfNeeded(
    String childId, {
    String? existingInsight,
    DateTime? lastDate,
  }) async {
    if (state.hasGeneratedInsight || state.isLoading) return;

    // If we have a fresh insight (less than 7 days old), use it directly
    if (existingInsight != null && lastDate != null) {
      final now = DateTime.now();
      final difference = now.difference(lastDate).inDays;
      if (difference < 7) {
        state = state.copyWith(
          insight: existingInsight,
          hasGeneratedInsight: true,
        );
        return;
      }
    }

    state = state.copyWith(isLoading: true);

    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('getBearAiInsight')
          .call({
        'childId': childId,
      });

      state = state.copyWith(
        insight: result.data['insight'] as String,
        isLoading: false,
        hasGeneratedInsight: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> sendMessage(String childId, String text) async {
    if (text.trim().isEmpty || state.isLoading) return;

    final userMessage = BearAiMessage(
      content: text,
      role: MessageRole.user,
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
    );

    try {
      final history = state.messages.map((m) => {
        'role': m.role.name,
        'content': m.content,
      }).toList();

      final result = await FirebaseFunctions.instance
          .httpsCallable('askBearAi')
          .call({
        'childId': childId,
        'message': text,
        'history': history,
      });

      final assistantMessage = BearAiMessage(
        content: result.data['text'] as String,
        role: MessageRole.assistant,
      );

      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final bearAiProvider = NotifierProvider<BearAiNotifier, BearAiState>(
  BearAiNotifier.new,
);
