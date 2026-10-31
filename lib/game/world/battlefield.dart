import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../game_config.dart';

class _Palette {
  const _Palette(
    this.skyTop,
    this.skyBottom,
    this.far,
    this.near,
    this.groundTop,
    this.groundBottom,
    this.glow,
  );
  final Color skyTop, skyBottom, far, near, groundTop, groundBottom, glow;
}

const List<_Palette> _palettes = [
  _Palette(
    Color(0xFF2B1B3D),
    Color(0xFFE0683A),
    Color(0xFF4A2E4F),
    Color(0xFF33243F),
    Color(0xFF5A4630),
    Color(0xFF2F2418),
    Color(0xFFFFC27A),
  ),
  _Palette(
    Color(0xFF28364F),
    Color(0xFF9FB4C8),
    Color(0xFF51647E),
    Color(0xFF3C4C63),
    Color(0xFF5B5F45),
    Color(0xFF2D3022),
    Color(0xFFFFF1C9),
  ),
  _Palette(
    Color(0xFF1F3B3F),
    Color(0xFF8CC4A0),
    Color(0xFF3F6A5E),
    Color(0xFF2B4F46),
    Color(0xFF55633A),
    Color(0xFF2A331C),
    Color(0xFFFFF0B0),
  ),
  _Palette(
    Color(0xFF23262F),
    Color(0xFF8A94A6),
    Color(0xFF454B5B),
    Color(0xFF30343F),
    Color(0xFF55555A),
    Color(0xFF2A2A2E),
    Color(0xFFE8ECF5),
  ),
  _Palette(
    Color(0xFF200F18),
    Color(0xFFC0392B),
    Color(0xFF4A1E2A),
    Color(0xFF331520),
    Color(0xFF5A3329),
    Color(0xFF2A1612),
    Color(0xFFFF8A5A),
  ),
];

class _Cloud {
  _Cloud(this.x, this.y, this.s, this.speed);
  double x;
  final double y, s, speed;
}

class _Ember {
  _Ember(this.x, this.y, this.vy, this.drift, this.size, this.phase);
  double x, y;
  final double vy, drift, size, phase;
}

Path _mountains(Random r, double baseY, double minH, double maxH, double step) {
  final p = Path()..moveTo(-300, baseY);
  var x = -300.0;
  while (x < 1900) {
    p.lineTo(x + step * 0.5, baseY - (minH + r.nextDouble() * (maxH - minH)));
    x += step;
    p.lineTo(x, baseY - minH * 0.35);
  }
  p
    ..lineTo(x, baseY)
    ..close();
  return p;
}

/// Layered sky, mountains, ruins, forests and ground. Drawn in virtual
/// coordinates and extended far beyond the world so letterboxing is seamless.
class BattlefieldBackground extends Component {
  BattlefieldBackground({required int theme, required this.lowQuality})
    : super(priority: 0) {
    palette = _palettes[theme.abs() % _palettes.length];
    final r = Random(theme * 7 + 3);
    _far = _mountains(r, GameConfig.groundY - 30, 120, 300, 200);
    _near = _mountains(r, GameConfig.groundY - 30, 60, 170, 150);
    skyPaint = Paint()
      ..shader = Gradient.linear(
        const Offset(0, 0),
        Offset(0, GameConfig.groundY),
        [palette.skyTop, palette.skyBottom],
      );
    groundPaint = Paint()
      ..shader = Gradient.linear(
        Offset(0, GameConfig.groundY - 34),
        const Offset(0, GameConfig.worldHeight),
        [palette.groundTop, palette.groundBottom],
      );
    for (var i = 0; i < 7; i++) {
      _clouds.add(
        _Cloud(
          r.nextDouble() * 1900 - 300,
          70 + r.nextDouble() * 170,
          0.7 + r.nextDouble() * 0.9,
          4 + r.nextDouble() * 8,
        ),
      );
    }
    for (var i = 0; i < 90; i++) {
      final x = r.nextDouble() * 1900 - 150;
      final y = GameConfig.groundY - 20 + r.nextDouble() * 190;
      _grain.add(Offset(x, y));
      _grain.add(Offset(x + 6 + r.nextDouble() * 14, y + r.nextDouble() * 2));
    }
    for (var i = 0; i < 26; i++) {
      _trees.add(
        Offset(-100 + i * 72 + r.nextDouble() * 30, 20 + r.nextDouble() * 30),
      );
    }
  }

  final bool lowQuality;
  late final _Palette palette;
  late final Paint skyPaint;
  late final Paint groundPaint;
  late final Path _far;
  late final Path _near;
  final List<_Cloud> _clouds = [];
  final List<Offset> _grain = [];
  final List<Offset> _trees = [];
  final Paint _p = Paint();

  @override
  void update(double dt) {
    super.update(dt);
    for (final c in _clouds) {
      c.x += c.speed * dt;
      if (c.x > 1900) c.x = -300;
    }
  }

