import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hack_prank/core/app_services.dart';
import 'package:hack_prank/core/constants/prank_constants.dart';
import 'package:hack_prank/core/services/audio_service.dart';
import 'package:hack_prank/core/services/haptics_service.dart';
import 'package:hack_prank/core/services/preferences_service.dart';
import 'package:hack_prank/core/services/shake_detector.dart';
import 'package:hack_prank/core/theme/app_theme.dart';
import 'package:hack_prank/features/prank/prank_screen.dart';
import 'package:hack_prank/features/prank/widgets/countdown_timer.dart';
import 'package:hack_prank/features/ransom/ransom_screen.dart';
import 'package:hack_prank/features/reaction/reaction_screen.dart';
import 'package:hack_prank/features/reveal/reveal_screen.dart';
import 'package:hack_prank/features/settings/settings_screen.dart';
import 'package:hack_prank/shared/effect_flags.dart';
import 'package:hack_prank/shared/widgets/exit_confirmation_dialog.dart';

import '../helpers/fakes.dart';

/// Hosts a single screen with the given services.
Future<void> pumpScreen(WidgetTester tester, TestServices s, Widget child) async {
  usePhoneScreen(tester);
  await tester.pumpWidget(
    AppServicesScope(
      services: s.services,
      child: MaterialApp(theme: AppTheme.dark(), home: child),
    ),
  );
  await tester.pump();
}

/// Any character from the common emoji blocks.
final _emoji = RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]', unicode: true);

