import 'json_utils.dart';

enum UnitKind { melee, ranged, mage, miner }

UnitKind _parseKind(String s, String ctx) {
  switch (s) {
    case 'melee':
      return UnitKind.melee;
    case 'ranged':
      return UnitKind.ranged;
    case 'mage':
      return UnitKind.mage;
    case 'miner':
      return UnitKind.miner;
  }
  throw DataFormatException('$ctx: unknown kind "$s"');
}

/// Static stats for one unit type. Loaded from assets/data/units.json.
class UnitModel {
  const UnitModel({
    required this.id,
    required this.name,
    required this.role,
    required this.kind,
    required this.cost,
    required this.health,
    required this.damage,
    required this.attackRange,
    required this.attackCooldown,
    required this.windup,
    required this.moveSpeed,
    required this.recruitTime,
    required this.armor,
    required this.defendReduction,
    required this.scale,
    required this.bodyRadius,
    required this.areaRadius,
    required this.projectileSpeed,
    required this.kiteDistance,
    required this.population,
    required this.attackSfx,
  });

  final String id;
  final String name;
  final String role;
  final UnitKind kind;
  final int cost;
  final double health;
  final double damage;
  final double attackRange;
  final double attackCooldown;
  final double windup;
  final double moveSpeed;
  final double recruitTime;
  final double armor;
  final double defendReduction;
  final double scale;
  final double bodyRadius;
  final double areaRadius;
  final double projectileSpeed;
  final double kiteDistance;
  final int population;
  final String attackSfx;

  factory UnitModel.fromJson(Map<String, dynamic> j) {
    final id = reqString(j, 'id', 'unit');
    final ctx = 'unit "$id"';
    final kind = _parseKind(reqString(j, 'kind', ctx), ctx);
    final model = UnitModel(
      id: id,
      name: reqString(j, 'name', ctx),
      role: optString(j, 'role', ''),
      kind: kind,
      cost: reqInt(j, 'cost', ctx),
      health: reqDouble(j, 'health', ctx),
      damage: reqDouble(j, 'damage', ctx),
      attackRange: reqDouble(j, 'attackRange', ctx),
      attackCooldown: reqDouble(j, 'attackCooldown', ctx),
      windup: reqDouble(j, 'windup', ctx),
      moveSpeed: reqDouble(j, 'moveSpeed', ctx),
      recruitTime: optDouble(j, 'recruitTime', ctx, 1.0),
      armor: optDouble(j, 'armor', ctx, 0),
      defendReduction: optDouble(j, 'defendReduction', ctx, 0),
      scale: optDouble(j, 'scale', ctx, 1),
      bodyRadius: optDouble(j, 'bodyRadius', ctx, 14),
      areaRadius: optDouble(j, 'areaRadius', ctx, 0),
      projectileSpeed: optDouble(j, 'projectileSpeed', ctx, 0),
      kiteDistance: optDouble(j, 'kiteDistance', ctx, 0),
      population: optInt(j, 'population', ctx, 1),
      attackSfx: optString(j, 'attackSfx', 'sword'),
    );
    check(model.cost >= 0, ctx, 'cost must be >= 0');
    check(model.health > 0, ctx, 'health must be > 0');
    check(model.damage >= 0, ctx, 'damage must be >= 0');
    check(model.attackRange > 0, ctx, 'attackRange must be > 0');
    check(model.attackCooldown > 0, ctx, 'attackCooldown must be > 0');
    check(model.windup >= 0, ctx, 'windup must be >= 0');
    check(model.moveSpeed >= 0, ctx, 'moveSpeed must be >= 0');
    check(model.population >= 1, ctx, 'population must be >= 1');
    check(
      model.scale > 0 && model.bodyRadius > 0,
      ctx,
      'scale/bodyRadius must be > 0',
    );
    if (kind == UnitKind.ranged || kind == UnitKind.mage) {
      check(
        model.projectileSpeed > 0,
        ctx,
        'ranged units need projectileSpeed > 0',
      );
    }
    return model;
  }
}
