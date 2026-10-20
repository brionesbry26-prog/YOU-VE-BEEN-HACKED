import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hack_prank/app.dart';
import 'package:hack_prank/core/app_services.dart';
import 'package:hack_prank/core/services/audio_service.dart';
import 'package:hack_prank/core/services/device_services.dart';
import 'package:hack_prank/core/services/haptics_service.dart';
import 'package:hack_prank/core/services/preferences_service.dart';
import 'package:hack_prank/features/prank/prank_controller.dart';
import 'package:hack_prank/features/prank/prank_stage.dart';

/// Records audio calls, applying the real [SoundPolicy] so tests can check
/// which sounds would actually be audible.
class FakeAudioService implements AudioService {
  FakeAudioService(this.settings);

  final SettingsController settings;
  final List<SoundEffect> audible = [];
  final List<SoundEffect> previews = [];
  SoundEffect? loop;
  int prankStops = 0;
  int allStops = 0;

  @override
  Future<void> init() async {}

  @override
  Future<void> play(SoundEffect effect, {bool preview = false}) async {
    if (SoundPolicy.volumeFor(effect, settings.value, preview: preview) > 0) {
      (preview ? previews : audible).add(effect);
    }
  }

  @override
  Future<void> startLoop(SoundEffect effect) async {
    if (SoundPolicy.volumeFor(effect, settings.value) > 0) {
      loop = effect;
      audible.add(effect);
    } else {
      loop = null;
    }
  }

  @override
  Future<void> stopLoop() async {
    loop = null;
  }

  @override
  Future<void> stopPrankAudio() async {
    loop = null;
    prankStops++;
  }

  @override
  Future<void> stopAll() async {
    await stopPrankAudio();
    allStops++;
  }

  @override
  Future<void> dispose() async {}
}

class FakeHaptics implements HapticsService {
  FakeHaptics(this.settings);

  final SettingsController settings;
  final List<HapticCue> pulses = [];
  int cancels = 0;

  @override
  Future<void> pulse(HapticCue cue) async {
    if (HapticPolicy.allowed(settings.value)) pulses.add(cue);
  }

  @override
  Future<void> cancel() async {
    cancels++;
  }
}

class FakeWakelock implements WakelockService {
  bool enabled = false;

  @override
  Future<void> enable() async {
    enabled = true;
  }

  @override
  Future<void> disable() async {
    enabled = false;
  }
}

class FakeShare implements ShareService {
  final List<String> shared = [];

  @override
  Future<void> shareText(String text) async {
    shared.add(text);
  }
}

class TestServices {
  TestServices([PrankSettings settings = const PrankSettings()])
    : settings = SettingsController.inMemory(settings) {
    audio = FakeAudioService(this.settings);
    haptics = FakeHaptics(this.settings);
  }

  final SettingsController settings;
  late final FakeAudioService audio;
  late final FakeHaptics haptics;
  final FakeWakelock wakelock = FakeWakelock();
  final FakeShare share = FakeShare();

  AppServices get services => AppServices(
    settings: settings,
    audio: audio,
    haptics: haptics,
    wakelock: wakelock,
    share: share,
  );
}

/// Records every effect callback from a [PrankController].
class RecordingEffects implements PrankEffects {
  final List<PrankStage> entered = [];
  int pauses = 0;
  int resumes = 0;
  int stops = 0;

  @override
  void onStageEntered(PrankStage stage) => entered.add(stage);

  @override
  void onPaused() => pauses++;

  @override
  void onResumed(PrankStage stage) => resumes++;

  @override
  void stop() => stops++;
}

/// Uses a typical phone-sized screen (360x780 logical pixels).
void usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> pumpApp(WidgetTester tester, TestServices s) async {
  usePhoneScreen(tester);
  await tester.pumpWidget(HackPrankApp(services: s.services));
  // Let the boot animation finish.
  await pumpFor(tester, const Duration(seconds: 2));
}

/// Advances fake time in small steps so periodic timers and frames run.
Future<void> pumpFor(
  WidgetTester tester,
  Duration total, {
  Duration step = const Duration(milliseconds: 100),
}) async {
  var elapsed = Duration.zero;
  while (elapsed < total) {
    await tester.pump(step);
    elapsed += step;
  }
}

/// Settings with every optional effect turned off.
const allEffectsOff = PrankSettings(
  durationSeconds: 15,
  terminalAnimations: false,
  screenShake: false,
  glitchEffects: false,
  soundEnabled: false,
  typingSounds: false,
  warningSounds: false,
  robotVoice: false,
  vibration: false,
  confetti: false,
  reduceMotion: true,
  disableFlashing: true,
);
