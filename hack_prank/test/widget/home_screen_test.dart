import 'package:flutter_test/flutter_test.dart';
import 'package:hack_prank/features/home/home_screen.dart';
import 'package:hack_prank/features/prank/prank_screen.dart';
import 'package:hack_prank/features/settings/settings_screen.dart';

import '../helpers/fakes.dart';

void main() {
  testWidgets('shows the title, actions and disclaimer', (tester) async {
    await pumpApp(tester, TestServices());

    expect(find.text("YOU'VE BEEN HACKED"), findsWidgets);
    expect(find.text('A harmless cinematic hacking prank.'), findsOneWidget);
    expect(find.text('START THE PRANK'), findsOneWidget);
    expect(find.text('CUSTOMIZE EXPERIENCE'), findsOneWidget);
    expect(find.byKey(HomeScreen.settingsKey), findsOneWidget);
    expect(find.text('Simulation only. No real hacking or data access.'), findsOneWidget);
  });

  testWidgets('START THE PRANK opens the prank', (tester) async {
    final s = TestServices();
    await pumpApp(tester, s);

    await tester.tap(find.byKey(HomeScreen.startKey));
    await pumpFor(tester, const Duration(milliseconds: 600));

    expect(find.byType(PrankScreen), findsOneWidget);
    expect(find.textContaining('STAGE 1/6'), findsOneWidget);

    // Leave cleanly so no timers outlive the test.
    await tester.tap(find.byKey(PrankScreen.exitKey));
    await pumpFor(tester, const Duration(milliseconds: 300));
    await tester.tap(find.text('EXIT SAFELY'));
    await pumpFor(tester, const Duration(milliseconds: 600));
  });

  testWidgets('CUSTOMIZE EXPERIENCE and the settings icon open settings', (tester) async {
    await pumpApp(tester, TestServices());

    await tester.tap(find.byKey(HomeScreen.customizeKey));
    await pumpFor(tester, const Duration(milliseconds: 600));
    expect(find.byType(SettingsScreen), findsOneWidget);

    await tester.pageBack();
    await pumpFor(tester, const Duration(milliseconds: 600));
    await tester.tap(find.byKey(HomeScreen.settingsKey));
    await pumpFor(tester, const Duration(milliseconds: 600));
    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testWidgets('renders statically with reduced motion', (tester) async {
    await pumpApp(tester, TestServices(allEffectsOff));
    expect(find.text('START THE PRANK'), findsOneWidget);
    expect(find.text("YOU'VE BEEN HACKED"), findsOneWidget);
  });
}
