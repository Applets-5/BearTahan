import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subject_weakness_info.dart';
import 'data_providers.dart';

final subjectStrengthProvider = StreamProvider.family<Map<String, SubjectWeaknessInfo>, String>((ref, childId) {
  final subjectsAsync = ref.watch(subjectProgressProvider(childId));
  final attemptsAsync = ref.watch(attemptsProvider(childId));

  // Combine streams
  return subjectsAsync.when(
    data: (subjects) {
      return attemptsAsync.when(
        data: (attempts) {
          final Map<String, SubjectWeaknessInfo> results = {};
          
          for (final subject in subjects) {
            final subjectAttempts = attempts.where((a) => a['subjectId'] == subject.id).toList();
            
            double accuracy = 0;
            int totalTime = 0;
            String weakestLevel = "N/A";
            String weakestChapter = "N/A";
            
            if (subjectAttempts.isNotEmpty) {
              int totalScore = 0;
              int totalQuestions = 0;
              int minScore = 101;
              
              for (final attempt in subjectAttempts) {
                final score = (attempt['score'] ?? 0) as int;
                final total = (attempt['total'] ?? 10) as int;
                totalScore += score;
                totalQuestions += total;
                totalTime += (attempt['timeInSeconds'] ?? 0) as int;
                
                final attemptAccuracy = (score / total) * 100;
                if (attemptAccuracy < minScore) {
                  minScore = attemptAccuracy.toInt();
                  weakestLevel = attempt['levelId'] ?? "N/A";
                  // Chapter mapping would ideally be done via subjectChaptersProvider
                  // but for simplicity here we'll use levelId prefix
                  if (weakestLevel.contains('_')) {
                    weakestChapter = weakestLevel.split('_')[0].toUpperCase();
                  }
                }
              }
              accuracy = totalQuestions > 0 ? totalScore / totalQuestions : 0;
            }
            
            final avgTime = subjectAttempts.isNotEmpty ? totalTime ~/ subjectAttempts.length : 0;
            
            // Normalize time: assuming 60s is good (1.0), 180s is poor (0.0)
            double timeScore = 1.0 - (avgTime / 180.0).clamp(0.0, 1.0);
            
            final double progressScore = subject.progress / 100.0;
            final double strengthScore = (progressScore + accuracy + timeScore) / 3.0;

            String suggestion = "Great job!";
            if (strengthScore < 0.4) {
              suggestion = "Needs more practice in $weakestChapter.";
            } else if (strengthScore < 0.7) {
              suggestion = "Good progress, focus on accuracy.";
            }

            results[subject.id] = SubjectWeaknessInfo(
              subjectId: subject.id,
              subjectName: subject.name,
              strengthScore: strengthScore,
              weakestChapter: weakestChapter,
              weakestLevel: weakestLevel,
              accuracy: accuracy * 100,
              averageTimeSeconds: avgTime,
              suggestion: suggestion,
            );
          }
          
          return Stream.value(results);
        },
        loading: () => const Stream.empty(),
        error: (e, st) => Stream.error(e, st),
      );
    },
    loading: () => const Stream.empty(),
    error: (e, st) => Stream.error(e, st),
  );
});
