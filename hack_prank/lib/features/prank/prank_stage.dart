import 'dart:math';

import '../../core/constants/prank_constants.dart';

/// States of the simulation lifecycle, in order.
enum PrankStage {
  idle,

  /// The innocent "I Love You" title card.
  intro,
  initializing,
  activity,
  warning,
  extracting,

  /// The ransom-inspired countdown ("SYSTEM STATUS: COMPROMISED").
  ransom,
  revealed,
  disposed;

  /// The timed stages that play before the countdown, in order.
  static const sequence = [intro, initializing, activity, warning, extracting];

  /// The five numbered stages shown in the status bar.
  static const numbered = [initializing, activity, warning, extracting, ransom];

  bool get isSequence => sequence.contains(this);

  /// Stages after which nothing else can happen.
  bool get isTerminal => this == revealed || this == disposed;

  /// 1-based position among the [numbered] stages, or null outside them.
  int? get stageNumber => numbered.contains(this) ? numbered.indexOf(this) + 1 : null;

  String get title => switch (this) {
    idle => '',
    intro => PrankConstants.appTitle,
    initializing => 'INITIALIZATION',
    activity => 'REMOTE ACTIVITY',
    warning => 'SECURITY ALERT',
    extracting => 'DATA EXTRACTION',
    ransom => 'SYSTEM COMPROMISED',
    revealed => 'AWARENESS',
    disposed => 'ENDED',
  };
}

/// Maps elapsed time to stages for one run.
///
/// The stages before the countdown have fixed lengths
/// ([defaultStageDurations]); the countdown length comes from settings.
/// Every boundary is a whole number of ticks, so stage changes are fully
/// deterministic.
class PrankTimeline {
  PrankTimeline({
    Map<PrankStage, Duration> stageDurations = defaultStageDurations,
    required this.ransomDuration,
    this.tick = PrankConstants.tickInterval,
  }) : stageDurations = Map.unmodifiable(stageDurations) {
    assert(
      PrankStage.sequence.every((s) => (this.stageDurations[s] ?? Duration.zero) > Duration.zero),
      'Every sequence stage needs a duration.',
    );
    assert(
      [...this.stageDurations.values, ransomDuration]
          .every((d) => d.inMicroseconds % tick.inMicroseconds == 0),
      'Stage boundaries must fall on ticks.',
    );
  }

  /// Stage lengths from the design brief: a 1-2 second title card, then the
  /// four breach stages.
  static const defaultStageDurations = {
    PrankStage.intro: Duration(milliseconds: 2200),
    PrankStage.initializing: Duration(seconds: 4),
    PrankStage.activity: Duration(seconds: 5),
    PrankStage.warning: Duration(seconds: 4),
    PrankStage.extracting: Duration(seconds: 5),
  };

  final Map<PrankStage, Duration> stageDurations;
  final Duration ransomDuration;
  final Duration tick;

  Duration get sequenceDuration =>
      stageDurations.values.fold(Duration.zero, (a, b) => a + b);

  /// Time from the start until the countdown hits zero.
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

/// Fictional values generated locally for one run.
class PrankSession {
  PrankSession({
    required this.remoteAddress,
    required this.routeHops,
    required this.hexSeed,
  });

  /// Builds a session from [random]. Addresses always come from ranges
  /// reserved for documentation (RFC 5737), so they can never be real.
  factory PrankSession.generate(Random random) {
    const nets = PrankConstants.documentationNetworks;
    String address() =>
        '${nets[random.nextInt(nets.length)]}.${1 + random.nextInt(254)}';
    return PrankSession(
      remoteAddress: address(),
      routeHops: List.generate(5, (_) => address()),
      hexSeed: random.nextInt(1 << 31),
    );
  }

  final String remoteAddress;
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
