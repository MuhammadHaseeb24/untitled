import 'dart:math';

import 'json_utils.dart';

enum UpgradeEffect {
  startingGold,
  miningYield,
  fortressHealth,
  armyDamage,
  armyHealth,
  population,
}

UpgradeEffect _parseEffect(String s, String ctx) {
  switch (s) {
    case 'starting_gold':
      return UpgradeEffect.startingGold;
    case 'mining_yield':
      return UpgradeEffect.miningYield;
    case 'fortress_health':
      return UpgradeEffect.fortressHealth;
    case 'army_damage':
      return UpgradeEffect.armyDamage;
    case 'army_health':
      return UpgradeEffect.armyHealth;
    case 'population':
      return UpgradeEffect.population;
  }
  throw DataFormatException('$ctx: unknown effect "$s"');
}

class UpgradeModel {
  const UpgradeModel({
    required this.id,
    required this.category,
    required this.name,
    required this.description,
    required this.effect,
    required this.perLevel,
    required this.maxLevel,
    required this.baseCost,
    required this.costGrowth,
  });

  final String id;
  final String category;
  final String name;
  final String description;
  final UpgradeEffect effect;
  final double perLevel;
  final int maxLevel;
  final int baseCost;
  final double costGrowth;

  /// Cost of buying the next level when [currentLevel] is owned.
  int costFor(int currentLevel) =>
      (baseCost * pow(costGrowth, currentLevel)).round();

  bool isPercent() =>
      effect == UpgradeEffect.fortressHealth ||
      effect == UpgradeEffect.armyDamage ||
      effect == UpgradeEffect.armyHealth;

  /// Human readable total effect at [level], e.g. "+15%" or "+50 gold".
  String describeEffect(int level) {
    final total = perLevel * level;
    if (isPercent()) return '+${(total * 100).round()}%';
    switch (effect) {
      case UpgradeEffect.startingGold:
        return '+${total.round()} starting gold';
      case UpgradeEffect.miningYield:
        return '+${total.round()} gold per trip';
      case UpgradeEffect.population:
        return '+${total.round()} troops';
      default:
        return '+${total.round()}';
    }
  }

  factory UpgradeModel.fromJson(Map<String, dynamic> j) {
    final id = reqString(j, 'id', 'upgrade');
    final ctx = 'upgrade "$id"';
    final m = UpgradeModel(
      id: id,
      category: reqString(j, 'category', ctx),
      name: reqString(j, 'name', ctx),
      description: optString(j, 'description', ''),
      effect: _parseEffect(reqString(j, 'effect', ctx), ctx),
      perLevel: reqDouble(j, 'perLevel', ctx),
      maxLevel: reqInt(j, 'maxLevel', ctx),
      baseCost: reqInt(j, 'baseCost', ctx),
      costGrowth: optDouble(j, 'costGrowth', ctx, 1.5),
    );
    check(m.maxLevel > 0, ctx, 'maxLevel must be > 0');
    check(m.baseCost > 0, ctx, 'baseCost must be > 0');
    check(m.costGrowth >= 1, ctx, 'costGrowth must be >= 1');
    return m;
  }
}

/// Aggregated effect of all purchased upgrades.
class UpgradeBonuses {
  const UpgradeBonuses({
    this.startingGold = 0,
    this.miningBonus = 0,
    this.fortressHealthMultiplier = 1,
    this.damageMultiplier = 1,
    this.healthMultiplier = 1,
    this.populationBonus = 0,
  });

  static const none = UpgradeBonuses();

  final int startingGold;
  final int miningBonus;
  final double fortressHealthMultiplier;
  final double damageMultiplier;
  final double healthMultiplier;
  final int populationBonus;

  factory UpgradeBonuses.fromLevels(
    List<UpgradeModel> models,
    Map<String, int> levels,
  ) {
    var gold = 0.0, income = 0.0, fort = 0.0, dmg = 0.0, hp = 0.0, pop = 0.0;
    for (final m in models) {
      final lvl = clampInt(levels[m.id] ?? 0, 0, m.maxLevel);
      final total = m.perLevel * lvl;
      switch (m.effect) {
        case UpgradeEffect.startingGold:
          gold += total;
        case UpgradeEffect.miningYield:
          income += total;
        case UpgradeEffect.fortressHealth:
          fort += total;
        case UpgradeEffect.armyDamage:
          dmg += total;
        case UpgradeEffect.armyHealth:
          hp += total;
        case UpgradeEffect.population:
          pop += total;
      }
    }
    return UpgradeBonuses(
      startingGold: gold.round(),
      miningBonus: income.round(),
      fortressHealthMultiplier: 1 + fort,
      damageMultiplier: 1 + dmg,
      healthMultiplier: 1 + hp,
      populationBonus: pop.round(),
    );
  }
}
