bool soundEffectsEnabled(Map<String, dynamic>? settings) {
  return settings?['soundEffects'] != false;
}

bool shouldPlayQuestionFeedback(
  String? questionType, {
  bool allowStrokeTrace = false,
}) {
  return allowStrokeTrace || questionType?.toLowerCase() != 'stroke_trace';
}
