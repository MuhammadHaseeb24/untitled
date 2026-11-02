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
  bool carrying = false;
  double time = 0;
}

/// Original stick-figure art. Your army is black with a blue headband;
/// the enemy is dark red with horns, so teams differ by shape as well as colour.
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
    ..strokeJoin = StrokeJoin.round
    ..color = c
    ..strokeWidth = w;

  static const _steel = Color(0xFFD5DCE6);
  static const _wood = Color(0xFF8A5A2B);

  static void paint(Canvas c, UnitVisual v) {
    final friendly = v.team == Team.player;
    final body = friendly ? const Color(0xFF111111) : const Color(0xFF7E1414);
    final accent = friendly ? const Color(0xFF4DB8FF) : const Color(0xFFFFC857);

    c.save();
    c.scale(v.facing * v.scale, v.scale);

    c.drawOval(
      Rect.fromCenter(center: const Offset(0, 2), width: 36, height: 9),
      _fill(const Color(0x55000000)),
    );
    if (v.buffed) {
      final a = (140 + 80 * sin(v.time * 6)).round().clamp(40, 255);
      c.drawOval(
        Rect.fromCenter(center: const Offset(0, 2), width: 46, height: 13),
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
    final thick = v.unitId == 'ember_titan' ? 7.0 : 4.6;
    if (v.unitId != 'flame_adept') _legs(c, v, body, thick);
    c.save();
    c.translate(0, -bob);
    switch (v.unitId) {
      case 'miner':
        _miner(c, v, body, accent, thick);
        break;
      case 'iron_guard':
        _guard(c, v, body, accent, thick);
        break;
      case 'ash_archer':
        _archer(c, v, body, accent, thick);
        break;
      case 'flame_adept':
        _adept(c, v, body, accent, thick);
        break;
      case 'ember_titan':
        _titan(c, v, body, accent, thick);
        break;
      default:
        _squire(c, v, body, accent, thick);
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

  static void _legs(Canvas c, UnitVisual v, Color color, double w) {
    final s = v.moving ? sin(v.walk) : 0.0;
    final p = _stroke(color, w);
    c.drawLine(const Offset(0, -28), Offset(s * 11 - 2, 0), p);
    c.drawLine(const Offset(0, -28), Offset(-s * 11 + 2, 0), p);
  }

  static void _torso(Canvas c, Color color, double w) {
    c.drawLine(
      const Offset(0, -28),
      const Offset(0, -52),
      _stroke(color, w + 1.2),
    );
  }

  static void _head(
    Canvas c,
    UnitVisual v,
    Color color,
    Color accent, {
    double r = 8.5,
    double y = -61,
  }) {
    c.drawCircle(Offset(0, y), r, _fill(color));
    if (v.team == Team.player) {
      // blue headband with a small tail
      c.drawLine(Offset(-r, y - 2), Offset(r, y - 2), _stroke(accent, 2.6));
      c.drawLine(
        Offset(-r, y - 2),
        Offset(-r - 7, y + 3),
        _stroke(accent, 2.4),
      );
    } else {
      // horns
      c.drawLine(
        Offset(-r * 0.6, y - r * 0.8),
        Offset(-r * 1.3, y - r * 2.0),
        _stroke(accent, 2.8),
      );
      c.drawLine(
        Offset(r * 0.6, y - r * 0.8),
        Offset(r * 1.3, y - r * 2.0),
        _stroke(accent, 2.8),
      );
    }
  }

  static void _backArm(Canvas c, Color color, double w) {
    c.drawLine(
      const Offset(0, -50),
      const Offset(-9, -36),
      _stroke(color, w - 0.6),
    );
  }

  /// Draws an arm from the shoulder at [angle] (0 = hanging down, positive =
  /// forward) and returns nothing; call [_weaponAlongArm] inside for gear.
  static void _arm(
    Canvas c,
    Color color,
    double w,
    double angle,
    double len,
    void Function() weapon,
  ) {
    c.save();
    c.translate(0, -50);
    c.rotate(angle - pi / 2); // local +x now points along the arm
    c.drawLine(Offset.zero, Offset(len, 0), _stroke(color, w - 0.6));
    c.translate(len, 0);
    weapon();
    c.restore();
  }

  static void _miner(
    Canvas c,
    UnitVisual v,
    Color body,
    Color accent,
    double w,
  ) {
    // gold sack on the back while carrying a load
    if (v.carrying) {
      c.drawCircle(const Offset(-9, -46), 10, _fill(const Color(0xFF8B5A2B)));
      c.drawCircle(
        const Offset(-9, -46),
        10,
        _stroke(const Color(0xFF3C2410), 2),
      );
      c.drawCircle(const Offset(-11, -48), 2.6, _fill(const Color(0xFFE9B72C)));
      c.drawCircle(const Offset(-6, -44), 2.2, _fill(const Color(0xFFE9B72C)));
    }
    _backArm(c, body, w);
    _torso(c, body, w);
    _head(c, v, body, accent);
    // miner's helmet lamp
    c.drawCircle(const Offset(6, -66), 2.6, _fill(const Color(0xFFFFE08A)));
    _arm(c, body, w, _swing(v, 0.5, -2.2, 1.35), 15, () {
      c.drawLine(const Offset(-6, 0), const Offset(22, 0), _stroke(_wood, 2.6));
      final head = Path()
        ..moveTo(18, -12)
        ..quadraticBezierTo(30, 0, 18, 12)
        ..lineTo(21, 0)
        ..close();
      c.drawPath(head, _fill(_steel));
    });
  }

  static void _squire(
    Canvas c,
    UnitVisual v,
    Color body,
    Color accent,
    double w,
  ) {
    _backArm(c, body, w);
    _torso(c, body, w);
    _head(c, v, body, accent);
    _arm(c, body, w, _swing(v, 0.7, -2.3, 1.45), 16, () {
      c.drawLine(
        const Offset(-2, 0),
        const Offset(32, 0),
        _stroke(_steel, 3.2),
      );
      c.drawLine(const Offset(3, -5), const Offset(3, 5), _stroke(accent, 2.6));
    });
  }

  static void _guard(
    Canvas c,
    UnitVisual v,
    Color body,
    Color accent,
    double w,
  ) {
    _backArm(c, body, w);
    _torso(c, body, w + 1);
    _head(c, v, body, accent);
    // spear (thrusts forward)
    _arm(c, body, w, _swing(v, 1.0, 0.55, 1.5), 15, () {
      c.drawLine(
        const Offset(-26, 0),
        const Offset(34, 0),
        _stroke(_wood, 2.8),
      );
      final tip = Path()
        ..moveTo(34, -4)
        ..lineTo(46, 0)
        ..lineTo(34, 4)
        ..close();
      c.drawPath(tip, _fill(_steel));
    });
    // big round shield
    c.drawCircle(const Offset(11, -40), 14, _fill(const Color(0xFF2B2B2B)));
    c.drawCircle(const Offset(11, -40), 14, _stroke(accent, 2.4));
    c.drawCircle(const Offset(11, -40), 4, _fill(accent));
  }

  static void _archer(
    Canvas c,
    UnitVisual v,
    Color body,
    Color accent,
    double w,
  ) {
    _backArm(c, body, w);
    _torso(c, body, w);
    _head(c, v, body, accent);
    final t = v.attackT;
    final pull = t < 0 ? 0.0 : (t < 0.55 ? t / 0.55 : 0.0);
    final sx = 16 - pull * 11;
    final bow = Path()
      ..moveTo(16, -76)
      ..quadraticBezierTo(32, -52, 16, -28);
    c.drawPath(bow, _stroke(_wood, 3));
    final str = Path()
      ..moveTo(16, -76)
      ..lineTo(sx, -52)
      ..lineTo(16, -28);
    c.drawPath(str, _stroke(const Color(0xFFEEEEEE), 1.1));
    if (t >= 0 && t < 0.56) {
      c.drawLine(Offset(sx, -52), Offset(sx + 28, -52), _stroke(_steel, 2));
    }
    c.drawLine(const Offset(0, -50), Offset(sx, -52), _stroke(body, w - 0.8));
    c.drawLine(
      const Offset(0, -50),
      const Offset(18, -52),
      _stroke(body, w - 0.8),
    );
  }

  static void _adept(
    Canvas c,
    UnitVisual v,
    Color body,
    Color accent,
    double w,
  ) {
    final robe = Path()
      ..moveTo(-3, -54)
      ..lineTo(-14, -2)
      ..lineTo(14, -2)
      ..lineTo(3, -54)
      ..close();
    c.drawPath(robe, _fill(body));
    c.drawLine(
      const Offset(-12, -14),
      const Offset(12, -14),
      _stroke(accent, 2.2),
    );
    _head(c, v, body, accent);
    final hat = Path()
      ..moveTo(-11, -66)
      ..lineTo(11, -66)
      ..lineTo(3, -92)
      ..close();
    c.drawPath(hat, _fill(body));
    c.drawLine(
      const Offset(-12, -66),
      const Offset(12, -66),
      _stroke(accent, 2.6),
    );
    final lift = v.attackT >= 0
        ? (v.attackT < 0.55 ? v.attackT / 0.55 : 0.0)
        : 0.0;
    c.drawLine(
      Offset(14, -4 - lift * 6),
      Offset(14, -80 - lift * 6),
      _stroke(_wood, 3),
    );
    final orbC = Offset(14, -84 - lift * 6);
    final orbR = 5 + lift * 3 + sin(v.time * 5) * 0.6;
    c.drawCircle(orbC, orbR + 5, _fill(const Color(0x66FF8A2B)));
    c.drawCircle(orbC, orbR, _fill(const Color(0xFFFFB347)));
    c.drawLine(
      const Offset(0, -48),
      Offset(14, -56 - lift * 8),
      _stroke(body, w - 0.8),
    );
  }

  static void _titan(
    Canvas c,
    UnitVisual v,
    Color body,
    Color accent,
    double w,
  ) {
    _backArm(c, body, w);
    _torso(c, body, w);
    _head(c, v, body, accent, r: 10.5, y: -64);
    _arm(c, body, w, _swing(v, 0.8, -2.4, 1.5), 17, () {
      c.drawLine(const Offset(0, 0), const Offset(36, 0), _stroke(_wood, 6));
      c.drawCircle(const Offset(40, 0), 11, _fill(const Color(0xFF5B5F68)));
      c.drawCircle(const Offset(40, 0), 11, _stroke(accent, 2));
    });
  }
}
