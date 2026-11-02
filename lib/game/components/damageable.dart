import '../game_types.dart';

/// Anything that can be hit: units and fortresses.
abstract class Damageable {
  Team get team;
  bool get isAlive;

  /// False while hidden inside the statue (garrison) or dead.
  bool get targetable;

  /// Fraction of incoming damage that is ignored (0..1).
  double get damageReduction;

  /// World y of the body centre (used for projectile hit tests).
  double get centerY;

  double get bodyRadius;

  /// World x used for targeting. Fortresses return their front edge.
  double get posX;

  /// Distance from [fromX] to the closest attackable point of this target.
  double gapFrom(double fromX);

  /// Applies already-reduced damage. Only CombatSystem should call this.
  void applyDamage(double amount);
}
