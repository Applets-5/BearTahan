enum MessageRole { user, assistant, error }

class BearAiMessage {
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final dynamic retryData;

  BearAiMessage({
    required this.content,
    required this.role,
    DateTime? timestamp,
    this.retryData,
  }) : timestamp = timestamp ?? DateTime.now();
}

class BearAiState {
  final String? insight;
  final String? insightError;
  final List<BearAiMessage> messages;
  final bool isChatLoading;
  final bool isInsightLoading;
  final bool hasGeneratedInsight;

  BearAiState({
    this.insight,
    this.insightError,
    this.messages = const [],
    this.isChatLoading = false,
    this.isInsightLoading = false,
    this.hasGeneratedInsight = false,
  });

  BearAiState copyWith({
    Object? insight = _sentinel,
    Object? insightError = _sentinel,
    List<BearAiMessage>? messages,
    bool? isChatLoading,
    bool? isInsightLoading,
    bool? hasGeneratedInsight,
  }) {
    return BearAiState(
      insight: insight == _sentinel ? this.insight : (insight as String?),
      insightError: insightError == _sentinel
          ? this.insightError
          : (insightError as String?),
      messages: messages ?? this.messages,
      isChatLoading: isChatLoading ?? this.isChatLoading,
      isInsightLoading: isInsightLoading ?? this.isInsightLoading,
      hasGeneratedInsight: hasGeneratedInsight ?? this.hasGeneratedInsight,
    );
  }
}

const _sentinel = Object();
