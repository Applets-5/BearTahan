enum MessageRole { user, assistant }

class BearAiMessage {
  final String content;
  final MessageRole role;
  final DateTime timestamp;

  BearAiMessage({
    required this.content,
    required this.role,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class BearAiState {
  final String? insight;
  final List<BearAiMessage> messages;
  final bool isLoading;
  final bool hasGeneratedInsight;

  BearAiState({
    this.insight,
    this.messages = const [],
    this.isLoading = false,
    this.hasGeneratedInsight = false,
  });

  BearAiState copyWith({
    String? insight,
    List<BearAiMessage>? messages,
    bool? isLoading,
    bool? hasGeneratedInsight,
  }) {
    return BearAiState(
      insight: insight ?? this.insight,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      hasGeneratedInsight: hasGeneratedInsight ?? this.hasGeneratedInsight,
    );
  }
}
