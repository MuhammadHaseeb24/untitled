import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../game_config.dart';

class _Star {
  _Star(this.x, this.y, this.r, this.phase);
  final double x, y, r, phase;
}

/// Level backdrops, drawn in virtual coordinates and extended beyond the
/// world so letterboxing is seamless. Theme (level.theme % 6):
/// 0 = night field with a moon, 1 = snow mountains with an orange sun,
/// 2 = brown desert with pyramids and flame braziers, 3 = volcano with
/// ash and lava, 4 = twilight forest with fireflies, 5 = storm with rain
/// and lightning.
class BattlefieldBackground extends Component {
  BattlefieldBackground({required int theme, required this.lowQuality})
      : mode = theme.abs() % 6,
        super(priority: 0) {
    final r = Random(theme * 13 + 7);
    final starCount = lowQuality ? 35 : 90;
    for (var i = 0; i < starCount; i++) {
      _stars.add(
        _Star(
          r.nextDouble() * 1700 - 50,
          r.nextDouble() * 300,
          0.8 + r.nextDouble() * 1.5,
          r.nextDouble() * 6.28,
        ),
      );
    }
    final List<Color> sky;
    final List<Color> ground;
    switch (mode) {
      case 1:
        sky = const [Color(0xFF081A52), Color(0xFF1C47A0), Color(0xFF3C74C8)];
        ground = const [
          Color(0xFF74AAB4),
          Color(0xFF5B8E9A),
          Color(0xFF3F6772),
        ];
        break;
      case 2:
        sky = const [Color(0xFFB8935A), Color(0xFFCFAA70), Color(0xFFDDBE86)];
        ground = const [
          Color(0xFFA27A4A),
          Color(0xFF86633A),
          Color(0xFF5E4426),
        ];
        break;
      case 3:
        sky = const [Color(0xFF1A0505), Color(0xFF5A1408), Color(0xFFD2501A)];
        ground = const [
          Color(0xFF4A3530),
          Color(0xFF332320),
          Color(0xFF170F0D),
        ];
        break;
      case 4:
        sky = const [Color(0xFF1B1038), Color(0xFF5B2A78), Color(0xFFE0709A)];
        ground = const [
          Color(0xFF2E6B63),
          Color(0xFF225650),
          Color(0xFF143A38),
        ];
        break;
      case 5:
        sky = const [Color(0xFF262A34), Color(0xFF454E5C), Color(0xFF7A8594)];
        ground = const [
          Color(0xFF55645A),
          Color(0xFF3F4C45),
          Color(0xFF2A332E),
        ];
        break;
      default:
        sky = const [Color(0xFF040A26), Color(0xFF0C2A63), Color(0xFF2C6CA8)];
        ground = const [
          Color(0xFF237A2E),
          Color(0xFF1B6A27),
          Color(0xFF11481B),
        ];
    }
    skyPaint = Paint()
      ..shader = Gradient.linear(
        const Offset(0, 0),
        const Offset(0, _horizon),
        sky,
        const [0.0, 0.65, 1.0],
      );
    groundPaint = Paint()
      ..shader = Gradient.linear(
        const Offset(0, _horizon),
        const Offset(0, GameConfig.worldHeight),
        ground,
        const [0.0, 0.5, 1.0],
      );
    _farHill = _hill(r, 335, 22, 260);
    _midHill = _hill(r, 370, 16, 190);
    _peaks = _mountains(r);
    for (var i = 0; i < 160; i++) {
      final x = r.nextDouble() * 1800 - 100;
      final y = _horizon + 30 + r.nextDouble() * 350;
      _marks.add(Offset(x, y));
      _marks.add(
        Offset(x + 7 + r.nextDouble() * 16, y + r.nextDouble() * 2 - 1),
      );
    }
    for (var i = 0; i < 9; i++) {
      _stains.add(
        Rect.fromCenter(
          center: Offset(
            300 + r.nextDouble() * 1000,
            GameConfig.groundY - 20 + r.nextDouble() * 90,
          ),
          width: 50 + r.nextDouble() * 70,
          height: 8 + r.nextDouble() * 6,
        ),
      );
    }
    for (var i = 0; i < 40; i++) {
      _pines.add(
        Offset(
          -40 + i * 44.0 + r.nextDouble() * 20,
          0.6 + r.nextDouble() * 0.6,
        ),
      );
    }
  }

