import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hack_prank/core/constants/prank_constants.dart';
import 'package:hack_prank/features/prank/prank_controller.dart';
import 'package:hack_prank/features/prank/prank_stage.dart';

import '../helpers/fakes.dart';

PrankController build({
  int seconds = 30,
  bool autoReveal = true,
  RecordingEffects? effects,
}) {
  return PrankController(
    timeline: PrankTimeline(ransomDuration: Duration(seconds: seconds)),
    effects: effects ?? RecordingEffects(),
    autoReveal: autoReveal,
    random: Random(1),
  );
}

void main() {
  group('PrankTimeline', () {
    test('uses the brief\'s stage lengths, starting with a short title card', () {
      final t = PrankTimeline(ransomDuration: const Duration(seconds: 30));
      expect(t.stageDurations.keys, PrankStage.sequence);
      expect(PrankStage.sequence.first, PrankStage.intro);
      expect(t.durationOf(PrankStage.intro).inMilliseconds, inInclusiveRange(1000, 2500));
      expect(t.durationOf(PrankStage.initializing), const Duration(seconds: 4));
      expect(t.durationOf(PrankStage.activity), const Duration(seconds: 5));
      expect(t.durationOf(PrankStage.warning), const Duration(seconds: 4));
      expect(t.durationOf(PrankStage.extracting), const Duration(seconds: 5));
      expect(t.durationOf(PrankStage.ransom), const Duration(seconds: 30));
      expect(t.total, t.sequenceDuration + const Duration(seconds: 30));
    });

    for (final seconds in PrankConstants.allowedCountdowns) {
      test('the countdown lasts exactly ${seconds}s', () {
        final t = PrankTimeline(ransomDuration: Duration(seconds: seconds));
        expect(t.total - t.startOf(PrankStage.ransom), Duration(seconds: seconds));
      });
    }

    test('stageAt walks the stages in order and ends on the countdown', () {
      final t = PrankTimeline(ransomDuration: const Duration(seconds: 30));
      final seen = <PrankStage>[];
      for (var ms = 0; ms < t.total.inMilliseconds + 2000; ms += 100) {
        final s = t.stageAt(Duration(milliseconds: ms));
        if (seen.isEmpty || seen.last != s) seen.add(s);
      }
      expect(seen, [...PrankStage.sequence, PrankStage.ransom]);
      expect(t.stageAt(t.startOf(PrankStage.extracting)), PrankStage.extracting);
    });

    test('numbers the five visible stages', () {
      expect(PrankStage.intro.stageNumber, isNull);
      expect(PrankStage.initializing.stageNumber, 1);
      expect(PrankStage.ransom.stageNumber, 5);
    });
  });

  group('PrankController stage transitions', () {
    test('runs every stage in order and reveals automatically at the end', () {
      fakeAsync((async) {
        final effects = RecordingEffects();
        final c = build(effects: effects);
        expect(c.stage, PrankStage.idle);

        c.start();
        expect(c.stage, PrankStage.intro);

        async.elapse(c.timeline.total - const Duration(milliseconds: 100));
        expect(c.stage, PrankStage.ransom);

        async.elapse(const Duration(milliseconds: 100));
        expect(c.stage, PrankStage.revealed);
        expect(effects.entered, [...PrankStage.sequence, PrankStage.ransom]);
        expect(effects.stops, 1);
        expect(async.pendingTimers, isEmpty, reason: 'ticker cancelled');
        c.dispose();
      });
    });

    test('each stage begins exactly at its scheduled time', () {
      fakeAsync((async) {
        final c = build()..start();
        for (final stage in [...PrankStage.sequence.skip(1), PrankStage.ransom]) {
          final start = c.timeline.startOf(stage);
          async.elapse(start - c.elapsed - const Duration(milliseconds: 100));
          expect(c.stage, isNot(stage));
          async.elapse(const Duration(milliseconds: 100));
          expect(c.stage, stage);
        }
        c.dispose();
      });
    });

    test('notifies listeners while running and never after dispose', () {
      fakeAsync((async) {
        final c = build()..start();
        var count = 0;
        c.addListener(() => count++);
        async.elapse(const Duration(seconds: 1));
        expect(count, 10);
        c.dispose();
        async.elapse(const Duration(seconds: 5));
        expect(async.pendingTimers, isEmpty);
      });
    });
  });

  group('countdown', () {
    test('starts at the ransom duration and counts down to zero', () {
      fakeAsync((async) {
        final c = build(seconds: 30)..start();
        async.elapse(c.timeline.sequenceDuration);
        expect(c.stage, PrankStage.ransom);
        expect(c.ransomRemaining, c.timeline.ransomDuration);

        async.elapse(const Duration(seconds: 1));
        expect(c.ransomRemaining, c.timeline.ransomDuration - const Duration(seconds: 1));
        expect(c.stageProgress, closeTo(1 / c.timeline.ransomDuration.inSeconds, 0.001));
        c.dispose();
      });
    });

    test('with auto-reveal off it holds at 00:00 but still reveals after the grace period', () {
      fakeAsync((async) {
        final c = build(seconds: 15, autoReveal: false)..start();
        async.elapse(c.timeline.total);
        expect(c.stage, PrankStage.ransom);
        expect(c.countdownExpired, isTrue);
        expect(c.ransomRemaining, Duration.zero);

        async.elapse(PrankConstants.revealGracePeriod - const Duration(milliseconds: 100));
        expect(c.stage, PrankStage.ransom);
        async.elapse(const Duration(milliseconds: 100));
        expect(c.stage, PrankStage.revealed);
        expect(async.pendingTimers, isEmpty);
        c.dispose();
      });
    });
  });

  group('reveal', () {
    for (final stage in [...PrankStage.sequence, PrankStage.ransom]) {
      test('works from ${stage.name}', () {
        fakeAsync((async) {
          final effects = RecordingEffects();
          final c = build(effects: effects)..start();
          async.elapse(c.timeline.startOf(stage));
          expect(c.stage, stage);

          expect(c.reveal(), isTrue);
          expect(c.stage, PrankStage.revealed);
          expect(effects.stops, 1);
          expect(async.pendingTimers, isEmpty);
          c.dispose();
        });
      });
    }

    test('can only happen once', () {
      fakeAsync((async) {
        final effects = RecordingEffects();
        final c = build(effects: effects)..start();
        var notifications = 0;
        c.addListener(() => notifications++);

        expect(c.reveal(), isTrue);
        expect(c.reveal(), isFalse);
        async.elapse(const Duration(minutes: 2));
        expect(notifications, 1);
        expect(effects.stops, 1);
        c.dispose();
        expect(effects.stops, 1, reason: 'dispose after reveal does not stop again');
      });
    });

    test('works while paused', () {
      fakeAsync((async) {
        final c = build()..start();
        c.pause();
        expect(c.reveal(), isTrue);
        expect(c.stage, PrankStage.revealed);
        c.dispose();
      });
    });
  });

  group('duplicate prevention', () {
    test('start is ignored once running and only one ticker ever exists', () {
      fakeAsync((async) {
        final effects = RecordingEffects();
        final c = build(effects: effects)..start();
        c.start();
        c.resume();
        expect(async.periodicTimerCount, 1);
        expect(effects.entered, [PrankStage.intro]);

        async.elapse(const Duration(seconds: 1));
        expect(c.elapsed, const Duration(seconds: 1), reason: 'no double ticking');
        c.dispose();
      });
    });

    test('pause and resume are idempotent', () {
      fakeAsync((async) {
        final effects = RecordingEffects();
        final c = build(effects: effects)..start();
        c
          ..pause()
          ..pause();
        expect(effects.pauses, 1);
        c
          ..resume()
          ..resume();
        expect(effects.resumes, 1);
        expect(async.periodicTimerCount, 1);
        c.dispose();
      });
    });
  });

  group('lifecycle interruption', () {
    test('pausing freezes time and resuming continues without restarting', () {
      fakeAsync((async) {
        final c = build(seconds: 30)..start();
        async.elapse(c.timeline.sequenceDuration + const Duration(seconds: 3));
        final remaining = c.ransomRemaining;
        expect(c.stage, PrankStage.ransom);

        c.pause();
        expect(async.pendingTimers, isEmpty);
        async.elapse(const Duration(minutes: 5));
        expect(c.stage, PrankStage.ransom);
        expect(c.ransomRemaining, remaining);

        c.resume();
        async.elapse(const Duration(seconds: 1));
        expect(c.ransomRemaining, remaining - const Duration(seconds: 1));
        async.elapse(remaining);
        expect(c.stage, PrankStage.revealed);
        c.dispose();
      });
    });
  });

  group('exit and disposal', () {
    test('exit stops effects and timers and blocks further changes', () {
      fakeAsync((async) {
        final effects = RecordingEffects();
        final c = build(effects: effects)..start();
        async.elapse(const Duration(seconds: 5));
        c.exit();
        expect(c.stage, PrankStage.disposed);
        expect(effects.stops, 1);
        expect(async.pendingTimers, isEmpty);

        c
          ..start()
          ..resume();
        expect(c.reveal(), isFalse);
        async.elapse(const Duration(minutes: 1));
        expect(c.stage, PrankStage.disposed);
        c.dispose();
        expect(effects.stops, 1);
      });
    });

    test('dispose mid-run stops effects and cancels the ticker', () {
      fakeAsync((async) {
        final effects = RecordingEffects();
        final c = build(effects: effects)..start();
        async.elapse(const Duration(seconds: 3));
        c.dispose();
        expect(effects.stops, 1);
        expect(async.pendingTimers, isEmpty);
        c.dispose(); // A second dispose is harmless.
      });
    });

    test('a new controller starts from a clean state (play again)', () {
      fakeAsync((async) {
        final first = build()..start();
        async.elapse(const Duration(seconds: 25));
        first.reveal();
        first.dispose();

        final second = build()..start();
        expect(second.stage, PrankStage.intro);
        expect(second.elapsed, Duration.zero);
        expect(second.countdownExpired, isFalse);
        expect(second.ransomRemaining, second.timeline.ransomDuration);
        second.dispose();
      });
    });
  });

  group('fictional session data', () {
    test('trace addresses always come from RFC 5737 documentation ranges', () {
      for (var seed = 0; seed < 200; seed++) {
        final session = PrankSession.generate(Random(seed));
        for (final ip in [session.remoteAddress, ...session.routeHops]) {
          final prefix = ip.substring(0, ip.lastIndexOf('.'));
          expect(PrankConstants.documentationNetworks, contains(prefix));
          final last = int.parse(ip.split('.').last);
          expect(last, inInclusiveRange(1, 254));
        }
      }
    });
  });
}
