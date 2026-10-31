import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import 'game_button.dart';

class PauseMenu extends StatelessWidget {
  const PauseMenu({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onMenu,
  });

  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onMenu;

  Future<void> _confirm(
    BuildContext context,
    String title,
    String body,
    VoidCallback action,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (ok == true) action();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withAlpha(170),
      child: Center(
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.gold, width: 2),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'PAUSED',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                GameButton(
                  label: 'Resume',
                  icon: Icons.play_arrow_rounded,
                  primary: true,
                  width: double.infinity,
                  onPressed: onResume,
                ),
                const SizedBox(height: 10),
                GameButton(
                  label: 'Restart',
                  icon: Icons.replay_rounded,
                  width: double.infinity,
                  onPressed: () => _confirm(
                    context,
                    'Restart level?',
                    'Your current battle progress will be lost.',
                    onRestart,
                  ),
                ),
                const SizedBox(height: 10),
                GameButton(
                  label: 'Main Menu',
                  icon: Icons.home_rounded,
                  width: double.infinity,
                  onPressed: () => _confirm(
                    context,
                    'Leave battle?',
                    'Your current battle progress will be lost.',
                    onMenu,
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
