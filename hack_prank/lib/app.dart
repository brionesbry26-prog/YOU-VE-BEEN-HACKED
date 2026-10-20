import 'package:flutter/material.dart';

import 'app_routes.dart';
import 'core/app_services.dart';
import 'core/constants/prank_constants.dart';
import 'core/theme/app_theme.dart';

class HackPrankApp extends StatelessWidget {
  const HackPrankApp({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return AppServicesScope(
      services: services,
      child: MaterialApp(
        title: PrankConstants.appTitle,
        debugShowCheckedModeBanner: false,
        // The prank is always dark, whatever the system theme.
        theme: AppTheme.dark(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.dark,
        initialRoute: AppRoutes.home,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
