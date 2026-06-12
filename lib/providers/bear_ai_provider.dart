import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bear_ai_message.dart';
import 'package:flutter/foundation.dart';

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
    if (state.hasGeneratedInsight || state.isInsightLoading) return;

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

    state = state.copyWith(isInsightLoading: true, insightError: null);

    try {
      final result = await FirebaseFunctions.instanceFor(
        region: 'asia-southeast1',
      ).httpsCallable('getBearAiInsight').call({'childId': childId});

      state = state.copyWith(
        insight: result.data['insight'] as String,
        isInsightLoading: false,
        hasGeneratedInsight: true,
      );
    } catch (e) {
      debugPrint("🐻 BearAI Insight Error: $e");
      
      String errorText = "Couldn't load weekly insight.";
      if (e is FirebaseFunctionsException && e.code == 'resource-exhausted') {
        errorText = e.message ?? "Rate limit reached. Please wait.";
      } else if (e is FirebaseFunctionsException) {
        errorText = e.message ?? "BearAI Insight Error: ${e.code}";
      }

      state = state.copyWith(
        isInsightLoading: false,
        insightError: errorText,
      );
    }
  }

  Future<void> sendMessage(String childId, String text, {bool isRetry = false}) async {
    if (text.trim().isEmpty || state.isChatLoading) return;

    // 1. Build history BEFORE potentially modifying state
    final history = state.messages
        .where((m) => m.role != MessageRole.error)
        .map(
          (m) => {
            'role': m.role.name == 'assistant' ? 'model' : 'user',
            'content': m.content,
          },
        )
        .toList();

    if (isRetry) {
      // Issue 10: Remove the previous error message before retrying
      state = state.copyWith(
        messages: state.messages.where((m) => m.role != MessageRole.error).toList(),
        isChatLoading: true,
      );
    } else {
      final userMessage = BearAiMessage(content: text, role: MessageRole.user);
      state = state.copyWith(
        messages: [...state.messages, userMessage],
        isChatLoading: true,
      );
    }

    try {
      final result =
          await FirebaseFunctions.instanceFor(region: 'asia-southeast1')
              .httpsCallable('askBearAi')
              .call({'childId': childId, 'message': text, 'history': history});

      final assistantMessage = BearAiMessage(
        content: result.data['text'] as String,
        role: MessageRole.assistant,
      );

      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isChatLoading: false,
      );
    } catch (e) {
      debugPrint("🐻 BearAI Error: $e");

      String errorText = "Couldn't reach BearAI. Tap to try again.";
      if (e is FirebaseFunctionsException && e.code == 'resource-exhausted') {
        errorText = e.message ?? "Please wait a bit before asking again.";
      }

      final errorMessage = BearAiMessage(
        content: errorText,
        role: MessageRole.error,
        retryData: text,
      );
      state = state.copyWith(
        messages: [...state.messages, errorMessage],
        isChatLoading: false,
      );
    }
  }
}

final bearAiProvider = NotifierProvider<BearAiNotifier, BearAiState>(
  BearAiNotifier.new,
);