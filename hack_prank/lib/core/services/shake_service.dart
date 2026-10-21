import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'preferences_service.dart';
import 'shake_detector.dart';

/// Listens for a deliberate shake while the simulation runs.
abstract class ShakeSensor {
  /// Starts listening (replacing any previous listener). [onShake] is called
  /// once per recognised shake.
  void start(VoidCallback onShake);

  /// Stops listening and releases the sensor.
  void stop();

  bool get isListening;
}

/// [ShakeSensor] backed by the `sensors_plus` user accelerometer (gravity
/// removed). Needs no permission on Android; on iOS the Info.plist motion
/// purpose string covers it. Devices without an accelerometer simply never
/// report a shake — the countdown still ends the simulation.
class AccelerometerShakeSensor implements ShakeSensor {
  AccelerometerShakeSensor(this._settings, {Stream<UserAccelerometerEvent> Function()? events})
    : _events = events ??
          (() => userAccelerometerEventStream(samplingPeriod: SensorInterval.gameInterval));

  final SettingsController _settings;
  final Stream<UserAccelerometerEvent> Function() _events;
  final Stopwatch _clock = Stopwatch();
  StreamSubscription<UserAccelerometerEvent>? _subscription;

  @override
  bool get isListening => _subscription != null;

  @override
  void start(VoidCallback onShake) {
    stop();
    final detector = ShakeDetector.forSensitivity(_settings.value.shakeSensitivity);
    _clock
      ..reset()
      ..start();
    try {
      _subscription = _events().listen(
        (e) {
          if (detector.addSample(e.x, e.y, e.z, _clock.elapsed)) onShake();
        },
        onError: (Object e) {
          debugPrint('Accelerometer unavailable: $e');
          stop();
        },
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('Accelerometer unavailable: $e');
      _subscription = null;
    }
  }

  @override
  void stop() {
    final subscription = _subscription;
    _subscription = null;
    _clock.stop();
    if (subscription != null) unawaited(subscription.cancel());
  }
}
