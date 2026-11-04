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

/// Horizontal list of all levels with chapter shortcuts. Uses a fixed item
/// extent so jumping to a chapter or to your current level is exact and the
/// list stays fast with 300+ levels.
class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  static const double _extent = 262;
  ScrollController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null) {
      final app = AppScope.read(context);
      final start = ((app.continueLevelId - 1) * _extent - 40)
          .clamp(0.0, double.infinity)
          .toDouble();
      _controller = ScrollController(initialScrollOffset: start);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _jumpTo(int index) {
    final c = _controller;
    if (c == null || !c.hasClients) return;
    final max = c.position.maxScrollExtent;
    c.animateTo(
      (index * _extent).clamp(0.0, max).toDouble(),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final levels = app.data.levels;

    // first index of every chapter
    final chapters = <String, int>{};
    for (var i = 0; i < levels.length; i++) {
      final name = levels[i].chapter.isEmpty ? 'Campaign' : levels[i].chapter;
      chapters.putIfAbsent(name, () => i);
    }

    return GameScaffold(
      title: 'LEVELS  (${app.save.completed.length}/${levels.length} cleared)',
      child: Column(
        children: [
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                for (final e in chapters.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      backgroundColor: AppColors.panelLight,
                      side: const BorderSide(color: Color(0xFF9B7A44)),
                      label: Text(
                        e.key,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.gold,
                        ),
                      ),
                      onPressed: () => _jumpTo(e.value),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 4, 16),
              itemExtent: _extent,
              itemCount: levels.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _LevelCard(level: levels[i]),
              ),
            ),
          ),
        ],
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

  static const _small = TextStyle(fontSize: 12, color: AppColors.text);

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final unlocked = app.isUnlocked(level.id);
    final record = app.recordFor(level.id);
    final dColor = _difficultyColor(level.difficulty);

    final star3 = level.isSurvival
        ? '3  Statue above ${(ResultCalculator.survivalTopHealth * 100).round()}%'
        : '3  Win within ${ResultCalculator.formatTime(level.parTimeSeconds)}';
    final star1 = level.isSurvival
        ? '1  Survive ${ResultCalculator.formatTime(level.surviveSeconds)}'
        : '1  Win the battle';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unlocked ? AppColors.gold.withAlpha(180) : Colors.white12,
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x88000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
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
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ember,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          level.name,
                          style: const TextStyle(
                            fontSize: 15,
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
                  if (level.tag.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      level.tag.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
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
                        UnitPortrait(unitId: id, team: Team.enemy, size: 32),
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
                  Text(star1, style: _small),
                  Text(
                    '2  Statue above ${(level.starFortressThreshold * 100).round()}%',
                    style: _small,
                  ),
                  Text(star3, style: _small),
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
    );
  }
}
