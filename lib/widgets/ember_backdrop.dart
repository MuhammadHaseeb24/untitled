import 'dart:math';

import 'package:flutter/material.dart';

import '../app/app_theme.dart';

/// Dark gradient with drifting embers, used behind menus and the splash.
class EmberBackdrop extends StatefulWidget {
  const EmberBackdrop({super.key, this.child});

  final Widget? child;

  @override
  State<EmberBackdrop> createState() => _EmberBackdropState();
}

class _EmberBackdropState extends State<EmberBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0E1020), Color(0xFF2A1730), Color(0xFF5A2418)],
            ),
          ),
        ),
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) =>
                CustomPaint(painter: _EmberPainter(_c.value)),
          ),
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _EmberPainter extends CustomPainter {
  _EmberPainter(this.t);
  final double t;

  static final List<List<double>> _seeds = () {
    final r = Random(5);
    return List.generate(
      40,
      (_) => [
        r.nextDouble(),
        r.nextDouble(),
        0.4 + r.nextDouble(),
        r.nextDouble() * 6.28,
      ],
    );
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    for (final s in _seeds) {
      final y = (s[1] - t * s[2]) % 1.0;
      final x = s[0] + sin(t * 6.28 + s[3]) * 0.015;
      final flick = 0.5 + 0.5 * sin(t * 18 + s[3]);
      final pos = Offset(x * size.width, y * size.height);
      p.color = AppColors.ember.withAlpha((60 * flick + 20).round());
      canvas.drawCircle(pos, 5 * s[2], p);
      p.color = AppColors.gold.withAlpha(
        (200 * flick + 40).round().clamp(0, 255),
      );
      canvas.drawCircle(pos, 1.8 * s[2], p);
    }
  }

  @override
  bool shouldRepaint(_EmberPainter old) => old.t != t;
}
