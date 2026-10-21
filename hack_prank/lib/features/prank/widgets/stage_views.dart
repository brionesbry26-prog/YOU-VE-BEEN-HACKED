import 'package:flutter/material.dart';

import '../../../core/constants/prank_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/effect_flags.dart';
import '../../../shared/widgets/visual_effects.dart';
import '../prank_controller.dart';
import '../prank_stage.dart';
import 'hacker_progress_bar.dart';
import 'network_animation.dart';
import 'simulated_file_list.dart';
import 'terminal_panel.dart';
import 'warning_banner.dart';

/// Picks the view for the controller's current breach stage (1-4). The
/// countdown (stage 5) is the separate `RansomScreen`.
class StageView extends StatelessWidget {
  const StageView({super.key, required this.controller, required this.fx});

  final PrankController controller;
  final EffectFlags fx;

  @override
  Widget build(BuildContext context) {
    final p = controller.stageProgress;
    return switch (controller.stage) {
      PrankStage.activity => _ActivityView(controller: controller, progress: p, fx: fx),
      PrankStage.warning => _WarningView(progress: p, fx: fx),
      PrankStage.extracting => _ExtractingView(progress: p, fx: fx),
      _ => _InitializingView(controller: controller, progress: p, fx: fx),
    };
  }
}

/// Stage 1 — initialization.
class _InitializingView extends StatelessWidget {
  const _InitializingView({required this.controller, required this.progress, required this.fx});

  final PrankController controller;
  final double progress;
  final EffectFlags fx;

  @override
  Widget build(BuildContext context) {
    final hex = controller.session.hexLines(4);
    final hexVisible = (progress * (hex.length + 1)).floor().clamp(0, hex.length);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatusRow(
          label: progress < 0.85 ? 'SESSION: NEGOTIATING' : 'SESSION: ESTABLISHED',
          color: AppColors.hackerGreen,
          pulse: fx.motion,
        ),
        const SizedBox(height: 14),
        TerminalPanel(
          lines: PrankConstants.initializingLines,
          progress: progress,
          typewriter: fx.typewriter,
          blinkCursor: fx.motion,
          highContrast: fx.highContrast,
          largeText: fx.largeText,
          footer: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final line in hex.take(hexVisible)) _HexLine(line, large: fx.largeText),
              const SizedBox(height: 12),
              HackerProgressBar(value: progress, label: 'SCANNING ENVIRONMENT'),
            ],
          ),
        ),
      ],
    );
  }
}

/// Stage 2 — simulated remote activity.
class _ActivityView extends StatelessWidget {
  const _ActivityView({required this.controller, required this.progress, required this.fx});

  final PrankController controller;
  final double progress;
  final EffectFlags fx;

  @override
  Widget build(BuildContext context) {
    final hex = controller.session.hexLines(2, length: 28);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TerminalPanel(
          lines: PrankConstants.activityLines,
          progress: progress,
          typingPortion: 0.6,
          typewriter: fx.typewriter,
          blinkCursor: fx.motion,
          highContrast: fx.highContrast,
          largeText: fx.largeText,
          footer: HackerProgressBar(
            // Climbs to the 47% the terminal reports.
            value: 0.47 * Curves.easeOut.transform(progress),
            label: 'DATA TRANSFER',
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.terminal,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.hackerGreen.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NetworkAnimation(
                progress: progress,
                hops: controller.session.routeHops,
                animate: fx.motion,
                height: 170,
              ),
              const SizedBox(height: 6),
              Text(
                'REMOTE NODE: ${controller.session.remoteAddress}',
                textAlign: TextAlign.center,
                style: AppText.terminal(color: AppColors.hackerGreen, size: 13, large: fx.largeText),
              ),
              for (final line in hex) _HexLine(line, large: fx.largeText),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.terminal.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.hackerGreen.withValues(alpha: 0.3)),
          ),
          child: SimulatedFileList(
            files: PrankConstants.simulatedSystemFiles,
            progress: progress,
            counterLabel: 'SYSTEM FILES ANALYZED',
            largeText: fx.largeText,
            highContrast: fx.highContrast,
          ),
        ),
      ],
    );
  }
}

/// Stage 3 — the dramatic warning.
class _WarningView extends StatelessWidget {
  const _WarningView({required this.progress, required this.fx});

  final double progress;
  final EffectFlags fx;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PulsingIcon(icon: Icons.gpp_bad_outlined, color: AppColors.danger, animate: fx.motion),
        const SizedBox(height: 16),
        WarningBanner(
          text: PrankConstants.alertTitle,
          subtitle: PrankConstants.alertSubtitle,
          flashing: fx.flashing,
          glitch: fx.glitch,
        ),
        const SizedBox(height: 18),
        TerminalPanel(
          lines: const [
            'INTRUSION SIGNATURE MATCHED',
            'FIREWALL STATUS: BYPASSED',
            'SECURITY LAYERS DISABLED: 3/3',
          ],
          progress: progress,
          typingPortion: 0.7,
          accent: AppColors.danger,
          textColor: const Color(0xFFFF8A9B),
          typewriter: fx.typewriter,
          blinkCursor: fx.motion,
          highContrast: fx.highContrast,
          largeText: fx.largeText,
        ),
      ],
    );
  }
}

/// Stage 4 — fictional file extraction. The file list is a constant; the
/// device's storage is never read.
class _ExtractingView extends StatelessWidget {
  const _ExtractingView({required this.progress, required this.fx});

  final double progress;
  final EffectFlags fx;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlitchText(
          'EXTRACTING DATA',
          enabled: fx.glitch,
          style: AppText.display(
            size: 28,
            color: AppColors.danger,
            letterSpacing: 3,
            shadows: AppText.glow(AppColors.danger, strength: 0.6),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.terminal.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.danger.withValues(alpha: 0.6)),
          ),
          child: SimulatedFileList(
            progress: progress,
            largeText: fx.largeText,
            highContrast: fx.highContrast,
          ),
        ),
        const SizedBox(height: 16),
        HackerProgressBar(
          value: progress,
          label: 'UPLOADING TO REMOTE HOST',
          color: AppColors.warning,
        ),
      ],
    );
  }
}

class _HexLine extends StatelessWidget {
  const _HexLine(this.line, {required this.large});

  final String line;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Text(
      '0x$line',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppText.terminal(
        color: AppColors.secondaryGreen.withValues(alpha: 0.7),
        size: 11,
        large: large,
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.color, required this.pulse});

  final String label;
  final Color color;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PulsingIcon(icon: Icons.circle, color: color, size: 12, animate: pulse),
        const SizedBox(width: 8),
        Flexible(
          child: Text(label, style: AppText.terminal(color: color, size: 13)),
        ),
      ],
    );
  }
}

/// An icon that gently scales and glows. Static when [animate] is false.
class PulsingIcon extends StatefulWidget {
  const PulsingIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 64,
    this.animate = true,
  });

  final IconData icon;
  final Color color;
  final double size;
  final bool animate;

  @override
  State<PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<PulsingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _c.repeat(reverse: true);
    } else {
      _c.value = 1;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final v = Curves.easeInOut.transform(_c.value);
          return Transform.scale(
            scale: 0.9 + 0.15 * v,
            child: Icon(
              widget.icon,
              size: widget.size,
              color: widget.color,
              shadows: [
                Shadow(color: widget.color.withValues(alpha: 0.4 + 0.5 * v), blurRadius: 10 + 14 * v),
              ],
            ),
          );
        },
      ),
    );
  }
}
