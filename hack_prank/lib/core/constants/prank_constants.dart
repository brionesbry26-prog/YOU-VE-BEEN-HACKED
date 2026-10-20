/// Every piece of "stolen" data in the prank comes from this file.
///
/// Nothing here is read from the device: file names, addresses, locations and
/// percentages are fixed fictional values chosen for the show.
abstract final class PrankConstants {
  static const appTitle = "You've Been Hacked 😂";

  static const allowedDurations = [15, 30, 45, 60];
  static const defaultDurationSeconds = 30;

  /// Share of the total prank time spent on the ransom countdown. The rest is
  /// split between the six breach stages.
  static const ransomShare = 1 / 3;

  /// Approximate stage lengths from the design brief (seconds). They are used
  /// as weights and scaled to fit the duration chosen in settings.
  static const stageWeights = [4, 5, 4, 7, 4, 3];

  /// How long the expired ransom screen waits for a tap when "automatically
  /// reveal" is turned off. The reveal is always guaranteed after this.
  static const revealGracePeriod = Duration(seconds: 8);

  static const tickInterval = Duration(milliseconds: 100);

  static const initializingLines = [
    'INITIALIZING SECURE CONNECTION...',
    'BYPASSING FIREWALL...',
    'ESTABLISHING ENCRYPTED TUNNEL...',
    'ANALYZING TARGET SYSTEM...',
  ];

  static const tracingLines = [
    'TRACING NETWORK ADDRESS...',
    'ANALYZING ROUTE...',
    'REMOTE CONNECTION DETECTED',
  ];

  static const breachBanner = '⚠ SYSTEM BREACH DETECTED ⚠';

  static const simulatedFiles = [
    SimulatedFile('photo_collection.jpg', '4.2 MB'),
    SimulatedFile('contacts_backup.vcf', '312 KB'),
    SimulatedFile('messages_archive.txt', '1.1 MB'),
    SimulatedFile('vacation_memories.zip', '86.4 MB'),
    SimulatedFile('personal_documents.pdf', '7.8 MB'),
    SimulatedFile('device_backup.enc', '1.3 GB'),
  ];

  static const fictionalLocation = 'QUEZON CITY, PHILIPPINES';

  static const trackingLines = [
    'SIMULATING LOCATION TRACE...',
    'LOCATION: $fictionalLocation',
    'CAMERA STATUS: SIMULATED',
    'MICROPHONE STATUS: SIMULATED',
    'DATA TRANSFER: 87%',
  ];

  static const breachCompleteLines = [
    'SIMULATED BREACH COMPLETE',
    'SYSTEM STATUS: COMPROMISED',
    'FINALIZING OPERATION...',
  ];

  static const ransomAmount = '₱500';

  /// Address prefixes reserved for documentation by RFC 5737. They can never
  /// belong to a real device, so the "traced" address is always fictional.
  static const documentationNetworks = ['192.0.2', '198.51.100', '203.0.113'];

  static const shareText =
      "I just got pranked by You've Been Hacked 😂 — my phone was never "
      'actually hacked, it was all a harmless simulation. Gotcha!';
}

class SimulatedFile {
  const SimulatedFile(this.name, this.size);

  final String name;
  final String size;

  String get label => '[SIMULATION] $name';
}
