class LevelProgressResult {
  const LevelProgressResult({
    required this.performanceStars,
    required this.newStarsAwarded,
    required this.dailyBonusStars,
    required this.didImprove,
    required this.didEscalate,
    this.bestStars = 0,
  });

  final int performanceStars;
  final int newStarsAwarded;
  final int dailyBonusStars;
  final bool didImprove;
  final bool didEscalate;
  final int bestStars;

  int get totalWalletStarsAwarded => newStarsAwarded + dailyBonusStars;
}
