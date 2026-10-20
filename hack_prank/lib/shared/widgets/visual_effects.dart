import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Subtle CRT scanlines and a vignette. Static, so it never flickers.
class CrtOverlay extends StatelessWidget {
  const CrtOverlay({super.key, this.tint = AppColors.hackerGreen});

  final Color tint;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _CrtPainter(tint),
        ),
      ),
    );
  }
}

class _CrtPainter extends CustomPainter {
  _CrtPainter(this.tint);

  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..strokeWidth = 1;
    for (var y = 0.0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 1.05,
          colors: [
            tint.withValues(alpha: 0.03),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.55),
          ],
          stops: const [0, 0.6, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_CrtPainter oldDelegate) => oldDelegate.tint != tint;
}

/// Falling hexadecimal "code rain" with drifting particles, used as an ambient
/// background. Draws a single still frame when [animate] is false.
class CodeRainBackground extends StatefulWidget {
  const CodeRainBackground({
    super.key,
    this.animate = true,
    this.color = AppColors.hackerGreen,
    this.opacity = 0.35,
  });

  final bool animate;
  final Color color;
  final double opacity;

  @override
  State<CodeRainBackground> createState() => _CodeRainBackgroundState();
}

class _CodeRainBackgroundState extends State<CodeRainBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(CodeRainBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate) _sync();
  }

  void _sync() {
    if (widget.animate) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _CodeRainPainter(
            animation: _controller,
            color: widget.color,
            opacity: widget.opacity,
          ),
        ),
      ),
    );
  }
}

