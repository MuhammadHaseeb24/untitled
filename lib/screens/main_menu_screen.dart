import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../app/app_theme.dart';
import '../services/audio_service.dart';
import '../widgets/ember_backdrop.dart';
import '../widgets/game_button.dart';
import 'battle_screen.dart';
import 'credits_screen.dart';
import 'level_select_screen.dart';
import 'settings_screen.dart';
import 'upgrade_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.read(context).audio.playMusic(MusicTrack.menu);
    });
  }

  void _push(Widget screen) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final hasProgress = app.hasAnyProgress;
    return Scaffold(
      body: EmberBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ShaderMask(
                            shaderCallback: (r) => const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [AppColors.gold, AppColors.ember],
                            ).createShader(r),
                            child: const Icon(
                              Icons.local_fire_department_rounded,
                              size: 84,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'KINGDOMS',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 6,
                              color: AppColors.gold,
                            ),
                          ),
                          const Text(
                            'OF EMBER',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 10,
                              color: AppColors.ember,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _StatChip(
                            icon: Icons.flag_rounded,
                            text: 'Level ${app.save.highestUnlocked} unlocked',
                          ),
                          const SizedBox(height: 6),
                          _StatChip(
                            icon: Icons.monetization_on_rounded,
                            text: '${app.save.coins} Ember Coins',
                          ),
                          const SizedBox(height: 6),
                          _StatChip(
                            icon: Icons.star_rounded,
                            text:
                                '${app.totalStars} / ${app.data.levels.length * 3} stars',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 4,
                  child: Center(
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 340),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            GameButton(
                              label: 'Play Campaign',
                              icon: Icons.play_arrow_rounded,
                              primary: true,
                              onPressed: () => _push(
                                hasProgress
                                    ? const LevelSelectScreen()
                                    : const BattleScreen(levelId: 1),
                              ),
                            ),
                            const SizedBox(height: 10),
                            GameButton(
                              label: 'Continue',
                              icon: Icons.fast_forward_rounded,
                              onPressed: hasProgress
                                  ? () => _push(
                                      BattleScreen(
                                        levelId: app.continueLevelId,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 10),
                            GameButton(
                              label: 'Level Selection',
                              icon: Icons.map_rounded,
                              onPressed: () => _push(const LevelSelectScreen()),
                            ),
                            const SizedBox(height: 10),
                            GameButton(
                              label: 'Army Upgrades',
                              icon: Icons.upgrade_rounded,
                              onPressed: () => _push(const UpgradeScreen()),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: GameButton(
                                    label: 'Settings',
                                    icon: Icons.settings_rounded,
                                    onPressed: () =>
                                        _push(const SettingsScreen()),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: GameButton(
                                    label: 'Credits',
                                    icon: Icons.info_outline_rounded,
                                    onPressed: () =>
                                        _push(const CreditsScreen()),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
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

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0x8812142A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.gold),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
