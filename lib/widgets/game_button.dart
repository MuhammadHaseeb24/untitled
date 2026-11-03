import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../app/app_theme.dart';
import '../services/audio_service.dart';

/// Large, high-contrast touch button (minimum 52 px tall).
class GameButton extends StatelessWidget {
  const GameButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.primary = false,
    this.danger = false,
    this.width,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool primary;
  final bool danger;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final colors = !enabled
        ? const [Color(0xFF3A3D50), Color(0xFF2C2F40)]
        : danger
            ? const [Color(0xFFE5483D), Color(0xFF9B1F18)]
            : primary
                ? const [AppColors.ember, AppColors.emberDeep]
                : const [AppColors.panelLight, AppColors.panel];
    final bottomColor = colors.last;
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: colors,
            ),
            border: Border.all(
              color: enabled
                  ? (primary ? const Color(0xFFF7E7A8) : Colors.white38)
                  : Colors.white10,
              width: primary ? 2.5 : 1.5,
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: Color.lerp(bottomColor, Colors.black, 0.55)!,
                      offset: const Offset(0, 5),
                    ),
                    const BoxShadow(
                      color: Color(0x88000000),
                      blurRadius: 10,
                      offset: Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: enabled
                ? () {
                    AppScope.read(context).audio.playSfx(Sfx.tap);
                    onPressed!();
                  }
                : null,
            child: Stack(
              children: [
                if (enabled)
                  Positioned(
                    left: 6,
                    right: 6,
                    top: 3,
                    height: 16,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x55FFFFFF), Color(0x00FFFFFF)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: 52,
                    minWidth: 52,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(
                            icon,
                            size: 22,
                            color: enabled ? AppColors.text : Colors.white38,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: enabled ? AppColors.text : Colors.white38,
                              shadows: enabled
                                  ? const [
                                      Shadow(
                                        color: Colors.black54,
                                        blurRadius: 2,
                                        offset: Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      ],
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

/// Screen scaffold with the ember backdrop, safe areas and a back button.
class GameScaffold extends StatelessWidget {
  const GameScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
  });

  final String title;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _Backdrop(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 12, 0),
                  child: Row(
                    children: [
                      IconButton(
                        iconSize: 28,
                        constraints: const BoxConstraints(
                          minWidth: 52,
                          minHeight: 52,
                        ),
                        icon: const Icon(Icons.arrow_back_rounded),
                        tooltip: 'Back',
                        onPressed: () {
                          AppScope.read(context).audio.playSfx(Sfx.tap);
                          Navigator.of(context).maybePop();
                        },
                      ),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      ...actions,
                    ],
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) => const EmberBackdropLite();
}

/// Static gradient (no animation) for secondary screens to save battery.
class EmberBackdropLite extends StatelessWidget {
  const EmberBackdropLite({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0E1020), Color(0xFF221730), Color(0xFF3A1A1E)],
        ),
      ),
    );
  }
}
