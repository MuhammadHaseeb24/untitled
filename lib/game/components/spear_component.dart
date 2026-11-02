import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../../services/audio_service.dart';
import '../game_config.dart';
import '../game_types.dart';
import '../kingdoms_game.dart';
import 'effect_component.dart';

enum _SpearPhase { waiting, flying, stuck }

/// One spear of a Spear Volley. It waits for its [delay], flies along a high
/// arc from the statue's spear rack, then lands and damages enemies in a small
/// area. Time comes from the game's simulation clock, so pause works.
class SpearComponent extends PositionComponent {
  SpearComponent({
    required this.game,
    required this.startX,
    required this.targetX,
    required this.landLane,
    required this.damage,
    required this.radius,
    required this.delay,
    required this.playSound,
  }) : super(priority: 410) {
    final dist = (targetX - startX).abs();
    duration = 0.9 + dist / 1400;
    apex = 170 + dist * 0.22;
    _applyPose(0);
  }

  final KingdomsGame game;
  final double startX;
  final double targetX;

  /// Lane offset (visual y) where this spear lands.
  final double landLane;
  final double damage;
  final double radius;
  double delay;
  final bool playSound;

  static const double _startHeight = 150;

  late final double duration;
  late final double apex;
  _SpearPhase _phase = _SpearPhase.waiting;
  double _age = 0;
  double _stuck = 0;
  double _angle = 0;

  static final Paint _p = Paint();

  double _h(double u) => _startHeight * (1 - u) + 4 * apex * u * (1 - u);
  double _x(double u) => startX + (targetX - startX) * u;
  double _laneY(double u) => landLane * u;
  double _screenY(double u) => GameConfig.groundY + _laneY(u) - _h(u);

  void _applyPose(double u) {
    x = _x(u);
    y = _screenY(u);
    final u2 = min(1.0, u + 0.03);
    final dx = _x(u2) - _x(u);
    final dy = _screenY(u2) - _screenY(u);
    if (dx.abs() + dy.abs() > 1e-6) _angle = atan2(dy, dx);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (dt <= 0) return;
    switch (_phase) {
      case _SpearPhase.waiting:
        if (!game.combatActive) {
          removeFromParent();
          return;
        }
        delay -= dt;
        if (delay <= 0) {
          _phase = _SpearPhase.flying;
          if (playSound) game.audio.playSfx(Sfx.bow);
        }
        break;
      case _SpearPhase.flying:
        _age += dt;
        final u = min(1.0, _age / duration);
        _applyPose(u);
        if (u >= 1) _land();
        break;
      case _SpearPhase.stuck:
        _stuck += dt;
        if (_stuck > 1.4) removeFromParent();
        break;
    }
  }

  void _land() {
    _phase = _SpearPhase.stuck;
    _angle = -pi / 2 + 0.25; // stuck in the ground, leaning
    y = GameConfig.groundY + landLane;
    if (game.combatActive) {
      game.combat.areaDamage(
        cx: targetX,
        cy: GameConfig.groundY + landLane,
        radius: radius,
        victimTeam: Team.enemy,
        raw: damage,
      );
      game.audio.playSfx(Sfx.arrowHit);
      game.addEffect(
        EffectComponent.burst(
          at: Vector2(targetX, GameConfig.groundY + landLane - 6),
          color: const Color(0xFFD8C9A3),
          count: game.lowQuality ? 3 : 7,
          rng: game.rng,
          speed: 90,
          duration: 0.4,
        ),
      );
    }
  }

  @override
  void render(Canvas canvas) {
    if (_phase == _SpearPhase.waiting) return;
    final alpha = _phase == _SpearPhase.stuck
        ? (1 - (_stuck / 1.4)).clamp(0.0, 1.0)
        : 1.0;
    final a = (alpha * 255).round();
    canvas.save();
    canvas.rotate(_angle);
    _p
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3
      ..color = Color.fromARGB(a, 120, 80, 40);
    canvas.drawLine(const Offset(-26, 0), const Offset(18, 0), _p);
    final tip = Path()
      ..moveTo(16, -4)
      ..lineTo(32, 0)
      ..lineTo(16, 4)
      ..close();
    _p
      ..style = PaintingStyle.fill
      ..color = Color.fromARGB(a, 220, 226, 236);
    canvas.drawPath(tip, _p);
    canvas.restore();
  }
}
