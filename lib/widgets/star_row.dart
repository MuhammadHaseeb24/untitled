import 'package:flutter/material.dart';

import '../app/app_theme.dart';

class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.stars, this.size = 20});

  final int stars;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Icon(
            i < stars ? Icons.star_rounded : Icons.star_border_rounded,
            size: size,
            color: i < stars ? AppColors.gold : Colors.white30,
          ),
      ],
    );
  }
}
