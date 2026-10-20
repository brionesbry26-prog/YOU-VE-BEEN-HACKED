# You've Been Hacked 😂

A harmless, fully offline, cinematic "hacker movie" prank for Android (and iOS).
The app plays a dramatic fake breach (terminal output, a network trace, fake file
"extraction", a ransom note) and then always ends with a cheerful
**GOTCHA!** that tells the person their phone was never touched.

Everything on screen is fictional and generated inside the app. Nothing is read
from, changed on, locked on, or sent from the device.

---

## Requirements

| Tool | Version |
| --- | --- |
| Flutter | 3.35.x or newer (stable) |
| Dart | 3.9.2 or newer (ships with Flutter) |
| Android | minSdk 24 (Android 7.0), target = Flutter default |
| iOS | Flutter default (13+) |

All package versions in `pubspec.yaml` were chosen as the newest releases that
still support Flutter 3.35.

## Setup and run

```bash
cd hack_prank
flutter pub get
flutter run            # pick an Android emulator or a connected phone
```

## Tests and analysis

```bash
flutter analyze
flutter test
```

| Folder | What it covers |
| --- | --- |
| `test/unit/prank_controller_test.dart` | Stage transitions, the timeline, the countdown, reveal from every stage, duplicate prevention, pause/resume (lifecycle), exit, dispose and timer cancellation, fictional IP ranges |
| `test/unit/settings_test.dart` | Defaults, persistence across restarts, invalid stored values, reset |
| `test/unit/effects_test.dart` | Audio and vibration toggles, master volume, the effects director (stop/resume), reduced-motion flags |
| `test/unit/privacy_guard_test.dart` | No sensitive Android permissions, no networking or data packages, camera only on the reaction screen, audio from bundled assets only |
| `test/widget/home_screen_test.dart` | Home screen content and navigation |
| `test/widget/prank_screen_test.dart` | Full run with auto reveal, the Reveal shortcut on every stage, triple-tap reveal, exit confirmation, back gesture, backgrounding/resuming, everything disabled, Play Again |
| `test/widget/screens_test.dart` | Ransom screen, reveal screen, share, reaction explanation, settings screen, exit dialog, system reduce motion |

## Build an Android APK

```bash
flutter build apk --release          # build/app/outputs/flutter-apk/app-release.apk
flutter build appbundle --release    # for the Play Store
```

The release build is still signed with the debug key, as in the Flutter
template. Before publishing, set up your own signing config in
`android/app/build.gradle.kts` and change `applicationId` from
`com.example.hack_prank`.

---

## How it works

```
lib/
  main.dart                  Loads settings, creates services, runs the app
  app.dart                   MaterialApp + dependency scope
  app_routes.dart            Named routes with a fade transition
  core/
    app_services.dart        Settings, audio, haptics, wakelock, share (injectable)
    constants/prank_constants.dart   All fictional data (files, lines, location, ₱500)
    theme/app_colors.dart, app_theme.dart
    services/
      preferences_service.dart   PrankSettings + SettingsController (shared_preferences)
      audio_service.dart         Sound effects, SoundPolicy, audioplayers backend
      haptics_service.dart       Short vibration cues (vibration package)
      device_services.dart       Wakelock + share sheet wrappers
  features/
    home/home_screen.dart
    prank/
      prank_stage.dart           State enum, PrankTimeline, fictional PrankSession
      prank_controller.dart      The single state machine
      prank_effects_director.dart  Maps stages to sounds, vibration, wakelock
      prank_screen.dart          Full-screen host, exit/reveal controls, lifecycle
      widgets/                   Terminal, progress bar, warning banner, file list,
                                 countdown, network map, stage views
    ransom/ransom_screen.dart
    reveal/reveal_screen.dart
    reaction/reaction_screen.dart  Optional post-reveal photo
    settings/settings_screen.dart
  shared/
    effect_flags.dart          Settings + system "reduce motion" → effect switches
    widgets/                   Neon button, animated skull, exit dialog, visual effects
```

**State machine.** `PrankController` owns one periodic ticker (100 ms). The
current stage is always derived from elapsed time through `PrankTimeline`:
`idle → initializing → tracing → warning → extracting → simulatedTracking →
breachComplete → ransom → revealed` (or `disposed` on exit). There are no
competing timers. Pausing cancels the ticker and resuming continues from the
same elapsed time, so the countdown never restarts. `reveal()` works from any
stage and only once. After reveal, exit or dispose, nothing can change state
again.

