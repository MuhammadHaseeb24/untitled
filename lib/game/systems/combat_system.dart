import 'dart:math';

import '../components/damageable.dart';
import '../components/unit_component.dart';
import '../game_types.dart';
import '../kingdoms_game.dart';

/// The single place where damage is calculated and applied.
class CombatSystem {
  CombatSystem(this.game);

  final KingdomsGame game;

  void dealDamage(Damageable target, double raw, {bool heavy = false}) {
    if (!game.combatActive || !target.isAlive || raw <= 0) return;
    final reduction = target.damageReduction.clamp(0.0, 0.9).toDouble();
    final amount = raw * (1.0 - reduction);
    target.applyDamage(amount);
    game.onDamageDealt(target, amount, heavy: heavy);
  }

  /// Damages every living unit of [victimTeam] inside an ellipse (depth is
  /// compressed for the 2.5D view) plus the fortress if the blast reaches it.
  int areaDamage({
    required double cx,
    required double cy,
    required double radius,
    required Team victimTeam,
    required double raw,
  }) {
    var hits = 0;
    for (final u in game.unitsOf(victimTeam)) {
      if (!u.isAlive) continue;
      final dx = u.x - cx;
      final dy = (u.y - cy) * 2;
      if (sqrt(dx * dx + dy * dy) <= radius + u.model.bodyRadius) {
        dealDamage(u, raw);
        hits++;
      }
    }
    final f = game.fortressOf(victimTeam);
    if (f.isAlive && (f.frontX - cx).abs() <= radius * 0.9) {
      dealDamage(f, raw, heavy: true);
      hits++;
    }
    return hits;
  }

  /// First opposing target overlapping a projectile at ([px], [py]).
  Damageable? findProjectileHit(double px, double py, Team projectileTeam) {
    final victim = projectileTeam.opponent;
    for (final UnitComponent u in game.unitsOf(victim)) {
      if (!u.isAlive) continue;
      if ((px - u.x).abs() <= u.model.bodyRadius + 6 &&
          (py - u.centerY).abs() <= 36 * u.model.scale) {
        return u;
      }
    }
    final f = game.fortressOf(victim);
    if (f.isAlive && f.containsWorldPoint(px, py)) return f;
    return null;
  }
}