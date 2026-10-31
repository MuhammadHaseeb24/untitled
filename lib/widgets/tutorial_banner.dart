import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../models/level_model.dart';

class TutorialBanner extends StatelessWidget {
  const TutorialBanner({
    super.key,
    required this.step,
    required this.onNext,
    required this.onSkip,
  });

  final TutorialStep step;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        decoration: BoxDecoration(
          color: const Color(0xF0181B33),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gold, width: 2),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.tips_and_updates_rounded,
              color: AppColors.gold,
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                step.text,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (step.advance == 'tap')
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(72, 44),
                    ),
                    onPressed: onNext,
                    child: const Text('Next'),
                  ),
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(72, 40),
                    foregroundColor: AppColors.textDim,
                  ),
                  onPressed: onSkip,
                  child: const Text('Skip'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
