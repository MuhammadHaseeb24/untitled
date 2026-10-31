import 'json_utils.dart';

enum Difficulty { easy, normal, hard }

Difficulty _parseDifficulty(String s, String ctx) {
  for (final d in Difficulty.values) {
    if (d.name == s) return d;
  }
  throw DataFormatException('$ctx: unknown difficulty "$s"');
}

class EnemyWave {
  const EnemyWave({required this.at, required this.units});
  final double at;
  final List<String> units;
}

class EnemyConfig {
  const EnemyConfig({
    required this.startingGold,
    required this.passiveIncome,
    required this.incomeIntervalSeconds,
    required this.populationLimit,
    required this.recruitIntervalSeconds,
    required this.buildOrder,
    required this.attackThreshold,
    required this.retreatBelow,
    required this.firstAttackAfterSeconds,
    required this.healthMultiplier,
    required this.damageMultiplier,
    required this.waves,
  });

  final int startingGold;
  final int passiveIncome;
  final double incomeIntervalSeconds;
  final int populationLimit;
  final double recruitIntervalSeconds;
  final List<String> buildOrder;
  final int attackThreshold;
  final int retreatBelow;
  final double firstAttackAfterSeconds;
  final double healthMultiplier;
  final double damageMultiplier;
  final List<EnemyWave> waves;

  factory EnemyConfig.fromJson(Map<String, dynamic> j, String ctx) {
    final waves = <EnemyWave>[];
    if (j.containsKey('waves')) {
      for (final w in asList(j['waves'], '$ctx.waves')) {
        final wm = asMap(w, '$ctx.waves[]');
        waves.add(
          EnemyWave(
            at: reqDouble(wm, 'at', '$ctx.waves[]'),
            units: optStringList(wm, 'units', '$ctx.waves[]'),
          ),
        );
      }
      waves.sort((a, b) => a.at.compareTo(b.at));
    }
    final cfg = EnemyConfig(
      startingGold: reqInt(j, 'startingGold', ctx),
      passiveIncome: reqInt(j, 'passiveIncome', ctx),
      incomeIntervalSeconds: reqDouble(j, 'incomeIntervalSeconds', ctx),
      populationLimit: reqInt(j, 'populationLimit', ctx),
      recruitIntervalSeconds: reqDouble(j, 'recruitIntervalSeconds', ctx),
      buildOrder: optStringList(j, 'buildOrder', ctx),
      attackThreshold: reqInt(j, 'attackThreshold', ctx),
      retreatBelow: reqInt(j, 'retreatBelow', ctx),
      firstAttackAfterSeconds: reqDouble(j, 'firstAttackAfterSeconds', ctx),
      healthMultiplier: optDouble(j, 'healthMultiplier', ctx, 1),
      damageMultiplier: optDouble(j, 'damageMultiplier', ctx, 1),
      waves: waves,
    );
    check(cfg.buildOrder.isNotEmpty, ctx, 'buildOrder must not be empty');
    check(
      cfg.incomeIntervalSeconds > 0,
      ctx,
      'incomeIntervalSeconds must be > 0',
    );
    check(cfg.populationLimit > 0, ctx, 'populationLimit must be > 0');
    check(
      cfg.recruitIntervalSeconds > 0,
      ctx,
      'recruitIntervalSeconds must be > 0',
    );
    check(
      cfg.healthMultiplier > 0 && cfg.damageMultiplier > 0,
      ctx,
      'multipliers must be > 0',
    );
    return cfg;
  }
}

class TutorialStep {
  const TutorialStep({
    required this.id,
    required this.text,
    required this.highlight,
    required this.advance,
  });

  final String id;
  final String text;

  /// One of: gold, recruit, attack, defend, ability, or null.
  final String? highlight;

  /// One of: tap, recruit, attack, defend, ability.
  final String advance;

  static const _advances = {'tap', 'recruit', 'attack', 'defend', 'ability'};

  factory TutorialStep.fromJson(Map<String, dynamic> j, String ctx) {
    final advance = optString(j, 'advance', 'tap');
    check(
      _advances.contains(advance),
      ctx,
      'unknown tutorial advance "$advance"',
    );
    final hl = j['highlight'];
    return TutorialStep(
      id: reqString(j, 'id', ctx),
      text: reqString(j, 'text', ctx),
      highlight: hl is String ? hl : null,
      advance: advance,
    );
  }
}

