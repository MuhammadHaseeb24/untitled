import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../game/battle_hud.dart';
import '../game/systems/level_system.dart';

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.color,
    required this.text,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String text;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label $text',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xCC12142A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 5),
            Text(
              text,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _HpBar extends StatelessWidget {
  const _HpBar({
    required this.fraction,
    required this.color,
    required this.label,
    required this.alignRight,
  });

  final double fraction;
  final Color color;
  final String label;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label ${(fraction * 100).round()} percent',
      child: Column(
        crossAxisAlignment: alignRight
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textDim,
            ),
          ),
          const SizedBox(height: 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: Color(0xCC000000)),
                  Align(
                    alignment: alignRight
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: fraction.clamp(0.0, 1.0),
                      child: ColoredBox(color: color),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BattleTopBar extends StatelessWidget {
  const BattleTopBar({
    super.key,
    required this.hud,
    required this.levelName,
    required this.onPause,
    required this.onToggleSpeed,
    required this.goldWrap,
  });

  final BattleHud hud;
  final String levelName;
  final VoidCallback onPause;
  final VoidCallback onToggleSpeed;
  final Widget Function(Widget child) goldWrap;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: hud,
      builder: (context, _) {
        final pf = hud.playerMaxHp <= 0 ? 0.0 : hud.playerHp / hud.playerMaxHp;
        final ef = hud.enemyMaxHp <= 0 ? 0.0 : hud.enemyHp / hud.enemyMaxHp;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xCC12142A),
                minimumSize: const Size(48, 48),
              ),
              tooltip: 'Pause',
              icon: const Icon(Icons.pause_rounded, size: 28),
              onPressed: onPause,
            ),
            const SizedBox(width: 8),
            goldWrap(
              _Chip(
                icon: Icons.monetization_on_rounded,
                color: AppColors.gold,
                text: '${hud.gold}',
                label: 'Gold',
              ),
            ),
            const SizedBox(width: 6),
            _Chip(
              icon: Icons.groups_rounded,
              color: AppColors.blue,
              text: '${hud.population}/${hud.populationMax}',
              label: 'Population',
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _HpBar(
                      fraction: pf,
                      color: AppColors.good,
                      label: 'YOUR FORTRESS',
                      alignRight: false,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ResultCalculator.formatTime(hud.elapsed),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          levelName,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textDim,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _HpBar(
                      fraction: ef,
                      color: AppColors.bad,
                      label: 'ENEMY FORTRESS',
                      alignRight: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xCC12142A),
                foregroundColor: AppColors.text,
                minimumSize: const Size(52, 48),
              ),
              onPressed: onToggleSpeed,
              child: Text(
                hud.speed >= 2 ? '2x' : '1x',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