  static const double _horizon = 330;

  final int mode;
  final bool lowQuality;
  late final Paint skyPaint;
  late final Paint groundPaint;
  late final Path _farHill;
  late final Path _midHill;
  late final List<List<double>> _peaks;
  final List<_Star> _stars = [];
  final List<Offset> _marks = [];
  final List<Rect> _stains = [];
  final List<Offset> _pines = [];
  final Paint _p = Paint();
  double _t = 0;

  static List<List<double>> _mountains(Random r) {
    final out = <List<double>>[];
    var x = -150.0;
    while (x < 1800) {
      final w = 280 + r.nextDouble() * 220;
      out.add([x, w, 130 + r.nextDouble() * 170]);
      x += w * 0.62;
    }
    return out;
  }

  static Path _hill(Random r, double baseY, double amp, double wave) {
    final p = Path()..moveTo(-300, 760);
    p.lineTo(-300, baseY);
    var x = -300.0;
    var up = true;
    while (x < 1900) {
      final nx = x + wave * (0.6 + r.nextDouble() * 0.8);
      final cy = baseY + (up ? -amp : amp) * (0.6 + r.nextDouble() * 0.8);
      p.quadraticBezierTo(
        (x + nx) / 2,
        cy,
        nx,
        baseY + (r.nextDouble() - 0.5) * amp * 0.8,
      );
      x = nx;
      up = !up;
    }
    p
      ..lineTo(x, 760)
      ..close();
    return p;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      const Rect.fromLTRB(-2000, -1500, 3600, _horizon + 40),
      skyPaint,
    );
    switch (mode) {
      case 1:
        _renderSnow(canvas);
        break;
      case 2:
        _renderDesert(canvas);
        break;
      case 3:
        _renderVolcano(canvas);
        break;
      case 4:
        _renderForest(canvas);
        break;
      case 5:
        _renderStorm(canvas);
        break;
      default:
        _renderNight(canvas);
    }

    canvas.drawRect(
      Rect.fromLTRB(-2000, _horizon + 40, 3600, 2200),
      groundPaint,
    );
    canvas.drawRect(
      Rect.fromLTRB(-2000, _horizon + 40, 3600, _horizon + 46),
      _p..color = mode == 2 ? const Color(0x33FFFFFF) : const Color(0x2200FF00),
    );

    final marks = _p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = mode == 0
          ? const Color(0x3300230A)
          : (mode == 3 ? const Color(0x77FF6A1A) : const Color(0x22000000));
    for (var i = 0; i + 1 < _marks.length; i += 2) {
      canvas.drawLine(_marks[i], _marks[i + 1], marks);
    }
    _p.style = PaintingStyle.fill;

