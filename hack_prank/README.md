# I Love You

*A cybersecurity awareness experience.*

The app looks innocent: a white heart icon, and a quiet "I Love You" when it
opens. Within two seconds it cuts to a cinematic, entirely fictional hacking
simulation. When the person **shakes the phone** (or the countdown runs out),
it stops and delivers the lesson:

> **DON'T INSTALL UNKNOWN APPS. THINK BEFORE YOU CLICK.**

The name is a nod to the real 2000 "ILOVEYOU" worm, which spread because
people opened an unexpected attachment. Nothing in this app is real: no data
is read, changed, locked or sent, and the phone's normal controls keep working
throughout.

---

## Requirements

| Tool | Version |
| --- | --- |
| Flutter | 3.35.x or newer (stable) |
| Dart | 3.9.2 or newer (ships with Flutter) |
| Android | minSdk 24 (Android 7.0) |
| iOS | Flutter default (13+) |

All package versions in `pubspec.yaml` were chosen as the newest releases that
still support Flutter 3.35.

## Setup, run, test

```bash
cd hack_prank
flutter pub get
flutter analyze
flutter test
flutter run      # an emulator works, but use a real phone to try shake-to-reveal
```

On an Android emulator you can test shaking under *Extended controls →
Virtual sensors → Move*. The countdown also ends the simulation on its own.

## Build an Android APK

```bash
flutter build apk --release          # build/app/outputs/flutter-apk/app-release.apk
flutter build appbundle --release    # for the Play Store
```

The release build still uses the debug signing key from the Flutter template.
Before publishing, set up your own signing in `android/app/build.gradle.kts`
and change `applicationId` from `com.example.hack_prank`.

---

## The experience

| # | Stage | Length | What happens |
| --- | --- | --- | --- |
| – | Title card | 2.2 s | Black screen, "I Love You" fades in and out, plus a soft startup tone |
| 1 | Initialization | 4 s | Typed terminal lines, blinking cursor, hex strings, progress bar, typing and background noise |
| 2 | Remote activity | 5 s | "REMOTE CONNECTION DETECTED", a network map lighting up, file-processing rows, "DATA TRANSFER: 47%" |
| 3 | Security alert | 4 s | Red "SECURITY ALERT / SIMULATED SYSTEM BREACH DETECTED" banner, brief shake, glitch, alarm |
| 4 | Extraction | 5 s | `photo_collection.jpg`, `contacts_backup.vcf`, `messages_archive.txt`, `personal_documents.pdf` "transferring" |
| 5 | Countdown | 30 s* | "SYSTEM STATUS: COMPROMISED", "SIMULATION IN PROGRESS", "TIME REMAINING: 00:30", heartbeat sound, robotic announcement |
| – | Lesson | – | The awareness screen (black, white type, green shield) |

\* The countdown can be 15/30/45/60 s, set in Settings.

**Ways it ends.** All of them lead to the lesson screen:
- **Shake the phone.** Shake detection is armed from stage 1, not during the title card.
- **The countdown reaches 00:00.** This always happens, so there is always an end state.
- **The discreet ✕ or the system back gesture**, then "End the simulation?" and **EXIT SAFELY**.
- **Triple-tap the stage title.** This is a hidden fallback for people who can't shake a phone.

Home, recents and every other system control keep working. The simulation
pauses when the app goes to the background and continues on return, so the
countdown never restarts.

There is no home screen. **Settings** (countdown length, shake sensitivity,
sound, accessibility) and **Replay** are on the lesson screen.

## How it works

```
lib/
  main.dart, app.dart, app_routes.dart   App opens straight into PrankScreen ("/")
  core/
    app_services.dart                    Settings, audio, haptics, wakelock, shake sensor
    constants/prank_constants.dart       All fictional data and every on-screen line
    services/
      shake_detector.dart                Pure-Dart shake recognition (unit-tested)
      shake_service.dart                 sensors_plus user accelerometer → detector
      audio_service.dart                 Bundled sounds, SoundPolicy, overlap limits
      haptics_service.dart               Short vibration cues
      preferences_service.dart           PrankSettings + persistence
      device_services.dart               Wakelock
  features/
    prank/
      prank_stage.dart                   Stage enum, PrankTimeline, fictional session data
      prank_controller.dart              The single deterministic state machine
      prank_effects_director.dart        Stage → sound, vibration, wakelock, shake sensor
      prank_screen.dart                  Title card, terminal, ✕/back/lifecycle handling
      widgets/                           Terminal, progress bar, banner, file list, network map…
    ransom/ransom_screen.dart            Stage 5 countdown (no payment, no buttons)
    reveal/reveal_screen.dart            The cybersecurity lesson
    reaction/reaction_screen.dart        Optional post-reveal reaction photo
    settings/settings_screen.dart
```

