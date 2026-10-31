import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../game_config.dart';
import '../game_types.dart';
import '../kingdoms_game.dart';
import 'damageable.dart';

class FortressComponent extends PositionComponent implements Damageable {
  FortressComponent({
    required this.game,
    required this.team,
    required this.maxHealth,
  }) : health = maxHealth,
        super(
        position: Vector2(
          team == Team.player
              ? GameConfig.playerFortressX
              : GameConfig.enemyFortressX,
          GameConfig.groundY,
        ),
        priority: 50,
      );

  final KingdomsGame game;
  @override
  final Team team;
  final double maxHealth;
  double health;

  double shieldTime = 0;
  double shieldReduction = 0;
  double _hitFlash = 0;
  double _t = 0;

  static final Paint _p = Paint();
  static Paint _fill(Color c) => _p
    ..style = PaintingStyle.fill
    ..color = c
    ..strokeWidth = 1;
  static Paint _stroke(Color c, double w) => _p
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..color = c
    ..strokeWidth = w;

  double get fraction => (health / maxHealth).clamp(0.0, 1.0).toDouble();

  double get frontX => team == Team.player
      ? x + GameConfig.fortressWidth / 2
      : x - GameConfig.fortressWidth / 2;

  bool containsWorldPoint(double px, double py) =>
      (px - x).abs() <= GameConfig.fortressWidth / 2 &&
          py <= GameConfig.groundY + 30 &&
          py >= GameConfig.groundY - GameConfig.fortressHeight;

  // Damageable
  @override
  bool get isAlive => health > 0;

  @override
  double get damageReduction => shieldTime > 0 ? shieldReduction : 0;

  @override
  double get centerY => GameConfig.groundY - 110;

  @override
  double get bodyRadius => 0;

  @override
  double get posX => frontX;

  @override
  double gapFrom(double fromX) => (fromX - frontX).abs();

  @override
  void applyDamage(double amount) {
    if (!isAlive) return;
    health = max(0.0, health - amount);
    _hitFlash = 0.15;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (dt <= 0) return;
    _t += dt;
    if (_hitFlash > 0) _hitFlash = max(0.0, _hitFlash - dt);
    if (shieldTime > 0) shieldTime = max(0.0, shieldTime - dt);
  }