    if (mode == 1) {
      for (var i = 0; i < _stains.length; i++) {
        canvas.drawOval(
          _stains[i].translate(0, -30),
          _p..color = const Color(0x55FFFFFF),
        );
      }
    }
    for (final s in _stains) {
      canvas.drawOval(s, _p..color = const Color(0x66660808));
    }
  }

  void _renderNight(Canvas canvas) {
    for (final s in _stars) {
      final tw = 0.55 + 0.45 * sin(_t * 1.6 + s.phase);
      canvas.drawCircle(
        Offset(s.x, s.y),
        s.r,
        _p..color = Color.fromARGB((220 * tw).round(), 255, 255, 255),
      );
    }
    const moon = Offset(300, 120);
    for (var i = 4; i >= 1; i--) {
      canvas.drawCircle(
        moon,
        62.0 + i * 20,
        _p..color = Color.fromARGB(14 + (4 - i) * 5, 150, 220, 235),
      );
    }
    canvas.drawCircle(moon, 62, _p..color = const Color(0xFF7FC4D6));
    canvas.drawCircle(moon, 62, _p..color = const Color(0x33FFFFFF));
    canvas.drawCircle(
      const Offset(280, 100),
      14,
      _p..color = const Color(0x3300283A),
    );
    canvas.drawCircle(
      const Offset(325, 138),
      10,
      _p..color = const Color(0x3300283A),
    );
    canvas.drawCircle(
      const Offset(268, 146),
      7,
      _p..color = const Color(0x3300283A),
    );
    canvas.drawPath(_farHill, _p..color = const Color(0xFF0E4A1E));
    canvas.drawPath(_midHill, _p..color = const Color(0xFF17642A));
  }

  void _renderSnow(Canvas canvas) {
    // big orange sun with glow
    const sun = Offset(1250, 210);
    for (var i = 5; i >= 1; i--) {
      canvas.drawCircle(
        sun,
        110.0 + i * 26,
        _p..color = Color.fromARGB(16 + (5 - i) * 6, 255, 120, 30),
      );
    }
    canvas.drawCircle(sun, 110, _p..color = const Color(0xFFFF8A18));
    canvas.drawCircle(
      const Offset(1235, 195),
      70,
      _p..color = const Color(0x55FF3B10),
    );

    // snowy mountains: icy body + white cap
    for (final m in _peaks) {
      final x = m[0], w = m[1], h = m[2];
      final base = _horizon + 30;
      final body = Path()
        ..moveTo(x, base)
        ..lineTo(x + w * 0.5, base - h)
        ..lineTo(x + w, base)
        ..close();
      canvas.drawPath(body, _p..color = const Color(0xFF6CCBE8));
      final cap = Path()
        ..moveTo(x + w * 0.5, base - h)
        ..lineTo(x + w * 0.32, base - h * 0.62)
        ..lineTo(x + w * 0.42, base - h * 0.66)
        ..lineTo(x + w * 0.5, base - h * 0.55)
        ..lineTo(x + w * 0.6, base - h * 0.68)
        ..lineTo(x + w * 0.68, base - h * 0.62)
        ..close();
      canvas.drawPath(cap, _p..color = const Color(0xFFF2FCFF));
    }
    canvas.drawPath(_midHill, _p..color = const Color(0xFF7DB4BE));
    // pine trees
    for (final t in _pines) {
      final bx = t.dx;
      final by = _horizon + 38 + (t.dy - 0.6) * 40;
      final hgt = 26 + t.dy * 34;
      canvas.drawRect(
        Rect.fromLTWH(bx - 2, by - 6, 4, 8),
        _p..color = const Color(0xFF4A3520),
      );
      for (var k = 0; k < 3; k++) {
        final w = hgt * (0.42 - k * 0.07);
        final y = by - 6 - k * hgt * 0.28;
        final tri = Path()
          ..moveTo(bx - w, y)
          ..lineTo(bx, y - hgt * 0.5)
          ..lineTo(bx + w, y)
          ..close();
        canvas.drawPath(tri, _p..color = const Color(0xFF2E7D4A));
      }
    }
  }

  void _renderDesert(Canvas canvas) {
    // far dunes
    canvas.drawPath(_farHill, _p..color = const Color(0xFFC49D61));
    // golden pyramids / temples
    for (final x in [380.0, 880.0, 1340.0]) {
      final base = _horizon + 40;
      final body = Path()
        ..moveTo(x - 120, base)
        ..lineTo(x, base - 150)
        ..lineTo(x + 120, base)
        ..close();
      canvas.drawPath(body, _p..color = const Color(0xFFE2B85A));
      final shade = Path()
        ..moveTo(x, base - 150)
        ..lineTo(x + 120, base)
        ..lineTo(x + 10, base)
        ..close();
      canvas.drawPath(shade, _p..color = const Color(0xFFB98A33));
      canvas.drawRect(
        Rect.fromLTWH(x - 18, base - 44, 36, 44),
        _p..color = const Color(0xFF3F2E18),
      );
    }
    // brown stone wall behind the battle line
    canvas.drawRect(
      const Rect.fromLTRB(-2000, _horizon - 20, 3600, _horizon + 44),
      _p..color = const Color(0xFF8A6A3E),
    );
    for (var x = -100.0; x < 1750; x += 64) {
      canvas.drawLine(
        Offset(x, _horizon - 20),
        Offset(x, _horizon + 44),
        _p
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0x33000000),
      );
    }
    _p.style = PaintingStyle.fill;
    // flame braziers
    for (final x in [150.0, 640.0, 1120.0, 1500.0]) {
      final y = _horizon + 38;
      canvas.drawRect(
        Rect.fromLTWH(x - 14, y - 26, 28, 26),
        _p..color = const Color(0xFF2E2216),
      );
      canvas.drawRect(
        Rect.fromLTWH(x - 20, y - 32, 40, 8),
        _p..color = const Color(0xFF4A3622),
      );
      final f = 1 + 0.12 * sin(_t * 9 + x);
      canvas.drawCircle(
        Offset(x, y - 48),
        18 * f,
        _p..color = const Color(0xAAFF7A1A),
      );
      canvas.drawCircle(
        Offset(x, y - 46),
        11 * f,
        _p..color = const Color(0xFFFFB02E),
      );
      canvas.drawCircle(
        Offset(x, y - 44),
        5 * f,
        _p..color = const Color(0xFFFFF0A0),
      );
    }
  }
}

