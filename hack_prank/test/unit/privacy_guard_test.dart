import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static checks that keep the prank harmless: no data-access permissions,
/// no networking or data-collection packages, and the camera confined to the
/// opt-in reaction screen.
void main() {
  final libFiles = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  test('the Android release manifest requests no sensitive permissions', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    for (final permission in [
      'INTERNET',
      'ACCESS_FINE_LOCATION',
      'ACCESS_COARSE_LOCATION',
      'READ_CONTACTS',
      'READ_SMS',
      'READ_MEDIA_IMAGES',
      'READ_EXTERNAL_STORAGE',
      'SYSTEM_ALERT_WINDOW',
      'BIND_DEVICE_ADMIN',
      'BIND_ACCESSIBILITY_SERVICE',
      'RECEIVE_BOOT_COMPLETED',
      'FOREGROUND_SERVICE',
      'POST_NOTIFICATIONS',
    ]) {
      expect(
        RegExp('<uses-permission[^>]*android.permission.$permission"(?![^>]*tools:node="remove")')
            .hasMatch(manifest),
        isFalse,
        reason: '$permission must not be requested',
      );
    }
    expect(
      manifest,
      contains('android.permission.RECORD_AUDIO" tools:node="remove"'),
      reason: 'the microphone permission added by the camera plugin is stripped',
    );
  });

  test('no networking, location, contacts or media-reading packages', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final pkg in [
      'http:',
      'dio:',
      'geolocator',
      'location:',
      'contacts_service',
      'flutter_contacts',
      'photo_manager',
      'image_picker',
      'firebase',
      'network_info_plus',
      'device_info_plus:',
      'google_fonts',
    ]) {
      expect(pubspec.contains(pkg), isFalse, reason: '$pkg must not be a dependency');
    }
  });

  test('app code makes no network requests', () {
    for (final f in libFiles) {
      final src = f.readAsStringSync();
      expect(src.contains('HttpClient'), isFalse, reason: f.path);
      expect(src.contains('package:http/'), isFalse, reason: f.path);
      expect(src.contains('Socket'), isFalse, reason: f.path);
      expect(src.contains('UrlSource'), isFalse, reason: f.path);
    }
  });

  test('the camera and gallery are only used by the opt-in reaction screen', () {
    for (final f in libFiles) {
      final src = f.readAsStringSync();
      final usesCamera = src.contains('package:camera/') || src.contains('package:gal/');
      if (usesCamera) {
        expect(f.path.replaceAll(r'\', '/'), endsWith('features/reaction/reaction_screen.dart'));
      }
    }
  });

  test('audio comes only from bundled assets', () {
    final audio = File('lib/core/services/audio_service.dart').readAsStringSync();
    expect(audio, contains('AssetSource'));
    for (final asset in RegExp(r"'(audio/[a-z]+\.wav)'").allMatches(audio)) {
      expect(File('assets/${asset.group(1)}').existsSync(), isTrue, reason: asset.group(1));
    }
  });
}