**State machine.** `PrankController` owns a single 100 ms ticker. The stage is
always derived from elapsed time:
`idle → intro → initializing → activity → warning → extracting → ransom → revealed`
(or `disposed`). `reveal()` works from any stage, only once. It cancels the
ticker and calls the effects director's `stop()`, which stops all audio,
cancels vibration, releases the wakelock and unsubscribes from the
accelerometer.

**Shake detection.** `ShakeDetector` low-pass filters the magnitude of the
gravity-free accelerometer at 50 Hz and counts local peaks above a threshold.
A shake is 4 peaks within 1 s, which is about two back-and-forth movements.
It ignores the first 0.8 s after arming and has a 1.5 s cooldown. Thresholds
are 20, 14 and 10 m/s² for Low, Medium and High sensitivity (default Medium).
Unit tests feed synthetic signals through it, the same ones used to tune it:
- **Should trigger:** firm shakes at 3–4 Hz.
- **Should not trigger:** walking, jogging, a single bump, and two knocks
  0.25 s apart.

**Please still test shaking on a real phone** and adjust the sensitivity if
needed. Sensors and hands vary.

## Safety and privacy

- **Fictional only.** File names, sizes and percentages are constants. "Remote"
  addresses are random but always from the RFC 5737 documentation ranges, so
  they can never belong to a real device. Nothing scans the device or network.
- **No impersonation.** All alerts are drawn inside the app's own terminal
  style. There are no fake system dialogs, permission prompts, install screens
  or notifications.
- **Never traps the user.** No device lock, no blocked navigation, no payment
  request. The countdown always ends in the lesson.
- **Offline.** No networking code, no runtime downloads. Fonts and sounds are
  bundled. The release manifest has no `INTERNET` permission.
- **Permissions.**
  - Android requests none at launch. The accelerometer needs none.
  - CAMERA is only requested if the person opts into the reaction photo after
    the reveal.
  - The camera plugin's `RECORD_AUDIO` is stripped from the manifest.
  - iOS declares motion, camera and photo-library purpose strings.
- **Comfort.** Shake and glitch effects are brief. Borders pulse slowly instead
  of strobing. "Reduce motion" (in the app or the system setting) turns off
  shake, glitches, typing and looping animations. Vibrations are under 0.4 s
  and never repeat.

### About reaction recording

The brief allowed optional reaction recording. Recording *during* the
simulation is **not** implemented. The person on camera would be the one being
pranked, and they haven't consented. A camera indicator appearing mid-"hack"
would also look exactly like the attack the app is pretending to be. Instead,
the existing **post-reveal** reaction photo is kept:
- It's offered on the lesson screen, after the truth is known.
- It explains itself first, and asks for camera permission only on request.
- It takes a photo only when the shutter is pressed.
- Save, Retake and Discard are explicit, and saving is local only. Nothing is
  uploaded.
- It never records audio, and the app works fully without it.

## Tests

| File | Covers |
| --- | --- |
| `test/unit/prank_controller_test.dart` | Timeline, stage order, countdown, reveal from every stage, duplicate prevention, pause/resume, exit, disposal and timer cancellation, fictional addresses |
| `test/unit/shake_detector_test.dart` | Shakes detected; walking, jogging and bumps ignored; sensitivity levels, arming delay, cooldown, reset; sensor subscription released, sensor errors handled |
| `test/unit/effects_test.dart` | Sound and vibration toggles, stage effects, shake arming/stopping, resume |
| `test/unit/settings_test.dart` | Defaults, persistence across restarts, invalid values, reset |
| `test/unit/privacy_guard_test.dart` | No sensitive permissions or networking; camera, gallery and accelerometer confined to their files; bundled audio |
| `test/widget/prank_screen_test.dart` | Auto-start with no home screen, title card on every launch, every stage, shake-to-reveal at every stage, nothing armed during the title card, no visible reveal button, ✕ / back / no-confirmation exits, triple-tap, background/resume, effects off, replay |
| `test/widget/screens_test.dart` | Countdown screen, lesson text, no emojis, reaction explanation, settings, exit dialog, system reduce motion |

## Assets

- `assets/audio/*.wav` are synthesized by `tool/generate_sounds.py` (original
  work). The robotic line is rendered offline with espeak-ng. To regenerate:
  `python3 tool/generate_sounds.py` (needs numpy, espeak-ng, ffmpeg).
- The launcher icons (Android, including adaptive; iOS; web; macOS) are made by
  `tool/generate_icon.py` (needs Pillow). The preview is at
  `tool/icon_preview.png`.
- The fonts (Share Tech Mono, Rajdhani) are under the SIL Open Font License.
  See `assets/fonts/OFL-*.txt`.

## Platform notes

- Android first, then iOS. The web build is not supported, because the
  reaction screen uses `dart:io` and the camera.
- Devices without an accelerometer still work: the countdown, ✕ and back all
  end the simulation.
- On Android, sounds follow the ringer mode and volume. The OS may suppress
  vibration in Do Not Disturb, and the app never overrides that.