class _CodeRainPainter extends CustomPainter {
  _CodeRainPainter({
    required this.animation,
    required this.color,
    required this.opacity,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final Color color;
  final double opacity;

  static const _glyphs = '0123456789ABCDEF<>/\\#\$%';
  static const _cell = 18.0;
  static final Map<String, TextPainter> _cache = {};

  TextPainter _glyph(String ch, Color c) {
    final key = '$ch${c.toARGB32()}';
    return _cache.putIfAbsent(key, () {
      return TextPainter(
        text: TextSpan(
          text: ch,
          style: AppText.terminal(color: c, size: 14),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final t = animation.value;
    final columns = (size.width / _cell).ceil();
    final rows = (size.height / _cell).ceil();
    final head = color.withValues(alpha: opacity);
    final tail = color.withValues(alpha: opacity * 0.35);

    for (var col = 0; col < columns; col++) {
      final r = math.Random(col * 7919);
      final speed = 0.6 + r.nextDouble() * 1.4;
      final length = 6 + r.nextInt(10);
      final phase = r.nextDouble();
      final headRow =
          (((t * speed + phase) % 1.0) * (rows + length)).floor();
      for (var i = 0; i < length; i++) {
        final row = headRow - i;
        if (row < 0 || row >= rows) continue;
        final glyphIndex =
            (col * 31 + row * 17 + (t * 40).floor() * (i == 0 ? 3 : 1)) %
            _glyphs.length;
        final painter = _glyph(_glyphs[glyphIndex], i == 0 ? head : tail);
        painter.paint(canvas, Offset(col * _cell + 3, row * _cell));
      }
    }

    // Floating particles drifting upwards.
    final dot = Paint()..color = color.withValues(alpha: opacity * 0.8);
    final rng = math.Random(42);
    for (var i = 0; i < 26; i++) {
      final x = rng.nextDouble() * size.width;
      final speed = 0.3 + rng.nextDouble() * 0.7;
      final y = size.height * (1 - ((t * speed + rng.nextDouble()) % 1.0));
      canvas.drawCircle(
        Offset(x + math.sin((t * 6 + i) * math.pi) * 6, y),
        0.8 + rng.nextDouble() * 1.6,
        dot,
      );
    }
  }

  @override
  bool shouldRepaint(_CodeRainPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.opacity != opacity;
}

/// Text with a neon glow and an occasional, brief RGB-split glitch.
class GlitchText extends StatefulWidget {
  const GlitchText(
    this.text, {
    super.key,
    required this.style,
    this.enabled = true,
    this.textAlign = TextAlign.center,
  });

  final String text;
  final TextStyle style;
  final bool enabled;
  final TextAlign textAlign;

  @override
  State<GlitchText> createState() => _GlitchTextState();
}

class _GlitchTextState extends State<GlitchText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(GlitchText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) _sync();
  }

  void _sync() {
    if (widget.enabled) {
      _controller.repeat();
    } else {
      _controller
        ..stop()
        ..value = 0.3;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Text(
      widget.text,
      textAlign: widget.textAlign,
      style: widget.style,
    );
    if (!widget.enabled) return base;

    return AnimatedBuilder(
      animation: _controller,
      child: base,
      builder: (context, child) {
        final v = _controller.value;
        // Glitch only during two short windows per cycle (~6% of the time).
        final glitching = (v > 0.0 && v < 0.04) || (v > 0.52 && v < 0.545);
        if (!glitching) return child!;
        final jitter = math.sin(v * 900) * 3;
        return Stack(
          children: [
            Transform.translate(
              offset: Offset(-2 + jitter, 0),
              child: _tinted(AppColors.danger.withValues(alpha: 0.7)),
            ),
            Transform.translate(
              offset: Offset(2 - jitter, 0),
              child: _tinted(const Color(0xFF00E5FF).withValues(alpha: 0.6)),
            ),
            Transform.translate(offset: Offset(jitter / 2, 0), child: child),
          ],
        );
      },
    );
  }

  Widget _tinted(Color color) => ExcludeSemantics(
    child: Text(
      widget.text,
      textAlign: widget.textAlign,
      style: widget.style.copyWith(color: color, shadows: const []),
    ),
  );
}

/// Shakes its child briefly whenever [trigger] changes to a new value.
/// The motion is small (max 8px) and lasts about half a second.
class ControlledShake extends StatefulWidget {
  const ControlledShake({
    super.key,
    required this.trigger,
    required this.enabled,
    required this.child,
  });

  final Object? trigger;
  final bool enabled;
  final Widget child;

  @override
  State<ControlledShake> createState() => _ControlledShakeState();
}

class _ControlledShakeState extends State<ControlledShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  );

  @override
  void initState() {
    super.initState();
    if (widget.enabled && widget.trigger != null) _controller.forward();
  }

  @override
  void didUpdateWidget(ControlledShake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled &&
        widget.trigger != null &&
        widget.trigger != oldWidget.trigger) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value;
        if (t == 0 || t == 1) return child!;
        final dx = math.sin(t * math.pi * 10) * 8 * (1 - t);
        final dy = math.cos(t * math.pi * 8) * 3 * (1 - t);
        return Transform.translate(offset: Offset(dx, dy), child: child);
      },
    );
  }
}

/// A one-shot confetti burst. Runs once for [duration] and then stops.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({
    super.key,
    this.duration = const Duration(milliseconds: 3800),
    this.pieces = 110,
  });

  final Duration duration;
  final int pieces;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_controller, widget.pieces),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.animation, this.pieces) : super(repaint: animation);

  final Animation<double> animation;
  final int pieces;

  static const _colors = [
    AppColors.revealAccent,
    AppColors.hackerGreen,
    Color(0xFF4CC9F0),
    Color(0xFFFF6B9A),
    Color(0xFFB388FF),
    Colors.white,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    if (t <= 0 || t >= 1) return;
    final seconds = t * 3.8;
    final fade = t < 0.75 ? 1.0 : (1 - t) / 0.25;
    final rng = math.Random(7);
    final paint = Paint();
    for (var i = 0; i < pieces; i++) {
      final fromLeft = i.isEven;
      final x0 = fromLeft ? -10.0 : size.width + 10;
      final angle = (fromLeft ? -1 : 1) * (0.35 + rng.nextDouble() * 0.9);
      final speed = size.height * (0.55 + rng.nextDouble() * 0.6);
      final vx = math.sin(angle).abs() * speed * (fromLeft ? 1 : -1) * 0.7;
      final vy = -math.cos(angle) * speed;
      final gravity = size.height * 0.9;
      final x = x0 + vx * seconds + math.sin(seconds * 4 + i) * 12;
      final y = size.height * 0.75 + vy * seconds + 0.5 * gravity * seconds * seconds;
      if (y > size.height + 20) continue;
      final spin = seconds * (2 + rng.nextDouble() * 6) + i;
      paint.color = _colors[i % _colors.length].withValues(alpha: fade);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(spin);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: 7 + rng.nextDouble() * 5,
          height: 4 + math.cos(spin * 2).abs() * 6,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => false;
}

/// A soft light sweep across the screen (a safe stand-in for flashlight or
/// brightness effects: it never touches real device brightness).
class LightSweep extends StatefulWidget {
  const LightSweep({
    super.key,
    required this.trigger,
    required this.enabled,
    this.color = Colors.white,
  });

  final Object? trigger;
  final bool enabled;
  final Color color;

  @override
  State<LightSweep> createState() => _LightSweepState();
}

class _LightSweepState extends State<LightSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    if (widget.enabled && widget.trigger != null) _controller.forward();
  }

  @override
  void didUpdateWidget(LightSweep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled &&
        widget.trigger != null &&
        widget.trigger != oldWidget.trigger) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          if (t == 0 || t == 1) return const SizedBox.shrink();
          return CustomPaint(
            size: Size.infinite,
            painter: _SweepPainter(t, widget.color),
          );
        },
      ),
    );
  }
}

class _SweepPainter extends CustomPainter {
  _SweepPainter(this.t, this.color);

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final x = -size.width * 0.5 + t * size.width * 2;
    final rect = Rect.fromLTWH(x - size.width * 0.3, 0, size.width * 0.6, size.height);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            color.withValues(alpha: 0.12 * math.sin(t * math.pi)),
            Colors.transparent,
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_SweepPainter oldDelegate) => oldDelegate.t != t || oldDelegate.color != color;
}
