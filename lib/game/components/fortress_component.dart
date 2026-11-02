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
  bool get targetable => isAlive;

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

  static const Color _stone = Color(0xFFB9BDC6);
  static const Color _stoneDark = Color(0xFF50535B);

  /// Thick rounded limb with a dark outline, used for the stone statue.
  void _limb(Canvas c, Offset a, Offset b, double w, Color fill) {
    c.drawLine(a, b, _stroke(_stoneDark, w + 5));
    c.drawLine(a, b, _stroke(fill, w));
  }

  void _drawStatue(Canvas canvas, bool friendly, int stage) {
    final stone = friendly ? _stone : const Color(0xFF9C8F96);
    final light = friendly ? const Color(0xFFE2E5EC) : const Color(0xFFC9B9BF);

    // pedestal of rocks
    final base = Path()
      ..moveTo(-60, 0)
      ..lineTo(-64, -16)
      ..lineTo(-50, -36)
      ..lineTo(-20, -44)
      ..lineTo(24, -42)
      ..lineTo(52, -32)
      ..lineTo(64, -14)
      ..lineTo(60, 0)
      ..close();
    canvas.drawPath(base, _fill(const Color(0xFF8D9098)));
    canvas.drawPath(base, _stroke(_stoneDark, 3));
    final rng = Random(5);
    for (var i = 0; i < 16; i++) {
      final dx = -52 + rng.nextDouble() * 104;
      final dy = -6 - rng.nextDouble() * 34;
      canvas.drawCircle(
        Offset(dx, dy),
        2 + rng.nextDouble() * 3.5,
        _fill(i.isEven ? const Color(0x55FFFFFF) : const Color(0x44000000)),
      );
    }

    if (friendly && stage < 3) {
      // spear rack behind the statue (used by the Spear Volley button)
      for (var i = 0; i < 7; i++) {
        final bx = -66.0 + i * 4.5;
        final tx = -96.0 + i * 9.0;
        final ty = -150.0 - (i % 3) * 9;
        canvas.drawLine(
          Offset(bx, -34),
          Offset(tx, ty),
          _stroke(const Color(0xFF6B4A26), 3),
        );
        final tip = Path()
          ..moveTo(tx - 3, ty + 4)
          ..lineTo(tx + (tx - bx) * 0.08, ty - 12)
          ..lineTo(tx + 3, ty + 4)
          ..close();
        canvas.drawPath(tip, _fill(const Color(0xFFDDE3EC)));
      }
      canvas.drawLine(
        const Offset(-72, -52),
        const Offset(-30, -52),
        _stroke(const Color(0xFF4A3520), 4),
      );
    }
    if (stage == 3) {
      // toppled statue: broken pieces on the pedestal
      _limb(canvas, const Offset(-30, -50), const Offset(10, -70), 16, stone);
      _limb(canvas, const Offset(14, -64), const Offset(48, -52), 12, stone);
      canvas.drawCircle(const Offset(-40, -60), 11, _fill(stone));
      canvas.drawCircle(const Offset(-40, -60), 11, _stroke(_stoneDark, 3));
      for (var i = 0; i < 3; i++) {
        final dy = (_t * 30 + i * 22) % 70;
        canvas.drawCircle(
          Offset(-10.0 + i * 16, -80 - dy),
          9.0 + dy / 9,
          _fill(Color.fromARGB((80 - dy).round().clamp(0, 255), 50, 50, 50)),
        );
      }
      return;
    }

    final tilt = stage == 2 ? 0.12 : 0.0;
    canvas.save();
    canvas.translate(0, -40);
    canvas.rotate(tilt);
    // legs
    _limb(canvas, const Offset(-4, -4), const Offset(-18, -62), 15, stone);
    _limb(canvas, const Offset(6, -4), const Offset(22, -62), 15, stone);
    // torso
    _limb(canvas, const Offset(0, -60), const Offset(0, -120), 26, stone);
    // head
    canvas.drawCircle(const Offset(2, -142), 15, _fill(stone));
    canvas.drawCircle(const Offset(2, -142), 15, _stroke(_stoneDark, 3));
    canvas.drawCircle(const Offset(-3, -146), 5, _fill(light));
    final eye = friendly ? const Color(0xFF222222) : const Color(0xFFFF4A3A);
    canvas.drawCircle(const Offset(9, -143), 2.4, _fill(eye));
    // arms and bow (bow is lost at stage 2)
    if (stage < 2) {
      _limb(canvas, const Offset(4, -112), const Offset(48, -140), 12, stone);
      _limb(canvas, const Offset(-2, -112), const Offset(-30, -150), 12, stone);
      final bow = Path()
        ..moveTo(52, -196)
        ..quadraticBezierTo(86, -140, 52, -84);
      canvas.drawPath(bow, _stroke(_stoneDark, 8));
      canvas.drawPath(bow, _stroke(stone, 4));
      canvas.drawLine(
        const Offset(52, -196),
        const Offset(-30, -150),
        _stroke(const Color(0xFF3C3E44), 2),
      );
      canvas.drawLine(
        const Offset(52, -84),
        const Offset(-30, -150),
        _stroke(const Color(0xFF3C3E44), 2),
      );
    } else {
      _limb(canvas, const Offset(4, -112), const Offset(34, -92), 12, stone);
      _limb(canvas, const Offset(-2, -112), const Offset(-24, -86), 12, stone);
    }
    // stone texture highlights
    canvas.drawLine(
      const Offset(-6, -118),
      const Offset(-6, -70),
      _stroke(const Color(0x66FFFFFF), 3),
    );
    // cracks
    if (stage >= 1) {
      final crack = _stroke(const Color(0xCC1A1A1A), 2.4);
      canvas.drawPath(
        Path()
          ..moveTo(-8, -118)
          ..lineTo(2, -100)
          ..lineTo(-6, -84)
          ..lineTo(4, -66),
        crack,
      );
      canvas.drawPath(
        Path()
          ..moveTo(2, -154)
          ..lineTo(8, -142)
          ..lineTo(0, -132),
        crack,
      );
    }
    canvas.restore();
    if (stage >= 1) {
      for (var i = 0; i < 3; i++) {
        final dy = (_t * 28 + i * 25) % 80;
        canvas.drawCircle(
          Offset(12.0 + i * 12, -170 - dy),
          8.0 + dy / 10,
          _fill(Color.fromARGB((90 - dy).round().clamp(0, 255), 60, 60, 60)),
        );
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final friendly = team == Team.player;
    final stage = fraction > 0.66
        ? 0
        : (fraction > 0.33 ? 1 : (fraction > 0 ? 2 : 3));

    canvas.save();
    if (!friendly) canvas.scale(-1, 1);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 4), width: 150, height: 18),
      _fill(const Color(0x66000000)),
    );

    final flash = _hitFlash > 0;
    if (flash) {
      canvas.saveLayer(
        const Rect.fromLTWH(-120, -300, 240, 330),
        Paint()
          ..colorFilter = const ColorFilter.mode(
            Color(0x99FFFFFF),
            BlendMode.srcATop,
          ),
      );
    }
    _drawStatue(canvas, friendly, stage);
    if (flash) canvas.restore();

    if (shieldTime > 0 && stage < 3) {
      final a = (90 + 50 * sin(_t * 8)).round().clamp(0, 255);
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, -110), width: 170, height: 250),
        _fill(Color.fromARGB(a ~/ 2, 120, 190, 255)),
      );
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, -110), width: 170, height: 250),
        _stroke(Color.fromARGB(min(255, a + 80), 170, 220, 255), 4),
      );
    }
    canvas.restore();

    // Health bar (never mirrored): red for the enemy statue, green for yours.
    const w = 120.0;
    const top = -262.0;
    canvas.drawRect(
      const Rect.fromLTWH(-w / 2 - 2, top - 2, w + 4, 13),
      _fill(const Color(0xDD000000)),
    );
    final fc = friendly
        ? (fraction > 0.5
              ? const Color(0xFF58D26B)
              : (fraction > 0.25
                    ? const Color(0xFFF2B33D)
                    : const Color(0xFFE5483D)))
        : const Color(0xFFE5231B);
    canvas.drawRect(Rect.fromLTWH(-w / 2, top, w * fraction, 9), _fill(fc));
  }
}
