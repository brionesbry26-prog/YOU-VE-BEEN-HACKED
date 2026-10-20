import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// A neon skull that glows in a slow pulse and can morph into a smiling face.
///
/// [smile] animates the morph (used on the reveal screen). With [animate]
/// false the skull is drawn statically (reduced motion).
class AnimatedSkull extends StatefulWidget {
  const AnimatedSkull({
    super.key,
    this.size = 180,
    this.smile = false,
    this.animate = true,
    this.color = AppColors.hackerGreen,
    this.morphDuration = const Duration(milliseconds: 1400),
  });

  final double size;
  final bool smile;
  final bool animate;
  final Color color;
  final Duration morphDuration;

  @override
  State<AnimatedSkull> createState() => _AnimatedSkullState();
}

class _AnimatedSkullState extends State<AnimatedSkull>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void initState() {
    super.initState();
    _syncPulse();
  }

  @override
  void didUpdateWidget(AnimatedSkull oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate) _syncPulse();
  }

  void _syncPulse() {
    if (widget.animate) {
      _pulse.repeat(reverse: true);
    } else {
      _pulse
        ..stop()
        ..value = 0.5;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: widget.smile ? 'Smiling face' : 'Glowing skull',
      child: RepaintBoundary(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: widget.smile ? 1.0 : 0.0),
          duration: widget.animate ? widget.morphDuration : Duration.zero,
          curve: Curves.easeInOutCubic,
          builder: (context, morph, _) => AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) => CustomPaint(
              size: Size.square(widget.size),
              painter: SkullPainter(
                morph: morph,
                glow: 0.55 + 0.45 * _pulse.value,
                color: widget.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the skull (morph 0) or smiley (morph 1) on a 200x200 grid.
class SkullPainter extends CustomPainter {
  SkullPainter({required this.morph, required this.glow, required this.color});

  final double morph;
  final double glow;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 200;
    canvas.save();
    canvas.translate(
      (size.width - 200 * s) / 2,
      (size.height - 200 * s) / 2,
    );
    canvas.scale(s);

    final m = morph.clamp(0.0, 1.0);
    final c = Color.lerp(color, AppColors.revealAccent, m)!;
    final skull = 1 - m;

    final glowPaint = Paint()
      ..color = c.withValues(alpha: 0.55 * glow)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    final line = Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = const Color(0xFF07110B);
    final solid = Paint()..color = c;

    // Head: a cranium over a jaw for the skull, a full circle for the smiley.
    final headCenter = Offset(100, 88 + 12 * m);
    final headRadius = 64 + 10 * m;
    final head = Path()
      ..addOval(Rect.fromCircle(center: headCenter, radius: headRadius));
    if (skull > 0) {
      final jawWidth = 64 * skull;
      final jaw = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: const Offset(100, 150),
          width: jawWidth,
          height: 44 * skull,
        ),
        const Radius.circular(10),
      );
      head.addRRect(jaw);
    }
    final outline = Path.combine(PathOperation.union, head, Path());
    canvas.drawPath(outline, glowPaint);
    canvas.drawPath(outline, fill);
    canvas.drawPath(outline, line);

    // Eye sockets fade out while happy eyes fade in.
    if (skull > 0.01) {
      final eyeGlow = Paint()
        ..color = c.withValues(alpha: skull * (0.5 + 0.5 * glow))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      final eye = Paint()..color = c.withValues(alpha: skull);
      for (final x in const [74.0, 126.0]) {
        final r = Rect.fromCenter(
          center: Offset(x, 92),
          width: 30 * skull + 4,
          height: 34 * skull + 4,
        );
        canvas.drawOval(r.inflate(3), eyeGlow);
        canvas.drawOval(r, eye);
        canvas.drawCircle(
          Offset(x, 94),
          4 * skull,
          Paint()..color = const Color(0xFF07110B).withValues(alpha: skull),
        );
      }
      // Nose.
      final nose = Path()
        ..moveTo(100, 108)
        ..lineTo(92, 124)
        ..lineTo(108, 124)
        ..close();
      canvas.drawPath(nose, Paint()..color = c.withValues(alpha: skull));
      // Teeth.
      final teeth = Paint()
        ..color = c.withValues(alpha: skull)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      for (var i = -2; i <= 2; i++) {
        final x = 100 + i * 11.0;
        canvas.drawLine(Offset(x, 140), Offset(x, 162), teeth);
      }
    }

    if (m > 0.01) {
      final happy = Paint()
        ..color = c.withValues(alpha: m)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;
      for (final x in const [74.0, 126.0]) {
        canvas.drawArc(
          Rect.fromCenter(center: Offset(x, 96), width: 30, height: 26),
          math.pi,
          math.pi,
          false,
          happy,
        );
      }
      canvas.drawArc(
        Rect.fromCenter(center: const Offset(100, 112), width: 86, height: 66),
        0.15,
        math.pi - 0.3,
        false,
        happy,
      );
      // Rosy cheeks.
      final cheek = Paint()
        ..color = const Color(0xFFFF6B9A).withValues(alpha: 0.35 * m)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(const Offset(58, 122), 9, cheek);
      canvas.drawCircle(const Offset(142, 122), 9, cheek);
    }

    // A single highlight so the neon reads as glass.
    canvas.drawArc(
      Rect.fromCircle(center: headCenter, radius: headRadius - 12),
      math.pi * 1.15,
      math.pi * 0.35,
      false,
      Paint()
        ..color = solid.color.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(SkullPainter oldDelegate) =>
      oldDelegate.morph != morph || oldDelegate.glow != glow || oldDelegate.color != color;
}
