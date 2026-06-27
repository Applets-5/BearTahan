bool shouldPlayQuestionFeedback(
  String? questionType, {
  bool allowStrokeTrace = false,
}) {
  return allowStrokeTrace || questionType?.toLowerCase() != 'stroke_trace';
}
