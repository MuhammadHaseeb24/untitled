import 'package:flutter/foundation.dart';

import '../models/level_model.dart';
import 'game_types.dart';

/// Snapshot of battle state for the Flutter HUD. The game writes the fields
/// and calls [notifyListeners] at a throttled rate (about 12 Hz) or on events.
class BattleHud extends ChangeNotifier {
  int gold = 0;
  int population = 0;
  int populationMax = 0;
  int queued = 0;
  final Map<String, int> queuedByUnit = {};
  double queueProgress = 0;

  double playerHp = 1;
  double playerMaxHp = 1;
  double enemyHp = 1;
  double enemyMaxHp = 1;

  Command command = Command.defend;
  double speed = 1;
  bool paused = false;
  bool battleOver = false;
  double elapsed = 0;

  /// Ability id -> remaining cooldown fraction (0 = ready).
  final Map<String, double> abilityCooldown = {};
  final Map<String, double> abilityRemainingSeconds = {};
  double rallyRemaining = 0;
  double wardRemaining = 0;

  String? toast;
  TutorialStep? tutorial;

  void notifyHud() => notifyListeners();
}
