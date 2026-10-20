import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// A red warning banner whose border pulses slowly (well under three pulses
/// per second). With [flashing] off the border is solid.
class WarningBanner extends StatefulWidget {
  const WarningBanner({
    super.key,
    required this.text,
    this.flashing = true,
    this.color = AppColors.danger,
    this.icon = Icons.warning_amber_rounded,
  });

  final String text;
  final bool flashing;
  final Color color;
  final IconData icon;

  @override
  State<WarningBanner> createState() => _WarningBannerState();
}

class _WarningBannerState extends State<WarningBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(WarningBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.flashing != widget.flashing) _sync();
  }

  void _sync() {
    if (widget.flashing) {
      _pulse.repeat(reverse: true);
    } else {
      _pulse
        ..stop()
        ..value = 1;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    return Semantics(
      liveRegion: true,
      label: widget.text,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final p = Curves.easeInOut.transform(_pulse.value);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12 + 0.08 * p),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.45 + 0.55 * p), width: 2.5),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.25 + 0.35 * p), blurRadius: 12 + 18 * p),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: 0.9 + 0.2 * p,
                  child: Icon(widget.icon, color: color, size: 30),
                ),
                const SizedBox(width: 10),
                Flexible(child: child!),
                const SizedBox(width: 10),
                Transform.scale(
                  scale: 0.9 + 0.2 * p,
                  child: Icon(widget.icon, color: color, size: 30),
                ),
              ],
            ),
          );
        },
        child: Text(
          widget.text,
          textAlign: TextAlign.center,
          style: AppText.display(
            size: 24,
            color: AppColors.textPrimary,
            shadows: AppText.glow(color),
          ),
        ),
      ),
    );
  }
}
