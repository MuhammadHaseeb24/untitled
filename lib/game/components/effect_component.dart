import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

enum EffectKind { ring, burst, floatText }

class _Particle {
  _Particle(this.vx, this.vy, this.size);
  final double vx;
  double vy;
  final double size;
  double dx = 0;
  double dy = 0;
}

/// Short-lived visual effect (ring, particle burst, floating damage number).
class EffectComponent extends PositionComponent {
  EffectComponent._({
    required this.kind,
    required Vector2 at,
    required this.color,
    required this.duration,
    this.radius = 0,
    this.particles = const [],
    this.text,
  }) : super(position: at, priority: 500);

  factory EffectComponent.ring({
    required Vector2 at,
    required Color color,
    required double radius,
    double duration = 0.45,
  }) => EffectComponent._(
    kind: EffectKind.ring,
    at: at,
    color: color,
    duration: duration,
    radius: radius,
  );

  factory EffectComponent.burst({
    required Vector2 at,
    required Color color,
    required int count,
    required Random rng,
    double speed = 140,
    double duration = 0.6,
  }) {
    final list = <_Particle>[
      for (var i = 0; i < count; i++)
        _Particle(
          (rng.nextDouble() * 2 - 1) * speed,
          -(rng.nextDouble() * 0.9 + 0.2) * speed,
          2 + rng.nextDouble() * 2.5,
        ),
    ];
    return EffectComponent._(
      kind: EffectKind.burst,
      at: at,
      color: color,
      duration: duration,
      particles: list,
    );
  }

  factory EffectComponent.floatText({
    required Vector2 at,
    required String text,
    required Color color,
    double size = 18,
  }) {
    final e = EffectComponent._(
      kind: EffectKind.floatText,
      at: at,
      color: color,
      duration: 0.8,
      text: text,
    );
    e._painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w800,
          shadows: const [Shadow(color: Color(0xFF000000), blurRadius: 3)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return e;
  }

  final EffectKind kind;
  final Color color;
  final double duration;
  final double radius;
  final List<_Particle> particles;
  final String? text;
  TextPainter? _painter;
  double _age = 0;

  static final Paint _p = Paint();

  @override
  void update(double dt) {
    super.update(dt);
    if (dt <= 0) return;
    _age += dt;
    if (_age >= duration) {
      removeFromParent();
      return;
    }
    if (kind == EffectKind.floatText) {
      position.y -= 42 * dt;
    } else if (kind == EffectKind.burst) {
      for (final p in particles) {
        p.vy += 420 * dt;
        p.dx += p.vx * dt;
        p.dy += p.vy * dt;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final t = (_age / duration).clamp(0.0, 1.0);
    switch (kind) {
      case EffectKind.ring:
        final r = radius * t;
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: r * 2, height: r),
          _p
            ..style = PaintingStyle.stroke
            ..strokeWidth = (1 - t) * 6 + 1
            ..color = color.withAlpha(((1 - t) * 255).round()),
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: r * 2, height: r),
          _p
            ..style = PaintingStyle.fill
            ..color = color.withAlpha(((1 - t) * 70).round()),
        );
        break;
      case EffectKind.burst:
        _p
          ..style = PaintingStyle.fill
          ..color = color.withAlpha(((1 - t) * 255).round());
        for (final p in particles) {
          canvas.drawCircle(Offset(p.dx, p.dy), p.size * (1 - t * 0.5), _p);
        }
        break;
      case EffectKind.floatText:
        final tp = _painter;
        if (tp == null) return;
        canvas.saveLayer(
          Rect.fromLTWH(-tp.width, -tp.height, tp.width * 2, tp.height * 2),
          Paint()
            ..color = Color.fromARGB(
              ((1 - t * t) * 255).round().clamp(0, 255),
              255,
              255,
              255,
            ),
        );
        tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
        canvas.restore();
        break;
    }
  }
}
