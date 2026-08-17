import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand palette from the Docora Figma file (Styles panel). Named to match
/// the Figma color-style names 1:1 so design and code stay in sync.
class AppColors {
  AppColors._();

  static const buntOrange = Color(0xFFF2622C); // primary brand / hero card
  static const coralGlass = Color(0xFFF89E7B); // gradient accent on the hero card
  static const peachMist = Color(0xFFFBE4D8); // tag chips / soft container fill
  static const ink = Color(0xFF191715); // primary text
  static const warmWhite = Color(0xFFFFFDFB); // card surfaces
  static const surface = Color(0xFFFBF1EA); // screen background
  static const softBorder = Color(0xFFF0E0D4); // hairlines / outlines
  static const aiViolet = Color(0xFF7C6FE0); // AI-assistant accent
}

/// Central design system: one seed color drives the whole Material 3 palette,
/// component themes below just tune shape/spacing so every screen shares the
/// same rounded, low-elevation look without repeating styling per-widget.
class AppTheme {
  AppTheme._();

  static const _seed = AppColors.buntOrange;
  static const _radius = 16.0;

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colorScheme = brightness == Brightness.light
        ? ColorScheme.fromSeed(seedColor: _seed, brightness: brightness).copyWith(
            primary: AppColors.buntOrange,
            secondary: AppColors.coralGlass,
            tertiary: AppColors.aiViolet,
            surface: AppColors.surface,
            surfaceContainerHigh: AppColors.warmWhite,
            surfaceContainerHighest: AppColors.warmWhite,
            primaryContainer: AppColors.peachMist,
            onPrimaryContainer: AppColors.buntOrange,
            outlineVariant: AppColors.softBorder,
            onSurface: AppColors.ink,
          )
        : ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      splashFactory: InkSparkle.splashFactory,

      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.k2d(
          color: colorScheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),

      // K2D is the brand heading font (Figma "Quick Actions" style: K2D,
      // weight 500, 20px) — applied to headings/titles only, body text keeps
      // the platform default for readability at small sizes.
      textTheme: ThemeData(brightness: brightness).textTheme.copyWith(
            headlineMedium: GoogleFonts.k2d(fontWeight: FontWeight.w700),
            titleLarge: GoogleFonts.k2d(fontWeight: FontWeight.w500),
            titleMedium: GoogleFonts.k2d(fontWeight: FontWeight.w500),
            titleSmall: GoogleFonts.k2d(fontWeight: FontWeight.w500),
            bodyLarge: const TextStyle(height: 1.4),
            bodyMedium: const TextStyle(height: 1.4),
          ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius + 4)),
        margin: EdgeInsets.zero,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
          side: BorderSide(color: colorScheme.outlineVariant),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        selectedColor: colorScheme.primary,
        labelStyle: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w600),
        secondaryLabelStyle:
            TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.w600),
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),

      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        thickness: 1,
        space: 1,
      ),

      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius + 4)),
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius - 2),
          borderSide: BorderSide.none,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(color: colorScheme.primary),
    );
  }
}
