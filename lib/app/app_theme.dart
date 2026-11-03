import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const ember = Color(0xFFFF7A2B);
  static const emberDeep = Color(0xFFC2410C);
  static const gold = Color(0xFFF2C14E);
  static const night = Color(0xFF0E1020);
  static const panel = Color(0xFF1B1F36);
  static const panelLight = Color(0xFF2A2F4D);
  static const text = Color(0xFFF4EFE6);
  static const textDim = Color(0xFFB7B3C7);
  static const good = Color(0xFF58D26B);
  static const bad = Color(0xFFE5483D);
  static const blue = Color(0xFF3E80F0);
}

class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.ember,
      brightness: Brightness.dark,
    ).copyWith(
      surface: AppColors.panel,
      primary: AppColors.ember,
      secondary: AppColors.gold,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.night,
      textTheme: ThemeData.dark().textTheme.apply(
            bodyColor: AppColors.text,
            displayColor: AppColors.text,
          ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.ember,
        thumbColor: AppColors.gold,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected) ? AppColors.gold : Colors.grey,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.emberDeep
              : Colors.black38,
        ),
      ),
    );
  }
}
