import 'package:flutter/material.dart';

import '../app/app_theme.dart';

/// Pulsing gold outline used by the tutorial to point at a control.
class PulseHighlight extends StatefulWidget {
  const PulseHighlight({
    super.key,
    required this.active,
    required this.child,
    this.radius = 14,
  });

  final bool active;
  final Widget child;
  final double radius;

  @override
  State<PulseHighlight> createState() => _PulseHighlightState();
}

class _PulseHighlightState extends State<PulseHighlight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(PulseHighlight old) {
    super.didUpdateWidget(old);
    if (widget.active && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.active && _c.isAnimating) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) => DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          border: Border.all(
            color: AppColors.gold.withAlpha((120 + 135 * _c.value).round()),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withAlpha((40 + 90 * _c.value).round()),
              blurRadius: 14,
              spreadRadius: 2,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
