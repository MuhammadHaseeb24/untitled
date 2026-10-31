import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kingdoms_of_ember/game/game_types.dart';
import 'package:kingdoms_of_ember/game/systems/economy_system.dart';
import 'package:kingdoms_of_ember/game/systems/enemy_ai_system.dart';
import 'package:kingdoms_of_ember/game/systems/level_system.dart';
import 'package:kingdoms_of_ember/models/ability_model.dart';
import 'package:kingdoms_of_ember/models/battle_result.dart';
import 'package:kingdoms_of_ember/models/json_utils.dart';
import 'package:kingdoms_of_ember/models/level_model.dart';
import 'package:kingdoms_of_ember/models/save_data.dart';
import 'package:kingdoms_of_ember/models/unit_model.dart';
import 'package:kingdoms_of_ember/models/upgrade_model.dart';

Map<String, dynamic> _json(String file) =>
    jsonDecode(File('assets/data/$file').readAsStringSync())
        as Map<String, dynamic>;

Map<String, UnitModel> _units() => {
  for (final u in (_json('units.json')['units'] as List))
    (u as Map<String, dynamic>)['id'] as String: UnitModel.fromJson(u),
};

List<LevelModel> _levels() => [
  for (final l in (_json('levels.json')['levels'] as List))
    LevelModel.fromJson(l as Map<String, dynamic>),
];

