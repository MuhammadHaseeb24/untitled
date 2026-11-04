import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../app/app_theme.dart';
import '../widgets/game_button.dart';
import 'credits_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmReset(BuildContext context) async {
    final app = AppScope.read(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset all progress?'),
        content: const Text(
          'This erases completed levels, stars, Ember Coins and upgrades. Settings are kept. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.bad),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await app.resetProgress();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Progress reset')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.settings;

    Widget slider(
      String label,
      double value,
      bool enabled,
      ValueChanged<double> onChanged,
    ) => Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          child: Slider(value: value, onChanged: enabled ? onChanged : null),
        ),
        SizedBox(
          width: 44,
          child: Text('${(value * 100).round()}%', textAlign: TextAlign.end),
        ),
      ],
    );

    return GameScaffold(
      title: 'SETTINGS',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              SwitchListTile(
                title: const Text('Music'),
                value: s.musicOn,
                onChanged: (v) => app.updateSettings(s.copyWith(musicOn: v)),
              ),
              SwitchListTile(
                title: const Text('Sound effects'),
                value: s.sfxOn,
                onChanged: (v) => app.updateSettings(s.copyWith(sfxOn: v)),
              ),
              slider(
                'Master volume',
                s.masterVolume,
                true,
                (v) => app.updateSettings(s.copyWith(masterVolume: v)),
              ),
              slider(
                'Music volume',
                s.musicVolume,
                s.musicOn,
                (v) => app.updateSettings(s.copyWith(musicVolume: v)),
              ),
              slider(
                'Effects volume',
                s.sfxVolume,
                s.sfxOn,
                (v) => app.updateSettings(s.copyWith(sfxVolume: v)),
              ),
              const Divider(height: 28),
              SwitchListTile(
                title: const Text('Low graphics quality'),
                subtitle: const Text(
                  'Fewer particles and effects for older phones. Applies to the next battle.',
                ),
                value: s.lowQuality,
                onChanged: (v) => app.updateSettings(s.copyWith(lowQuality: v)),
              ),
              const Divider(height: 28),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  GameButton(
                    label: 'Replay tutorials',
                    icon: Icons.school_rounded,
                    onPressed: () {
                      app.resetTutorials();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Tutorials will show again in their levels',
                          ),
                        ),
                      );
                    },
                  ),
                  GameButton(
                    label: 'Credits',
                    icon: Icons.info_outline_rounded,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CreditsScreen(),
                      ),
                    ),
                  ),
                  GameButton(
                    label: 'Reset progress',
                    icon: Icons.delete_forever_rounded,
                    danger: true,
                    onPressed: () => _confirmReset(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
