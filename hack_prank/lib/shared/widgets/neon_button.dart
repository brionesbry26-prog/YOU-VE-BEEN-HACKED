import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

enum NeonButtonStyle { primary, secondary, danger, gold }

/// A glowing call-to-action with press-down scale feedback.
class NeonButton extends StatefulWidget {
  const NeonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.style = NeonButtonStyle.primary,
    this.expand = true,
    this.large = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final NeonButtonStyle style;
  final bool expand;
  final bool large;

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> {
  bool _pressed = false;

  Color get _accent => switch (widget.style) {
    NeonButtonStyle.primary || NeonButtonStyle.secondary => AppColors.hackerGreen,
    NeonButtonStyle.danger => AppColors.danger,
    NeonButtonStyle.gold => AppColors.revealAccent,
  };

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent;
    final filled = widget.style != NeonButtonStyle.secondary;
    final enabled = widget.onPressed != null;
    final foreground = filled ? AppColors.background : accent;

    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, color: foreground, size: widget.large ? 26 : 22),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: AppText.display(
              size: widget.large ? 24 : 19,
              color: foreground,
              letterSpacing: 2,
            ),
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      onTap: widget.onPressed,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: enabled ? (_) => _setPressed(true) : null,
        onTapUp: enabled ? (_) => _setPressed(false) : null,
        onTapCancel: () => _setPressed(false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: enabled ? 1 : 0.45,
            duration: const Duration(milliseconds: 200),
            child: Container(
              constraints: BoxConstraints(minHeight: widget.large ? 64 : 54),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                color: filled ? accent : accent.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accent, width: 1.6),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: _pressed ? 0.75 : 0.4),
                    blurRadius: _pressed ? 28 : 18,
                    spreadRadius: _pressed ? 2 : 0,
                  ),
                ],
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