  @override
  void render(Canvas canvas) {
    final friendly = team == Team.player;
    final stone = friendly ? const Color(0xFF8C93A6) : const Color(0xFF6A5555);
    final stoneDark = friendly
        ? const Color(0xFF666D80)
        : const Color(0xFF4A3B3B);
    final roof = friendly ? const Color(0xFF2F6FE4) : const Color(0xFFB02828);
    final trim = friendly ? const Color(0xFFF2C14E) : const Color(0xFFEADFCB);
    final stage = fraction > 0.66
        ? 0
        : (fraction > 0.33 ? 1 : (fraction > 0 ? 2 : 3));

    canvas.save();
    if (!friendly) canvas.scale(-1, 1);

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 4), width: 230, height: 22),
      _fill(const Color(0x55000000)),
    );

    if (stage == 3) {
      final rubble = Path()
        ..moveTo(-95, 0)
        ..lineTo(-70, -34)
        ..lineTo(-40, -20)
        ..lineTo(-10, -48)
        ..lineTo(25, -26)
        ..lineTo(55, -40)
        ..lineTo(95, 0)
        ..close();
      canvas.drawPath(rubble, _fill(stoneDark));
      for (var i = 0; i < 4; i++) {
        canvas.drawCircle(
          Offset(-30.0 + i * 22, -60.0 - i * 18 - (_t * 30 + i * 20) % 40),
          12.0 + i * 3,
          _fill(const Color(0x55222222)),
        );
      }
    } else {
      // wall + towers
      canvas.drawRect(const Rect.fromLTRB(-60, -150, 60, 0), _fill(stone));
      canvas.drawRect(const Rect.fromLTRB(-95, -230, -55, 0), _fill(stoneDark));
      final rightTop = stage == 2 ? -150.0 : -200.0;
      canvas.drawRect(Rect.fromLTRB(55, rightTop, 95, 0), _fill(stoneDark));
      // crenellations
      for (var i = 0; i < 4; i++) {
        canvas.drawRect(
          Rect.fromLTWH(-60.0 + i * 32, -164, 18, 14),
          _fill(stone),
        );
      }
      // roofs
      canvas.drawPath(
        Path()
          ..moveTo(-101, -230)
          ..lineTo(-75, -285)
          ..lineTo(-49, -230)
          ..close(),
        _fill(roof),
      );
      if (stage < 2) {
        canvas.drawPath(
          Path()
            ..moveTo(49, -200)
            ..lineTo(75, -250)
            ..lineTo(101, -200)
            ..close(),
          _fill(roof),
        );
      } else {
        canvas.drawPath(
          Path()
            ..moveTo(55, -150)
            ..lineTo(66, -170)
            ..lineTo(76, -154)
            ..lineTo(86, -176)
            ..lineTo(95, -150)
            ..close(),
          _fill(stoneDark),
        );
      }
      // gate + windows
      final gate = RRect.fromRectAndCorners(
        const Rect.fromLTRB(-20, -78, 20, 0),
        topLeft: const Radius.circular(20),
        topRight: const Radius.circular(20),
      );
      canvas.drawRRect(gate, _fill(const Color(0xFF2A1F1A)));
      canvas.drawRRect(gate, _stroke(trim, 3));
      final glow = 160 + (60 * sin(_t * 4)).round();
      for (final wx in [-75.0, 75.0]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(wx, -120), width: 12, height: 26),
            const Radius.circular(6),
          ),
          _fill(Color.fromARGB(glow.clamp(0, 255), 255, 160, 60)),
        );
      }
      // flag
      canvas.drawLine(
        const Offset(-75, -285),
        const Offset(-75, -325),
        _stroke(const Color(0xFF444444), 3),
      );
      final wave = sin(_t * 3) * 4;
      canvas.drawPath(
        Path()
          ..moveTo(-75, -325)
          ..lineTo(-45, -318 + wave)
          ..lineTo(-75, -306)
          ..close(),
        _fill(trim),
      );
      // damage cracks
      if (stage >= 1) {
        final crack = _stroke(const Color(0xAA1A1A1A), 2.5);
        canvas.drawPath(
          Path()
            ..moveTo(-30, -150)
            ..lineTo(-22, -120)
            ..lineTo(-36, -96)
            ..lineTo(-26, -70),
          crack,
        );
        canvas.drawPath(
          Path()
            ..moveTo(36, -140)
            ..lineTo(28, -110)
            ..lineTo(40, -84),
          crack,
        );
        for (var i = 0; i < 3; i++) {
          final dy = (_t * 28 + i * 25) % 75;
          canvas.drawCircle(
            Offset(20.0 + i * 14, -170 - dy),
            8.0 + dy / 10,
            _fill(Color.fromARGB((90 - dy).round().clamp(0, 255), 60, 60, 60)),
          );
        }
      }
      if (stage >= 2) {
        for (var i = 0; i < 3; i++) {
          final fl = 10 + 4 * sin(_t * 9 + i * 2);
          canvas.drawCircle(
            Offset(68.0 + i * 8, -158),
            fl,
            _fill(const Color(0xAAFF7A1A)),
          );
          canvas.drawCircle(
            Offset(68.0 + i * 8, -158),
            fl * 0.5,
            _fill(const Color(0xFFFFD36B)),
          );
        }
      }
      if (_hitFlash > 0) {
        final a = (_hitFlash / 0.15 * 110).round().clamp(0, 255);
        canvas.drawRect(
          const Rect.fromLTRB(-95, -230, 95, 0),
          _fill(Color.fromARGB(a, 255, 255, 255)),
        );
      }
      if (shieldTime > 0) {
        final a = (90 + 50 * sin(_t * 8)).round().clamp(0, 255);
        canvas.drawOval(
          Rect.fromCenter(
            center: const Offset(0, -140),
            width: 270,
            height: 330,
          ),
          _fill(Color.fromARGB(a ~/ 2, 120, 190, 255)),
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: const Offset(0, -140),
            width: 270,
            height: 330,
          ),
          _stroke(
            Color.fromARGB(a + 80 > 255 ? 255 : a + 80, 170, 220, 255),
            4,
          ),
        );
      }
    }
    canvas.restore();

    // Health bar (never mirrored).
    const w = 170.0;
    const top = -355.0;
    canvas.drawRect(
      const Rect.fromLTWH(-w / 2 - 2, top - 2, w + 4, 14),
      _fill(const Color(0xCC000000)),
    );
    final fc = fraction > 0.5
        ? const Color(0xFF58D26B)
        : (fraction > 0.25 ? const Color(0xFFF2B33D) : const Color(0xFFE5483D));
    canvas.drawRect(Rect.fromLTWH(-w / 2, top, w * fraction, 10), _fill(fc));
  }
}