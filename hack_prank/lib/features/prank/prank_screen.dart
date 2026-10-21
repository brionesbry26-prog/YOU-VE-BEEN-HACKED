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

/// The app's first and only "start" screen: it opens on an innocent
/// "I Love You" title card and runs the whole simulation automatically.
///
/// Ways the simulation ends (all lead to the awareness screen):
/// * a deliberate shake of the phone (armed from the first terminal screen);
/// * the countdown reaching zero (always — the end state is guaranteed);
/// * the discreet ✕ button or the system back gesture, with an
///   "End the simulation?" confirmation;
/// * a hidden triple-tap on the stage title (accessibility fallback for
///   people who cannot shake the phone).
///
/// Home, recents and every other system control keep working normally, and
/// the simulation pauses while the app is in the background.
class PrankScreen extends StatefulWidget {
  const PrankScreen({super.key});

  static const exitKey = Key('prank-exit');
  static const titleKey = Key('prank-stage-title');
  static const introKey = Key('prank-intro');

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
      timeline: PrankTimeline(ransomDuration: settings.countdown),
      autoReveal: settings.autoReveal,
      effects: PrankEffectsDirector(
        audio: _services.audio,
        haptics: _services.haptics,
        wakelock: _services.wakelock,
        shake: _services.shake,
        onShake: _endSimulation,
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

  /// Ends the simulation and shows the awareness screen. Safe to call from
  /// any stage and any number of times.
  void _endSimulation() => _controller?.reveal();

  Future<void> _requestExit() async {
    if (_leaving || _dialogOpen) return;
    if (!_services.settings.value.exitConfirmation) {
      _endSimulation();
      return;
    }
    _dialogOpen = true;
    _c.pause();
    final exit = await showExitConfirmationDialog(context);
    _dialogOpen = false;
    if (!mounted || _leaving) return;
    if (exit) {
      _endSimulation();
    } else {
      _c.resume();
    }
  }

  /// Three taps on the stage title within 1.5 s end the simulation.
  void _onTitleTap() {
    final now = DateTime.now();
    _titleTaps
      ..add(now)
      ..removeWhere((t) => now.difference(t) > const Duration(milliseconds: 1500));
    if (_titleTaps.length >= 3) {
      _titleTaps.clear();
      _endSimulation();
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
    final showIntro = stage == PrankStage.idle || stage == PrankStage.intro;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _requestExit();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 700),
          switchInCurve: Curves.easeOutCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: fx.motion ? 1.06 : 1, end: 1).animate(animation),
              child: child,
            ),
          ),
          child: showIntro
              ? _IntroCard(
                  key: PrankScreen.introKey,
                  progress: stage == PrankStage.intro ? _c.stageProgress : 0,
                )
              : _Terminal(
                  key: const ValueKey('terminal'),
                  controller: _c,
                  fx: fx,
                  paused: _c.isPaused && !_dialogOpen,
                  onExit: _requestExit,
                  onTitleTap: _onTitleTap,
                ),
        ),
      ),
    );
  }
}

/// The innocent opening: a quiet "I Love You" that fades in, then away.
class _IntroCard extends StatelessWidget {
  const _IntroCard({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final fadeIn = (progress / 0.3).clamp(0.0, 1.0);
    final fadeOut = ((1 - progress) / 0.25).clamp(0.0, 1.0);
    final opacity = fadeIn < fadeOut ? fadeIn : fadeOut;
    return ColoredBox(
      color: AppColors.background,
      child: Center(
        child: AnimatedOpacity(
          opacity: opacity,
          duration: const Duration(milliseconds: 180),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'I Love You',
                style: AppText.display(
                  size: 40,
                  weight: FontWeight.w500,
                  letterSpacing: 3,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: 36,
                height: 2,
                color: AppColors.danger.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Terminal extends StatelessWidget {
  const _Terminal({
    super.key,
    required this.controller,
    required this.fx,
    required this.paused,
    required this.onExit,
    required this.onTitleTap,
  });

  final PrankController controller;
  final EffectFlags fx;
  final bool paused;
  final VoidCallback onExit;
  final VoidCallback onTitleTap;

  @override
  Widget build(BuildContext context) {
    final stage = controller.stage;
    final danger = stage.index >= PrankStage.warning.index;
    final accent = danger ? AppColors.danger : AppColors.hackerGreen;

    final Widget body = stage == PrankStage.ransom
        ? RansomScreen(
            remaining: controller.ransomRemaining,
            progress: controller.stageProgress,
            expired: controller.countdownExpired,
            fx: fx,
          )
        : StageView(controller: controller, fx: fx);

    return ControlledShake(
      trigger: stage == PrankStage.warning ? stage : null,
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
                _TopBar(stage: stage, accent: accent, onExit: onExit, onTitleTap: onTitleTap),
                _SequenceBar(value: controller.sequenceProgress, color: accent),
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
                              transitionBuilder: (child, animation) => FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                  scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
                                  child: child,
                                ),
                              ),
                              child: KeyedSubtree(key: ValueKey(stage), child: body),
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
          if (paused) const _PausedOverlay(),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.stage,
    required this.accent,
    required this.onExit,
    required this.onTitleTap,
  });

  final PrankStage stage;
  final Color accent;
  final VoidCallback onExit;
  final VoidCallback onTitleTap;

  @override
  Widget build(BuildContext context) {
    final number = stage.stageNumber;
    final title = number != null
        ? 'STAGE $number/${PrankStage.numbered.length} · ${stage.title}'
        : stage.title;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 2),
      child: Row(
        children: [
          // Always available, deliberately low-key so it doesn't spoil the show.
          IconButton(
            key: PrankScreen.exitKey,
            tooltip: 'Exit simulation',
            onPressed: onExit,
            icon: Icon(
              Icons.close_rounded,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
          Expanded(
            child: GestureDetector(
              key: PrankScreen.titleKey,
              behavior: HitTestBehavior.opaque,
              onTap: onTitleTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
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
          const SizedBox(width: 48),
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