void main() {
  group('RansomScreen (countdown)', () {
    Widget countdown({Duration remaining = const Duration(seconds: 30), bool expired = false}) {
      return Scaffold(
        body: SingleChildScrollView(
          child: RansomScreen(
            remaining: remaining,
            progress: 0.4,
            expired: expired,
            fx: EffectFlags.resolve(const PrankSettings()),
          ),
        ),
      );
    }

    testWidgets('shows the compromised status and the countdown', (tester) async {
      await pumpScreen(tester, TestServices(), countdown());
      expect(find.text(PrankConstants.compromisedStatus), findsWidgets);
      expect(find.text(PrankConstants.simulationInProgress), findsOneWidget);
      expect(find.text('TIME REMAINING:'), findsOneWidget);
      expect(find.text('00:30'), findsOneWidget);
      expect(find.text('FINALIZING...'), findsNothing);
    });

    testWidgets('asks for nothing: no payment, no inputs, no links, no buttons', (tester) async {
      await pumpScreen(tester, TestServices(), countdown());
      expect(find.byType(TextField), findsNothing);
      expect(find.byWidgetPredicate((w) => w is ButtonStyleButton || w is IconButton), findsNothing);
      expect(find.textContaining('PAY'), findsNothing);
      expect(find.textContaining('₱'), findsNothing);
      expect(find.textContaining('http'), findsNothing);
    });

    testWidgets('shows the expired state at 00:00', (tester) async {
      await pumpScreen(tester, TestServices(), countdown(remaining: Duration.zero, expired: true));
      expect(find.text('00:00'), findsOneWidget);
      expect(find.text('FINALIZING...'), findsOneWidget);
    });

    test('countdown format rounds partial seconds up', () {
      expect(CountdownTimer.format(const Duration(seconds: 30)), '00:30');
      expect(CountdownTimer.format(const Duration(milliseconds: 29100)), '00:30');
      expect(CountdownTimer.format(const Duration(milliseconds: 100)), '00:01');
      expect(CountdownTimer.format(Duration.zero), '00:00');
      expect(CountdownTimer.format(const Duration(seconds: -3)), '00:00');
      expect(CountdownTimer.format(const Duration(seconds: 75)), '01:15');
    });
  });

  group('RevealScreen (awareness)', () {
    testWidgets('delivers the cybersecurity lesson', (tester) async {
      final s = TestServices();
      await pumpScreen(tester, s, const RevealScreen());
      await pumpFor(tester, const Duration(seconds: 2));

      expect(find.text("DON'T INSTALL UNKNOWN APPS."), findsOneWidget);
      expect(find.text('THINK BEFORE YOU CLICK.'), findsOneWidget);
      for (final line in [
        'This was a simulated hacking prank.',
        'Your device was not hacked.',
        'No personal files were stolen.',
        "Always check an app's source and permissions before installing it.",
      ]) {
        expect(find.text(line), findsOneWidget, reason: line);
      }
      expect(find.textContaining('Install applications only from trusted sources'), findsOneWidget);
      expect(find.text('CYBERSECURITY AWARENESS EXPERIENCE'), findsOneWidget);
      expect(find.byIcon(Icons.verified_user_outlined), findsOneWidget);

      expect(s.audio.audible, [SoundEffect.reveal]);
      expect(s.haptics.pulses, [HapticCue.reveal]);
    });

    testWidgets('uses no emojis and a black background', (tester) async {
      await pumpScreen(tester, TestServices(), const RevealScreen());
      await pumpFor(tester, const Duration(seconds: 2));
      for (final text in tester.widgetList<Text>(find.byType(Text))) {
        final content = text.data ?? text.textSpan?.toPlainText() ?? '';
        expect(_emoji.hasMatch(content), isFalse, reason: content);
      }
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.black);
    });

    testWidgets('settings and the optional reaction photo are reachable', (tester) async {
      final s = TestServices();
      await pumpScreen(tester, s, const RevealScreen());
      await pumpFor(tester, const Duration(seconds: 2));
      expect(find.byKey(RevealScreen.replayKey), findsOneWidget);
      expect(find.byKey(RevealScreen.settingsKey), findsOneWidget);
      expect(find.byKey(RevealScreen.reactionKey), findsOneWidget);
    });

    testWidgets('works with motion disabled', (tester) async {
      final s = TestServices(allEffectsOff);
      await pumpScreen(tester, s, const RevealScreen());
      expect(find.text("DON'T INSTALL UNKNOWN APPS."), findsOneWidget);
      expect(s.audio.audible, isEmpty);
    });
  });

  group('ReactionScreen (optional, post-reveal)', () {
    testWidgets('explains everything first and does not open the camera', (tester) async {
      await pumpScreen(
        tester,
        TestServices(),
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const ReactionScreen()),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await pumpFor(tester, const Duration(milliseconds: 500));

      expect(find.text('Capture your reaction'), findsOneWidget);
      expect(find.textContaining('only after you tap OPEN CAMERA'), findsOneWidget);
      expect(find.textContaining('Nothing is uploaded'), findsOneWidget);
      expect(find.byKey(ReactionScreen.openCameraKey), findsOneWidget);
    });
  });

  group('SettingsScreen', () {
    testWidgets('shows every section and option', (tester) async {
      await pumpScreen(tester, TestServices(), const SettingsScreen());
      for (final label in [
        'COUNTDOWN',
        '15s',
        '30s',
        '45s',
        '60s',
        'SHAKE TO REVEAL',
        'Low',
        'Medium',
        'High',
        'Terminal animations',
        'Screen shake',
        'Glitch effects',
        'Warning sounds',
        'Robotic voice',
        'Vibration',
        'Reduce motion',
        'Disable flashing transitions',
        'High-contrast text',
        'Larger terminal text',
        'Automatically reveal when the countdown ends',
        'Exit confirmation',
        'PREVIEW SOUND EFFECTS',
      ]) {
        await tester.scrollUntilVisible(find.text(label).first, 200, scrollable: find.byType(Scrollable).first);
        expect(find.text(label), findsWidgets, reason: label);
      }
    });

    testWidgets('changes apply immediately to the shared settings', (tester) async {
      final s = TestServices();
      await pumpScreen(tester, s, const SettingsScreen());

      await tester.tap(find.text('60s'));
      await tester.pump();
      expect(s.settings.value.countdownSeconds, 60);

      await tester.tap(find.text('High'));
      await tester.pump();
      expect(s.settings.value.shakeSensitivity, ShakeSensitivity.high);

      final shake = find.text('Screen shake');
      await tester.scrollUntilVisible(shake, 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(shake);
      await tester.pump();
      expect(s.settings.value.screenShake, isFalse);
    });

    testWidgets('sound previews play through the audio service', (tester) async {
      final s = TestServices(const PrankSettings(robotVoice: false));
      await pumpScreen(tester, s, const SettingsScreen());
      await tester.scrollUntilVisible(find.text('Reveal tone'), 200, scrollable: find.byType(Scrollable).first);
      final chip = find.text('Robotic announcement');
      await tester.ensureVisible(chip);
      await tester.pump();
      await tester.tap(chip);
      await tester.pump();
      expect(s.audio.previews, [SoundEffect.voice]);
    });

    testWidgets('offers no way to disable the reveal or the exit', (tester) async {
      await pumpScreen(tester, TestServices(), const SettingsScreen());
      expect(find.textContaining('Disable reveal'), findsNothing);
      expect(find.textContaining('Hide exit'), findsNothing);
      expect(find.textContaining('Lock'), findsNothing);
    });
  });

  group('ExitConfirmationDialog', () {
    /// Opens the dialog and returns a getter for its eventual result.
    Future<bool? Function()> openDialog(WidgetTester tester) async {
      bool? result;
      await pumpScreen(
        tester,
        TestServices(),
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async => result = await showExitConfirmationDialog(context),
                child: const Text('exit'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('exit'));
      await pumpFor(tester, const Duration(milliseconds: 300));
      expect(find.text('End the simulation?'), findsOneWidget);
      expect(find.text('CONTINUE PRANK'), findsOneWidget);
      expect(find.text('EXIT SAFELY'), findsOneWidget);
      return () => result;
    }

    testWidgets('EXIT SAFELY resolves to true', (tester) async {
      final result = await openDialog(tester);
      await tester.tap(find.text('EXIT SAFELY'));
      await pumpFor(tester, const Duration(milliseconds: 300));
      expect(result(), isTrue);
      expect(find.text('End the simulation?'), findsNothing);
    });

    testWidgets('CONTINUE PRANK resolves to false', (tester) async {
      final result = await openDialog(tester);
      await tester.tap(find.text('CONTINUE PRANK'));
      await pumpFor(tester, const Duration(milliseconds: 300));
      expect(result(), isFalse);
      expect(find.text('End the simulation?'), findsNothing);
    });

    testWidgets('dismissing the dialog continues the prank', (tester) async {
      final result = await openDialog(tester);
      await tester.tapAt(const Offset(5, 5)); // Tap the barrier.
      await pumpFor(tester, const Duration(milliseconds: 300));
      expect(result(), isFalse);
    });
  });

  testWidgets('the simulation honours the system reduce-motion setting', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    final s = TestServices(const PrankSettings(countdownSeconds: 15));
    await launchApp(tester, s);
    await pumpFor(tester, const Duration(seconds: 3));
    expect(find.byType(PrankScreen), findsOneWidget);
    // Typewriter disabled by the system setting: all lines shown at once.
    expect(find.textContaining('SCANNING SIMULATED ENVIRONMENT'), findsOneWidget);
    s.shake.shake();
    await pumpFor(tester, const Duration(milliseconds: 800));
    expect(find.byType(RevealScreen), findsOneWidget);
  });
}
