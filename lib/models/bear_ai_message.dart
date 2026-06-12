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
    String? insight,
    String? insightError,
    List<BearAiMessage>? messages,
    bool? isChatLoading,
    bool? isInsightLoading,
    bool? hasGeneratedInsight,
  }) {
    return BearAiState(
      insight: insight ?? this.insight,
      insightError: insightError ?? this.insightError,
      messages: messages ?? this.messages,
      isChatLoading: isChatLoading ?? this.isChatLoading,
      isInsightLoading: isInsightLoading ?? this.isInsightLoading,
      hasGeneratedInsight: hasGeneratedInsight ?? this.hasGeneratedInsight,
    );
  }
}
