import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../game/systems/level_system.dart';
import '../models/battle_result.dart';
import '../models/level_model.dart';
import 'game_button.dart';
import 'glossy.dart';
import 'star_row.dart';

class BattleResultDialog extends StatelessWidget {
  const BattleResultDialog({
    super.key,
    required this.level,
    required this.result,
    required this.reward,
    required this.hasNextLevel,
    required this.onNext,
    required this.onRetry,
    required this.onMenu,
  });

  final LevelModel level;
  final BattleResult result;
  final RewardSummary? reward;
  final bool hasNextLevel;
  final VoidCallback onNext;
  final VoidCallback onRetry;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final victory = result.outcome == BattleOutcome.victory;
    final draw = result.outcome == BattleOutcome.draw;
    final title = victory ? 'VICTORY!' : (draw ? 'DRAW' : 'DEFEAT');
    final color = victory
        ? AppColors.gold
        : (draw ? AppColors.textDim : AppColors.bad);
    final hpOk = result.playerFortressFraction >= level.starFortressThreshold;
    final timeOk = result.timeSeconds <= level.parTimeSeconds;

    Widget criterion(bool done, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? Icons.star_rounded : Icons.star_border_rounded,
            size: 18,
            color: done ? AppColors.gold : Colors.white38,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: done ? AppColors.text : AppColors.textDim,
            ),
          ),
        ],
      ),
    );

    return ColoredBox(
      color: Colors.black.withAlpha(190),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(18),
            decoration: bevelPanel(border: color),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    color: color,
                  ),
                ),
                Text(
                  level.name,
                  style: const TextStyle(color: AppColors.textDim),
                ),
                const SizedBox(height: 10),
                if (victory) StarRow(stars: result.stars, size: 40),
                if (draw)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Both statues fell together. Retry to win.',
                      style: TextStyle(color: AppColors.textDim),
                    ),
                  ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 20,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    _stat(
                      Icons.timer_rounded,
                      ResultCalculator.formatTime(result.timeSeconds),
                    ),
                    _stat(
                      Icons.heart_broken_rounded,
                      '${result.unitsLost} lost',
                    ),
                    _stat(
                      Icons.whatshot_rounded,
                      '${result.unitsKilled} defeated',
                    ),
                    _stat(
                      Icons.castle_rounded,
                      '${(result.playerFortressFraction * 100).round()}% statue',
                    ),
                  ],
                ),
                if (victory) ...[
                  const SizedBox(height: 10),
                  criterion(true, 'Win the battle'),
                  criterion(
                    hpOk,
                    'Keep your statue above ${(level.starFortressThreshold * 100).round()}%',
                  ),
                  criterion(
                    timeOk,
                    'Finish within ${ResultCalculator.formatTime(level.parTimeSeconds)}',
                  ),
                  const SizedBox(height: 8),
                  if (reward != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.monetization_on_rounded,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          reward!.coinsAwarded > 0
                              ? '+${reward!.coinsAwarded} Ember Coins'
                              : 'No new coins (already earned)',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    if (victory && hasNextLevel)
                      GameButton(
                        label: 'Next Level',
                        icon: Icons.arrow_forward_rounded,
                        primary: true,
                        onPressed: reward == null ? null : onNext,
                      ),
                    GameButton(
                      label: 'Retry',
                      icon: Icons.replay_rounded,
                      primary: !victory,
                      onPressed: onRetry,
                    ),
                    GameButton(
                      label: 'Menu',
                      icon: Icons.home_rounded,
                      onPressed: onMenu,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 18, color: AppColors.textDim),
      const SizedBox(width: 5),
      Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
    ],
  );
}
