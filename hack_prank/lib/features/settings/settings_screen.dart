import 'package:flutter/material.dart';

import '../../core/app_services.dart';
import '../../core/constants/prank_constants.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/preferences_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Every option applies immediately and is saved on the device.
///
/// There is intentionally no option to disable the reveal or the exit
/// controls; the "Always on" section lists those guarantees.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppServices.of(context);
    final controller = services.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('CUSTOMIZE')),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final s = controller.value;
          void set(PrankSettings next) => controller.update(next);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              const _Header('DURATION'),
              _Card(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: SegmentedButton<int>(
                      showSelectedIcon: false,
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: AppColors.hackerGreen,
                        selectedForegroundColor: AppColors.background,
                        foregroundColor: AppColors.hackerGreen,
                        side: const BorderSide(color: AppColors.hackerGreen),
                      ),
                      segments: [
                        for (final d in PrankConstants.allowedDurations)
                          ButtonSegment<int>(value: d, label: Text('${d}s')),
                      ],
                      selected: {s.durationSeconds},
                      onSelectionChanged: (v) => set(s.copyWith(durationSeconds: v.first)),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _Hint(
                      'Total time from start until the automatic reveal. '
                      'A third of it is the ransom countdown.',
                    ),
                  ),
                ],
              ),
              const _Header('EFFECTS'),
              _Card(
                children: [
                  _Toggle('Terminal animations', s.terminalAnimations,
                      (v) => set(s.copyWith(terminalAnimations: v)),
                      subtitle: 'Type terminal text character by character'),
                  _Toggle('Screen shake', s.screenShake, (v) => set(s.copyWith(screenShake: v))),
                  _Toggle('Glitch effects', s.glitchEffects, (v) => set(s.copyWith(glitchEffects: v))),
                  _Toggle('Confetti', s.confetti, (v) => set(s.copyWith(confetti: v))),
                  _Toggle('Vibration', s.vibration, (v) => set(s.copyWith(vibration: v)),
                      subtitle: 'Short pulses at key moments. Follows system settings'),
                ],
              ),
              const _Header('SOUND'),
              _Card(
                children: [
                  _Toggle('Sound', s.soundEnabled, (v) => set(s.copyWith(soundEnabled: v)),
                      subtitle: 'Master switch for every sound'),
                  ListTile(
                    title: const Text('Master volume'),
                    subtitle: Slider(
                      value: s.masterVolume,
                      divisions: 10,
                      label: '${(s.masterVolume * 100).round()}%',
                      onChanged: s.soundEnabled
                          ? (v) => set(s.copyWith(masterVolume: v))
                          : null,
                    ),
                  ),
                  _Toggle('Background typing', s.typingSounds, (v) => set(s.copyWith(typingSounds: v)),
                      enabled: s.soundEnabled),
                  _Toggle('Warning sounds', s.warningSounds, (v) => set(s.copyWith(warningSounds: v)),
                      subtitle: 'Beeps, alarms, transfer noise and siren', enabled: s.soundEnabled),
                  _Toggle('Robotic voice', s.robotVoice, (v) => set(s.copyWith(robotVoice: v)),
                      subtitle: '"Your device has been compromised."', enabled: s.soundEnabled),
                ],
              ),
              const _Header('PREVIEW SOUND EFFECTS'),
              _Card(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final effect in SoundEffect.values)
                          ActionChip(
                            avatar: const Icon(Icons.play_arrow_rounded, size: 18, color: AppColors.hackerGreen),
                            label: Text(effect.label),
                            side: const BorderSide(color: AppColors.secondaryGreen),
                            onPressed: () {
                              if (!s.soundEnabled || s.masterVolume == 0) {
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(const SnackBar(content: Text('Sound is muted.')));
                                return;
                              }
                              services.audio.play(effect, preview: true);
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const _Header('ACCESSIBILITY'),
              _Card(
                children: [
                  _Toggle('Reduce motion', s.reduceMotion, (v) => set(s.copyWith(reduceMotion: v)),
                      subtitle: 'Turns off shake, glitches, confetti and looping animations'),
                  _Toggle('Disable flashing transitions', s.disableFlashing,
                      (v) => set(s.copyWith(disableFlashing: v)),
                      subtitle: 'Warning borders and light sweeps stay still'),
                  _Toggle('High-contrast text', s.highContrast, (v) => set(s.copyWith(highContrast: v))),
                  _Toggle('Larger terminal text', s.largeTerminalText,
                      (v) => set(s.copyWith(largeTerminalText: v))),
                ],
              ),
              const _Header('PRANK BEHAVIOR'),
              _Card(
                children: [
                  _Toggle('Show reveal shortcut', s.showRevealShortcut,
                      (v) => set(s.copyWith(showRevealShortcut: v)),
                      subtitle: 'A small "Reveal" button during the prank. '
                          'Triple-tapping the stage title always reveals too'),
                  _Toggle('Automatically reveal when the countdown ends', s.autoReveal,
                      (v) => set(s.copyWith(autoReveal: v)),
                      subtitle: s.autoReveal
                          ? 'Reveals the moment the timer hits 00:00'
                          : 'Holds at 00:00 for a few seconds, then reveals anyway'),
                  _Toggle('Exit confirmation', s.exitConfirmation,
                      (v) => set(s.copyWith(exitConfirmation: v)),
                      subtitle: 'Ask "End the simulation?" before exiting'),
                ],
              ),
              const _Header('ALWAYS ON'),
              const _Card(
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: _Hint(
                      '• The reveal always appears when the prank ends.\n'
                      '• EXIT and the back gesture work on every screen.\n'
                      '• Nothing on the device is read, locked, encrypted or sent anywhere.\n'
                      '• The camera is never used during the prank.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  onPressed: controller.reset,
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('Reset to defaults'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 22, 4, 8),
      child: Text(
        text,
        style: AppText.terminal(color: AppColors.hackerGreen, size: 13),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.terminal,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.hackerGreen.withValues(alpha: 0.25)),
      ),
      child: Column(children: children),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle(
    this.title,
    this.value,
    this.onChanged, {
    this.subtitle,
    this.enabled = true,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? subtitle;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
      value: value,
      onChanged: enabled ? onChanged : null,
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
    );
  }
}
