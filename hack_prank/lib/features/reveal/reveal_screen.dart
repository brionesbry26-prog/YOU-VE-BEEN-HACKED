import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app_routes.dart';
import '../../core/app_services.dart';
import '../../core/constants/prank_constants.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/haptics_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/effect_flags.dart';
import '../../shared/widgets/animated_skull.dart';
import '../../shared/widgets/neon_button.dart';
import '../../shared/widgets/visual_effects.dart';

/// "GOTCHA!" — tells the user, clearly and immediately, that nothing was real.
class RevealScreen extends StatefulWidget {
  const RevealScreen({super.key});

  static const playAgainKey = Key('reveal-play-again');
  static const homeKey = Key('reveal-home');
  static const shareKey = Key('reveal-share');
  static const reactionKey = Key('reveal-reaction');

  @override
  State<RevealScreen> createState() => _RevealScreenState();
}

class _RevealScreenState extends State<RevealScreen> {
  bool _started = false;
  bool _smile = false;
  Timer? _smileTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final services = AppServices.of(context);
    unawaited(services.audio.play(SoundEffect.celebrate));
    unawaited(services.haptics.pulse(HapticCue.reveal));
    // Show the skull for a beat, then morph it into a smile.
    _smileTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _smile = true);
    });
  }

  @override
  void dispose() {
    _smileTimer?.cancel();
    super.dispose();
  }

  Widget _enter(Widget child, EffectFlags fx, int delayMs) {
    if (!fx.motion) return child;
    return child
        .animate()
        .fadeIn(delay: delayMs.ms, duration: 450.ms)
        .slideY(begin: 0.25, end: 0, delay: delayMs.ms, duration: 450.ms, curve: Curves.easeOutBack);
  }

  @override
  Widget build(BuildContext context) {
    final services = AppServices.of(context);
    final fx = EffectFlags.of(context, services.settings.value);
    final navigator = Navigator.of(context);

    return Scaffold(
      backgroundColor: AppColors.revealBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.5),
                radius: 1.2,
                colors: [Color(0xFF1D2B4A), AppColors.revealBackground],
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: (constraints.maxHeight - 48).clamp(0.0, double.infinity)),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: AnimatedSkull(
                              size: 150,
                              smile: _smile,
                              animate: fx.motion,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _enter(
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.verified_user_rounded, color: AppColors.hackerGreen, size: 30),
                                const SizedBox(width: 8),
                                Text(
                                  'YOUR DEVICE IS SAFE',
                                  style: AppText.display(size: 18, color: AppColors.hackerGreen),
                                ),
                              ],
                            ),
                            fx,
                            100,
                          ),
                          const SizedBox(height: 18),
                          _enter(
                            Text(
                              'GOTCHA! 😂',
                              textAlign: TextAlign.center,
                              style: AppText.display(
                                size: 54,
                                color: AppColors.revealAccent,
                                shadows: AppText.glow(AppColors.revealAccent, strength: 0.7),
                              ),
                            ),
                            fx,
                            200,
                          ),
                          const SizedBox(height: 6),
                          _enter(
                            Text(
                              "YOU'VE BEEN PRANKED!",
                              textAlign: TextAlign.center,
                              style: AppText.display(size: 28),
                            ),
                            fx,
                            320,
                          ),
                          const SizedBox(height: 18),
                          _enter(
                            Text(
                              'Your phone was never hacked.',
                              textAlign: TextAlign.center,
                              style: AppText.display(size: 21, weight: FontWeight.w600, letterSpacing: 0.4),
                            ),
                            fx,
                            440,
                          ),
                          const SizedBox(height: 8),
                          _enter(
                            Text(
                              'No files were stolen. No camera was activated. '
                              'No personal data was accessed.',
                              textAlign: TextAlign.center,
                              style: AppText.display(
                                size: 17,
                                color: AppColors.textSecondary,
                                weight: FontWeight.w500,
                                letterSpacing: 0.3,
                              ).copyWith(height: 1.35),
                            ),
                            fx,
                            520,
                          ),
                          const SizedBox(height: 28),
                          NeonButton(
                            key: RevealScreen.playAgainKey,
                            label: 'PLAY AGAIN',
                            icon: Icons.replay_rounded,
                            style: NeonButtonStyle.gold,
                            onPressed: () => navigator.pushReplacementNamed(AppRoutes.prank),
                          ),
                          const SizedBox(height: 12),
                          NeonButton(
                            key: RevealScreen.homeKey,
                            label: 'BACK TO HOME',
                            icon: Icons.home_outlined,
                            style: NeonButtonStyle.secondary,
                            onPressed: () => navigator.popUntil((route) => route.isFirst),
                          ),
                          const SizedBox(height: 12),
                          NeonButton(
                            key: RevealScreen.shareKey,
                            label: 'SHARE THE JOKE',
                            icon: Icons.share_rounded,
                            style: NeonButtonStyle.secondary,
                            onPressed: () => services.share.shareText(PrankConstants.shareText),
                          ),
                          const SizedBox(height: 18),
                          TextButton.icon(
                            key: RevealScreen.reactionKey,
                            onPressed: () => navigator.pushNamed(AppRoutes.reaction),
                            icon: const Icon(Icons.photo_camera_front_outlined, color: AppColors.revealAccent),
                            label: Text(
                              'CAPTURE YOUR REACTION',
                              style: AppText.display(size: 16, color: AppColors.revealAccent),
                            ),
                          ),
                          Text(
                            'Optional. The camera is only used if you choose this, now that the prank is over.',
                            textAlign: TextAlign.center,
                            style: AppText.display(
                              size: 13,
                              color: AppColors.textSecondary,
                              weight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (fx.confetti) const ConfettiBurst(),
        ],
      ),
    );
  }
}
