import 'json_utils.dart';

enum AbilityType { areaDamage, armyBuff, fortressShield, spearVolley }

AbilityType _parseType(String s, String ctx) {
  switch (s) {
    case 'area_damage':
      return AbilityType.areaDamage;
    case 'army_buff':
      return AbilityType.armyBuff;
    case 'fortress_shield':
      return AbilityType.fortressShield;
    case 'spear_volley':
      return AbilityType.spearVolley;
  }
  throw DataFormatException('$ctx: unknown ability type "$s"');
}

class AbilityModel {
  const AbilityModel({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.cooldown,
    required this.radius,
    required this.damage,
    required this.duration,
    required this.damageMultiplier,
    required this.attackSpeedMultiplier,
    required this.reduction,
    required this.count,
    required this.spread,
  });

  final String id;
  final String name;
  final String description;
  final AbilityType type;
  final double cooldown;
  final double radius;
  final double damage;
  final double duration;
  final double damageMultiplier;
  final double attackSpeedMultiplier;
  final double reduction;

  /// Spear volley: number of spears and how wide they spread (world units).
  final int count;
  final double spread;

  factory AbilityModel.fromJson(Map<String, dynamic> j) {
    final id = reqString(j, 'id', 'ability');
    final ctx = 'ability "$id"';
    final m = AbilityModel(
      id: id,
      name: reqString(j, 'name', ctx),
      description: optString(j, 'description', ''),
      type: _parseType(reqString(j, 'type', ctx), ctx),
      cooldown: reqDouble(j, 'cooldown', ctx),
      radius: optDouble(j, 'radius', ctx, 0),
      damage: optDouble(j, 'damage', ctx, 0),
      duration: optDouble(j, 'duration', ctx, 0),
      damageMultiplier: optDouble(j, 'damageMultiplier', ctx, 1),
      attackSpeedMultiplier: optDouble(j, 'attackSpeedMultiplier', ctx, 1),
      reduction: optDouble(j, 'reduction', ctx, 0),
      count: optInt(j, 'count', ctx, 0),
      spread: optDouble(j, 'spread', ctx, 0),
    );
    if (m.type == AbilityType.spearVolley) {
      check(
        m.count > 0 && m.spread > 0 && m.radius > 0,
        ctx,
        'spear volley needs count, spread and radius',
      );
    }
    check(m.cooldown > 0, ctx, 'cooldown must be > 0');
    check(
      m.reduction >= 0 && m.reduction < 1,
      ctx,
      'reduction must be in [0, 1)',
    );
    return m;
  }
}
