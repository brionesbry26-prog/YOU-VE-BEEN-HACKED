import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Font families bundled in `assets/fonts`.
abstract final class AppFonts {
  static const mono = 'ShareTechMono';
  static const display = 'Rajdhani';
  static const monoFallback = ['monospace', 'Courier', 'RobotoMono'];
}

/// Shared text styles. Terminal styles honour the accessibility settings.
abstract final class AppText {
  static TextStyle terminal({
    Color color = AppColors.mutedTerminal,
    bool large = false,
    bool highContrast = false,
    double size = 14,
    FontWeight weight = FontWeight.w400,
  }) {
    return TextStyle(
      fontFamily: AppFonts.mono,
      fontFamilyFallback: AppFonts.monoFallback,
      fontSize: large ? size * 1.3 : size,
      fontWeight: weight,
      height: 1.35,
      letterSpacing: 0.4,
      color: highContrast ? _boost(color) : color,
    );
  }

  static TextStyle display({
    double size = 32,
    Color color = AppColors.textPrimary,
    FontWeight weight = FontWeight.w700,
    double letterSpacing = 1.5,
    List<Shadow>? shadows,
  }) {
    return TextStyle(
      fontFamily: AppFonts.display,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: 1.05,
      color: color,
      shadows: shadows,
    );
  }

  /// Soft neon glow used on headings.
  static List<Shadow> glow(Color color, {double strength = 1}) => [
    Shadow(color: color.withValues(alpha: 0.85 * strength), blurRadius: 8),
    Shadow(color: color.withValues(alpha: 0.45 * strength), blurRadius: 22),
  ];

  /// High-contrast mode swaps muted tints for full-strength colours.
  static Color _boost(Color color) {
    if (color == AppColors.mutedTerminal || color == AppColors.secondaryGreen) {
      return AppColors.hackerGreen;
    }
    if (color == AppColors.textSecondary) return AppColors.textPrimary;
    return color;
  }
}

abstract final class AppTheme {
  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.hackerGreen,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.hackerGreen,
      onPrimary: AppColors.background,
      secondary: AppColors.secondaryGreen,
      error: AppColors.danger,
      surface: AppColors.terminal,
      onSurface: AppColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: AppFonts.display,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        bodySmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarThemeData(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.hackerGreen,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.display,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
          color: AppColors.hackerGreen,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.terminal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.hackerGreen, width: 1.2),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.background
              : AppColors.textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.hackerGreen
              : AppColors.terminal,
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.hackerGreen,
        thumbColor: AppColors.hackerGreen,
        inactiveTrackColor: Color(0xFF1B2A20),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.terminal,
        contentTextStyle: TextStyle(
          fontFamily: AppFonts.mono,
          color: AppColors.hackerGreen,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF1B2A20)),
    );
  }
}
