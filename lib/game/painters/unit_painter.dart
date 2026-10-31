import 'dart:math';
import 'dart:ui';

import '../game_types.dart';

/// Mutable animation snapshot handed to [UnitPainter].
class UnitVisual {
  String unitId = 'ember_squire';
  Team team = Team.player;
  double scale = 1;
  double facing = 1;
  double walk = 0;
  bool moving = false;

  /// 0..1 swing phase (impact at ~0.55), or -1 when not attacking.
  double attackT = -1;
  double hurt = 0;

  /// 0..1 while dying, or -1 when alive.
  double dying = -1;

  /// 0..1 while spawning, 1 when fully spawned.
  double spawn = 1;
  bool buffed = false;
  double time = 0;
}

/// Original procedural character art. Friendly units wear blue/gold with a
/// round helmet and a gold badge; enemies wear crimson with horned helmets and
/// a spiked badge, so teams differ by shape as well as colour.
class UnitPainter {
  UnitPainter._();

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

  static const _skin = Color(0xFFF2C9A0);
  static const _steel = Color(0xFFD9E2EC);
  static const _wood = Color(0xFF7A5230);

  static void paint(Canvas c, UnitVisual v) {
    final friendly = v.team == Team.player;
    final main = friendly ? const Color(0xFF2F6FE4) : const Color(0xFFC62F2F);
    final dark = friendly ? const Color(0xFF1B3F8F) : const Color(0xFF7A1717);
    final trim = friendly ? const Color(0xFFF2C14E) : const Color(0xFFEADFCB);

    c.save();
    c.scale(v.facing * v.scale, v.scale);

    // Ground shadow and buff ring (not affected by the death rotation).
    c.drawOval(
      Rect.fromCenter(center: const Offset(0, 2), width: 38, height: 11),
      _fill(const Color(0x55000000)),
    );
    if (v.buffed) {
      final a = (140 + 80 * sin(v.time * 6)).round().clamp(40, 255);
      c.drawOval(
        Rect.fromCenter(center: const Offset(0, 2), width: 46, height: 14),
        _stroke(Color.fromARGB(a, 255, 214, 90), 2.5),
      );
    }

    var alpha = 1.0;
    if (v.dying >= 0) {
      c.rotate(-v.dying * 1.35);
      alpha = 1 - v.dying;
    } else if (v.spawn < 1) {
      alpha = 0.35 + 0.65 * v.spawn;
      c.translate(0, (1 - v.spawn) * 14);
    }
    final layered = alpha < 1 || v.hurt > 0;
    if (layered) {
      final lp = Paint()
        ..color = Color.fromARGB(
          (alpha * 255).round().clamp(0, 255),
          255,
          255,
          255,
        );
      if (v.hurt > 0) {
        lp.colorFilter = ColorFilter.mode(
          Color.fromARGB((v.hurt * 380).round().clamp(0, 150), 255, 255, 255),
          BlendMode.srcATop,
        );
      }
      c.saveLayer(const Rect.fromLTWH(-90, -170, 180, 190), lp);
    }

    final bob = v.moving
        ? sin(v.walk * 2).abs() * 2.0
        : sin(v.time * 2.5) * 0.8;
    _legs(c, v, dark);
    c.save();
    c.translate(0, -bob);

    switch (v.unitId) {
      case 'iron_guard':
        _guard(c, v, main, dark, trim);
        break;
      case 'ash_archer':
        _archer(c, v, main, dark, trim);
        break;
      case 'flame_adept':
        _adept(c, v, main, dark, trim);
        break;
      case 'ember_titan':
        _titan(c, v, main, dark, trim);
        break;
      default:
        _squire(c, v, main, dark, trim);
    }
    c.restore();

    if (layered) c.restore();
    c.restore();
  }

  static double _swing(
    UnitVisual v,
    double rest,
    double raised,
    double strike,
  ) {
    final t = v.attackT;
    if (t < 0) return rest;
    if (t < 0.5) return rest + (raised - rest) * (t / 0.5);
    if (t < 0.6) return raised + (strike - raised) * ((t - 0.5) / 0.1);
    return strike + (rest - strike) * ((t - 0.6) / 0.4).clamp(0.0, 1.0);
  }

