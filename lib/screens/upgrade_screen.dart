import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../app/app_theme.dart';
import '../models/upgrade_model.dart';
import '../services/app_state.dart';
import '../services/audio_service.dart';
import '../widgets/game_button.dart';

class UpgradeScreen extends StatelessWidget {
  const UpgradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final categories = <String>[];
    for (final u in app.data.upgrades) {
      if (!categories.contains(u.category)) categories.add(u.category);
    }
    return GameScaffold(
      title: 'ARMY UPGRADES',
      actions: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xCC12142A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.monetization_on_rounded,
                color: AppColors.gold,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                '${app.save.coins}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          for (final cat in categories) ...[
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 8),
              child: Text(
                cat.toUpperCase(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: AppColors.gold,
                ),
              ),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final u in app.data.upgrades)
                  if (u.category == cat) _UpgradeCard(model: u),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _UpgradeCard extends StatelessWidget {
  const _UpgradeCard({required this.model});

  final UpgradeModel model;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final level = app.upgradeLevel(model.id);
    final maxed = level >= model.maxLevel;
    final cost = model.costFor(level);
    final canBuy = !maxed && app.save.coins >= cost;

    return Container(
      width: 300,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: canBuy ? AppColors.gold : Colors.white12,
          width: canBuy ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            model.name,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            model.description,
            style: const TextStyle(fontSize: 12, color: AppColors.textDim),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < model.maxLevel; i++)
                Container(
                  width: 22,
                  height: 8,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: i < level ? AppColors.ember : Colors.white12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              const Spacer(),
              Text(
                '$level/${model.maxLevel}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Now: ${level == 0 ? 'none' : model.describeEffect(level)}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            maxed
                ? 'Maximum level reached'
                : 'Next: ${model.describeEffect(level + 1)}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.good,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          GameButton(
            label: maxed ? 'Maxed' : 'Buy  $cost',
            icon: maxed ? Icons.check_rounded : Icons.monetization_on_rounded,
            primary: canBuy,
            width: double.infinity,
            onPressed: canBuy
                ? () {
                    final r = app.buyUpgrade(model.id);
                    if (r == PurchaseResult.ok) app.audio.playSfx(Sfx.recruit);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
