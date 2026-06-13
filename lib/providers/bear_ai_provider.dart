import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bear_ai_message.dart';
import 'package:flutter/foundation.dart';

class BearAiNotifier extends Notifier<Map<String, BearAiState>> {
  @override
  Map<String, BearAiState> build() {
    return {};
  }

  BearAiState _getState(String childId) => state[childId] ?? BearAiState();

  void _updateState(String childId, BearAiState newState) {
    state = {...state, childId: newState};
  }

  Future<void> generateInsightIfNeeded(
    String childId, {
    String? existingInsight,
    DateTime? lastDate,
  }) async {
    final currentState = _getState(childId);
    if (currentState.hasGeneratedInsight || currentState.isInsightLoading) {
      return;
    }
    // If we have a fresh insight (less than 7 days old), use it directly
    if (existingInsight != null && lastDate != null) {
      final now = DateTime.now();
      final difference = now.difference(lastDate).inDays;
      if (difference < 7) {
        _updateState(
          childId,
          currentState.copyWith(
            insight: existingInsight,
            hasGeneratedInsight: true,
          ),
        );
        return;
      }
    }

    _updateState(
      childId,
      currentState.copyWith(isInsightLoading: true, insightError: null),
    );

    try {
      final result = await FirebaseFunctions.instanceFor(
        region: 'asia-southeast1',
      ).httpsCallable('getBearAiInsight').call({'childId': childId});

      final updatedState = _getState(childId);
      _updateState(
        childId,
        updatedState.copyWith(
          insight: result.data['insight'] as String,
          isInsightLoading: false,
          hasGeneratedInsight: true,
        ),
      );
    } catch (e) {
      debugPrint("🐻 BearAI Insight Error: $e");

      String errorText = "Couldn't load weekly insight.";
      if (e is FirebaseFunctionsException && e.code == 'resource-exhausted') {
        errorText = e.message ?? "Rate limit reached. Please wait.";
      } else if (e is FirebaseFunctionsException) {
        errorText = e.message ?? "BearAI Insight Error: ${e.code}";
      }

      final updatedState = _getState(childId);
      _updateState(
        childId,
        updatedState.copyWith(isInsightLoading: false, insightError: errorText),
      );
    }
  }

  Future<void> sendMessage(
    String childId,
    String text, {
    bool isRetry = false,
  }) async {
    final currentState = _getState(childId);
    if (text.trim().isEmpty || currentState.isChatLoading) return;

    // 1. Build history BEFORE potentially modifying state
    final history = currentState.messages
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
      _updateState(
        childId,
        currentState.copyWith(
          messages: currentState.messages
              .where((m) => m.role != MessageRole.error)
              .toList(),
          isChatLoading: true,
        ),
      );
    } else {
      final userMessage = BearAiMessage(content: text, role: MessageRole.user);
      _updateState(
        childId,
        currentState.copyWith(
          messages: [...currentState.messages, userMessage],
          isChatLoading: true,
        ),
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

      final updatedState = _getState(childId);
      _updateState(
        childId,
        updatedState.copyWith(
          messages: [...updatedState.messages, assistantMessage],
          isChatLoading: false,
        ),
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
      final updatedState = _getState(childId);
      _updateState(
        childId,
        updatedState.copyWith(
          messages: [...updatedState.messages, errorMessage],
          isChatLoading: false,
        ),
      );
    }
  }
}

final bearAiProvider =
    NotifierProvider<BearAiNotifier, Map<String, BearAiState>>(
      BearAiNotifier.new,
    );

final bearAiChildProvider = Provider.family<BearAiState, String>((
  ref,
  childId,
) {
  return ref.watch(bearAiProvider)[childId] ?? BearAiState();
});
