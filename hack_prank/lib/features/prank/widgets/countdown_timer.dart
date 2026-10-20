import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// Large red mm:ss countdown. Each new second slides in with a quick
/// scale-and-fade (or switches instantly when [animate] is false).
class CountdownTimer extends StatelessWidget {
  const CountdownTimer({
    super.key,
    required this.remaining,
    this.animate = true,
    this.size = 64,
  });

  final Duration remaining;
  final bool animate;
  final double size;

  /// Formats [remaining] as mm:ss, rounding partial seconds up so the display
  /// only reaches 00:00 when time has actually run out.
  static String format(Duration remaining) {
    final ms = remaining.isNegative ? 0 : remaining.inMilliseconds;
    final seconds = (ms / 1000).ceil();
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final text = format(remaining);
    return Semantics(
      label: 'Time remaining $text',
      excludeSemantics: true,
      child: AnimatedSwitcher(
        duration: animate ? const Duration(milliseconds: 260) : Duration.zero,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 1.25, end: 1).animate(animation),
            child: child,
          ),
        ),
        child: Text(
          text,
          key: ValueKey(text),
          style: TextStyle(
            fontFamily: AppFonts.mono,
            fontFamilyFallback: AppFonts.monoFallback,
            fontSize: size,
            fontWeight: FontWeight.w700,
            color: AppColors.danger,
            letterSpacing: 4,
            shadows: AppText.glow(AppColors.danger),
          ),
        ),
      ),
    );
  }
}
