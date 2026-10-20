import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_routes.dart';
import '../../core/app_services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/effect_flags.dart';
import '../../shared/widgets/exit_confirmation_dialog.dart';
import '../../shared/widgets/visual_effects.dart';
import '../ransom/ransom_screen.dart';
import 'prank_controller.dart';
import 'prank_effects_director.dart';
import 'prank_stage.dart';
import 'widgets/stage_views.dart';

/// Full-screen host for the breach sequence and the ransom note.
///
/// Safety guarantees implemented here:
/// * a visible EXIT control on every stage (plus the normal back gesture);
/// * a visible reveal shortcut (when enabled) and a hidden triple-tap on the
///   stage title, which always works;
/// * pausing when the app is backgrounded, without restarting the countdown;
/// * stopping all sound, vibration and timers on exit or dispose.
class PrankScreen extends StatefulWidget {
  const PrankScreen({super.key});

  static const exitKey = Key('prank-exit');
  static const revealKey = Key('prank-reveal');
  static const titleKey = Key('prank-stage-title');

  @override
  State<PrankScreen> createState() => _PrankScreenState();
}

class _PrankScreenState extends State<PrankScreen> with WidgetsBindingObserver {
  PrankController? _controller;
  late AppServices _services;
  bool _dialogOpen = false;
  bool _leaving = false;
  final List<DateTime> _titleTaps = [];

