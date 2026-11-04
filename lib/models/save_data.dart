import 'dart:convert';

import 'json_utils.dart';

class GameSettings {
  const GameSettings({
    this.masterVolume = 0.8,
    this.musicVolume = 0.6,
    this.sfxVolume = 0.9,
    this.musicOn = true,
    this.sfxOn = true,
    this.lowQuality = false,
  });

  final double masterVolume;
  final double musicVolume;
  final double sfxVolume;
  final bool musicOn;
  final bool sfxOn;
  final bool lowQuality;

  GameSettings copyWith({
    double? masterVolume,
    double? musicVolume,
    double? sfxVolume,
    bool? musicOn,
    bool? sfxOn,
    bool? lowQuality,
  }) => GameSettings(
    masterVolume: masterVolume ?? this.masterVolume,
    musicVolume: musicVolume ?? this.musicVolume,
    sfxVolume: sfxVolume ?? this.sfxVolume,
    musicOn: musicOn ?? this.musicOn,
    sfxOn: sfxOn ?? this.sfxOn,
    lowQuality: lowQuality ?? this.lowQuality,
  );

  Map<String, dynamic> toJson() => {
    'masterVolume': masterVolume,
    'musicVolume': musicVolume,
    'sfxVolume': sfxVolume,
    'musicOn': musicOn,
    'sfxOn': sfxOn,
    'lowQuality': lowQuality,
  };

  static double _vol(Object? v, double def) =>
      v is num && v.isFinite ? clampDouble(v.toDouble(), 0, 1) : def;
  static bool _bool(Object? v, bool def) => v is bool ? v : def;

  /// Tolerant parser: any missing or invalid field falls back to its default.
  factory GameSettings.fromJson(Object? raw) {
    const d = GameSettings();
    if (raw is! Map<String, dynamic>) return d;
    return GameSettings(
      masterVolume: _vol(raw['masterVolume'], d.masterVolume),
      musicVolume: _vol(raw['musicVolume'], d.musicVolume),
      sfxVolume: _vol(raw['sfxVolume'], d.sfxVolume),
      musicOn: _bool(raw['musicOn'], d.musicOn),
      sfxOn: _bool(raw['sfxOn'], d.sfxOn),
      lowQuality: _bool(raw['lowQuality'], d.lowQuality),
    );
  }
}

class LevelRecord {
  const LevelRecord({required this.stars, this.bestTime});
  final int stars;
  final double? bestTime;

  Map<String, dynamic> toJson() => {'stars': stars, 'bestTime': bestTime};
}

/// Versioned campaign save. Battle state is never stored here.
class SaveData {
  SaveData({
    required this.highestUnlocked,
    required this.completed,
    required this.coins,
    required this.upgrades,
    required this.tutorialsDone,
    required this.settings,
  });

  static const int currentVersion = 1;

  int highestUnlocked;
  Map<int, LevelRecord> completed;
  int coins;
  Map<String, int> upgrades;
  Set<String> tutorialsDone;
  GameSettings settings;

  factory SaveData.fresh({GameSettings settings = const GameSettings()}) =>
      SaveData(
        highestUnlocked: 1,
        completed: {},
        coins: 0,
        upgrades: {},
        tutorialsDone: {},
        settings: settings,
      );

  Map<String, dynamic> toJson() => {
    'version': currentVersion,
    'highestUnlocked': highestUnlocked,
    'completed': {
      for (final e in completed.entries) '${e.key}': e.value.toJson(),
    },
    'coins': coins,
    'upgrades': upgrades,
    'tutorialsDone': tutorialsDone.toList(),
    'settings': settings.toJson(),
  };

  String encode() => jsonEncode(toJson());

  /// Returns null when [raw] is not a usable save. Individual bad fields are
  /// sanitised instead of rejecting the whole save.
  static SaveData? tryParse(String raw, {required int levelCount}) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final version = decoded['version'];
      if (version is! int || version < 1) return null;

      final completed = <int, LevelRecord>{};
      final rawCompleted = decoded['completed'];
      if (rawCompleted is Map<String, dynamic>) {
        for (final e in rawCompleted.entries) {
          final id = int.tryParse(e.key);
          final v = e.value;
          if (id == null ||
              id < 1 ||
              id > levelCount ||
              v is! Map<String, dynamic>)
            continue;
          final stars = v['stars'] is num
              ? clampInt((v['stars'] as num).toInt(), 1, 3)
              : 1;
          final t = v['bestTime'];
          completed[id] = LevelRecord(
            stars: stars,
            bestTime: t is num && t.isFinite && t > 0 ? t.toDouble() : null,
          );
        }
      }

      final upgrades = <String, int>{};
      final rawUp = decoded['upgrades'];
      if (rawUp is Map<String, dynamic>) {
        for (final e in rawUp.entries) {
          final v = e.value;
          if (v is num && v >= 0) upgrades[e.key] = v.toInt();
        }
      }

      final done = <String>{};
      final rawDone = decoded['tutorialsDone'];
      if (rawDone is List<dynamic>) {
        for (final e in rawDone) {
          if (e is String) done.add(e);
        }
      }

      var highest = decoded['highestUnlocked'] is num
          ? (decoded['highestUnlocked'] as num).toInt()
          : 1;
      for (final id in completed.keys) {
        if (id + 1 > highest) highest = id + 1;
      }
      highest = clampInt(highest, 1, levelCount);

      final coins = decoded['coins'] is num
          ? (decoded['coins'] as num).toInt()
          : 0;

      return SaveData(
        highestUnlocked: highest,
        completed: completed,
        coins: coins < 0 ? 0 : coins,
        upgrades: upgrades,
        tutorialsDone: done,
        settings: GameSettings.fromJson(decoded['settings']),
      );
    } catch (_) {
      return null;
    }
  }
}
