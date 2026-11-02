import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../game_config.dart';

/// A pile of gold ore. Miners dig from it until it is empty.
class MineComponent extends PositionComponent {
  MineComponent({required double x, required this.totalGold})
    : gold = totalGold,
      super(position: Vector2(x, GameConfig.groundY + 44), priority: 60);

  final int totalGold;
  int gold;

  /// Miners currently digging here (at most [maxMiners] at a time).
  int occupants = 0;
  static const int maxMiners = 2;

  bool get depleted => gold <= 0;
  bool get hasRoom => occupants < maxMiners;

  /// Takes up to [amount] gold from the pile and returns what was taken.
  int take(int amount) {
    final t = min(amount, gold);
    gold -= t;
    return t;
  }

  static final Paint _p = Paint();

  @override
  void render(Canvas canvas) {
    final f = (gold / totalGold).clamp(0.0, 1.0).toDouble();
    final s = 0.35 + 0.65 * f;
    canvas.save();
    canvas.scale(s, s);
    final rock = Path()
      ..moveTo(-34, 0)
      ..lineTo(-30, -16)
      ..lineTo(-12, -26)
      ..lineTo(14, -22)
      ..lineTo(32, -10)
      ..lineTo(34, 0)
      ..close();
    canvas.drawPath(rock, _p..color = const Color(0xFF8A8C92));
    canvas.drawPath(
      rock,
      _p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = const Color(0xFF3A3C41),
    );
    _p.style = PaintingStyle.fill;
    if (f > 0.02) {
      const crystals = [
        [-16.0, -22.0, 9.0],
        [0.0, -30.0, 12.0],
        [15.0, -20.0, 9.0],
        [-4.0, -14.0, 7.0],
        [-24.0, -10.0, 6.0],
      ];
      for (final c in crystals) {
        final cx = c[0], cy = c[1], h = c[2];
        final gem = Path()
          ..moveTo(cx - h * 0.45, cy)
          ..lineTo(cx - h * 0.1, cy - h)
          ..lineTo(cx + h * 0.45, cy - h * 0.2)
          ..lineTo(cx + h * 0.3, cy)
          ..close();
        canvas.drawPath(gem, _p..color = const Color(0xFFE9B72C));
        canvas.drawLine(
          Offset(cx - h * 0.1, cy - h),
          Offset(cx + h * 0.1, cy - 2),
          _p
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = const Color(0xFFFFF0A0),
        );
        _p.style = PaintingStyle.fill;
      }
    }
    canvas.restore();
  }
}
