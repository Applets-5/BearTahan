import '../models/question.dart';

List<Question> selectBalancedMandarinL4Questions(
  List<Question> questions, {
  required int count,
}) {
  if (count <= 0) return const [];

  final tracing =
      questions
          .where((question) => question.type?.toLowerCase() == 'stroke_trace')
          .toList()
        ..shuffle();
  final exercises =
      questions
          .where((question) => question.type?.toLowerCase() != 'stroke_trace')
          .toList()
        ..shuffle();

  final selected = <Question>[];
  selected.addAll(exercises.take(count));
  if (selected.length < count) {
    selected.addAll(tracing.take(count - selected.length));
  }
  if (selected.length < count) {
    selected.addAll(
      questions
          .where((question) => !selected.contains(question))
          .take(count - selected.length),
    );
  }

  return selected..shuffle();
}