void main() {
  group('Economy', () {
    test('passive income is granted once per interval', () {
      final e = EconomySystem(
        startingGold: 250,
        passiveIncome: 10,
        intervalSeconds: 5,
      );
      e.tick(4.9);
      expect(e.gold, 250);
      e.tick(0.1);
      expect(e.gold, 260);
      e.tick(10);
      expect(e.gold, 280);
    });

    test('spending deducts exactly once and never goes negative', () {
      final e = EconomySystem(
        startingGold: 100,
        passiveIncome: 0,
        intervalSeconds: 5,
      );
      expect(e.trySpend(50), isTrue);
      expect(e.gold, 50);
      expect(e.trySpend(80), isFalse);
      expect(e.gold, 50);
      expect(e.trySpend(-5), isFalse);
      expect(e.gold, 50);
    });
  });

  group('Recruit queue', () {
    test('units finish in order and count as reserved population', () {
      final units = _units();
      final q = RecruitQueue();
      q.enqueue(units['ember_squire']!);
      q.enqueue(units['ash_archer']!);
      expect(q.reservedPopulation, 2);
      expect(q.tick(1.0), isEmpty);
      final first = q.tick(0.3);
      expect(first.map((u) => u.id).toList(), ['ember_squire']);
      expect(q.length, 1);
      final second = q.tick(2.0);
      expect(second.map((u) => u.id).toList(), ['ash_archer']);
      expect(q.isEmpty, isTrue);
    });
  });

  group('Cooldown', () {
    test('starts, ticks and never goes negative', () {
      final c = Cooldown(20);
      expect(c.ready, isTrue);
      c.start();
      expect(c.ready, isFalse);
      c.tick(25);
      expect(c.remaining, 0);
      expect(c.ready, isTrue);
    });
  });

  group('Stars and rewards', () {
    test('stars follow the documented criteria', () {
      final level = _levels().first;
      expect(ResultCalculator.starsFor(level, 0.3, 9999), 1);
      expect(ResultCalculator.starsFor(level, 0.9, 9999), 2);
      expect(ResultCalculator.starsFor(level, 0.9, 10), 3);
      expect(ResultCalculator.starsFor(level, 0.1, 10), 2);
    });

    test('simultaneous fortress destruction is a draw', () {
      expect(
        ResultCalculator.outcomeFor(playerAlive: false, enemyAlive: false),
        BattleOutcome.draw,
      );
      expect(
        ResultCalculator.outcomeFor(playerAlive: true, enemyAlive: false),
        BattleOutcome.victory,
      );
      expect(
        ResultCalculator.outcomeFor(playerAlive: false, enemyAlive: true),
        BattleOutcome.defeat,
      );
    });

    test('replaying a level never repeats the level reward', () {
      final level = _levels().first;
      final first = ResultCalculator.rewardFor(
        level: level,
        previous: null,
        stars: 2,
        hasNextLevel: true,
        highestUnlocked: 1,
      );
      expect(
        first.coinsAwarded,
        level.rewardCoins + 2 * ResultCalculator.coinsPerNewStar,
      );
      expect(first.unlockedNextLevel, isTrue);
      final replay = ResultCalculator.rewardFor(
        level: level,
        previous: const LevelRecord(stars: 2),
        stars: 2,
        hasNextLevel: true,
        highestUnlocked: 2,
      );
      expect(replay.coinsAwarded, 0);
      final better = ResultCalculator.rewardFor(
        level: level,
        previous: const LevelRecord(stars: 2),
        stars: 3,
        hasNextLevel: true,
        highestUnlocked: 2,
      );
      expect(better.coinsAwarded, ResultCalculator.coinsPerNewStar);
    });
  });

  group('Save data', () {
    test('round-trips', () {
      final s = SaveData.fresh()
        ..coins = 120
        ..completed[1] = const LevelRecord(stars: 3, bestTime: 90)
        ..upgrades['eco_income'] = 2
        ..tutorialsDone.add('level_1');
      final parsed = SaveData.tryParse(s.encode(), levelCount: 10)!;
      expect(parsed.coins, 120);
      expect(parsed.completed[1]!.stars, 3);
      expect(parsed.highestUnlocked, 2);
      expect(parsed.upgrades['eco_income'], 2);
      expect(parsed.tutorialsDone, contains('level_1'));
    });

    test('rejects garbage and sanitises bad fields', () {
      expect(SaveData.tryParse('not json', levelCount: 10), isNull);
      expect(SaveData.tryParse('[1,2]', levelCount: 10), isNull);
      expect(SaveData.tryParse('{"version":"x"}', levelCount: 10), isNull);
      final s = SaveData.tryParse(
        '{"version":1,"coins":-50,"highestUnlocked":99,"completed":{"3":{"stars":9},"abc":{}},"settings":{"masterVolume":7}}',
        levelCount: 10,
      )!;
      expect(s.coins, 0);
      expect(s.highestUnlocked, 10);
      expect(s.completed[3]!.stars, 3);
      expect(s.completed.length, 1);
      expect(s.settings.masterVolume, 1.0);
    });
  });

  group('Data files', () {
    test('all levels parse and reference known units and abilities', () {
      final units = _units();
      final abilities = {
        for (final a in (_json('abilities.json')['abilities'] as List))
          (a as Map<String, dynamic>)['id'] as String: AbilityModel.fromJson(a),
      };
      final levels = _levels();
      expect(levels.length, 10);
      for (var i = 0; i < levels.length; i++) {
        expect(levels[i].id, i + 1);
        for (final id in [
          ...levels[i].unlockedUnits,
          ...levels[i].enemyUnitIds,
        ]) {
          expect(
            units.containsKey(id),
            isTrue,
            reason: 'level ${levels[i].id}: $id',
          );
        }
        for (final id in levels[i].availableAbilities) {
          expect(abilities.containsKey(id), isTrue);
        }
      }
    });

    test('invalid unit data gives a readable error', () {
      expect(
        () => UnitModel.fromJson({
          'id': 'x',
          'name': 'X',
          'kind': 'melee',
          'cost': -1,
          'health': 10,
          'damage': 1,
          'attackRange': 10,
          'attackCooldown': 1,
          'windup': 0.1,
          'moveSpeed': 10,
        }),
        throwsA(isA<DataFormatException>()),
      );
    });

    test('upgrade bonuses are capped at max level', () {
      final models = [
        for (final u in (_json('upgrades.json')['upgrades'] as List))
          UpgradeModel.fromJson(u as Map<String, dynamic>),
      ];
      final b = UpgradeBonuses.fromLevels(models, {
        'population': 99,
        'army_damage': 2,
      });
      expect(b.populationBonus, 5);
      expect(b.damageMultiplier, closeTo(1.10, 1e-9));
    });
  });

  group('Enemy AI', () {
    test('only spends gold it has and respects the population limit', () {
      final units = _units();
      final level = _levels().first;
      final ai = EnemyAiSystem(config: level.enemy, catalog: units);
      final econ = EconomySystem(
        startingGold: 10,
        passiveIncome: 0,
        intervalSeconds: 5,
      );
      var recruited = 0;
      for (var i = 0; i < 400; i++) {
        final out = ai.think(
          0.5,
          AiView(
            armyCount: 0,
            population: 0,
            fortressThreatened: false,
            elapsed: i * 0.5,
          ),
          econ,
        );
        recruited += out.paid.length;
      }
      expect(recruited, 0);
      expect(econ.gold, 10);

      final rich = EconomySystem(
        startingGold: 100000,
        passiveIncome: 0,
        intervalSeconds: 5,
      );
      final full = ai.think(
        30,
        AiView(
          armyCount: 0,
          population: level.enemy.populationLimit,
          fortressThreatened: false,
          elapsed: 100,
        ),
        rich,
      );
      expect(full.paid, isEmpty);
    });

    test('attacks once the army is big enough, defends when threatened', () {
      final units = _units();
      final level = _levels().first;
      final ai = EnemyAiSystem(config: level.enemy, catalog: units);
      final econ = EconomySystem(
        startingGold: 0,
        passiveIncome: 0,
        intervalSeconds: 5,
      );
      ai.think(
        0.6,
        AiView(
          armyCount: 5,
          population: 5,
          fortressThreatened: false,
          elapsed: 100,
        ),
        econ,
      );
      expect(ai.command, Command.attack);
      ai.think(
        0.6,
        AiView(
          armyCount: 1,
          population: 1,
          fortressThreatened: true,
          elapsed: 101,
        ),
        econ,
      );
      expect(ai.command, Command.defend);
    });
  });
}
