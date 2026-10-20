import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// A fictional network map: nodes light up one by one while a neon trace
/// line travels between them as [progress] goes 0 → 1. Purely decorative;
/// no network is touched.
class NetworkAnimation extends StatefulWidget {
  const NetworkAnimation({
    super.key,
    required this.progress,
    required this.hops,
    this.animate = true,
    this.color = AppColors.hackerGreen,
    this.height = 210,
  });

  final double progress;
  final List<String> hops;
  final bool animate;
  final Color color;
  final double height;

  /// Normalised node positions on the map.
  static const nodes = [
    Offset(0.08, 0.78),
    Offset(0.27, 0.32),
    Offset(0.45, 0.66),
    Offset(0.63, 0.22),
    Offset(0.80, 0.58),
    Offset(0.93, 0.18),
  ];

  /// How many nodes are lit at [progress].
  static int litNodes(double progress) =>
      (progress.clamp(0.0, 1.0) * nodes.length * 1.15).floor().clamp(0, nodes.length);

  @override
  State<NetworkAnimation> createState() => _NetworkAnimationState();
}

class _NetworkAnimationState extends State<NetworkAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(NetworkAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate) _sync();
  }

  void _sync() {
    if (widget.animate) {
      _pulse.repeat();
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
      label: 'Fictional network map',
      child: RepaintBoundary(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: widget.progress.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 160),
          builder: (context, progress, _) => CustomPaint(
            size: Size(double.infinity, widget.height),
            painter: _NetworkPainter(
              progress: progress,
              pulse: _pulse,
              hops: widget.hops,
              color: widget.color,
            ),
          ),
        ),
      ),
    );
  }
}

class _NetworkPainter extends CustomPainter {
  _NetworkPainter({
    required this.progress,
    required this.pulse,
    required this.hops,
    required this.color,
  }) : super(repaint: pulse);

  final double progress;
  final Animation<double> pulse;
  final List<String> hops;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = color.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 22) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += 22) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final points = [
      for (final n in NetworkAnimation.nodes)
        Offset(n.dx * size.width, n.dy * size.height),
    ];

    // Dim route.
    final route = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      route.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      route,
      Paint()
        ..color = color.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Neon trace drawn up to the current progress.
    final metrics = route.computeMetrics().toList();
    final total = metrics.fold<double>(0, (s, m) => s + m.length);
    var budget = total * progress;
    final traced = Path();
    Offset? head;
    for (final m in metrics) {
      if (budget <= 0) break;
      final len = math.min(budget, m.length);
      traced.addPath(m.extractPath(0, len), Offset.zero);
      head = m.getTangentForOffset(len)?.position;
      budget -= len;
    }
    canvas.drawPath(
      traced,
      Paint()
        ..color = color.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(
      traced,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );

    final lit = NetworkAnimation.litNodes(progress);
    final p = pulse.value;
    for (var i = 0; i < points.length; i++) {
      final on = i < lit;
      final c = on ? color : color.withValues(alpha: 0.25);
      if (on) {
        canvas.drawCircle(
          points[i],
          10 + 8 * p,
          Paint()..color = color.withValues(alpha: 0.35 * (1 - p)),
        );
      }
      canvas.drawCircle(points[i], 6, Paint()..color = AppColors.terminal);
      canvas.drawCircle(
        points[i],
        6,
        Paint()
          ..color = c
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      if (on) canvas.drawCircle(points[i], 3, Paint()..color = color);

      if (on && i < hops.length) {
        final tp = TextPainter(
          text: TextSpan(
            text: hops[i],
            style: AppText.terminal(color: color.withValues(alpha: 0.8), size: 9),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final dx = (points[i].dx - tp.width / 2).clamp(0.0, size.width - tp.width);
        final dy = points[i].dy + (points[i].dy > size.height * 0.6 ? -24 : 12);
        tp.paint(canvas, Offset(dx, dy));
        tp.dispose();
      }
    }

    final h = head;
    if (h != null && progress < 1) {
      canvas.drawCircle(
        h,
        5,
        Paint()
          ..color = Colors.white
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  @override
  bool shouldRepaint(_NetworkPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color || oldDelegate.hops != hops;
}
