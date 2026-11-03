import '../../models/level_model.dart';
import '../../models/unit_model.dart';
import '../game_config.dart';
import '../game_types.dart';
import 'economy_system.dart';

class AiView {
  const AiView({
    required this.armyCount,
    required this.population,
    required this.fortressThreatened,
    required this.elapsed,
  });

  final int armyCount;
  final int population;
  final bool fortressThreatened;
  final double elapsed;
}

class AiOutput {
  const AiOutput({this.paid = const [], this.free = const []});
  static const empty = AiOutput();

  /// Units the AI paid for; they go through the normal recruit queue.
  final List<UnitModel> paid;

  /// Scripted reinforcement waves defined by level data (no gold needed).
  final List<UnitModel> free;
}

/// Decision-making for the enemy. It uses the same units, economy and combat
/// rules as the player and only decides on a fixed interval.
class EnemyAiSystem {
  EnemyAiSystem({required this.config, required this.catalog})
      : _waves = List.of(config.waves);

  final EnemyConfig config;
  final Map<String, UnitModel> catalog;
  final List<EnemyWave> _waves;
  final List<String> _backlog = [];

  Command command = Command.defend;
  double _decisionTimer = 0;
  double _recruitTimer = 0;
  double _threatHold = 0;
  int _buildIndex = 0;

  AiOutput think(double dt, AiView view, EconomySystem econ) {
    _decisionTimer += dt;
    _recruitTimer += dt;
    if (_threatHold > 0) _threatHold -= dt;
    if (_decisionTimer < GameConfig.aiDecisionInterval) return AiOutput.empty;
    _decisionTimer = 0;

    // 1. Is the fortress threatened?
    if (view.fortressThreatened) _threatHold = 4.0;

    // 2. Strategy with hysteresis so the army does not flip every tick.
    if (_threatHold > 0 && view.armyCount < config.attackThreshold * 2) {
      command = Command.defend;
    } else if (command == Command.defend &&
        view.armyCount >= config.attackThreshold &&
        view.elapsed >= config.firstAttackAfterSeconds) {
      command = Command.attack;
    } else if (command == Command.attack &&
        view.armyCount <= config.retreatBelow) {
      command = Command.defend;
    }

    // 3. Recruit only what it can afford and has room for.
    final paid = <UnitModel>[];
    if (_recruitTimer >= config.recruitIntervalSeconds &&
        view.population < config.populationLimit) {
      final id = config.buildOrder[_buildIndex % config.buildOrder.length];
      final model = catalog[id];
      if (model != null && econ.trySpend(model.cost)) {
        paid.add(model);
        _buildIndex++;
        _recruitTimer = 0;
      }
    }

    // 4. Scripted waves become a backlog that spawns when there is room.
    while (_waves.isNotEmpty && view.elapsed >= _waves.first.at) {
      _backlog.addAll(_waves.removeAt(0).units);
    }
    final free = <UnitModel>[];
    final cap = config.populationLimit + GameConfig.waveBonusPopulation;
    var pop = view.population + paid.length;
    while (_backlog.isNotEmpty && pop < cap) {
      final model = catalog[_backlog.removeAt(0)];
      if (model == null) continue;
      free.add(model);
      pop += model.population;
    }
    return AiOutput(paid: paid, free: free);
  }
}
