import 'package:flutter_test/flutter_test.dart';
import 'package:hack_prank/core/services/preferences_service.dart';
import 'package:hack_prank/core/services/shake_detector.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('loads defaults on first launch', () async {
    final c = await SettingsController.load();
    expect(c.value, const PrankSettings());
    expect(c.value.countdownSeconds, 30);
    expect(c.value.autoReveal, isTrue);
    expect(c.value.shakeSensitivity, ShakeSensitivity.medium);
  });

  test('changes apply immediately and persist across restarts', () async {
    final c = await SettingsController.load();
    var notified = 0;
    c.addListener(() => notified++);

    await c.update(
      c.value.copyWith(
        countdownSeconds: 45,
        shakeSensitivity: ShakeSensitivity.high,
        vibration: false,
        robotVoice: false,
        masterVolume: 0.3,
        reduceMotion: true,
        exitConfirmation: false,
      ),
    );
    expect(notified, 1);
    expect(c.value.countdownSeconds, 45);

    // Simulate an app restart by loading a fresh controller.
    final restarted = await SettingsController.load();
    expect(restarted.value.countdownSeconds, 45);
    expect(restarted.value.shakeSensitivity, ShakeSensitivity.high);
    expect(restarted.value.vibration, isFalse);
    expect(restarted.value.robotVoice, isFalse);
    expect(restarted.value.masterVolume, 0.3);
    expect(restarted.value.reduceMotion, isTrue);
    expect(restarted.value.exitConfirmation, isFalse);
    expect(restarted.value, c.value);
  });

  test('updating with identical settings does not notify', () async {
    final c = await SettingsController.load();
    var notified = 0;
    c.addListener(() => notified++);
    await c.update(c.value.copyWith());
    expect(notified, 0);
  });

  test('invalid stored values fall back to safe defaults', () async {
    SharedPreferences.setMockInitialValues({
      'countdown_seconds': 999,
      'master_volume': 7.5,
      'shake_sensitivity': 'extreme',
    });
    final c = await SettingsController.load();
    expect(c.value.countdownSeconds, 30);
    expect(c.value.masterVolume, 1.0);
    expect(c.value.shakeSensitivity, ShakeSensitivity.medium);
  });

  test('reset restores and persists defaults', () async {
    final c = await SettingsController.load();
    await c.update(c.value.copyWith(countdownSeconds: 60, shakeSensitivity: ShakeSensitivity.low));
    await c.reset();
    final restarted = await SettingsController.load();
    expect(restarted.value, const PrankSettings());
  });

  test('there is no setting that can disable the reveal or exit controls', () {
    final keys = const PrankSettings().toMap().keys;
    for (final forbidden in ['disable_reveal', 'hide_exit', 'lock_device', 'block_back']) {
      expect(keys, isNot(contains(forbidden)));
    }
  });
}