  PrankController get _c => _controller!;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    _services = AppServices.of(context);
    final settings = _services.settings.value;
    _controller = PrankController(
      timeline: PrankTimeline.forTotal(settings.duration),
      autoReveal: settings.autoReveal,
      effects: PrankEffectsDirector(
        audio: _services.audio,
        haptics: _services.haptics,
        wakelock: _services.wakelock,
      ),
    )..addListener(_onControllerChanged);
    // Start after the first frame so listeners never fire mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _c.start();
    });
  }

  void _onControllerChanged() {
    if (!mounted || _leaving) return;
    if (_c.stage == PrankStage.revealed) {
      _leaving = true;
      Navigator.of(context).pushReplacementNamed(AppRoutes.reveal);
      return;
    }
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null) return;
    switch (state) {
      case AppLifecycleState.resumed:
        if (!_dialogOpen) controller.resume();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        controller.pause();
      case AppLifecycleState.detached:
        controller.exit();
    }
  }

  Future<void> _requestExit() async {
    if (_leaving || _dialogOpen) return;
    if (!_services.settings.value.exitConfirmation) {
      _exitNow();
      return;
    }
    _dialogOpen = true;
    _c.pause();
    final exit = await showExitConfirmationDialog(context);
    _dialogOpen = false;
    if (!mounted || _leaving) return;
    if (exit) {
      _exitNow();
    } else {
      _c.resume();
    }
  }

  void _exitNow() {
    if (_leaving) return;
    _leaving = true;
    _c.exit();
    Navigator.of(context).pop();
  }

  void _reveal() => _c.reveal();

  /// Three taps on the stage title within 1.5 s reveal the prank.
  void _onTitleTap() {
    final now = DateTime.now();
    _titleTaps
      ..add(now)
      ..removeWhere((t) => now.difference(t) > const Duration(milliseconds: 1500));
    if (_titleTaps.length >= 3) {
      _titleTaps.clear();
      _reveal();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller
      ?..removeListener(_onControllerChanged)
      ..dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = _services.settings.value;
    final fx = EffectFlags.of(context, settings);
    final stage = _c.stage;
    final danger = stage.index >= PrankStage.warning.index;
    final accent = danger ? AppColors.danger : AppColors.hackerGreen;

    final Widget body = stage == PrankStage.ransom
        ? RansomScreen(
            remaining: _c.ransomRemaining,
            total: _c.timeline.ransomDuration,
            expired: _c.countdownExpired,
            onReveal: _reveal,
            fx: fx,
          )
        : StageView(controller: _c, fx: fx);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _requestExit();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: ControlledShake(
          trigger: stage == PrankStage.warning || stage == PrankStage.breachComplete
              ? stage
              : null,
          enabled: fx.shake,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CodeRainBackground(
                animate: fx.motion,
                color: accent,
                opacity: danger ? 0.12 : 0.16,
              ),
              // Subtle red glow from the edges once the "breach" begins.
              IgnorePointer(
                child: AnimatedOpacity(
                  opacity: danger ? (fx.flashing ? 0.55 : 0.35) : 0,
                  duration: const Duration(milliseconds: 900),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        radius: 1.1,
                        colors: [Colors.transparent, Color(0x99FF1744)],
                        stops: [0.55, 1],
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    _TopBar(
                      stage: stage,
                      accent: accent,
                      showReveal: settings.showRevealShortcut,
                      onExit: _requestExit,
                      onReveal: _reveal,
                      onTitleTap: _onTitleTap,
                    ),
                    _SequenceBar(value: _c.sequenceProgress, color: accent),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) => SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: (constraints.maxHeight - 40).clamp(0.0, double.infinity),
                            ),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 560),
                                child: AnimatedSwitcher(
                                  duration: fx.motion
                                      ? const Duration(milliseconds: 450)
                                      : Duration.zero,
                                  transitionBuilder: (child, animation) =>
                                      FadeTransition(
                                        opacity: animation,
                                        child: ScaleTransition(
                                          scale: Tween<double>(begin: 0.96, end: 1)
                                              .animate(animation),
                                          child: child,
                                        ),
                                      ),
                                  child: KeyedSubtree(
                                    key: ValueKey(stage),
                                    child: body,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              LightSweep(trigger: stage, enabled: fx.flashing, color: accent),
              CrtOverlay(tint: accent),
              if (_c.isPaused && !_dialogOpen) const _PausedOverlay(),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.stage,
    required this.accent,
    required this.showReveal,
    required this.onExit,
    required this.onReveal,
    required this.onTitleTap,
  });

  final PrankStage stage;
  final Color accent;
  final bool showReveal;
  final VoidCallback onExit;
  final VoidCallback onReveal;
  final VoidCallback onTitleTap;

  @override
  Widget build(BuildContext context) {
    final number = stage.sequenceNumber;
    final title = number != null
        ? 'STAGE $number/${PrankStage.sequence.length} · ${stage.title}'
        : stage.title;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
      child: Row(
        children: [
          TextButton.icon(
            key: PrankScreen.exitKey,
            onPressed: onExit,
            icon: const Icon(Icons.close_rounded, size: 20),
            label: Text('EXIT', style: AppText.display(size: 15, color: AppColors.textPrimary)),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              minimumSize: const Size(48, 44),
            ),
          ),
          Expanded(
            child: GestureDetector(
              key: PrankScreen.titleKey,
              behavior: HitTestBehavior.opaque,
              onTap: onTitleTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.terminal(color: accent, size: 12),
                ),
              ),
            ),
          ),
          if (showReveal)
            TextButton(
              key: PrankScreen.revealKey,
              onPressed: onReveal,
              style: TextButton.styleFrom(minimumSize: const Size(48, 44)),
              child: Text(
                'Reveal',
                style: AppText.display(size: 15, color: AppColors.textSecondary, letterSpacing: 0.5),
              ),
            )
          else
            const SizedBox(width: 72),
        ],
      ),
    );
  }
}

class _SequenceBar extends StatelessWidget {
  const _SequenceBar({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: value),
          duration: const Duration(milliseconds: 160),
          builder: (context, v, _) => LinearProgressIndicator(
            value: v,
            minHeight: 3,
            color: color,
            backgroundColor: color.withValues(alpha: 0.12),
          ),
        ),
      ),
    );
  }
}

class _PausedOverlay extends StatelessWidget {
  const _PausedOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.6),
        child: Center(
          child: Text(
            'SIMULATION PAUSED',
            style: AppText.terminal(color: AppColors.hackerGreen, size: 18),
          ),
        ),
      ),
    );
  }
}
