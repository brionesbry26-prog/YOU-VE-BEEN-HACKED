/// Every piece of "stolen" data in the simulation comes from this file.
///
/// Nothing here is read from the device: file names, addresses and
/// percentages are fixed fictional values chosen for the show.
abstract final class PrankConstants {
  static const appTitle = 'I Love You';
  static const appSubtitle = 'A cybersecurity awareness experience';

  /// Choices for the ransom-style countdown length (seconds).
  static const allowedCountdowns = [15, 30, 45, 60];
  static const defaultCountdownSeconds = 30;

  /// How long the expired countdown waits when "automatically reveal" is
  /// turned off. The reveal is always guaranteed after this.
  static const revealGracePeriod = Duration(seconds: 8);

  static const tickInterval = Duration(milliseconds: 100);

  // Stage 1 — initialization.
  static const initializingLines = [
    'INITIALIZING CONNECTION...',
    'ANALYZING NETWORK ROUTE...',
    'ESTABLISHING ENCRYPTED SESSION...',
    'SCANNING SIMULATED ENVIRONMENT...',
  ];

  // Stage 2 — simulated remote activity.
  static const activityLines = [
    'REMOTE CONNECTION DETECTED',
    'ANALYZING SYSTEM STATUS...',
    'PROCESSING SIMULATED FILES...',
    'DATA TRANSFER: 47%',
  ];

  /// Fictional system files "processed" in stage 2.
  static const simulatedSystemFiles = [
    SimulatedFile('system_index.db', '2.1 MB'),
    SimulatedFile('session_cache.tmp', '640 KB'),
    SimulatedFile('app_registry.dat', '1.4 MB'),
  ];

  // Stage 3 — dramatic warning.
  static const alertTitle = 'SECURITY ALERT';
  static const alertSubtitle = 'SIMULATED SYSTEM BREACH DETECTED';

  /// Stage 4 — fictional files "extracted". They do not exist; the device's
  /// storage is never read.
  static const simulatedFiles = [
    SimulatedFile('photo_collection.jpg', '4.2 MB'),
    SimulatedFile('contacts_backup.vcf', '312 KB'),
    SimulatedFile('messages_archive.txt', '1.1 MB'),
    SimulatedFile('personal_documents.pdf', '7.8 MB'),
  ];

  // Stage 5 — ransom-inspired countdown (no payment of any kind).
  static const compromisedStatus = 'SYSTEM STATUS: COMPROMISED';
  static const simulationInProgress = 'SIMULATION IN PROGRESS';

  /// Address prefixes reserved for documentation by RFC 5737. They can never
  /// belong to a real device, so every "remote" address is fictional.
  static const documentationNetworks = ['192.0.2', '198.51.100', '203.0.113'];

  // Reveal — the lesson.
  static const lessonHeadline = "DON'T INSTALL UNKNOWN APPS.";
  static const lessonSubline = 'THINK BEFORE YOU CLICK.';
  static const revealFacts = [
    'This was a simulated hacking prank.',
    'Your device was not hacked.',
    'No personal files were stolen.',
    "Always check an app's source and permissions before installing it.",
  ];
  static const revealExplanation =
      'Unexpected apps can request access to your camera, contacts, location, '
      'files, and other sensitive information. Install applications only from '
      'trusted sources, review their permissions, and keep your device updated.';
  static const revealAcknowledgment = 'CYBERSECURITY AWARENESS EXPERIENCE';
}

class SimulatedFile {
  const SimulatedFile(this.name, this.size);

  final String name;
  final String size;
}
