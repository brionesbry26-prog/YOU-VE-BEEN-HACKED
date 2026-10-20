import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// A terminal window that "types" its [lines] as [progress] goes 0 → 1.
///
/// The typed amount is derived from [progress] (driven by the prank
/// controller), so no extra timers are involved. With [typewriter] off, all
/// lines appear at once.
class TerminalPanel extends StatefulWidget {
  const TerminalPanel({
    super.key,
    required this.lines,
    required this.progress,
    this.title = 'root@simulation:~#',
    this.typewriter = true,
    this.blinkCursor = true,
    this.accent = AppColors.hackerGreen,
    this.textColor = AppColors.mutedTerminal,
    this.highContrast = false,
    this.largeText = false,
    this.typingPortion = 0.8,
    this.footer,
  });

  final List<String> lines;
  final double progress;
  final String title;
  final bool typewriter;
  final bool blinkCursor;
  final Color accent;
  final Color textColor;
  final bool highContrast;
  final bool largeText;

  /// Fraction of [progress] over which typing happens; the rest holds.
  final double typingPortion;
  final Widget? footer;

  /// Number of characters visible at [progress].
  static int visibleChars(
    List<String> lines,
    double progress, {
    double typingPortion = 0.8,
  }) {
    final total = lines.fold<int>(0, (sum, l) => sum + l.length);
    final typed = (progress / typingPortion).clamp(0.0, 1.0);
    return (typed * total).round();
  }

  @override
  State<TerminalPanel> createState() => _TerminalPanelState();
}

class _TerminalPanelState extends State<TerminalPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1060),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(TerminalPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.blinkCursor != widget.blinkCursor) _sync();
  }

  void _sync() {
    if (widget.blinkCursor) {
      _blink.repeat();
    } else {
      _blink
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = AppText.terminal(
      color: widget.textColor,
      large: widget.largeText,
      highContrast: widget.highContrast,
    );
    final budget = widget.typewriter
        ? TerminalPanel.visibleChars(
            widget.lines,
            widget.progress,
            typingPortion: widget.typingPortion,
          )
        : 1 << 30;

    final rows = <Widget>[];
    var remaining = budget;
    for (var i = 0; i < widget.lines.length && remaining > 0; i++) {
      final line = widget.lines[i];
      final shown = remaining >= line.length ? line : line.substring(0, remaining);
      remaining -= line.length;
      final isLast = remaining <= 0 || i == widget.lines.length - 1;
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '> ',
                  style: style.copyWith(color: widget.accent),
                ),
                TextSpan(text: shown),
                if (isLast)
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: _Cursor(animation: _blink, color: widget.accent, style: style),
                  ),
              ],
            ),
            style: style,
          ),
        ),
      );
    }
    if (rows.isEmpty) {
      rows.add(_Cursor(animation: _blink, color: widget.accent, style: style));
    }

    return Semantics(
      container: true,
      label: 'Simulated terminal output',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          color: AppColors.terminal.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: widget.accent.withValues(alpha: 0.7), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: widget.accent.withValues(alpha: 0.18),
              blurRadius: 24,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TitleBar(title: widget.title, accent: widget.accent),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...rows,
                  if (widget.footer != null) ...[
                    const SizedBox(height: 12),
                    widget.footer!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TitleBar extends StatelessWidget {
  const _TitleBar({required this.title, required this.accent});

  final String title;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
        border: Border(bottom: BorderSide(color: accent.withValues(alpha: 0.35))),
      ),
      child: Row(
        children: [
          for (final c in const [AppColors.danger, AppColors.warning, AppColors.hackerGreen])
            Container(
              width: 9,
              height: 9,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: AppText.terminal(color: accent, size: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _Cursor extends StatelessWidget {
  const _Cursor({required this.animation, required this.color, required this.style});

  final Animation<double> animation;
  final Color color;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) => Opacity(
          opacity: animation.value < 0.5 ? 1 : 0,
          child: Text('▋', style: style.copyWith(color: color)),
        ),
      ),
    );
  }
}
