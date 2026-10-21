import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:hack_prank/core/services/preferences_service.dart';
import 'package:hack_prank/core/services/shake_detector.dart';
import 'package:hack_prank/core/services/shake_service.dart';
import 'package:sensors_plus/sensors_plus.dart';

typedef Signal = (double, double, double) Function(double t);

/// A back-and-forth hand shake: [amplitude] m/s² at [hz], with some
/// cross-axis motion as real shakes have.
Signal shake(double amplitude, double hz) => (t) => (
  amplitude * math.sin(2 * math.pi * hz * t),
  0.3 * amplitude * math.cos(2 * math.pi * hz * t),
  0.2 * amplitude * math.sin(4 * math.pi * hz * t),
);

(double, double, double) walking(double t) => (
  1.5 * math.sin(2 * math.pi * 2 * t),
  3.5 * math.sin(2 * math.pi * t).abs(),
  1.0,
);

(double, double, double) jogging(double t) => (
  4 * math.sin(2 * math.pi * 1.4 * t),
  9 * math.sin(2 * math.pi * 1.4 * t).abs(),
  2.0,
);

/// Putting the phone down hard on a table: one sharp spike.
(double, double, double) bump(double t) =>
    (0.0, 0.0, 30 * math.exp(-math.pow((t - 2.0) / 0.03, 2)));

/// Two knocks a quarter of a second apart.
(double, double, double) doubleBump(double t) => (
  0.0,
  0.0,
  30 * math.exp(-math.pow((t - 2.0) / 0.03, 2)) +
      25 * math.exp(-math.pow((t - 2.25) / 0.03, 2)),
);

/// Feeds [seconds] of [signal] at 50 Hz (the sensor's game interval) with a
/// little sensor noise, and returns the times (s) at which shakes fired.
List<double> run(Signal signal, ShakeSensitivity sensitivity, {double seconds = 6}) {
  final detector = ShakeDetector.forSensitivity(sensitivity);
  final noise = math.Random(1);
  double n() => noise.nextDouble() * 1.2 - 0.6;
  final hits = <double>[];
  for (var i = 0; i < seconds * 50; i++) {
    final t = i / 50;
    final (x, y, z) = signal(t);
    if (detector.addSample(x + n(), y + n(), z + n(), Duration(milliseconds: i * 20))) {
      hits.add(t);
    }
  }
  return hits;
}

void main() {
  group('ShakeDetector', () {
    test('a deliberate shake is recognised quickly at every sensitivity', () {
      for (final s in ShakeSensitivity.values) {
        final hits = run(shake(30, 4), s);
        expect(hits, isNotEmpty, reason: s.name);
        expect(hits.first, lessThan(1.6), reason: 'within ~0.8 s of arming');
      }
      expect(run(shake(25, 3), ShakeSensitivity.medium), isNotEmpty);
    });

    test('ordinary movement never triggers it', () {
      for (final s in ShakeSensitivity.values) {
        expect(run(walking, s, seconds: 10), isEmpty, reason: 'walking, ${s.name}');
        expect(run(jogging, s, seconds: 10), isEmpty, reason: 'jogging, ${s.name}');
        expect(run(bump, s), isEmpty, reason: 'single bump, ${s.name}');
        expect(run(doubleBump, s), isEmpty, reason: 'double bump, ${s.name}');
      }
    });

    test('sensitivity controls how hard the shake must be', () {
      expect(run(shake(16, 4), ShakeSensitivity.low), isEmpty);
      expect(run(shake(16, 4), ShakeSensitivity.medium), isNotEmpty);
      expect(run(shake(12, 4), ShakeSensitivity.medium), isEmpty);
      expect(run(shake(12, 4), ShakeSensitivity.high), isNotEmpty);
    });

    test('samples before the arming delay are ignored', () {
      final hits = run(shake(30, 4), ShakeSensitivity.medium);
      expect(hits.first, greaterThanOrEqualTo(0.8));
    });

    test('a cooldown follows each shake (debounce)', () {
      final hits = run(shake(30, 4), ShakeSensitivity.medium);
      expect(hits.length, greaterThan(1));
      for (var i = 1; i < hits.length; i++) {
        expect(hits[i] - hits[i - 1], greaterThanOrEqualTo(1.5));
      }
    });

    test('reset forgets partial shakes', () {
      final d = ShakeDetector(threshold: 14, armDelay: Duration.zero);
      var fired = false;
      for (var i = 0; i < 20; i++) {
        final t = i / 50;
        fired |= d.addSample(30 * math.sin(2 * math.pi * 4 * t), 0.0, 0.0, Duration(milliseconds: i * 20));
      }
      expect(fired, isFalse, reason: 'only 0.4 s of shaking so far');
      d.reset();
      for (var i = 20; i < 30; i++) {
        final t = i / 50;
        fired |= d.addSample(30 * math.sin(2 * math.pi * 4 * t), 0.0, 0.0, Duration(milliseconds: i * 20));
      }
      expect(fired, isFalse, reason: 'earlier peaks were discarded');
    });
  });

  group('AccelerometerShakeSensor', () {
    test('listens only while started and reports a shake once', () async {
      final events = StreamController<UserAccelerometerEvent>.broadcast();
      final sensor = AccelerometerShakeSensor(
        SettingsController.inMemory(),
        events: () => events.stream,
      );
      var shakes = 0;
      expect(sensor.isListening, isFalse);
      sensor.start(() => shakes++);
      expect(sensor.isListening, isTrue);
      expect(events.hasListener, isTrue);

      sensor.stop();
      expect(sensor.isListening, isFalse);
      await Future<void>.delayed(Duration.zero);
      expect(events.hasListener, isFalse, reason: 'sensor subscription released');
      expect(shakes, 0);
      unawaited(events.close());
    });

    test('a sensor error stops listening instead of crashing', () async {
      final events = StreamController<UserAccelerometerEvent>();
      final sensor = AccelerometerShakeSensor(
        SettingsController.inMemory(),
        events: () => events.stream,
      );
      sensor.start(() {});
      events.addError(StateError('no accelerometer'));
      await Future<void>.delayed(Duration.zero);
      expect(sensor.isListening, isFalse);
      unawaited(events.close());
    });
  });
}
