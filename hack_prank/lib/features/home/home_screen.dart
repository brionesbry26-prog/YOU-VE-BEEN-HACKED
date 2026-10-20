import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app_routes.dart';
import '../../core/app_services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/effect_flags.dart';
import '../../shared/widgets/animated_skull.dart';
import '../../shared/widgets/neon_button.dart';
import '../../shared/widgets/visual_effects.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const startKey = Key('home-start');
  static const customizeKey = Key('home-customize');
  static const settingsKey = Key('home-settings');

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  /// Drives the one-off boot sequence shown when the app opens.
  late final AnimationController _boot = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  );
  bool _bootChecked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootChecked) return;
    _bootChecked = true;
    final fx = EffectFlags.of(context, AppServices.of(context).settings.value);
    if (fx.motion) {
      _boot.forward();
    } else {
      _boot.value = 1;
    }
  }

  @override
  void dispose() {
    _boot.dispose();
    super.dispose();
  }

  Widget _enter(Widget child, EffectFlags fx, int delayMs) {
    if (!fx.motion) return child;
    return child
        .animate()
        .fadeIn(delay: (1100 + delayMs).ms, duration: 500.ms)
        .slideY(begin: 0.2, end: 0, delay: (1100 + delayMs).ms, duration: 500.ms, curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final services = AppServices.of(context);
    return ListenableBuilder(
      listenable: services.settings,
      builder: (context, _) {
        final settings = services.settings.value;
        final fx = EffectFlags.of(context, settings);
        final navigator = Navigator.of(context);
        final skullSize = math.min(MediaQuery.sizeOf(context).width * 0.45, 190.0);

        return Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              CodeRainBackground(animate: fx.motion, opacity: 0.22),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.35),
                    radius: 0.9,
                    colors: [Color(0x3300FF66), Colors.transparent],
                  ),
                ),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: (constraints.maxHeight - 32).clamp(0.0, double.infinity)),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Align(
                                alignment: Alignment.centerRight,
                                child: IconButton(
                                  key: HomeScreen.settingsKey,
                                  tooltip: 'Settings',
                                  icon: const Icon(Icons.settings_outlined, color: AppColors.hackerGreen),
                                  onPressed: () => navigator.pushNamed(AppRoutes.settings),
                                ),
                              ),
                              Center(
                                child: _enter(
                                  AnimatedSkull(size: skullSize, animate: fx.motion),
                                  fx,
                                  0,
                                ),
                              ),
                              const SizedBox(height: 18),
                              _enter(
                                GlitchText(
                                  "YOU'VE BEEN HACKED",
                                  enabled: fx.glitch,
                                  style: AppText.display(
                                    size: 40,
                                    color: AppColors.hackerGreen,
                                    letterSpacing: 2.5,
                                    shadows: AppText.glow(AppColors.hackerGreen),
                                  ),
                                ),
                                fx,
                                120,
                              ),
                              const SizedBox(height: 8),
                              _enter(
                                Text(
                                  'A harmless cinematic hacking prank.',
                                  textAlign: TextAlign.center,
                                  style: AppText.display(
                                    size: 18,
                                    color: AppColors.textSecondary,
                                    weight: FontWeight.w500,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                fx,
                                200,
                              ),
                              const SizedBox(height: 36),
                              _enter(
                                NeonButton(
                                  key: HomeScreen.startKey,
                                  label: 'START THE PRANK',
                                  icon: Icons.play_arrow_rounded,
                                  large: true,
                                  onPressed: () => navigator.pushNamed(AppRoutes.prank),
                                ),
                                fx,
                                300,
                              ),
                              const SizedBox(height: 14),
                              _enter(
                                NeonButton(
                                  key: HomeScreen.customizeKey,
                                  label: 'CUSTOMIZE EXPERIENCE',
                                  icon: Icons.tune_rounded,
                                  style: NeonButtonStyle.secondary,
                                  onPressed: () => navigator.pushNamed(AppRoutes.settings),
                                ),
                                fx,
                                380,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Duration: ${settings.durationSeconds}s  ·  Reveal is always guaranteed',
                                textAlign: TextAlign.center,
                                style: AppText.terminal(color: AppColors.mutedTerminal, size: 12),
                              ),
                              const SizedBox(height: 28),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.shield_outlined, size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Simulation only. No real hacking or data access.',
                                      textAlign: TextAlign.center,
                                      style: AppText.display(
                                        size: 14,
                                        color: AppColors.textSecondary,
                                        weight: FontWeight.w500,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const CrtOverlay(),
              _BootOverlay(animation: _boot),
            ],
          ),
        );
      },
    );
  }
}

/// "Booting" terminal splash that fades away to reveal the home screen.
class _BootOverlay extends StatelessWidget {
  const _BootOverlay({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        if (t >= 1) return const SizedBox.shrink();
        final fade = t < 0.65 ? 1.0 : 1 - (t - 0.65) / 0.35;
        final progress = (t / 0.6).clamp(0.0, 1.0);
        const lines = ['BOOT SEQUENCE v1.0', 'LOADING NEON_UI...', 'SIMULATION MODE: ON'];
        final shown = (progress * lines.length).ceil().clamp(1, lines.length);
        return IgnorePointer(
          child: Opacity(
            opacity: fade.clamp(0.0, 1.0),
            child: ColoredBox(
              color: AppColors.background,
              child: Center(
                child: SizedBox(
                  width: 260,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final line in lines.take(shown))
                        Text('> $line', style: AppText.terminal(color: AppColors.hackerGreen)),
                      const SizedBox(height: 14),
                      LinearProgressIndicator(
                        value: progress,
                        minHeight: 3,
                        color: AppColors.hackerGreen,
                        backgroundColor: AppColors.hackerGreen.withValues(alpha: 0.12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
