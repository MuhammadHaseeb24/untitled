import 'dart:math';

import 'package:flutter/material.dart';

import '../app/app_theme.dart';

/// Round, beveled 3D-style button: radial gradient, thick rim, drop shadow
/// and a glossy highlight on top.
class GlossyCircle extends StatelessWidget {
  const GlossyCircle({
    super.key,
    required this.diameter,
    required this.colors,
    required this.child,
    this.onTap,
    this.borderColor = const Color(0xFFF7E7A8),
    this.borderWidth = 3,
    this.glow,
  });

  final double diameter;
  final List<Color> colors;
  final Widget child;
  final VoidCallback? onTap;
  final Color borderColor;
  final double borderWidth;
  final Color? glow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.45),
                  radius: 1.0,
                  colors: colors,
                ),
                border: Border.all(color: borderColor, width: borderWidth),
                boxShadow: [
                  const BoxShadow(
                    color: Color(0xAA000000),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                  if (glow != null)
                    BoxShadow(
                      color: glow!.withAlpha(170),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                ],
              ),
            ),
          ),
          Positioned.fill(child: Center(child: child)),
          // glossy highlight
          Positioned(
            top: diameter * 0.07,
            left: diameter * 0.17,
            width: diameter * 0.66,
            height: diameter * 0.40,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(diameter),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x80FFFFFF), Color(0x00FFFFFF)],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(customBorder: const CircleBorder(), onTap: onTap),
            ),
          ),
        ],
      ),
    );
  }
}

/// Wooden plank panel like the top bar of the reference game.
class WoodPanel extends StatelessWidget {
  const WoodPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(10, 6, 10, 8),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFC48A44), Color(0xFF9A6630), Color(0xFF7A4E22)],
        ),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFF2C14E), width: 3),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
        child: CustomPaint(
          painter: const _WoodGrainPainter(),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class _WoodGrainPainter extends CustomPainter {
  const _WoodGrainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0x22000000);
    for (var i = 0; i < 9; i++) {
      final y = size.height * (i + 0.5) / 9;
      final path = Path()..moveTo(0, y);
      for (double x = 0; x <= size.width; x += 24) {
        path.lineTo(x, y + sin(x / 38 + i * 1.7) * 3);
      }
      canvas.drawPath(path, p);
    }
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, 3),
      Paint()..color = const Color(0x44FFFFFF),
    );
  }

  @override
  bool shouldRepaint(_WoodGrainPainter old) => false;
}

/// Beveled dark panel used by dialogs.
BoxDecoration bevelPanel({Color border = AppColors.gold}) => BoxDecoration(
  borderRadius: BorderRadius.circular(20),
  gradient: const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF2B2F52), Color(0xFF181B33)],
  ),
  border: Border.all(color: border, width: 3),
  boxShadow: const [
    BoxShadow(color: Color(0xCC000000), blurRadius: 24, offset: Offset(0, 10)),
    BoxShadow(color: Color(0x33FFFFFF), blurRadius: 0, offset: Offset(0, -1)),
  ],
);

/// Three white spears crossing diagonally; the Spear Volley icon.
class SpearIcon extends StatelessWidget {
  const SpearIcon({super.key, required this.size, this.color = Colors.white});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _SpearIconPainter(color)),
  );
}

class _SpearIconPainter extends CustomPainter {
  _SpearIconPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final shaft = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s.width * 0.07
      ..color = color;
    final tip = Paint()..color = color;
    for (var i = 0; i < 3; i++) {
      final dx = (i - 1) * s.width * 0.26;
      final a = Offset(s.width * 0.12 + dx, s.height * 0.92);
      final b = Offset(s.width * 0.78 + dx, s.height * 0.16);
      canvas.drawLine(a, b, shaft);
      final dir = (b - a) / (b - a).distance;
      final n = Offset(-dir.dy, dir.dx);
      final head = Path()
        ..moveTo(b.dx + dir.dx * s.width * 0.14, b.dy + dir.dy * s.width * 0.14)
        ..lineTo(b.dx + n.dx * s.width * 0.08, b.dy + n.dy * s.width * 0.08)
        ..lineTo(b.dx - n.dx * s.width * 0.08, b.dy - n.dy * s.width * 0.08)
        ..close();
      canvas.drawPath(head, tip);
    }
  }

  @override
  bool shouldRepaint(_SpearIconPainter old) => old.color != color;
}
