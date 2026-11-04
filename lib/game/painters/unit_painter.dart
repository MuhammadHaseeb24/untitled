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

/// Original cartoon stickman heroes with outlines and soft shading so they
/// read as chunky, volumetric characters: a Spartan-style spearman (silver
/// helmet, red crest, round shield), a hooded archer with a shell vest, a
/// bearded mage in a purple hat, miners with helmet lamps and giants.
///
/// Your army has grey skin and bright gear; the enemy has dark-red skin and
/// horns, so teams differ by shape as well as colour.
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

  static const _outline = Color(0xFF0B0B10);
  static const _steel = Color(0xFFD9DEE8);
  static const _wood = Color(0xFF8A5A2B);
  static const _white = Color(0xFFFFFFFF);

  static Color _light(Color c, [double t = 0.3]) => Color.lerp(c, _white, t)!;
  static Color _dark(Color c, [double t = 0.35]) =>
      Color.lerp(c, const Color(0xFF000000), t)!;

  // --- entry point --------------------------------------------------------------

  static void paint(Canvas c, UnitVisual v) {
    final friendly = v.team == Team.player;
    final skin = friendly ? const Color(0xFF5C5C65) : const Color(0xFF8E2A2A);
    final limb = friendly ? const Color(0xFF34343C) : const Color(0xFF5A1616);

    c.save();
    c.scale(v.facing * v.scale, v.scale);

    c.drawOval(
      Rect.fromCenter(center: const Offset(0, 2), width: 40, height: 10),
      _fill(const Color(0x66000000)),
    );
    if (v.buffed) {
      final a = (140 + 80 * sin(v.time * 6)).round().clamp(40, 255);
      c.drawOval(
        Rect.fromCenter(center: const Offset(0, 2), width: 48, height: 14),
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
      c.saveLayer(const Rect.fromLTWH(-100, -190, 200, 210), lp);
    }

    final bob = v.moving
        ? sin(v.walk * 2).abs() * 2.0
        : sin(v.time * 2.5) * 0.8;
    final w = v.unitId == 'ember_titan' ? 13.0 : 8.0;
    if (v.unitId != 'flame_adept') _legs(c, v, limb, w * 0.85);
    c.save();
    c.translate(0, -bob);
    switch (v.unitId) {
      case 'miner':
        _miner(c, v, skin, limb, w);
        break;
      case 'iron_guard':
        _guard(c, v, skin, limb, w);
        break;
      case 'ash_archer':
        _archer(c, v, skin, limb, w);
        break;
      case 'flame_adept':
        _adept(c, v, skin, limb, w);
        break;
      case 'ember_titan':
        _titan(c, v, skin, limb, w);
        break;
      default:
        _squire(c, v, skin, limb, w);
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

  // --- building blocks ----------------------------------------------------------

  /// Thick limb with a dark outline and a soft highlight (gives volume).
  static void _limb(Canvas c, Offset a, Offset b, double w, Color base) {
    c.drawLine(a, b, _stroke(_outline, w + 3.2));
    c.drawLine(a, b, _stroke(base, w));
    final d = Offset(-w * 0.16, -w * 0.2);
    c.drawLine(a + d, b + d, _stroke(_light(base, 0.28), w * 0.28));
  }

  static void _legs(Canvas c, UnitVisual v, Color limb, double w) {
    final s = v.moving ? sin(v.walk) : 0.0;
    for (final side in const [1.0, -1.0]) {
      final foot = Offset(s * side * 11 - 1 + side * 2, -1);
      _limb(c, const Offset(0, -28), foot, w, limb);
      c.drawOval(
        Rect.fromCenter(center: foot.translate(3, 0), width: 14, height: 6),
        _fill(_outline),
      );
    }
  }

  static void _torso(Canvas c, Color limb, double w, {double top = -54}) {
    _limb(c, const Offset(0, -28), Offset(0, top), w + 2, limb);
  }

  /// Angry cartoon face on a round head.
  static void _head(
    Canvas c,
    UnitVisual v,
    Color skin, {
    double r = 10,
    double y = -64,
    bool horns = true,
    bool face = true,
  }) {
    final ctr = Offset(0, y);
    c.drawCircle(ctr, r + 1.7, _fill(_outline));
    c.drawCircle(ctr, r, _fill(skin));
    c.drawCircle(
      ctr.translate(-r * 0.3, -r * 0.35),
      r * 0.55,
      _fill(Color.fromARGB(70, 255, 255, 255)),
    );
    if (v.team == Team.enemy && horns) {
      for (final s in const [-1.0, 1.0]) {
        final horn = Path()
          ..moveTo(s * r * 0.45, y - r * 0.8)
          ..quadraticBezierTo(
            s * r * 1.5,
            y - r * 1.1,
            s * r * 1.45,
            y - r * 2.0,
          )
          ..quadraticBezierTo(
            s * r * 0.95,
            y - r * 1.2,
            s * r * 0.1,
            y - r * 0.6,
          )
          ..close();
        c.drawPath(horn, _fill(const Color(0xFFF1E6CF)));
        c.drawPath(horn, _stroke(_outline, 1.6));
      }
    }
    if (!face) return;
    final e1 = Offset(r * 0.18, y - r * 0.12);
    final e2 = Offset(r * 0.66, y - r * 0.12);
    for (final e in [e1, e2]) {
      c.drawOval(
        Rect.fromCenter(center: e, width: r * 0.5, height: r * 0.42),
        _fill(_white),
      );
      c.drawCircle(e.translate(r * 0.08, 0), r * 0.13, _fill(_outline));
    }
    c.drawLine(
      e1.translate(-r * 0.3, -r * 0.34),
      e1.translate(r * 0.28, -r * 0.12),
      _stroke(_outline, 2.2),
    );
    c.drawLine(
      e2.translate(r * 0.3, -r * 0.34),
      e2.translate(-r * 0.28, -r * 0.12),
      _stroke(_outline, 2.2),
    );
    c.drawLine(
      Offset(r * 0.3, y + r * 0.5),
      Offset(r * 0.85, y + r * 0.42),
      _stroke(_outline, 2),
    );
  }

  static void _backArm(Canvas c, Color limb, double w) {
    _limb(
      c,
      const Offset(0, -50),
      const Offset(-10, -36),
      w * 0.8,
      _dark(limb, 0.15),
    );
  }

  /// Draws an arm from the shoulder at [angle] (0 = hanging, positive = forward)
  /// and calls [weapon] with the canvas at the hand.
  static void _arm(
    Canvas c,
    Color skin,
    double w,
    double angle,
    double len,
    void Function() weapon,
  ) {
    c.save();
    c.translate(0, -50);
    c.rotate(angle - pi / 2);
    _limb(c, Offset.zero, Offset(len, 0), w * 0.85, skin);
    c.translate(len, 0);
    c.drawCircle(Offset.zero, w * 0.62, _fill(_outline));
    c.drawCircle(Offset.zero, w * 0.5, _fill(skin));
    weapon();
    c.restore();
  }

  static void _blade(Canvas c, double from, double to, double w) {
    c.drawLine(Offset(from, 0), Offset(to, 0), _stroke(_outline, w + 2.6));
    c.drawLine(Offset(from, 0), Offset(to, 0), _stroke(_steel, w));
    c.drawLine(
      Offset(from, -w * 0.25),
      Offset(to, -w * 0.25),
      _stroke(_white, w * 0.25),
    );
  }

  // --- unit types ---------------------------------------------------------------

  static void _squire(
    Canvas c,
    UnitVisual v,
    Color skin,
    Color limb,
    double w,
  ) {
    final f = v.team == Team.player;
    _backArm(c, limb, w);
    _torso(c, limb, w);
    // belt
    c.drawLine(
      const Offset(-6, -32),
      const Offset(6, -32),
      _stroke(_outline, 3),
    );
    _head(c, v, skin);
    if (f) {
      c.drawLine(
        const Offset(-9, -68),
        const Offset(10, -68),
        _stroke(const Color(0xFF3A8DFF), 3.4),
      );
      c.drawLine(
        const Offset(-9, -68),
        const Offset(-18, -62),
        _stroke(const Color(0xFF3A8DFF), 3),
      );
    }
    _arm(c, skin, w, _swing(v, 0.7, -2.3, 1.45), 17, () {
      c.drawLine(
        const Offset(-3, -6),
        const Offset(-3, 6),
        _stroke(const Color(0xFFB98A33), 3.4),
      );
      _blade(c, -4, 36, 4.2);
    });
  }

  static void _guard(Canvas c, UnitVisual v, Color skin, Color limb, double w) {
    final f = v.team == Team.player;
    final cape = f ? const Color(0xFFC4281F) : const Color(0xFF3B0E0E);
    final crest = f ? const Color(0xFFE8542A) : const Color(0xFF1C1C20);
    final helm = f ? const Color(0xFFC9CED8) : const Color(0xFF8A8F99);
    // cape flowing behind
    final sway = v.moving ? sin(v.walk) * 3 : sin(v.time * 2) * 1.2;
    final capePath = Path()
      ..moveTo(-2, -54)
      ..quadraticBezierTo(-20 + sway, -34, -24 + sway, -6)
      ..lineTo(-6, -10)
      ..lineTo(2, -50)
      ..close();
    c.drawPath(capePath, _fill(cape));
    c.drawPath(capePath, _stroke(_outline, 2));
    _backArm(c, limb, w);
    _torso(c, limb, w + 1);
    // chest plate
    c.drawOval(
      Rect.fromCenter(center: const Offset(2, -42), width: 18, height: 22),
      _fill(_outline),
    );
    c.drawOval(
      Rect.fromCenter(center: const Offset(2, -42), width: 15, height: 19),
      _fill(helm),
    );
    // spartan helmet
    _head(c, v, skin, horns: false, face: false);
    c.drawCircle(const Offset(0, -64), 11.8, _fill(_outline));
    c.drawCircle(const Offset(0, -64), 10.4, _fill(helm));
    c.drawCircle(const Offset(-3, -68), 5.5, _fill(const Color(0x66FFFFFF)));
    // face opening
    final face = RRect.fromRectAndRadius(
      const Rect.fromLTWH(1, -70, 11, 17),
      const Radius.circular(4),
    );
    c.drawRRect(face, _fill(_outline));
    c.drawOval(
      Rect.fromCenter(center: const Offset(5, -63), width: 4.6, height: 3.4),
      _fill(_white),
    );
    c.drawOval(
      Rect.fromCenter(center: const Offset(10, -63), width: 4.6, height: 3.4),
      _fill(_white),
    );
    c.drawLine(
      const Offset(2, -67),
      const Offset(7, -65),
      _stroke(const Color(0xFFB0B4BC), 1.6),
    );
    c.drawLine(
      const Offset(12, -67),
      const Offset(8, -65),
      _stroke(const Color(0xFFB0B4BC), 1.6),
    );
    c.drawLine(
      const Offset(4, -56),
      const Offset(11, -56),
      _stroke(const Color(0xFFB04A4A), 1.8),
    );
    // crest
    final crestPath = Path()
      ..moveTo(-8, -73)
      ..lineTo(-10, -81)
      ..lineTo(-4, -79)
      ..lineTo(-1, -90)
      ..lineTo(3, -80)
      ..lineTo(9, -83)
      ..lineTo(8, -73)
      ..close();
    c.drawPath(crestPath, _fill(crest));
    c.drawPath(crestPath, _stroke(_outline, 1.8));
    c.drawPath(
      Path()
        ..moveTo(-2, -80)
        ..lineTo(-1, -87)
        ..lineTo(1, -80),
      _stroke(_light(crest, 0.4), 1.6),
    );
    // spear (thrusts forward)
    _arm(c, skin, w, _swing(v, 1.0, 0.55, 1.5), 16, () {
      c.drawLine(
        const Offset(-30, 0),
        const Offset(38, 0),
        _stroke(_outline, 5),
      );
      c.drawLine(const Offset(-30, 0), const Offset(38, 0), _stroke(_wood, 3));
      final tip = Path()
        ..moveTo(36, -5)
        ..lineTo(52, 0)
        ..lineTo(36, 5)
        ..close();
      c.drawPath(tip, _fill(_steel));
      c.drawPath(tip, _stroke(_outline, 1.6));
    });
    // big round shield
    c.drawCircle(const Offset(13, -38), 17, _fill(_outline));
    c.drawCircle(const Offset(13, -38), 15, _fill(const Color(0xFF9AA0AC)));
    c.drawCircle(
      const Offset(13, -38),
      15,
      _stroke(const Color(0xFFB98A33), 3),
    );
    c.drawCircle(const Offset(13, -38), 6, _fill(const Color(0xFFB98A33)));
    c.drawCircle(const Offset(9, -43), 4, _fill(const Color(0x66FFFFFF)));
  }

  static void _archer(
    Canvas c,
    UnitVisual v,
    Color skin,
    Color limb,
    double w,
  ) {
    final f = v.team == Team.player;
    final shell = f ? const Color(0xFF8A6A3C) : const Color(0xFF3C2A20);
    // shell vest on the back
    c.drawOval(
      Rect.fromCenter(center: const Offset(-8, -42), width: 22, height: 34),
      _fill(_outline),
    );
    c.drawOval(
      Rect.fromCenter(center: const Offset(-8, -42), width: 19, height: 31),
      _fill(shell),
    );
    c.drawLine(
      const Offset(-8, -56),
      const Offset(-8, -28),
      _stroke(_dark(shell), 1.6),
    );
    c.drawLine(
      const Offset(-15, -48),
      const Offset(-1, -48),
      _stroke(_dark(shell), 1.6),
    );
    c.drawLine(
      const Offset(-15, -38),
      const Offset(-1, -38),
      _stroke(_dark(shell), 1.6),
    );
    _backArm(c, limb, w);
    _torso(c, limb, w);
    _head(c, v, skin);
    // hood band
    c.drawArc(
      Rect.fromCircle(center: const Offset(0, -64), radius: 10.5),
      pi * 1.05,
      pi * 0.9,
      false,
      _stroke(_dark(shell, 0.2), 4),
    );
    final t = v.attackT;
    final pull = t < 0 ? 0.0 : (t < 0.55 ? t / 0.55 : 0.0);
    final sx = 17 - pull * 12;
    final bow = Path()
      ..moveTo(17, -80)
      ..quadraticBezierTo(36, -52, 17, -24);
    c.drawPath(bow, _stroke(_outline, 6));
    c.drawPath(bow, _stroke(_wood, 3.4));
    final str = Path()
      ..moveTo(17, -80)
      ..lineTo(sx, -52)
      ..lineTo(17, -24);
    c.drawPath(str, _stroke(const Color(0xFFEEEEEE), 1.2));
    if (t >= 0 && t < 0.56) {
      c.drawLine(Offset(sx, -52), Offset(sx + 30, -52), _stroke(_outline, 3.6));
      c.drawLine(Offset(sx, -52), Offset(sx + 30, -52), _stroke(_steel, 2));
      final head = Path()
        ..moveTo(sx + 28, -55)
        ..lineTo(sx + 38, -52)
        ..lineTo(sx + 28, -49)
        ..close();
      c.drawPath(head, _fill(_steel));
    }
    _limb(c, const Offset(0, -50), Offset(sx, -52), w * 0.8, skin);
    _limb(c, const Offset(0, -50), const Offset(20, -53), w * 0.8, skin);
  }

  static void _adept(Canvas c, UnitVisual v, Color skin, Color limb, double w) {
    final f = v.team == Team.player;
    final robe = f ? const Color(0xFF3B2468) : const Color(0xFF4A1414);
    final hat = f ? const Color(0xFF4B2E83) : const Color(0xFF2C1212);
    final orb = f ? const Color(0xFFB36BFF) : const Color(0xFFFF6A3A);
    final robePath = Path()
      ..moveTo(-4, -56)
      ..lineTo(-17, -2)
      ..lineTo(17, -2)
      ..lineTo(4, -56)
      ..close();
    c.drawPath(robePath, _fill(robe));
    c.drawPath(robePath, _stroke(_outline, 2.4));
    c.drawLine(
      const Offset(-13, -16),
      const Offset(13, -16),
      _stroke(const Color(0xFFF2C14E), 2.4),
    );
    c.drawLine(
      const Offset(-5, -50),
      const Offset(-9, -8),
      _stroke(_light(robe, 0.2), 1.6),
    );
    // beard
    final beard = Path()
      ..moveTo(1, -58)
      ..quadraticBezierTo(12, -56, 11, -46)
      ..quadraticBezierTo(6, -34, 0, -32)
      ..quadraticBezierTo(-3, -44, 1, -58)
      ..close();
    _head(c, v, skin, horns: false);
    c.drawPath(beard, _fill(const Color(0xFFF2F2F2)));
    c.drawPath(beard, _stroke(_outline, 1.8));
    // hat
    final hatPath = Path()
      ..moveTo(-13, -69)
      ..lineTo(13, -69)
      ..lineTo(6, -88)
      ..quadraticBezierTo(14, -96, 18, -104)
      ..quadraticBezierTo(2, -100, -4, -90)
      ..close();
    c.drawPath(hatPath, _fill(hat));
    c.drawPath(hatPath, _stroke(_outline, 2.2));
    c.drawLine(
      const Offset(-14, -69),
      const Offset(14, -69),
      _stroke(_outline, 6),
    );
    c.drawLine(
      const Offset(-14, -69),
      const Offset(14, -69),
      _stroke(_dark(hat, 0.1), 3.6),
    );
    c.drawLine(
      const Offset(-9, -73),
      const Offset(9, -73),
      _stroke(const Color(0xFFF2C14E), 2.4),
    );
    final lift = v.attackT >= 0
        ? (v.attackT < 0.55 ? v.attackT / 0.55 : 0.0)
        : 0.0;
    // staff
    final top = Offset(16, -86 - lift * 6);
    c.drawLine(Offset(16, -2 - lift * 6), top, _stroke(_outline, 6));
    c.drawLine(Offset(16, -2 - lift * 6), top, _stroke(_wood, 3.4));
    final orbR = 6 + lift * 3 + sin(v.time * 5) * 0.7;
    c.drawCircle(top.translate(0, -6), orbR + 8, _fill(orb.withAlpha(70)));
    c.drawCircle(top.translate(0, -6), orbR + 1.6, _fill(_outline));
    c.drawCircle(top.translate(0, -6), orbR, _fill(orb));
    c.drawCircle(
      top.translate(-2, -8),
      orbR * 0.4,
      _fill(const Color(0xAAFFFFFF)),
    );
    for (var i = 0; i < 3; i++) {
      final a = v.time * 3 + i * 2.09;
      c.drawCircle(
        top.translate(-0.0 + cos(a) * (orbR + 9), -6 + sin(a) * (orbR + 6)),
        1.8,
        _fill(orb),
      );
    }
    _limb(c, const Offset(0, -50), Offset(16, -58 - lift * 8), w * 0.8, skin);
    _limb(c, const Offset(0, -50), const Offset(-8, -38), w * 0.8, skin);
  }

  static void _miner(Canvas c, UnitVisual v, Color skin, Color limb, double w) {
    if (v.carrying) {
      c.drawCircle(const Offset(-11, -46), 13, _fill(_outline));
      c.drawCircle(
        const Offset(-11, -46),
        11.4,
        _fill(const Color(0xFF8B5A2B)),
      );
      c.drawCircle(const Offset(-14, -49), 3, _fill(const Color(0xFFE9B72C)));
      c.drawCircle(const Offset(-8, -44), 2.6, _fill(const Color(0xFFE9B72C)));
      c.drawCircle(const Offset(-12, -42), 2.2, _fill(const Color(0xFFFFE066)));
      c.drawCircle(const Offset(-15, -52), 4.5, _fill(const Color(0x55FFFFFF)));
    }
    _backArm(c, limb, w);
    _torso(c, limb, w);
    _head(c, v, skin, horns: v.team == Team.enemy);
    // yellow hard hat with lamp
    final hat = Path()
      ..moveTo(-11, -66)
      ..quadraticBezierTo(0, -82, 11, -66)
      ..close();
    c.drawPath(hat, _fill(const Color(0xFFFFC400)));
    c.drawPath(hat, _stroke(_outline, 2));
    c.drawLine(
      const Offset(-12, -66),
      const Offset(12, -66),
      _stroke(_outline, 3.4),
    );
    c.drawCircle(const Offset(9, -71), 3.2, _fill(const Color(0xFFFFF2A8)));
    c.drawCircle(const Offset(9, -71), 6, _fill(const Color(0x44FFE066)));
    _arm(c, skin, w, _swing(v, 0.5, -2.2, 1.35), 16, () {
      c.drawLine(
        const Offset(-8, 0),
        const Offset(26, 0),
        _stroke(_outline, 5),
      );
      c.drawLine(const Offset(-8, 0), const Offset(26, 0), _stroke(_wood, 3));
      final head = Path()
        ..moveTo(22, -14)
        ..quadraticBezierTo(36, 0, 22, 14)
        ..lineTo(26, 0)
        ..close();
      c.drawPath(head, _fill(_steel));
      c.drawPath(head, _stroke(_outline, 1.8));
    });
  }

  static void _titan(Canvas c, UnitVisual v, Color skin, Color limb, double w) {
    final f = v.team == Team.player;
    _backArm(c, limb, w);
    _torso(c, limb, w);
    // shoulder pads
    for (final s in const [-1.0, 1.0]) {
      c.drawCircle(Offset(s * 11, -52), 10, _fill(_outline));
      c.drawCircle(Offset(s * 11, -52), 8.4, _fill(const Color(0xFF6B717E)));
      c.drawCircle(Offset(s * 11 - 2, -55), 3, _fill(const Color(0x66FFFFFF)));
    }
    _head(c, v, skin, r: 12, y: -68);
    if (f) {
      c.drawLine(
        const Offset(-11, -72),
        const Offset(12, -72),
        _stroke(const Color(0xFFD7322B), 3.6),
      );
    }
    _arm(c, skin, w, _swing(v, 0.8, -2.4, 1.5), 18, () {
      c.drawLine(const Offset(0, 0), const Offset(38, 0), _stroke(_outline, 9));
      c.drawLine(const Offset(0, 0), const Offset(38, 0), _stroke(_wood, 6));
      c.drawCircle(const Offset(44, 0), 15, _fill(_outline));
      c.drawCircle(const Offset(44, 0), 13, _fill(const Color(0xFF5B5F68)));
      for (var i = 0; i < 6; i++) {
        final a = i / 6 * 2 * pi;
        final p1 = Offset(44 + cos(a) * 12, sin(a) * 12);
        final p2 = Offset(44 + cos(a) * 21, sin(a) * 21);
        c.drawLine(p1, p2, _stroke(_outline, 6));
        c.drawLine(p1, p2, _stroke(_steel, 3));
      }
    });
  }
}
