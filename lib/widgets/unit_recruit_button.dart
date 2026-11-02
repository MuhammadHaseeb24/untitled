import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../models/unit_model.dart';
import 'glossy.dart';
import 'unit_portrait.dart';

/// Round gold unit button with the price underneath and a badge showing how
/// many of that unit are being trained.
class UnitRecruitButton extends StatelessWidget {
  const UnitRecruitButton({
    super.key,
    required this.model,
    required this.gold,
    required this.size,
    required this.queued,
    required this.onTap,
  });

  final UnitModel model;
  final int gold;
  final double size;
  final int queued;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final affordable = gold >= model.cost;
    final d = size * 0.86;
    return Semantics(
      button: true,
      label:
          'Recruit ${model.name}, ${model.cost} gold${affordable ? '' : ', not enough gold'}',
      child: Opacity(
        opacity: affordable ? 1 : 0.55,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                GlossyCircle(
                  diameter: d,
                  colors: const [
                    Color(0xFFFFF08A),
                    Color(0xFFF2C500),
                    Color(0xFFB88700),
                  ],
                  borderColor: affordable
                      ? Colors.white
                      : const Color(0xFF8A6B3A),
                  borderWidth: affordable ? 3 : 2,
                  onTap: onTap,
                  child: UnitPortrait(unitId: model.id, size: d * 0.86),
                ),
                if (queued > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: d * 0.34,
                      height: d * 0.34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.gold, width: 1.5),
                      ),
                      child: Text(
                        '$queued',
                        style: TextStyle(
                          fontSize: d * 0.2,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Text(
              '${model.cost}',
              style: TextStyle(
                fontSize: size * 0.2,
                fontWeight: FontWeight.w900,
                color: AppColors.gold,
                shadows: const [Shadow(color: Colors.black, blurRadius: 3)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