  @override
  void render(Canvas canvas) {
    final gy = GameConfig.groundY;
    canvas.drawRect(Rect.fromLTRB(-2000, -1500, 3600, gy), skyPaint);

    // sun / moon with glow
    final sun = Offset(1180, 190);
    for (var i = 4; i >= 1; i--) {
      canvas.drawCircle(
        sun,
        34.0 + i * 22,
        _p..color = palette.glow.withAlpha(14 + (4 - i) * 6),
      );
    }
    canvas.drawCircle(sun, 34, _p..color = palette.glow);

    for (final c in _clouds) {
      final col = _white(40);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(c.x, c.y),
          width: 150 * c.s,
          height: 34 * c.s,
        ),
        _p..color = col,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(c.x + 40 * c.s, c.y - 12 * c.s),
          width: 100 * c.s,
          height: 30 * c.s,
        ),
        _p..color = col,
      );
    }

    canvas.drawPath(_far, _p..color = palette.far);
    // ruined towers
    final ruin = _p..color = Color.lerp(palette.far, palette.near, 0.6)!;
    for (final rx in [470.0, 820.0, 1130.0]) {
      final tower = Path()
        ..moveTo(rx - 22, gy - 28)
        ..lineTo(rx - 22, gy - 150)
        ..lineTo(rx - 10, gy - 140)
        ..lineTo(rx - 2, gy - 168)
        ..lineTo(rx + 8, gy - 146)
        ..lineTo(rx + 22, gy - 158)
        ..lineTo(rx + 22, gy - 28)
        ..close();
      canvas.drawPath(tower, ruin);
    }
    canvas.drawPath(_near, _p..color = palette.near);

    // distant forest
    final forest = _p
      ..color = Color.lerp(palette.near, const Color(0xFF000000), 0.25)!;
    for (final t in _trees) {
      final bx = t.dx;
      final by = gy - 30 + t.dy * 0.2;
      final path = Path()
        ..moveTo(bx - 13, by)
        ..lineTo(bx, by - 38 - t.dy)
        ..lineTo(bx + 13, by)
        ..close();
      canvas.drawPath(path, forest);
    }

    // ground
    canvas.drawRect(Rect.fromLTRB(-2000, gy - 34, 3600, 2200), groundPaint);
    canvas.drawRect(
      Rect.fromLTRB(-2000, gy - 34, 3600, gy - 28),
      _p..color = const Color(0x33FFFFFF),
    );
    final grain = _p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0x22000000);
    for (var i = 0; i + 1 < _grain.length; i += 2) {
      canvas.drawLine(_grain[i], _grain[i + 1], grain);
    }
    _p.style = PaintingStyle.fill;
  }

  static Color _white(int a) => Color.fromARGB(a, 255, 255, 255);
}

/// Rocks, grass and drifting embers drawn in front of the units.
class ForegroundLayer extends Component {
  ForegroundLayer({required this.lowQuality, required int seed})
    : super(priority: 900) {
    final r = Random(seed + 11);
    final count = lowQuality ? 10 : 28;
    for (var i = 0; i < count; i++) {
      _embers.add(
        _Ember(
          r.nextDouble() * 1600,
          r.nextDouble() * 720,
          14 + r.nextDouble() * 26,
          (r.nextDouble() - 0.5) * 20,
          1.5 + r.nextDouble() * 2.2,
          r.nextDouble() * 6,
        ),
      );
    }
    for (var i = 0; i < 9; i++) {
      final x = -60 + i * 215 + r.nextDouble() * 80;
      final w = 40 + r.nextDouble() * 60;
      final h = 18 + r.nextDouble() * 26;
      _rocks.add(
        Path()
          ..moveTo(x, 735)
          ..lineTo(x + w * 0.15, 735 - h)
          ..lineTo(x + w * 0.5, 735 - h * 1.25)
          ..lineTo(x + w * 0.85, 735 - h * 0.8)
          ..lineTo(x + w, 735)
          ..close(),
      );
    }
  }

  final bool lowQuality;
  final List<_Ember> _embers = [];
  final List<Path> _rocks = [];
  final Paint _p = Paint();
  double _t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    for (final e in _embers) {
      e.y -= e.vy * dt;
      e.x += e.drift * dt;
      if (e.y < -20) {
        e.y = 740;
        e.x = (e.x * 7.3) % 1600;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    for (final rock in _rocks) {
      canvas.drawPath(rock, _p..color = const Color(0xFF15121A));
    }
    for (final e in _embers) {
      final flick = 0.6 + 0.4 * sin(_t * 5 + e.phase);
      canvas.drawCircle(
        Offset(e.x, e.y),
        e.size * 2.2,
        _p..color = Color.fromARGB((50 * flick).round(), 255, 140, 40),
      );
      canvas.drawCircle(
        Offset(e.x, e.y),
        e.size,
        _p..color = Color.fromARGB((230 * flick).round(), 255, 190, 90),
      );
    }
  }
}
