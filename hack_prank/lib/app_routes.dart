import 'package:flutter/material.dart';

import 'features/home/home_screen.dart';
import 'features/prank/prank_screen.dart';
import 'features/reaction/reaction_screen.dart';
import 'features/reveal/reveal_screen.dart';
import 'features/settings/settings_screen.dart';

/// Named routes and the shared fade transition.
abstract final class AppRoutes {
  static const home = '/';
  static const prank = '/prank';
  static const reveal = '/reveal';
  static const settings = '/settings';
  static const reaction = '/reaction';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final page = switch (settings.name) {
      prank => const PrankScreen(),
      reveal => const RevealScreen(),
      AppRoutes.settings => const SettingsScreen(),
      reaction => const ReactionScreen(),
      _ => const HomeScreen(),
    };
    return fade(page, settings);
  }

  static Route<T> fade<T>(Widget page, RouteSettings settings) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 450),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    );
  }
}
