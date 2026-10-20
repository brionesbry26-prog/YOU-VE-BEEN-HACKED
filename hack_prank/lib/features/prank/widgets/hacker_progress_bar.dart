import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// A segmented neon progress bar with a label and percentage readout.
/// Values animate smoothly between controller ticks.
class HackerProgressBar extends StatelessWidget {
  const HackerProgressBar({
    super.key,
    required this.value,
    this.label,
    this.color = AppColors.hackerGreen,
    this.segments = 24,
    this.height = 14,
    this.showPercent = true,
  });

  final double value;
  final String? label;
  final Color color;
  final int segments;
  final double height;
  final bool showPercent;

  static String percentLabel(double value) =>
      '${(value.clamp(0.0, 1.0) * 100).round().toString().padLeft(3, '0')}%';

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return Semantics(
      label: label ?? 'Progress',
      value: '${(clamped * 100).round()} percent',
      child: ExcludeSemantics(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: clamped),
          duration: const Duration(milliseconds: 160),
          builder: (context, v, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (label != null || showPercent)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      if (label != null)
                        Expanded(
                          child: Text(
                            label!,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.terminal(color: color, size: 12),
                          ),
                        )
                      else
                        const Spacer(),
                      if (showPercent)
                        Text(
                          percentLabel(v),
                          style: AppText.terminal(color: color, size: 12),
                        ),
                    ],
                  ),
                ),
              SizedBox(
                height: height,
                child: CustomPaint(
                  painter: _SegmentsPainter(value: v, color: color, segments: segments),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SegmentsPainter extends CustomPainter {
  _SegmentsPainter({required this.value, required this.color, required this.segments});

  final double value;
  final Color color;
  final int segments;

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 3.0;
    final w = (size.width - gap * (segments - 1)) / segments;
    final filled = value * segments;
    final off = Paint()..color = color.withValues(alpha: 0.1);
    final glow = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    for (var i = 0; i < segments; i++) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(i * (w + gap), 0, w, size.height),
        const Radius.circular(2),
      );
      final amount = (filled - i).clamp(0.0, 1.0);
      canvas.drawRRect(rect, off);
      if (amount > 0) {
        canvas.drawRRect(rect, glow..color = color.withValues(alpha: 0.5 * amount));
        canvas.drawRRect(rect, Paint()..color = color.withValues(alpha: amount));
      }
    }
  }

  @override
  bool shouldRepaint(_SegmentsPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.color != color || oldDelegate.segments != segments;
}
