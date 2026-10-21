import 'package:flutter/material.dart';

import '../../core/constants/prank_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/effect_flags.dart';
import '../../shared/widgets/visual_effects.dart';
import '../prank/widgets/countdown_timer.dart';
import '../prank/widgets/hacker_progress_bar.dart';
import '../prank/widgets/stage_views.dart';

/// Stage 5 — the ransom-inspired countdown. Purely visual.
///
/// It asks for nothing, locks nothing, encrypts nothing and links nowhere.
/// The countdown is owned by the prank controller and always ends with the
/// awareness screen.
class RansomScreen extends StatelessWidget {
  const RansomScreen({
    super.key,
    required this.remaining,
    required this.progress,
    required this.expired,
    required this.fx,
  });

  final Duration remaining;

  /// Progress through the countdown, 0.0 to 1.0.
  final double progress;
  final bool expired;
  final EffectFlags fx;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PulsingIcon(
          icon: Icons.lock_outline_rounded,
          color: AppColors.danger,
          size: 72,
          animate: fx.motion,
        ),
        const SizedBox(height: 14),
        GlitchText(
          PrankConstants.compromisedStatus,
          enabled: fx.glitch,
          style: AppText.display(
            size: 30,
            color: AppColors.danger,
            shadows: AppText.glow(AppColors.danger),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          PrankConstants.simulationInProgress,
          textAlign: TextAlign.center,
          style: AppText.terminal(color: AppColors.warning, size: 16, weight: FontWeight.w700),
        ),
        const SizedBox(height: 22),
        _CountdownCard(
          pulse: fx.flashing,
          child: Column(
            children: [
              Text(
                'TIME REMAINING:',
                style: AppText.terminal(color: AppColors.textPrimary, size: 15),
              ),
              const SizedBox(height: 4),
              CountdownTimer(remaining: remaining, animate: fx.motion),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _LockGrid(progress: progress),
        if (expired) ...[
          const SizedBox(height: 18),
          Text(
            'FINALIZING...',
            textAlign: TextAlign.center,
            style: AppText.terminal(color: AppColors.textSecondary, size: 15),
          ),
        ],
      ],
    );
  }
}

class _CountdownCard extends StatefulWidget {
  const _CountdownCard({required this.child, required this.pulse});

  final Widget child;
  final bool pulse;

  @override
  State<_CountdownCard> createState() => _CountdownCardState();
}

class _CountdownCardState extends State<_CountdownCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    if (widget.pulse) {
      _c.repeat(reverse: true);
    } else {
      _c.value = 0.6;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final v = Curves.easeInOut.transform(_c.value);
        return Transform.scale(
          scale: 1 + 0.015 * v,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF2A0008),
                  AppColors.danger.withValues(alpha: 0.18 + 0.1 * v),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.danger.withValues(alpha: 0.6 + 0.4 * v), width: 2),
              boxShadow: [
                BoxShadow(color: AppColors.danger.withValues(alpha: 0.2 + 0.3 * v), blurRadius: 20 + 16 * v),
              ],
            ),
            child: child,
          ),
        );
      },
    );
  }
}

/// File tiles that turn into padlocks as the countdown runs (decoration only).
class _LockGrid extends StatelessWidget {
  const _LockGrid({required this.progress});

  final double progress;

  static const _icons = [
    Icons.image_outlined,
    Icons.description_outlined,
    Icons.music_note_outlined,
    Icons.contacts_outlined,
    Icons.movie_outlined,
    Icons.chat_bubble_outline,
    Icons.folder_outlined,
    Icons.picture_as_pdf_outlined,
    Icons.photo_library_outlined,
    Icons.mail_outline,
  ];

  @override
  Widget build(BuildContext context) {
    final locked = (progress * _icons.length).ceil();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < _icons.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: i < locked
                      ? AppColors.danger.withValues(alpha: 0.18)
                      : AppColors.terminal,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: i < locked ? AppColors.danger : AppColors.textSecondary.withValues(alpha: 0.4),
                  ),
                ),
                child: Icon(
                  i < locked ? Icons.lock_rounded : _icons[i],
                  size: 20,
                  color: i < locked ? AppColors.danger : AppColors.textSecondary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        HackerProgressBar(value: progress, label: 'ACCESS LOCK', color: AppColors.danger),
      ],
    );
  }
}
