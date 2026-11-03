import '../../models/battle_result.dart';
import '../../models/level_model.dart';
import '../../models/save_data.dart';

/// Pure rules for stars and rewards, shared by the game and the save layer.
class ResultCalculator {
  ResultCalculator._();

  static const int coinsPerNewStar = 20;

  /// Statue health needed for the 3rd star on survival levels.
  static const double survivalTopHealth = 0.8;

  /// 1 star for winning, +1 for keeping the fortress above the level's health
  /// threshold, +1 for finishing within the par time.
  static int starsFor(
    LevelModel level,
    double fortressFraction,
    double timeSeconds,
  ) {
    var stars = 1;
    if (fortressFraction >= level.starFortressThreshold) stars++;
    if (level.isSurvival) {
      // Survival levels: the third star is for a nearly untouched statue.
      if (fortressFraction >= survivalTopHealth) stars++;
    } else if (timeSeconds <= level.parTimeSeconds) {
      stars++;
    }
    return stars;
  }

  static BattleOutcome outcomeFor({
    required bool playerAlive,
    required bool enemyAlive,
  }) {
    if (!playerAlive && !enemyAlive) return BattleOutcome.draw;
    if (!enemyAlive) return BattleOutcome.victory;
    return BattleOutcome.defeat;
  }

  /// Coins for a finished battle. The level reward is paid only on the first
  /// completion; afterwards only stars not earned before pay a bonus, so a
  /// replay can never duplicate rewards.
  static RewardSummary rewardFor({
    required LevelModel level,
    required LevelRecord? previous,
    required int stars,
    required bool hasNextLevel,
    required int highestUnlocked,
  }) {
    final previousStars = previous?.stars ?? 0;
    final newStars = stars > previousStars ? stars - previousStars : 0;
    final first = previous == null;
    final coins = (first ? level.rewardCoins : 0) + newStars * coinsPerNewStar;
    return RewardSummary(
      coinsAwarded: coins,
      newStars: newStars,
      firstCompletion: first,
      unlockedNextLevel: hasNextLevel && highestUnlocked < level.id + 1,
    );
  }

  static String formatTime(double seconds) {
    final s = seconds.floor();
    final m = s ~/ 60;
    final r = s % 60;
    return '$m:${r.toString().padLeft(2, '0')}';
  }
}