**Timing.** The chosen duration (15/30/45/60 s, default 30 s) is the total time
until the guaranteed reveal. One third is the ransom countdown. The rest is
split between the six stages in the design's 4:5:4:7:4:3 proportions. For 30 s
that gives a 20 s breach sequence and a 10 s countdown.

**State management.** A `ChangeNotifier` plus `InheritedWidget` scope is used
instead of Riverpod. It's the "lightweight, consistent" option from the brief
and keeps the app free of extra dependencies.

## Safety and privacy design

- **Always escapable.** An EXIT button is on every prank screen, and the
  system back gesture works too. Both show "End the simulation?" with
  CONTINUE PRANK / EXIT SAFELY, unless you turn confirmation off. Home and
  app switching are never intercepted. The device is never locked.
- **Reveal guaranteed.** The reveal happens automatically when the time runs
  out. With "Automatically reveal" off, the ransom screen holds at 00:00 for
  8 seconds, then reveals anyway. There's also a visible *Reveal* link, a
  hidden triple-tap on the stage title (always active), and the
  WAIT... WHAT?! button. No setting can disable the reveal.
- **Fictional data only.** File names, sizes, the location ("QUEZON CITY,
  PHILIPPINES") and percentages are constants. The traced IP is random but
  always from the RFC 5737 documentation ranges (192.0.2.x, 198.51.100.x,
  203.0.113.x), so it can never belong to a real device.
- **No network.** No HTTP or networking code, no fonts or sounds downloaded at
  runtime. The release manifest has no `INTERNET` permission. The debug and
  profile manifests keep Flutter's default one for hot reload.
- **No sensitive permissions.** No location, contacts, SMS, storage reading,
  overlays, device admin or accessibility service. The camera plugin's
  `RECORD_AUDIO` permission is removed from the merged manifest.
- **Camera only after the reveal, and only on request.** "Capture your
  reaction" explains what will happen first. Permission is asked only when you
  tap OPEN CAMERA. A photo is taken only when you press the shutter, and it's
  saved only when you tap SAVE (Retake and Discard delete the temporary file).
  Nothing is uploaded, and audio is never recorded.
- **Safe effects.** The flashing is a slow border pulse (about 0.7 Hz, well
  under 3 Hz), never a full-screen strobe. Light sweeps and the red glow are
  in-app overlays only: device brightness and the flashlight are never touched.
  Vibration patterns are under 0.4 s and never repeat. "Reduce motion" (app
  setting or the system setting) turns off shake, glitches, confetti, the
  typewriter and looping animations.
- **Audio.** Sounds play locally from bundled files, at most 4 at once (loop,
  2 alerts, voice). They use an ambient audio session that respects the iOS
  silent switch and Android ringer mode, and mixes with other apps. Everything
  stops on exit, reveal or backgrounding.

## Assets and licences

- `assets/audio/*.wav` are synthesized by `tool/generate_sounds.py` (original
  work, free to use). The robotic voice line is rendered offline with
  espeak-ng and processed to sound robotic. To regenerate:
  `python3 tool/generate_sounds.py` (needs numpy, espeak-ng, ffmpeg).
- `assets/fonts/` contains Share Tech Mono and Rajdhani from Google Fonts,
  licensed under the SIL Open Font License (`OFL-*.txt`). They're bundled so
  that no font is fetched at runtime.

## Platform notes and limitations

- **Targets:** Android first, then iOS. The reaction screen imports `dart:io`
  and the camera plugin, so a **web build is not supported**. Desktop builds
  are not a target either.
- **Vibration:** devices without custom vibration patterns get a single
  standard haptic tap. The OS may suppress vibration in Do Not Disturb or
  silent mode, and the app never overrides that.
- **Silent mode:** on Android, sounds follow the ringer mode and ringer volume
  (they use the notification/ringtone audio stream).
- **Gallery saving:** on Android 10 and older the app asks for storage write
  permission when you tap SAVE. On iOS it asks for Photos "add" access.
- **iOS:** run `flutter build ios` on a Mac. The Info.plist contains camera,
  photo-library and microphone purpose strings. The microphone string is
  required by App Store tooling because the camera plugin links audio APIs,
  but the app never uses the microphone.
