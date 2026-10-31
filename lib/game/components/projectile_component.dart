import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../../services/audio_service.dart';
import '../game_types.dart';
import '../kingdoms_game.dart';
import 'effect_component.dart';

/// Arrow or fireball. Travels in a straight line and resolves its hit only
/// when it actually reaches an opposing target (or its end point for magic).
class ProjectileComponent extends PositionComponent {
  ProjectileComponent({
    required this.game,
    required this.team,
    required Vector2 from,
    required Vector2 to,
    required this.speed,
    required this.damage,
    required this.areaRadius,
    required this.isMagic,
  }) : super(position: from.clone(), priority: 400) {
    final delta = to - from;
    final len = delta.length;
    if (len < 1) {
      direction = Vector2(team.direction, 0);
      totalLength = 40;
    } else {
      direction = delta / len;
      totalLength = len;
    }
  }

  final KingdomsGame game;
  final Team team;
  final double speed;
  final double damage;
  final double areaRadius;
  final bool isMagic;

  late final Vector2 direction;
  late final double totalLength;
  double _traveled = 0;
  bool _done = false;

  static final Paint _p = Paint();

  @override
  void update(double dt) {
    super.update(dt);
    if (dt <= 0 || _done) return;
    if (!game.combatActive) {
      _finish();
      return;
    }
    final step = speed * dt;
    position.add(direction * step);
    _traveled += step;

    final hit = game.combat.findProjectileHit(position.x, position.y, team);
    if (hit != null) {
      if (isMagic) {
        _explode();
      } else {
        game.combat.dealDamage(hit, damage);
        game.audio.playSfx(Sfx.arrowHit);
        _finish();
      }
      return;
    }
    if (isMagic && _traveled >= totalLength) {
      _explode();
      return;
    }
    if (_traveled >= totalLength + 80 ||
        position.x < -100 ||
        position.x > 1700) {
      _finish();
    }
  }

  void _explode() {
    game.combat.areaDamage(
      cx: position.x,
      cy: position.y + 30,
      radius: areaRadius,
      victimTeam: team.opponent,
      raw: damage,
    );
    game.audio.playSfx(Sfx.magicHit);
    game.addEffect(
      EffectComponent.ring(
        at: Vector2(position.x, position.y + 30),
        color: const Color(0xFFFF8A2B),
        radius: areaRadius,
      ),
    );
    game.addEffect(
      EffectComponent.burst(
        at: position.clone(),
        color: const Color(0xFFFFB347),
        count: 10,
        rng: game.rng,
      ),
    );
    _finish();
  }

  void _finish() {
    if (_done) return;
    _done = true;
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final angle = atan2(direction.y, direction.x);
    canvas.save();
    canvas.rotate(angle);
    if (isMagic) {
      canvas.drawCircle(
        const Offset(-8, 0),
        11,
        _p..color = const Color(0x44FF6A1A),
      );
      canvas.drawCircle(Offset.zero, 8, _p..color = const Color(0xFFFF8A2B));
      canvas.drawCircle(Offset.zero, 4, _p..color = const Color(0xFFFFE08A));
    } else {
      _p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFE8E2D0);
      canvas.drawLine(const Offset(-14, 0), const Offset(10, 0), _p);
      canvas.drawLine(
        const Offset(10, 0),
        const Offset(5, -3.5),
        _p..color = const Color(0xFFF2C14E),
      );
      canvas.drawLine(const Offset(10, 0), const Offset(5, 3.5), _p);
      _p.style = PaintingStyle.fill;
    }
    canvas.restore();
  }
}
