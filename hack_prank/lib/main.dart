import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/app_services.dart';
import 'core/services/audio_service.dart';
import 'core/services/device_services.dart';
import 'core/services/haptics_service.dart';
import 'core/services/preferences_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF050505),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final settings = await SettingsController.load();
  final audio = AudioPlayersAudioService(settings);
  // Prepare the players in the background; sounds are optional.
  unawaited(audio.init());

  runApp(
    HackPrankApp(
      services: AppServices(
        settings: settings,
        audio: audio,
        haptics: VibrationHapticsService(settings),
        wakelock: WakelockPlusService(),
        share: SystemShareService(),
      ),
    ),
  );
}
