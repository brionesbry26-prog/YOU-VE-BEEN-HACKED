import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
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

/// Opens the platform share sheet. Only plain text is ever shared.
abstract class ShareService {
  Future<void> shareText(String text);
}

class SystemShareService implements ShareService {
  @override
  Future<void> shareText(String text) async {
    try {
      await SharePlus.instance.share(
        ShareParams(text: text, subject: "You've Been Hacked 😂"),
      );
    } catch (e) {
      debugPrint('Share unavailable: $e');
    }
  }
}
