import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/ability_model.dart';
import '../models/json_utils.dart';
import '../models/level_model.dart';
import '../models/unit_model.dart';
import '../models/upgrade_model.dart';

/// All static game data, loaded from assets/data/*.json and validated.
class GameData {
  GameData({
    required this.units,
    required this.abilities,
    required this.levels,
    required this.upgrades,
  });

  final Map<String, UnitModel> units;
  final Map<String, AbilityModel> abilities;
  final List<LevelModel> levels;
  final List<UpgradeModel> upgrades;

  LevelModel? levelById(int id) {
    for (final l in levels) {
      if (l.id == id) return l;
    }
    return null;
  }

  static Future<Map<String, dynamic>> _readJson(
    AssetBundle bundle,
    String name,
  ) async {
    final String text;
    try {
      text = await bundle.loadString('assets/data/$name');
    } catch (e) {
      throw DataFormatException('$name: could not be loaded ($e)');
    }
    try {
      return asMap(jsonDecode(text), name);
    } on FormatException catch (e) {
      throw DataFormatException('$name: invalid JSON (${e.message})');
    }
  }

  static Future<GameData> load(AssetBundle bundle) async {
    final unitsJson = await _readJson(bundle, 'units.json');
    final abilitiesJson = await _readJson(bundle, 'abilities.json');
    final levelsJson = await _readJson(bundle, 'levels.json');
    final upgradesJson = await _readJson(bundle, 'upgrades.json');

    final units = <String, UnitModel>{};
    for (final u in asList(unitsJson['units'], 'units.json')) {
      final m = UnitModel.fromJson(asMap(u, 'units.json[]'));
      check(
        !units.containsKey(m.id),
        'units.json',
        'duplicate unit id "${m.id}"',
      );
      units[m.id] = m;
    }
    final abilities = <String, AbilityModel>{};
    for (final a in asList(abilitiesJson['abilities'], 'abilities.json')) {
      final m = AbilityModel.fromJson(asMap(a, 'abilities.json[]'));
      abilities[m.id] = m;
    }
    final levels = [
      for (final l in asList(levelsJson['levels'], 'levels.json'))
        LevelModel.fromJson(asMap(l, 'levels.json[]')),
    ]..sort((a, b) => a.id.compareTo(b.id));
    final upgrades = [
      for (final u in asList(upgradesJson['upgrades'], 'upgrades.json'))
        UpgradeModel.fromJson(asMap(u, 'upgrades.json[]')),
    ];

    check(levels.isNotEmpty, 'levels.json', 'no levels defined');
    for (var i = 0; i < levels.length; i++) {
      check(
        levels[i].id == i + 1,
        'levels.json',
        'level ids must be 1..N without gaps (found ${levels[i].id})',
      );
    }
    for (final level in levels) {
      final ctx = 'level ${level.id}';
      for (final id in [...level.unlockedUnits, ...level.enemyUnitIds]) {
        check(units.containsKey(id), ctx, 'unknown unit "$id"');
      }
      for (final id in level.availableAbilities) {
        check(abilities.containsKey(id), ctx, 'unknown ability "$id"');
      }
    }
    return GameData(
      units: units,
      abilities: abilities,
      levels: levels,
      upgrades: upgrades,
    );
  }
}
