import 'package:flutter/material.dart';

import '../game/game_types.dart';
import '../game/painters/unit_painter.dart';

/// Small static render of a unit using the same painter as the battlefield.
class UnitPortrait extends StatelessWidget {
  const UnitPortrait({
    super.key,
    required this.unitId,
    this.team = Team.player,
    this.size = 48,
  });

  final String unitId;
  final Team team;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _PortraitPainter(unitId, team)),
    );
  }
}

class _PortraitPainter extends CustomPainter {
  _PortraitPainter(this.unitId, this.team);

  final String unitId;
  final Team team;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.height / 105;
    canvas.save();
    canvas.translate(size.width / 2 - 4 * s, size.height - 4 * s);
    canvas.scale(s);
    final v = UnitVisual()
      ..unitId = unitId
      ..team = team;
    UnitPainter.paint(canvas, v);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PortraitPainter old) =>
      old.unitId != unitId || old.team != team;
}
