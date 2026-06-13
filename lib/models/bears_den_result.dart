enum BearsDenAwardStatus { awarded, dailyCap, notEarned, saveFailed }

class BearsDenResult {
  const BearsDenResult({
    required this.performanceStars,
    required this.awardedStars,
    required this.status,
  });

  final int performanceStars;
  final int awardedStars;
  final BearsDenAwardStatus status;
}
