import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../models/ability_model.dart';
import 'glossy.dart';

/// Round ability button with a cooldown ring. The Spear Volley uses a larger,
/// red variant ([big] = true) with its own label.
class AbilityButton extends StatelessWidget {
  const AbilityButton({
    super.key,
    required this.model,
    required this.cooldownFraction,
    required this.remainingSeconds,
    required this.size,
    required this.enabled,
    required this.onTap,
    this.big = false,
  });

  final AbilityModel model;
  final double cooldownFraction;
  final double remainingSeconds;
  final double size;
  final bool enabled;
  final VoidCallback onTap;
  final bool big;

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
    final isSpear = model.id == 'spear_volley';
    final colors = isSpear
        ? const [Color(0xFFFF9A8A), Color(0xFFD7322B), Color(0xFF7E1410)]
        : const [Color(0xFF4A4F7A), Color(0xFF262A4A), Color(0xFF14172B)];
    return Semantics(
      button: true,
      label: '${model.name}, ${ready ? 'ready' : 'cooling down'}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                GlossyCircle(
                  diameter: size,
                  colors: colors,
                  borderColor: ready ? AppColors.gold : Colors.white30,
                  borderWidth: ready ? 4 : 2,
                  glow: ready
                      ? (isSpear ? const Color(0xFFFF5A4A) : AppColors.ember)
                      : null,
                  onTap: onTap,
                  child: isSpear
                      ? SpearIcon(
                          size: size * 0.6,
                          color: ready ? Colors.white : Colors.white54,
                        )
                      : Icon(
                          iconFor(model.id),
                          size: size * 0.5,
                          color: ready ? AppColors.ember : AppColors.textDim,
                        ),
                ),
                if (cooldownFraction > 0) ...[
                  IgnorePointer(
                    child: SizedBox(
                      width: size - 4,
                      height: size - 4,
                      child: CircularProgressIndicator(
                        value: cooldownFraction,
                        strokeWidth: 6,
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
          if (big)
            Text(
              'SPEARS',
              style: TextStyle(
                fontSize: size * 0.18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                color: ready ? AppColors.gold : AppColors.textDim,
                shadows: const [Shadow(color: Colors.black, blurRadius: 3)],
              ),
            ),
        ],
      ),
    );
  }
}
