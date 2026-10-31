import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../models/ability_model.dart';

class AbilityButton extends StatelessWidget {
  const AbilityButton({
    super.key,
    required this.model,
    required this.cooldownFraction,
    required this.remainingSeconds,
    required this.size,
    required this.enabled,
    required this.onTap,
  });

  final AbilityModel model;
  final double cooldownFraction;
  final double remainingSeconds;
  final double size;
  final bool enabled;
  final VoidCallback onTap;

  static IconData iconFor(String id) {
    switch (id) {
      case 'ember_burst':
        return Icons.local_fire_department_rounded;
      case 'royal_rally':
        return Icons.flag_rounded;
      case 'stone_ward':
        return Icons.security_rounded;
    }
    return Icons.auto_awesome_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final ready = cooldownFraction <= 0 && enabled;
    return Semantics(
      button: true,
      label: '${model.name}, ${ready ? 'ready' : 'cooling down'}',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: Ink(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.panel,
                  border: Border.all(
                    color: ready ? AppColors.gold : Colors.white24,
                    width: ready ? 3 : 1,
                  ),
                  boxShadow: ready
                      ? [
                          BoxShadow(
                            color: AppColors.ember.withAlpha(150),
                            blurRadius: 14,
                          ),
                        ]
                      : null,
                ),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onTap,
                  child: Icon(
                    iconFor(model.id),
                    size: size * 0.5,
                    color: ready ? AppColors.ember : AppColors.textDim,
                  ),
                ),
              ),
            ),
            if (cooldownFraction > 0) ...[
              IgnorePointer(
                child: SizedBox(
                  width: size - 4,
                  height: size - 4,
                  child: CircularProgressIndicator(
                    value: cooldownFraction,
                    strokeWidth: 5,
                    color: Colors.black54,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
              IgnorePointer(
                child: Text(
                  remainingSeconds.ceil().toString(),
                  style: TextStyle(
                    fontSize: size * 0.34,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
