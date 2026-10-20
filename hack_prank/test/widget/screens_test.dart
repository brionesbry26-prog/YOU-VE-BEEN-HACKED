import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hack_prank/core/app_services.dart';
import 'package:hack_prank/core/constants/prank_constants.dart';
import 'package:hack_prank/core/services/audio_service.dart';
import 'package:hack_prank/core/services/haptics_service.dart';
import 'package:hack_prank/core/services/preferences_service.dart';
import 'package:hack_prank/core/theme/app_theme.dart';
import 'package:hack_prank/features/home/home_screen.dart';
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

void main() {
  group('RansomScreen', () {
    Widget ransom({
      Duration remaining = const Duration(seconds: 10),
      bool expired = false,
      VoidCallback? onReveal,
    }) {
      return Scaffold(
        body: SingleChildScrollView(
          child: RansomScreen(
            remaining: remaining,
            total: const Duration(seconds: 10),
            expired: expired,
            onReveal: onReveal ?? () {},
            fx: EffectFlags.resolve(const PrankSettings()),
          ),
        ),
      );
    }

    testWidgets('shows the ransom note, countdown and button', (tester) async {
      await pumpScreen(tester, TestServices(), ransom());
      expect(find.text('YOUR DEVICE HAS BEEN HACKED!'), findsWidgets);
      expect(find.text('ALL YOUR FILES ARE AT RISK!'), findsOneWidget);
      expect(find.text('TIME REMAINING:'), findsOneWidget);
      expect(find.text('00:10'), findsOneWidget);
      expect(find.text('PAY ₱500 TO RESTORE ACCESS'), findsOneWidget);
      expect(find.text('WAIT... WHAT?!'), findsOneWidget);
      expect(find.text("TIME'S UP... OR IS IT?"), findsNothing);
    });

    testWidgets('has no payment controls or links of any kind', (tester) async {
      await pumpScreen(tester, TestServices(), ransom());
      expect(find.byType(TextField), findsNothing);
      expect(find.textContaining('http'), findsNothing);
      expect(find.textContaining('card number', findRichText: true), findsNothing);
      // The only button is the one that ends the prank.
      expect(find.bySemanticsLabel('WAIT... WHAT?!'), findsOneWidget);
    });

    testWidgets('WAIT... WHAT?! calls onReveal', (tester) async {
      var revealed = 0;
      await pumpScreen(tester, TestServices(), ransom(onReveal: () => revealed++));
      await tester.ensureVisible(find.text('WAIT... WHAT?!'));
      await tester.tap(find.text('WAIT... WHAT?!'));
      expect(revealed, 1);
    });

    testWidgets('shows the expired state at 00:00', (tester) async {
      await pumpScreen(tester, TestServices(), ransom(remaining: Duration.zero, expired: true));
      expect(find.text('00:00'), findsOneWidget);
      expect(find.text("TIME'S UP... OR IS IT?"), findsOneWidget);
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

  group('RevealScreen', () {
    testWidgets('tells the truth clearly and celebrates', (tester) async {
      final s = TestServices();
      await pumpScreen(tester, s, const RevealScreen());
      await pumpFor(tester, const Duration(seconds: 2));

      expect(find.text('GOTCHA! 😂'), findsOneWidget);
      expect(find.text("YOU'VE BEEN PRANKED!"), findsOneWidget);
      expect(find.text('Your phone was never hacked.'), findsOneWidget);
      expect(
        find.text('No files were stolen. No camera was activated. No personal data was accessed.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.verified_user_rounded), findsOneWidget);
      expect(find.text('PLAY AGAIN'), findsOneWidget);
      expect(find.text('BACK TO HOME'), findsOneWidget);
      expect(find.text('SHARE THE JOKE'), findsOneWidget);
      expect(find.text('CAPTURE YOUR REACTION'), findsOneWidget);

      expect(s.audio.audible, [SoundEffect.celebrate]);
      expect(s.haptics.pulses, [HapticCue.reveal]);
      await pumpFor(tester, const Duration(seconds: 3));
    });

    testWidgets('SHARE THE JOKE shares harmless text only', (tester) async {
      final s = TestServices();
      await pumpScreen(tester, s, const RevealScreen());
      await tester.ensureVisible(find.byKey(RevealScreen.shareKey));
      await tester.tap(find.byKey(RevealScreen.shareKey));
      expect(s.share.shared, [PrankConstants.shareText]);
      await pumpFor(tester, const Duration(seconds: 4));
    });

    testWidgets('CAPTURE YOUR REACTION explains first and does not open the camera', (tester) async {
      final s = TestServices();
      await pumpScreen(
        tester,
        s,
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

    testWidgets('works with confetti and motion disabled', (tester) async {
      final s = TestServices(allEffectsOff);
      await pumpScreen(tester, s, const RevealScreen());
      expect(find.text('GOTCHA! 😂'), findsOneWidget);
      expect(s.audio.audible, isEmpty);
      await pumpFor(tester, const Duration(seconds: 1));
    });
  });

  group('SettingsScreen', () {
    testWidgets('shows every section and option', (tester) async {
      await pumpScreen(tester, TestServices(), const SettingsScreen());
      for (final label in [
        'DURATION',
        '15s',
        '30s',
        '45s',
        '60s',
        'Terminal animations',
        'Screen shake',
        'Glitch effects',
        'Warning sounds',
        'Robotic voice',
        'Vibration',
        'Confetti',
        'Reduce motion',
        'Disable flashing transitions',
        'High-contrast text',
        'Larger terminal text',
        'Show reveal shortcut',
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
      expect(s.settings.value.durationSeconds, 60);

      await tester.tap(find.text('Screen shake'));
      await tester.pump();
      expect(s.settings.value.screenShake, isFalse);

      final reduce = find.text('Reduce motion');
      await tester.scrollUntilVisible(reduce, 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(reduce);
      await tester.pump();
      expect(s.settings.value.reduceMotion, isTrue);
    });

    testWidgets('sound previews play through the audio service', (tester) async {
      final s = TestServices(const PrankSettings(robotVoice: false));
      await pumpScreen(tester, s, const SettingsScreen());
      final chip = find.text('Robotic voice').last;
      await tester.scrollUntilVisible(find.text('Reveal celebration'), 200, scrollable: find.byType(Scrollable).first);
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

  testWidgets('HomeScreen honours the system reduce-motion setting', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await pumpScreen(tester, TestServices(), const HomeScreen());
    // No boot sequence and no glitch copies: exactly one title.
    expect(find.text("YOU'VE BEEN HACKED"), findsOneWidget);
    expect(find.text('START THE PRANK'), findsOneWidget);
  });
}
