import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../core/constants/prank_constants.dart';
import 'prank_stage.dart';

/// Side effects (sound, vibration, wakelock) driven by the controller.
abstract class PrankEffects {
  void onStageEntered(PrankStage stage);
  void onPaused();
  void onResumed(PrankStage stage);

  /// Stops every effect immediately. Called on reveal, exit and dispose.
  void stop();
}

class NoopPrankEffects implements PrankEffects {
  const NoopPrankEffects();
  @override
  void onStageEntered(PrankStage stage) {}
  @override
  void onPaused() {}
  @override
  void onResumed(PrankStage stage) {}
  @override
  void stop() {}
}

/// The single authority over a prank run.
///
/// One periodic ticker advances [elapsed]; the current stage is always derived
/// from [elapsed] through the [PrankTimeline], so there are no competing
/// timers and every transition is deterministic. Pausing cancels the ticker
/// and resuming continues from the same [elapsed], so the countdown never
/// restarts. Once revealed or disposed, nothing can change state again.
class PrankController extends ChangeNotifier {
  PrankController({
    required this.timeline,
    this.effects = const NoopPrankEffects(),
    this.autoReveal = true,
    this.revealGracePeriod = PrankConstants.revealGracePeriod,
    Random? random,
  }) : session = PrankSession.generate(random ?? Random());

  final PrankTimeline timeline;
  final PrankEffects effects;

  /// When false, the ransom screen waits at 00:00 for [revealGracePeriod]
  /// before revealing. The reveal itself is always guaranteed.
  final bool autoReveal;
  final Duration revealGracePeriod;
  final PrankSession session;

  PrankStage _stage = PrankStage.idle;
  Duration _elapsed = Duration.zero;
  Timer? _ticker;
  bool _paused = false;
  bool _disposed = false;

  PrankStage get stage => _stage;
  Duration get elapsed => _elapsed;
  bool get isPaused => _paused;
  bool get isRunning => _ticker != null;

  /// True when the ransom countdown has hit zero but the reveal is waiting
  /// (only possible with auto-reveal off).
  bool get countdownExpired =>
      _stage == PrankStage.ransom && _elapsed >= timeline.total;

  /// Progress through the current stage, 0.0 to 1.0.
  double get stageProgress {
    if (_stage.isTerminal) return 1;
    if (!_stage.isSequence && _stage != PrankStage.ransom) return 0;
    final length = timeline.durationOf(_stage).inMilliseconds;
    if (length == 0) return 1;
    final into = (_elapsed - timeline.startOf(_stage)).inMilliseconds;
    return (into / length).clamp(0.0, 1.0);
  }

  /// Progress through the breach sequence (stages 1-6), 0.0 to 1.0.
  double get sequenceProgress {
    final length = timeline.sequenceDuration.inMilliseconds;
    if (length == 0) return 1;
    return (_elapsed.inMilliseconds / length).clamp(0.0, 1.0);
  }

  /// Time left on the ransom countdown.
  Duration get ransomRemaining {
    final left = timeline.total - _elapsed;
    if (left.isNegative) return Duration.zero;
    return left > timeline.ransomDuration ? timeline.ransomDuration : left;
  }

  /// Starts the run. Does nothing unless the controller is idle.
  void start() {
    if (_disposed || _stage != PrankStage.idle) return;
    _elapsed = Duration.zero;
    _enter(PrankStage.initializing);
    _startTicker();
    notifyListeners();
  }

  /// Freezes the run (e.g. app backgrounded or exit dialog open).
  void pause() {
    if (_disposed || _paused || _stage.isTerminal || _stage == PrankStage.idle) {
      return;
    }
    _paused = true;
    _stopTicker();
    effects.onPaused();
    notifyListeners();
  }

  /// Continues a paused run from exactly where it stopped.
  void resume() {
    if (_disposed || !_paused || _stage.isTerminal) return;
    _paused = false;
    effects.onResumed(_stage);
    _startTicker();
    notifyListeners();
  }

  /// Ends the prank and shows the truth. Safe to call from any stage and any
  /// number of times; returns true only for the call that actually revealed.
  bool reveal() {
    if (_disposed || _stage.isTerminal) return false;
    _stopTicker();
    _paused = false;
    effects.stop();
    _stage = PrankStage.revealed;
    notifyListeners();
    return true;
  }

  /// Stops the prank without revealing (user chose "Exit safely").
  void exit() {
    if (_disposed || _stage == PrankStage.disposed) return;
    _stopTicker();
    _paused = false;
    if (_stage != PrankStage.revealed) effects.stop();
    _stage = PrankStage.disposed;
    notifyListeners();
  }

  void _startTicker() {
    _stopTicker();
    _ticker = Timer.periodic(timeline.tick, (_) => _onTick());
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _onTick() {
    if (_disposed || _paused || _stage.isTerminal) {
      _stopTicker();
      return;
    }
    _elapsed += timeline.tick;

    if (_elapsed >= timeline.total) {
      if (_stage != PrankStage.ransom) _enter(PrankStage.ransom);
      final waitedLongEnough = _elapsed >= timeline.total + revealGracePeriod;
      if (autoReveal || waitedLongEnough) {
        reveal();
        return;
      }
      notifyListeners();
      return;
    }

    final target = timeline.stageAt(_elapsed);
    if (target != _stage) _enter(target);
    notifyListeners();
  }

  void _enter(PrankStage stage) {
    _stage = stage;
    effects.onStageEntered(stage);
  }

  @override
  void dispose() {
    if (_disposed) return;
    _stopTicker();
    if (!_stage.isTerminal && _stage != PrankStage.idle) effects.stop();
    _stage = PrankStage.disposed;
    _disposed = true;
    super.dispose();
  }
}
