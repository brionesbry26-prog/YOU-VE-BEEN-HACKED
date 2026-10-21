import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the screen awake while a prank is running.
abstract class WakelockService {
  Future<void> enable();
  Future<void> disable();
}

class WakelockPlusService implements WakelockService {
  @override
  Future<void> enable() => _guard(WakelockPlus.enable);

  @override
  Future<void> disable() => _guard(WakelockPlus.disable);

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      debugPrint('Wakelock unavailable: $e');
    }
  }
}