class LevelModel {
  const LevelModel({
    required this.id,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.theme,
    required this.startingGold,
    required this.passiveIncome,
    required this.incomeIntervalSeconds,
    required this.playerFortressHealth,
    required this.enemyFortressHealth,
    required this.populationLimit,
    required this.unlockedUnits,
    required this.availableAbilities,
    required this.rewardCoins,
    required this.parTimeSeconds,
    required this.starFortressThreshold,
    required this.enemy,
    required this.tutorial,
  });

  final int id;
  final String name;
  final String description;
  final Difficulty difficulty;
  final int theme;
  final int startingGold;
  final int passiveIncome;
  final double incomeIntervalSeconds;
  final double playerFortressHealth;
  final double enemyFortressHealth;
  final int populationLimit;
  final List<String> unlockedUnits;
  final List<String> availableAbilities;
  final int rewardCoins;
  final double parTimeSeconds;
  final double starFortressThreshold;
  final EnemyConfig enemy;
  final List<TutorialStep> tutorial;

  String get tutorialKey => 'level_$id';

  /// Distinct enemy unit ids used by this level (build order + waves).
  List<String> get enemyUnitIds {
    final ids = <String>[...enemy.buildOrder];
    for (final w in enemy.waves) {
      ids.addAll(w.units);
    }
    return ids.toSet().toList();
  }

  factory LevelModel.fromJson(Map<String, dynamic> j) {
    final id = reqInt(j, 'id', 'level');
    final ctx = 'level $id';
    final tutorial = <TutorialStep>[];
    if (j.containsKey('tutorial')) {
      for (final s in asList(j['tutorial'], '$ctx.tutorial')) {
        tutorial.add(
          TutorialStep.fromJson(asMap(s, '$ctx.tutorial[]'), '$ctx.tutorial[]'),
        );
      }
    }
    final level = LevelModel(
      id: id,
      name: reqString(j, 'name', ctx),
      description: optString(j, 'description', ''),
      difficulty: _parseDifficulty(optString(j, 'difficulty', 'normal'), ctx),
      theme: optInt(j, 'theme', ctx, 0),
      startingGold: reqInt(j, 'startingGold', ctx),
      passiveIncome: reqInt(j, 'passiveIncome', ctx),
      incomeIntervalSeconds: reqDouble(j, 'incomeIntervalSeconds', ctx),
      playerFortressHealth: reqDouble(j, 'playerFortressHealth', ctx),
      enemyFortressHealth: reqDouble(j, 'enemyFortressHealth', ctx),
      populationLimit: reqInt(j, 'populationLimit', ctx),
      unlockedUnits: optStringList(j, 'unlockedUnits', ctx),
      availableAbilities: optStringList(j, 'availableAbilities', ctx),
      rewardCoins: reqInt(j, 'rewardCoins', ctx),
      parTimeSeconds: reqDouble(j, 'parTimeSeconds', ctx),
      starFortressThreshold: optDouble(j, 'starFortressThreshold', ctx, 0.6),
      enemy: EnemyConfig.fromJson(
        asMap(j['enemy'], '$ctx.enemy'),
        '$ctx.enemy',
      ),
      tutorial: tutorial,
    );
    check(
      level.unlockedUnits.isNotEmpty,
      ctx,
      'unlockedUnits must not be empty',
    );
    check(
      level.incomeIntervalSeconds > 0,
      ctx,
      'incomeIntervalSeconds must be > 0',
    );
    check(
      level.playerFortressHealth > 0 && level.enemyFortressHealth > 0,
      ctx,
      'fortress health must be > 0',
    );
    check(level.populationLimit > 0, ctx, 'populationLimit must be > 0');
    check(level.parTimeSeconds > 0, ctx, 'parTimeSeconds must be > 0');
    check(
      level.starFortressThreshold > 0 && level.starFortressThreshold <= 1,
      ctx,
      'starFortressThreshold must be in (0, 1]',
    );
    return level;
  }
}
