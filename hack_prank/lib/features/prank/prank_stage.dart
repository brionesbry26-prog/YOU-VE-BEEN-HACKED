import 'dart:math';

import '../../core/constants/prank_constants.dart';

/// States of the prank lifecycle, in order.
enum PrankStage {
  idle,
  initializing,
  tracing,
  warning,
  extracting,
  simulatedTracking,
  breachComplete,
  ransom,
  revealed,
  disposed;

  /// The six timed breach stages, in playback order.
  static const sequence = [
    initializing,
    tracing,
    warning,
    extracting,
    simulatedTracking,
    breachComplete,
  ];

  bool get isSequence => sequence.contains(this);

  /// Stages after which nothing else can happen.
  bool get isTerminal => this == revealed || this == disposed;

  /// 1-based position in the breach sequence, or null outside it.
  int? get sequenceNumber => isSequence ? sequence.indexOf(this) + 1 : null;

  String get title => switch (this) {
    idle => 'STANDBY',
    initializing => 'INITIALIZING SYSTEM',
    tracing => 'NETWORK TRACE',
    warning => 'BREACH WARNING',
    extracting => 'FILE EXTRACTION',
    simulatedTracking => 'DEVICE TRACKING',
    breachComplete => 'BREACH COMPLETE',
    ransom => 'ACCESS LOCKED',
    revealed => 'GOTCHA',
    disposed => 'ENDED',
  };
}

/// Maps elapsed time to stages for one prank run.
///
/// The total duration chosen in settings is split so that the ransom countdown
/// gets [PrankConstants.ransomShare] of it and the six breach stages share the
/// rest in proportion to [PrankConstants.stageWeights]. Every boundary is a
/// whole number of ticks, so stage changes are fully deterministic.
class PrankTimeline {
  PrankTimeline._(this.stageDurations, this.ransomDuration, this.tick);

  factory PrankTimeline.forTotal(
    Duration total, {
    Duration tick = PrankConstants.tickInterval,
  }) {
    final tickMs = tick.inMilliseconds;
    final totalTicks = (total.inMilliseconds / tickMs).round();
    final ransomTicks = max(1, (totalTicks * PrankConstants.ransomShare).round());
    final sequenceTicks = totalTicks - ransomTicks;
    const weights = PrankConstants.stageWeights;
    final weightSum = weights.reduce((a, b) => a + b);

    final durations = <PrankStage, Duration>{};
    var used = 0;
    for (var i = 0; i < PrankStage.sequence.length; i++) {
      final isLast = i == PrankStage.sequence.length - 1;
      final ticks = isLast
          ? sequenceTicks - used
          : max(1, (sequenceTicks * weights[i] / weightSum).round());
      used += ticks;
      durations[PrankStage.sequence[i]] = Duration(
        milliseconds: ticks * tickMs,
      );
    }
    return PrankTimeline._(
      Map.unmodifiable(durations),
      Duration(milliseconds: ransomTicks * tickMs),
      tick,
    );
  }

  final Map<PrankStage, Duration> stageDurations;
  final Duration ransomDuration;
  final Duration tick;

  Duration get sequenceDuration =>
      stageDurations.values.fold(Duration.zero, (a, b) => a + b);

  /// Time from the start of the prank until the guaranteed reveal.
  Duration get total => sequenceDuration + ransomDuration;

  Duration durationOf(PrankStage stage) {
    if (stage == PrankStage.ransom) return ransomDuration;
    return stageDurations[stage] ?? Duration.zero;
  }

  Duration startOf(PrankStage stage) {
    if (stage == PrankStage.ransom) return sequenceDuration;
    var start = Duration.zero;
    for (final s in PrankStage.sequence) {
      if (s == stage) return start;
      start += stageDurations[s]!;
    }
    return Duration.zero;
  }

  /// The stage that should be showing [elapsed] after the start. Never
  /// returns [PrankStage.revealed]; the controller decides when to reveal.
  PrankStage stageAt(Duration elapsed) {
    var end = Duration.zero;
    for (final s in PrankStage.sequence) {
      end += stageDurations[s]!;
      if (elapsed < end) return s;
    }
    return PrankStage.ransom;
  }
}

/// Fictional values generated locally for one prank run.
class PrankSession {
  PrankSession({
    required this.traceAddress,
    required this.routeHops,
    required this.hexSeed,
  });

  /// Builds a session from [random]. The address always comes from a range
  /// reserved for documentation (RFC 5737), so it can never be a real device.
  factory PrankSession.generate(Random random) {
    const nets = PrankConstants.documentationNetworks;
    String address() =>
        '${nets[random.nextInt(nets.length)]}.${1 + random.nextInt(254)}';
    return PrankSession(
      traceAddress: address(),
      routeHops: List.generate(5, (_) => address()),
      hexSeed: random.nextInt(1 << 31),
    );
  }

  final String traceAddress;
  final List<String> routeHops;
  final int hexSeed;

  /// Deterministic pseudo-random hex strings for terminal decoration.
  List<String> hexLines(int count, {int length = 32}) {
    final r = Random(hexSeed);
    const chars = '0123456789ABCDEF';
    return List.generate(
      count,
      (_) => List.generate(length, (_) => chars[r.nextInt(16)]).join(),
    );
  }
}
