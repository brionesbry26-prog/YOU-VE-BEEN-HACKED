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

/// The lesson: direct, calm and serious. No jokes, no emojis.
///
/// By the time this screen appears every prank timer, sound, vibration and
/// sensor subscription has already been stopped by the controller. The back
/// gesture closes the app normally.
class RevealScreen extends StatefulWidget {
  const RevealScreen({super.key});

  static const replayKey = Key('reveal-replay');
  static const settingsKey = Key('reveal-settings');
  static const reactionKey = Key('reveal-reaction');

  @override
  State<RevealScreen> createState() => _RevealScreenState();
}

class _RevealScreenState extends State<RevealScreen> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final services = AppServices.of(context);
    unawaited(services.audio.play(SoundEffect.reveal));
    unawaited(services.haptics.pulse(HapticCue.reveal));
  }

  Widget _enter(Widget child, EffectFlags fx, int delayMs) {
    if (!fx.motion) return child;
    return child
        .animate()
        .fadeIn(delay: delayMs.ms, duration: 600.ms)
        .slideY(begin: 0.12, end: 0, delay: delayMs.ms, duration: 600.ms, curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final services = AppServices.of(context);
    final fx = EffectFlags.of(context, services.settings.value);
    final navigator = Navigator.of(context);
    final bodyStyle = AppText.display(
      size: 18,
      weight: FontWeight.w600,
      letterSpacing: 0.3,
      color: AppColors.textPrimary,
    ).copyWith(height: 1.35);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(26, 28, 26, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - 52).clamp(0.0, double.infinity),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _enter(
                        const Icon(Icons.verified_user_outlined, color: AppColors.hackerGreen, size: 56),
                        fx,
                        0,
                      ),
                      const SizedBox(height: 26),
                      _enter(
                        Text(
                          PrankConstants.lessonHeadline,
                          style: AppText.display(size: 38, letterSpacing: 1.2),
                        ),
                        fx,
                        150,
                      ),
                      const SizedBox(height: 8),
                      _enter(
                        Text(
                          PrankConstants.lessonSubline,
                          style: AppText.display(size: 38, letterSpacing: 1.2, color: AppColors.hackerGreen),
                        ),
                        fx,
                        350,
                      ),
                      const SizedBox(height: 30),
                      for (var i = 0; i < PrankConstants.revealFacts.length; i++)
                        _enter(
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(PrankConstants.revealFacts[i], style: bodyStyle),
                          ),
                          fx,
                          600 + i * 120,
                        ),
                      const SizedBox(height: 14),
                      _enter(
                        Text(
                          PrankConstants.revealExplanation,
                          style: AppText.display(
                            size: 16,
                            weight: FontWeight.w500,
                            letterSpacing: 0.2,
                            color: AppColors.textSecondary,
                          ).copyWith(height: 1.45),
                        ),
                        fx,
                        1150,
                      ),
                      const SizedBox(height: 34),
                      Text(
                        PrankConstants.revealAcknowledgment,
                        style: AppText.terminal(color: AppColors.textSecondary, size: 12),
                      ),
                      const SizedBox(height: 22),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          _QuietButton(
                            key: RevealScreen.replayKey,
                            label: 'REPLAY',
                            icon: Icons.replay_rounded,
                            onPressed: () => navigator.pushReplacementNamed(AppRoutes.prank),
                          ),
                          _QuietButton(
                            key: RevealScreen.settingsKey,
                            label: 'SETTINGS',
                            icon: Icons.tune_rounded,
                            onPressed: () => navigator.pushNamed(AppRoutes.settings),
                          ),
                          _QuietButton(
                            key: RevealScreen.reactionKey,
                            label: 'CAPTURE YOUR REACTION',
                            icon: Icons.photo_camera_front_outlined,
                            onPressed: () => navigator.pushNamed(AppRoutes.reaction),
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
    );
  }
}

class _QuietButton extends StatelessWidget {
  const _QuietButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: AppText.display(size: 14, color: AppColors.textSecondary, letterSpacing: 1),
      ),
    );
  }
}
