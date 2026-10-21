import 'dart:math' as math;

/// How hard the phone must be shaken to end the simulation.
///
/// Thresholds are peak user acceleration (gravity removed) in m/s². Normal
/// handling, walking and jogging stay well below the low end; a deliberate
/// back-and-forth shake reaches 15-40 m/s².
enum ShakeSensitivity {
  low(20),
  medium(14),
  high(10);

  const ShakeSensitivity(this.threshold);

  final double threshold;

  String get label => switch (this) {
    ShakeSensitivity.low => 'Low (hard shake)',
    ShakeSensitivity.medium => 'Medium',
    ShakeSensitivity.high => 'High (gentle shake)',
  };
}

/// Recognises a deliberate shake from a stream of accelerometer samples.
///
/// Each sample's magnitude is smoothed with an exponential low-pass filter.
/// Every local maximum of the smoothed signal above [threshold] counts as one
/// "peak" (peaks closer than [minPeakGap] are merged). A shake is
/// [requiredPeaks] peaks within [window] — roughly two full back-and-forth
/// movements. A single bump, putting the phone down or walking produces at
/// most one or two peaks, so it never qualifies.
///
/// Samples before [armDelay] are ignored, and after a shake nothing else is
/// reported for [cooldown]. Pure Dart, so it is fully unit-testable.
class ShakeDetector {
  ShakeDetector({
    required this.threshold,
    this.requiredPeaks = 4,
    this.window = const Duration(milliseconds: 1000),
    this.minPeakGap = const Duration(milliseconds: 80),
    this.cooldown = const Duration(milliseconds: 1500),
    this.armDelay = const Duration(milliseconds: 800),
    this.smoothing = 0.6,
  });

  factory ShakeDetector.forSensitivity(ShakeSensitivity sensitivity) =>
      ShakeDetector(threshold: sensitivity.threshold);

  final double threshold;
  final int requiredPeaks;
  final Duration window;
  final Duration minPeakGap;
  final Duration cooldown;
  final Duration armDelay;

  /// Low-pass factor between 0 (ignore new samples) and 1 (no smoothing).
  final double smoothing;

  double? _smoothed;
  double? _previous;
  double? _beforePrevious;
  Duration _previousTime = Duration.zero;
  final List<Duration> _peaks = [];
  Duration? _lastShake;

  /// Feeds one sample taken at [time] (since the detector started). Returns
  /// true exactly when a shake is recognised.
  bool addSample(double x, double y, double z, Duration time) {
    final magnitude = math.sqrt(x * x + y * y + z * z);
    final current = _smoothed == null
        ? magnitude
        : _smoothed! + smoothing * (magnitude - _smoothed!);
    _smoothed = current;

    var shake = false;
    final prev = _previous;
    final prev2 = _beforePrevious;
    // The previous sample is a local maximum above the threshold.
    final isPeak =
        prev != null && prev2 != null && prev >= threshold && prev >= prev2 && prev > current;
    if (isPeak && _armed(time)) {
      final peakTime = _previousTime;
      _peaks.removeWhere((t) => peakTime - t > window);
      if (_peaks.isEmpty || peakTime - _peaks.last >= minPeakGap) {
        _peaks.add(peakTime);
      }
      if (_peaks.length >= requiredPeaks) {
        _peaks.clear();
        _lastShake = time;
        shake = true;
      }
    }

    _beforePrevious = prev;
    _previous = current;
    _previousTime = time;
    return shake;
  }

  bool _armed(Duration time) {
    if (time < armDelay) return false;
    final last = _lastShake;
    return last == null || time - last >= cooldown;
  }

  void reset() {
    _smoothed = _previous = _beforePrevious = null;
    _previousTime = Duration.zero;
    _peaks.clear();
    _lastShake = null;
  }
}
