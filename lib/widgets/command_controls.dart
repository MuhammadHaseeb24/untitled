import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../game/game_types.dart';
import 'glossy.dart';

/// Garrison / Defend / Attack buttons. The selected command is highlighted.
class CommandControls extends StatelessWidget {
  const CommandControls({
    super.key,
    required this.current,
    required this.size,
    required this.onSelect,
    required this.garrisonWrap,
    required this.attackWrap,
    required this.defendWrap,
  });

  final Command current;
  final double size;
  final ValueChanged<Command> onSelect;

  /// Wrappers so the screen can add tutorial highlighting around each button.
  final Widget Function(Widget child) garrisonWrap;
  final Widget Function(Widget child) attackWrap;
  final Widget Function(Widget child) defendWrap;

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox(width: size * 0.1);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        garrisonWrap(
          _button(
            Command.garrison,
            'GARRISON',
            Icons.castle_rounded,
            const Color(0xFFE0584F),
          ),
        ),
        gap,
        defendWrap(
          _button(
            Command.defend,
            'DEFEND',
            Icons.shield_rounded,
            const Color(0xFFF2C14E),
          ),
        ),
        gap,
        attackWrap(
          _button(
            Command.attack,
            'ATTACK',
            Icons.gavel_rounded,
            const Color(0xFF47B85A),
          ),
        ),
      ],
    );
  }

  Widget _button(Command c, String label, IconData icon, Color color) {
    final selected = current == c;
    final d = size * 0.9;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label command${selected ? ', selected' : ''}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlossyCircle(
            diameter: d,
            colors: selected
                ? [Colors.white, color, Color.lerp(color, Colors.black, 0.35)!]
                : const [
                    Color(0xFF6B5638),
                    Color(0xFF3A2D1C),
                    Color(0xFF241B10),
                  ],
            borderColor: selected ? AppColors.gold : const Color(0xFF9B7A44),
            borderWidth: selected ? 4 : 2.5,
            glow: selected ? color : null,
            onTap: () => onSelect(c),
            child: Icon(
              icon,
              size: d * 0.5,
              color: selected ? Colors.black87 : AppColors.textDim,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: size * 0.15,
              fontWeight: FontWeight.w900,
              color: selected ? AppColors.gold : AppColors.textDim,
              shadows: const [Shadow(color: Colors.black, blurRadius: 3)],
            ),
          ),
        ],
      ),
    );
  }
}
