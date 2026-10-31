import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../models/unit_model.dart';
import 'unit_portrait.dart';

class UnitRecruitButton extends StatelessWidget {
  const UnitRecruitButton({
    super.key,
    required this.model,
    required this.gold,
    required this.size,
    required this.onTap,
  });

  final UnitModel model;
  final int gold;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final affordable = gold >= model.cost;
    return Semantics(
      button: true,
      label:
          'Recruit ${model.name}, ${model.cost} gold${affordable ? '' : ', not enough gold'}',
      child: Opacity(
        opacity: affordable ? 1 : 0.5,
        child: Material(
          color: Colors.transparent,
          child: Ink(
            width: size,
            height: size * 1.12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.panelLight, AppColors.panel],
              ),
              border: Border.all(
                color: affordable ? AppColors.gold : Colors.white24,
                width: affordable ? 2 : 1,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: UnitPortrait(unitId: model.id, size: size * 0.7),
                    ),
                  ),
                  Container(
                    height: size * 0.28,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0x66000000),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.monetization_on_rounded,
                          size: size * 0.2,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${model.cost}',
                          style: TextStyle(
                            fontSize: size * 0.21,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