extension _MoreThemes on BattlefieldBackground {
  void _renderVolcano(Canvas canvas) {
    // drifting ash / embers
    for (final st in _stars) {
      final y = (st.y - _t * 22 * st.r) % 330;
      final a = (60 + 120 * (0.5 + 0.5 * sin(_t * 2 + st.phase))).round();
      canvas.drawCircle(
        Offset(st.x, y),
        st.r * 1.1,
        _p..color = Color.fromARGB(a, 255, 150, 60),
      );
    }
    canvas.drawPath(_farHill, _p..color = const Color(0xFF2A1512));
    for (final x in [260.0, 820.0, 1330.0]) {
      const base = BattlefieldBackground._horizon + 40;
      final cone = Path()
        ..moveTo(x - 190, base)
        ..lineTo(x - 36, base - 190)
        ..lineTo(x + 36, base - 190)
        ..lineTo(x + 190, base)
        ..close();
      canvas.drawPath(cone, _p..color = const Color(0xFF3A1D16));
      // lava glow and streams
      canvas.drawCircle(
        Offset(x, base - 190),
        44 + 4 * sin(_t * 3 + x),
        _p..color = const Color(0x55FF6A1A),
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, base - 190), width: 74, height: 20),
        _p..color = const Color(0xFFFF8A2B),
      );
      canvas.drawLine(
        Offset(x - 10, base - 188),
        Offset(x - 60, base - 60),
        _p
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..color = const Color(0xCCFF6A1A),
      );
      canvas.drawLine(
        Offset(x + 12, base - 188),
        Offset(x + 50, base - 80),
        _p..strokeWidth = 4,
      );
      _p.style = PaintingStyle.fill;
      // smoke
      for (var k = 0; k < 4; k++) {
        final dy = (_t * 26 + k * 40) % 160;
        canvas.drawCircle(
          Offset(x + 14 * sin(_t + k), base - 200 - dy),
          18 + dy * 0.18,
          _p
            ..color = Color.fromARGB(
              (90 - dy * 0.5).round().clamp(0, 255),
              40,
              30,
              30,
            ),
        );
      }
    }
    canvas.drawPath(_midHill, _p..color = const Color(0xFF241210));
  }

  void _renderForest(Canvas canvas) {
    for (final st in _stars) {
      final tw = 0.5 + 0.5 * sin(_t * 1.4 + st.phase);
      canvas.drawCircle(
        Offset(st.x, st.y * 0.8),
        st.r * 0.8,
        _p..color = Color.fromARGB((170 * tw).round(), 255, 235, 255),
      );
    }
    canvas.drawCircle(
      const Offset(980, 120),
      48,
      _p..color = const Color(0x44FFD6F0),
    );
    canvas.drawCircle(
      const Offset(980, 120),
      34,
      _p..color = const Color(0xFFF7DDF2),
    );
    canvas.drawPath(_farHill, _p..color = const Color(0xFF281645));
    // two layers of dark pines
    for (var layer = 0; layer < 2; layer++) {
      final col =
          layer == 0 ? const Color(0xFF1F1038) : const Color(0xFF2B1750);
      for (final t in _pines) {
        final bx = t.dx + layer * 22;
        final by = BattlefieldBackground._horizon + 42 + layer * 8;
        final hgt = (layer == 0 ? 60 : 44) + t.dy * 40;
        for (var k = 0; k < 4; k++) {
          final w = hgt * (0.34 - k * 0.05);
          final y = by - k * hgt * 0.22;
          final tri = Path()
            ..moveTo(bx - w, y)
            ..lineTo(bx, y - hgt * 0.42)
            ..lineTo(bx + w, y)
            ..close();
          canvas.drawPath(tri, _p..color = col);
        }
      }
    }
    // fireflies
    for (final st in _stars) {
      final fx = st.x + 20 * sin(_t * 0.6 + st.phase);
      final fy = BattlefieldBackground._horizon +
          60 +
          (st.y % 230) +
          12 * cos(_t * 0.7 + st.phase);
      final a = (60 + 190 * (0.5 + 0.5 * sin(_t * 3 + st.phase * 2))).round();
      canvas.drawCircle(
        Offset(fx, fy),
        6,
        _p..color = Color.fromARGB(a ~/ 3, 230, 255, 120),
      );
      canvas.drawCircle(
        Offset(fx, fy),
        2,
        _p..color = Color.fromARGB(a, 255, 255, 160),
      );
    }
  }

  void _renderStorm(Canvas canvas) {
    // heavy clouds
    for (final m in _peaks) {
      final cx = m[0] + m[1] * 0.5;
      final cy = 70 + (m[2] % 90);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: m[1] * 1.5, height: 80),
        _p..color = const Color(0xCC1E222B),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + 40, cy + 22),
          width: m[1] * 1.1,
          height: 60,
        ),
        _p..color = const Color(0xAA2D333F),
      );
    }
    // lightning flash
    final raw = sin(_t * 1.3) * sin(_t * 3.1 + 1);
    final flash = raw > 0.55 ? pow((raw - 0.55) / 0.45, 2).toDouble() : 0.0;
    if (flash > 0.02) {
      canvas.drawRect(
        const Rect.fromLTRB(
          -2000,
          -1500,
          3600,
          BattlefieldBackground._horizon + 40,
        ),
        _p..color = Color.fromARGB((flash * 120).round(), 235, 240, 255),
      );
      if (flash > 0.25) {
        final bx = 200.0 + ((_t * 0.5).floor() * 397) % 1200;
        final bolt = Path()
          ..moveTo(bx, 60)
          ..lineTo(bx - 30, 150)
          ..lineTo(bx + 4, 160)
          ..lineTo(bx - 46, 280)
          ..lineTo(bx - 8, 285)
          ..lineTo(bx - 40, 340);
        canvas.drawPath(
          bolt,
          _p
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5
            ..strokeJoin = StrokeJoin.round
            ..color = Color.fromARGB(
              (flash * 255).round().clamp(0, 255),
              255,
              255,
              255,
            ),
        );
        _p.style = PaintingStyle.fill;
      }
    }
    canvas.drawPath(_farHill, _p..color = const Color(0xFF3A463F));
    canvas.drawPath(_midHill, _p..color = const Color(0xFF2E3A34));
    // rain
    final rain = _p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = const Color(0x66C8D8F0);
    for (final st in _stars) {
      final y = (st.y * 2.3 + _t * 520) % 760;
      final x = (st.x - _t * 90) % 1700;
      canvas.drawLine(Offset(x, y), Offset(x - 7, y + 20), rain);
    }
    _p.style = PaintingStyle.fill;
  }
}

/// A few dark grass tufts drawn in front of the units at the bottom edge
/// (night theme only).
class ForegroundLayer extends Component {
  ForegroundLayer({required this.lowQuality, required int seed, this.theme = 0})
      : super(priority: 900) {
    final r = Random(seed + 21);
    final n = lowQuality ? 24 : 60;
    for (var i = 0; i < n; i++) {
      _tufts.add(Offset(r.nextDouble() * 1700 - 50, 700 + r.nextDouble() * 30));
    }
  }

  final bool lowQuality;
  final int theme;
  final List<Offset> _tufts = [];
  final Paint _p = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.6
    ..strokeCap = StrokeCap.round
    ..color = const Color(0xFF0B3A14);

  @override
  void render(Canvas canvas) {
    final m = theme.abs() % 6;
    if (m != 0 && m != 4) return;
    for (final t in _tufts) {
      canvas.drawLine(t, t.translate(-5, -16), _p);
      canvas.drawLine(t, t.translate(1, -20), _p);
      canvas.drawLine(t, t.translate(7, -14), _p);
    }
  }
}
