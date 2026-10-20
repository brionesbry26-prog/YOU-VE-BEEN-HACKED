import 'package:flutter/widgets.dart';

import 'services/audio_service.dart';
import 'services/device_services.dart';
import 'services/haptics_service.dart';
import 'services/preferences_service.dart';

/// The app's dependencies, created once at start-up and swapped for fakes in
/// tests.
class AppServices {
  const AppServices({
    required this.settings,
    required this.audio,
    required this.haptics,
    required this.wakelock,
    required this.share,
  });

  final SettingsController settings;
  final AudioService audio;
  final HapticsService haptics;
  final WakelockService wakelock;
  final ShareService share;

  static AppServices of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppServicesScope>();
    assert(scope != null, 'No AppServicesScope found in the widget tree.');
    return scope!.services;
  }
}

class AppServicesScope extends InheritedWidget {
  const AppServicesScope({
    super.key,
    required this.services,
    required super.child,
  });

  final AppServices services;

  @override
  bool updateShouldNotify(AppServicesScope oldWidget) =>
      services != oldWidget.services;
}
