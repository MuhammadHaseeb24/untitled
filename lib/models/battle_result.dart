enum BattleOutcome { victory, defeat, draw }

class BattleResult {
  const BattleResult({
    required this.battleId,
    required this.levelId,
    required this.outcome,
    required this.timeSeconds,
    required this.playerFortressFraction,
    required this.unitsLost,
    required this.unitsKilled,
    required this.stars,
  });

  final int battleId;
  final int levelId;
  final BattleOutcome outcome;
  final double timeSeconds;
  final double playerFortressFraction;
  final int unitsLost;
  final int unitsKilled;

  /// 0 unless the outcome is a victory.
  final int stars;
}

class RewardSummary {
  const RewardSummary({
    required this.coinsAwarded,
    required this.newStars,
    required this.firstCompletion,
    required this.unlockedNextLevel,
  });

  static const none = RewardSummary(
    coinsAwarded: 0,
    newStars: 0,
    firstCompletion: false,
    unlockedNextLevel: false,
  );

  final int coinsAwarded;
  final int newStars;
  final bool firstCompletion;
  final bool unlockedNextLevel;
}