  static void _legs(Canvas c, UnitVisual v, Color color) {
    final s = v.moving ? sin(v.walk) : 0.0;
    final p = _stroke(color, 5);
    c.drawLine(Offset(-5, -26), Offset(-5 + s * 9, 0), p);
    c.drawLine(Offset(5, -26), Offset(5 - s * 9, 0), p);
  }

  static void _torso(
    Canvas c,
    Color main,
    Color trim,
    bool friendly, {
    double half = 10,
    double top = -54,
  }) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(-half, top, half, -26),
        const Radius.circular(5),
      ),
      _fill(main),
    );
    if (friendly) {
      c.drawCircle(const Offset(0, -41), 3.6, _fill(trim));
    } else {
      final path = Path()
        ..moveTo(-4.5, -46)
        ..lineTo(4.5, -46)
        ..lineTo(0, -35)
        ..close();
      c.drawPath(path, _fill(trim));
    }
  }

  static void _head(
    Canvas c,
    bool friendly,
    Color helmet,
    Color trim, {
    double y = -64,
  }) {
    c.drawCircle(Offset(0, y), 9, _fill(_skin));
    c.drawArc(
      Rect.fromCircle(center: Offset(0, y - 1), radius: 10.5),
      pi,
      pi,
      true,
      _fill(helmet),
    );
    c.drawCircle(Offset(4, y), 1.4, _fill(const Color(0xFF222222)));
    if (friendly) {
      c.drawRect(Rect.fromLTRB(-1.5, y - 14, 1.5, y - 8), _fill(trim));
    } else {
      final l = Path()
        ..moveTo(-9, y - 6)
        ..lineTo(-16, y - 18)
        ..lineTo(-4, y - 9)
        ..close();
      final r = Path()
        ..moveTo(9, y - 6)
        ..lineTo(16, y - 18)
        ..lineTo(4, y - 9)
        ..close();
      c.drawPath(l, _fill(trim));
      c.drawPath(r, _fill(trim));
    }
  }

  static void _backArm(Canvas c) {
    c.drawLine(
      const Offset(-6, -50),
      const Offset(-10, -37),
      _stroke(_skin, 4),
    );
  }

  static void _squire(
    Canvas c,
    UnitVisual v,
    Color main,
    Color dark,
    Color trim,
  ) {
    final f = v.team == Team.player;
    _backArm(c);
    _torso(c, main, trim, f);
    _head(c, f, dark, trim);
    c.save();
    c.translate(6, -50);
    c.rotate(_swing(v, 0.9, -1.9, 1.2));
    c.drawLine(Offset.zero, const Offset(14, 0), _stroke(_skin, 4));
    c.drawLine(
      const Offset(14, -1),
      const Offset(44, -1),
      _stroke(_steel, 3.5),
    );
    c.drawLine(const Offset(14, -6), const Offset(14, 4), _stroke(trim, 3));
    c.restore();
  }

  static void _guard(
    Canvas c,
    UnitVisual v,
    Color main,
    Color dark,
    Color trim,
  ) {
    final f = v.team == Team.player;
    _backArm(c);
    _torso(c, dark, trim, f, half: 12, top: -56);
    _head(c, f, main, trim);
    // plume
    c.drawLine(const Offset(0, -75), const Offset(-6, -84), _stroke(trim, 3));
    // sword arm
    c.save();
    c.translate(8, -52);
    c.rotate(_swing(v, 0.7, -1.7, 1.1));
    c.drawLine(Offset.zero, const Offset(12, 0), _stroke(_skin, 4));
    c.drawLine(
      const Offset(12, -1),
      const Offset(34, -1),
      _stroke(_steel, 3.5),
    );
    c.restore();
    // big shield
    final shield = RRect.fromRectAndRadius(
      const Rect.fromLTRB(9, -58, 24, -22),
      const Radius.circular(6),
    );
    c.drawRRect(shield, _fill(main));
    c.drawRRect(shield, _stroke(trim, 2));
    c.drawCircle(const Offset(16.5, -40), 3.5, _fill(trim));
  }

  static void _archer(
    Canvas c,
    UnitVisual v,
    Color main,
    Color dark,
    Color trim,
  ) {
    final f = v.team == Team.player;
    _backArm(c);
    _torso(c, main, trim, f);
    _head(c, f, dark, trim);
    final t = v.attackT;
    final pull = t < 0 ? 0.0 : (t < 0.55 ? t / 0.55 : 0.0);
    final stringX = 12 - pull * 10;
    final bow = Path()
      ..moveTo(12, -72)
      ..quadraticBezierTo(26, -51, 12, -30);
    c.drawPath(bow, _stroke(_wood, 3));
    final str = Path()
      ..moveTo(12, -72)
      ..lineTo(stringX, -51)
      ..lineTo(12, -30);
    c.drawPath(str, _stroke(const Color(0xFFEEEEEE), 1.2));
    if (t >= 0 && t < 0.56) {
      c.drawLine(
        Offset(stringX, -51),
        Offset(stringX + 26, -51),
        _stroke(_steel, 2),
      );
      c.drawLine(
        Offset(stringX + 26, -54),
        Offset(stringX + 30, -51),
        _stroke(trim, 2),
      );
    }
    c.drawLine(const Offset(6, -51), const Offset(14, -51), _stroke(_skin, 4));
  }

  static void _adept(
    Canvas c,
    UnitVisual v,
    Color main,
    Color dark,
    Color trim,
  ) {
    final f = v.team == Team.player;
    _backArm(c);
    final robe = Path()
      ..moveTo(-13, -22)
      ..lineTo(13, -22)
      ..lineTo(9, -54)
      ..lineTo(-9, -54)
      ..close();
    c.drawPath(robe, _fill(main));
    c.drawRect(const Rect.fromLTRB(-9, -40, 9, -36), _fill(trim));
    c.drawCircle(const Offset(0, -64), 9, _fill(_skin));
    c.drawCircle(const Offset(4, -64), 1.4, _fill(const Color(0xFF222222)));
    final hat = Path()
      ..moveTo(-12, -69)
      ..lineTo(12, -69)
      ..lineTo(f ? 3 : 8, -98)
      ..close();
    c.drawPath(hat, _fill(dark));
    c.drawLine(const Offset(-13, -69), const Offset(13, -69), _stroke(trim, 3));
    final lift = v.attackT >= 0
        ? (v.attackT < 0.55 ? v.attackT / 0.55 : 0.0)
        : 0.0;
    c.drawLine(
      Offset(12, -18 - lift * 6),
      Offset(12, -84 - lift * 6),
      _stroke(_wood, 3),
    );
    final orbR = 5 + lift * 3 + sin(v.time * 5) * 0.6;
    final orbC = Offset(12, -88 - lift * 6);
    c.drawCircle(orbC, orbR + 5, _fill(const Color(0x66FF8A2B)));
    c.drawCircle(orbC, orbR, _fill(const Color(0xFFFFB347)));
    c.drawLine(
      const Offset(6, -50),
      Offset(12, -58 - lift * 8),
      _stroke(_skin, 4),
    );
  }

  static void _titan(
    Canvas c,
    UnitVisual v,
    Color main,
    Color dark,
    Color trim,
  ) {
    final f = v.team == Team.player;
    _backArm(c);
    _torso(c, dark, trim, f, half: 14, top: -58);
    c.drawCircle(const Offset(-14, -54), 7, _fill(main));
    c.drawCircle(const Offset(14, -54), 7, _fill(main));
    final crack = _stroke(const Color(0xFFFF8A2B), 1.8);
    c.drawLine(const Offset(-6, -52), const Offset(-2, -42), crack);
    c.drawLine(const Offset(-2, -42), const Offset(-7, -32), crack);
    c.drawLine(const Offset(7, -54), const Offset(4, -44), crack);
    _head(c, f, main, trim, y: -67);
    c.save();
    c.translate(10, -54);
    c.rotate(_swing(v, 0.8, -2.0, 1.25));
    c.drawLine(Offset.zero, const Offset(12, 0), _stroke(_skin, 5));
    c.drawLine(const Offset(12, 0), const Offset(46, 0), _stroke(_wood, 5));
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(40, -13, 58, 13),
        const Radius.circular(3),
      ),
      _fill(const Color(0xFF6E7787)),
    );
    c.drawRect(const Rect.fromLTRB(40, -13, 58, -9), _fill(trim));
    c.restore();
  }
}
