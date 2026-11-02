import '../../models/unit_model.dart';
import '../components/unit_component.dart';
import '../game_config.dart';
import '../kingdoms_game.dart';

class MovementSystem {
  MovementSystem._();

  /// Keeps units on the battlefield and out of the fortresses.
  static double clampX(double x, KingdomsGame game) {
    final minX = game.playerFortress.frontX + 10;
    final maxX = game.enemyFortress.frontX - 10;
    if (x < minX) return minX;
    if (x > maxX) return maxX;
    return x;
  }

  /// True when an ally in the same lane is directly ahead in the move
  /// direction. Ranged units never block melee units (melee can walk past
  /// archers), so frontliners are not stuck behind a shooting archer.
  static bool isBlocked(
    UnitComponent unit,
    double dir,
    List<UnitComponent> allies,
  ) {
    for (final a in allies) {
      if (identical(a, unit) || !a.targetable) continue;
      if (a.model.kind == UnitKind.miner) continue;
      if (a.state == UnitState.spawning) continue;
      if (a.lane != unit.lane) continue;
      if (unit.model.kind == UnitKind.melee && a.model.kind != UnitKind.melee)
        continue;
      final ahead = (a.x - unit.x) * dir;
      if (ahead <= 0) continue;
      var gap = (unit.model.bodyRadius + a.model.bodyRadius) * 0.9 + 4;
      if (gap < GameConfig.unitSpacing) gap = GameConfig.unitSpacing;
      if (ahead < gap) return true;
    }
    return false;
  }
}
