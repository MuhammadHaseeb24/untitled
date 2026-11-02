import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../app/app_theme.dart';
import '../game/game_types.dart';
import '../game/systems/level_system.dart';
import '../models/level_model.dart';
import '../widgets/game_button.dart';
import '../widgets/star_row.dart';
import '../widgets/unit_portrait.dart';
import 'battle_screen.dart';

class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return GameScaffold(
      title: 'LEVEL SELECTION',
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: app.data.levels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) => _LevelCard(level: app.data.levels[i]),
      ),
    );
  }
}

Color _difficultyColor(Difficulty d) {
  switch (d) {
    case Difficulty.easy:
      return AppColors.good;
    case Difficulty.normal:
      return AppColors.gold;
    case Difficulty.hard:
      return AppColors.bad;
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.level});

  final LevelModel level;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final unlocked = app.isUnlocked(level.id);
    final record = app.recordFor(level.id);
    final dColor = _difficultyColor(level.difficulty);

    return SizedBox(
      width: 250,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unlocked ? AppColors.gold.withAlpha(180) : Colors.white12,
            width: 2,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${level.id}',
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ember,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            level.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (!unlocked)
                          const Icon(
                            Icons.lock_rounded,
                            color: AppColors.textDim,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      level.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textDim,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: dColor.withAlpha(50),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: dColor),
                          ),
                          child: Text(
                            level.difficulty.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: dColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        StarRow(stars: record?.stars ?? 0),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'ENEMY FORCES',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDim,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 2,
                      children: [
                        for (final id in level.enemyUnitIds)
                          UnitPortrait(unitId: id, team: Team.enemy, size: 34),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'STARS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDim,
                      ),
                    ),
                    Text('1  Win the battle', style: _small),
                    Text(
                      '2  Statue above ${(level.starFortressThreshold * 100).round()}%',
                      style: _small,
                    ),
                    Text(
                      '3  Win within ${ResultCalculator.formatTime(level.parTimeSeconds)}',
                      style: _small,
                    ),
                    if (record?.bestTime != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Best time ${ResultCalculator.formatTime(record!.bestTime!)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            GameButton(
              label: record == null ? 'Play' : 'Replay',
              icon: Icons.play_arrow_rounded,
              primary: true,
              width: double.infinity,
              onPressed: unlocked
                  ? () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => BattleScreen(levelId: level.id),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  static const _small = TextStyle(fontSize: 12, color: AppColors.text);
}
