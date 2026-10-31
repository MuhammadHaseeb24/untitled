import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../game/game_types.dart';

class CommandControls extends StatelessWidget {
  const CommandControls({
    super.key,
    required this.current,
    required this.size,
    required this.onSelect,
    required this.attackWrap,
    required this.defendWrap,
  });

  final Command current;
  final double size;
  final ValueChanged<Command> onSelect;

  /// Wrappers so the screen can add tutorial highlighting around each button.
  final Widget Function(Widget child) attackWrap;
  final Widget Function(Widget child) defendWrap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        defendWrap(
          _button(
            Command.defend,
            'DEFEND',
            Icons.shield_rounded,
            AppColors.blue,
          ),
        ),
        SizedBox(width: size * 0.12),
        attackWrap(
          _button(Command.attack, 'ATTACK', Icons.gavel_rounded, AppColors.bad),
        ),
      ],
    );
  }

  Widget _button(Command c, String label, IconData icon, Color color) {
    final selected = current == c;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label command${selected ? ', selected' : ''}',
      child: Material(
        color: Colors.transparent,
        child: Ink(
          width: size * 1.05,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: selected ? color : AppColors.panel,
            border: Border.all(
              color: selected ? AppColors.gold : Colors.white24,
              width: selected ? 3 : 1,
            ),
            boxShadow: selected
                ? [BoxShadow(color: color.withAlpha(140), blurRadius: 12)]
                : null,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onSelect(c),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: size * 0.42,
                  color: selected ? Colors.white : AppColors.textDim,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: size * 0.18,
                    fontWeight: FontWeight.w900,
                    color: selected ? Colors.white : AppColors.textDim,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
