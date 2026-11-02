import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../game/battle_hud.dart';
import '../game/systems/level_system.dart';
import 'glossy.dart';

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
          color: const Color(0x66000000),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF2C14E), width: 1.6),
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
        return WoodPanel(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Semantics(
                button: true,
                label: 'Pause',
                child: GlossyCircle(
                  diameter: 48,
                  colors: const [
                    Color(0xFFFFF08A),
                    Color(0xFFF2C500),
                    Color(0xFFB88700),
                  ],
                  onTap: onPause,
                  child: const Icon(
                    Icons.pause_rounded,
                    size: 28,
                    color: Color(0xFF3A2A08),
                  ),
                ),
              ),
              const SizedBox(width: 10),
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
                color: const Color(0xFFBFD7FF),
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
                        label: 'YOUR STATUE',
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
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            levelName,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFFF3E1B5),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _HpBar(
                        fraction: ef,
                        color: const Color(0xFFE5231B),
                        label: 'ENEMY STATUE',
                        alignRight: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Semantics(
                button: true,
                label: 'Game speed',
                child: GlossyCircle(
                  diameter: 48,
                  colors: const [
                    Color(0xFF8FD0FF),
                    Color(0xFF3E82D6),
                    Color(0xFF1B4488),
                  ],
                  borderColor: Colors.white,
                  onTap: onToggleSpeed,
                  child: Text(
                    hud.speed >= 2 ? '2x' : '1x',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
