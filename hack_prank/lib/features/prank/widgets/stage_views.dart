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

/// Picks the view for the controller's current breach stage.
class StageView extends StatelessWidget {
  const StageView({super.key, required this.controller, required this.fx});

  final PrankController controller;
  final EffectFlags fx;

  @override
  Widget build(BuildContext context) {
    final p = controller.stageProgress;
    return switch (controller.stage) {
      PrankStage.tracing => _TracingView(controller: controller, progress: p, fx: fx),
      PrankStage.warning => _WarningView(progress: p, fx: fx),
      PrankStage.extracting => _ExtractingView(progress: p, fx: fx),
      PrankStage.simulatedTracking => _TrackingView(progress: p, fx: fx),
      PrankStage.breachComplete => _BreachCompleteView(progress: p, fx: fx),
      _ => _InitializingView(controller: controller, progress: p, fx: fx),
    };
  }
}

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
          label: progress < 0.85 ? 'CONNECTION: NEGOTIATING' : 'CONNECTION: ESTABLISHED',
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
              for (final line in hex.take(hexVisible))
                Text(
                  '0x$line',
                  overflow: TextOverflow.ellipsis,
                  style: AppText.terminal(
                    color: AppColors.secondaryGreen.withValues(alpha: 0.7),
                    size: 11,
                    large: fx.largeText,
                  ),
                ),
              const SizedBox(height: 12),
              HackerProgressBar(value: progress, label: 'SCANNING TARGET SYSTEM'),
            ],
          ),
        ),
      ],
    );
  }
}

class _TracingView extends StatelessWidget {
  const _TracingView({required this.controller, required this.progress, required this.fx});

  final PrankController controller;
  final double progress;
  final EffectFlags fx;

  @override
  Widget build(BuildContext context) {
    final found = progress > 0.62;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TerminalPanel(
          lines: PrankConstants.tracingLines,
          progress: progress,
          typingPortion: 0.65,
          typewriter: fx.typewriter,
          blinkCursor: fx.motion,
          highContrast: fx.highContrast,
          largeText: fx.largeText,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.terminal,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.hackerGreen.withValues(alpha: 0.4)),
          ),
          child: NetworkAnimation(
            progress: progress,
            hops: controller.session.routeHops,
            animate: fx.motion,
          ),
        ),
        const SizedBox(height: 14),
        AnimatedOpacity(
          opacity: found ? 1 : 0.25,
          duration: const Duration(milliseconds: 400),
          child: Text(
            'SIMULATED TRACE: ${found ? controller.session.traceAddress : '···.···.···.···'}',
            textAlign: TextAlign.center,
            style: AppText.terminal(
              color: AppColors.hackerGreen,
              size: 18,
              large: fx.largeText,
              weight: FontWeight.w700,
            ).copyWith(shadows: AppText.glow(AppColors.hackerGreen, strength: 0.6)),
          ),
        ),
      ],
    );
  }
}

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
        WarningBanner(text: PrankConstants.breachBanner, flashing: fx.flashing),
        const SizedBox(height: 18),
        TerminalPanel(
          lines: const [
            'INTRUSION SIGNATURE MATCHED',
            'FIREWALL STATUS: BYPASSED (SIMULATED)',
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
        Text(
          'EXTRACTING DATA PACKETS',
          textAlign: TextAlign.center,
          style: AppText.display(size: 24, color: AppColors.danger, shadows: AppText.glow(AppColors.danger, strength: 0.6)),
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
          label: 'UPLOADING TO REMOTE HOST (SIMULATED)',
          color: AppColors.warning,
        ),
      ],
    );
  }
}

class _TrackingView extends StatelessWidget {
  const _TrackingView({required this.progress, required this.fx});

  final double progress;
  final EffectFlags fx;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _DeviceTile(icon: Icons.videocam_outlined, label: 'CAMERA', animate: fx.motion)),
            const SizedBox(width: 10),
            Expanded(child: _DeviceTile(icon: Icons.mic_none_rounded, label: 'MICROPHONE', animate: fx.motion)),
            const SizedBox(width: 10),
            Expanded(child: _DeviceTile(icon: Icons.flashlight_on_outlined, label: 'FLASHLIGHT', animate: fx.motion)),
          ],
        ),
        const SizedBox(height: 16),
        TerminalPanel(
          lines: PrankConstants.trackingLines,
          progress: progress,
          typingPortion: 0.75,
          accent: AppColors.warning,
          textColor: const Color(0xFFFFC27A),
          typewriter: fx.typewriter,
          blinkCursor: fx.motion,
          highContrast: fx.highContrast,
          largeText: fx.largeText,
        ),
        const SizedBox(height: 16),
        HackerProgressBar(
          value: 0.87 * Curves.easeOut.transform(progress),
          label: 'DATA TRANSFER',
          color: AppColors.warning,
        ),
        const SizedBox(height: 14),
        WarningBanner(
          text: 'REMOTE SESSION ACTIVE',
          color: AppColors.warning,
          icon: Icons.satellite_alt_outlined,
          flashing: fx.flashing,
        ),
      ],
    );
  }
}

class _BreachCompleteView extends StatelessWidget {
  const _BreachCompleteView({required this.progress, required this.fx});

  final double progress;
  final EffectFlags fx;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlitchText(
          'COMPROMISED',
          enabled: fx.glitch,
          style: AppText.display(
            size: 46,
            color: AppColors.danger,
            letterSpacing: 6,
            shadows: AppText.glow(AppColors.danger),
          ),
        ),
        const SizedBox(height: 18),
        TerminalPanel(
          lines: PrankConstants.breachCompleteLines,
          progress: progress,
          typingPortion: 0.6,
          accent: AppColors.danger,
          textColor: const Color(0xFFFF8A9B),
          typewriter: fx.typewriter,
          blinkCursor: fx.motion,
          highContrast: fx.highContrast,
          largeText: fx.largeText,
        ),
        const SizedBox(height: 16),
        HackerProgressBar(
          value: (progress / 0.8).clamp(0.0, 1.0),
          label: 'FINALIZING OPERATION',
          color: AppColors.danger,
        ),
      ],
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

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({required this.icon, required this.label, required this.animate});

  final IconData icon;
  final String label;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.terminal,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.55)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, color: AppColors.warning, size: 32),
                // An abstract "scanning" overlay; no real device is used.
                Positioned.fill(child: LightSweep(trigger: label, enabled: animate, color: AppColors.warning)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.terminal(color: AppColors.warning, size: 11),
          ),
          Text(
            'SIMULATED',
            style: AppText.terminal(color: AppColors.textSecondary, size: 10),
          ),
        ],
      ),
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

