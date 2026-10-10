import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color brandRed = Color(0xFFD62828);
const Color brandAmber = Color(0xFFFFC93C);

class AppColors {
  const AppColors({
    required this.background,
    required this.backgroundSecondary,
    required this.surface,
    required this.surfaceMuted,
    required this.text,
    required this.textSecondary,
    required this.textTertiary,
    required this.primary,
    required this.primaryDark,
    required this.accent,
    required this.error,
    required this.warning,
    required this.info,
    required this.border,
    required this.borderSubtle,
  });

  final Color background;
  final Color backgroundSecondary;
  final Color surface;
  final Color surfaceMuted;
  final Color text;
  final Color textSecondary;
  final Color textTertiary;
  final Color primary;
  final Color primaryDark;
  final Color accent;
  final Color error;
  final Color warning;
  final Color info;
  final Color border;
  final Color borderSubtle;

  factory AppColors.fromScheme(ColorScheme scheme) {
    final bool dark = scheme.brightness == Brightness.dark;
    final Color background =
        dark ? const Color(0xFF151414) : const Color(0xFFF7F6F4);
    final Color surface = dark ? const Color(0xFF201E1D) : Colors.white;
    final Color surfaceMuted =
        dark ? const Color(0xFF2B2827) : const Color(0xFFF0EEEC);

    return AppColors(
      background: background,
      backgroundSecondary: surface,
      surface: surface,
      surfaceMuted: surfaceMuted,
      text: dark ? const Color(0xFFF7F4F2) : const Color(0xFF211E1D),
      textSecondary: dark ? const Color(0xFFC5BFBC) : const Color(0xFF625B58),
      textTertiary: dark ? const Color(0xFF9C9490) : const Color(0xFF817975),
      primary: brandRed,
      primaryDark: brandRed,
      accent: brandRed,
      error: scheme.error,
      warning: const Color(0xFFF59E0B),
      info: const Color(0xFF2476A8),
      border: dark ? const Color(0xFF514A47) : const Color(0xFFD7D2CE),
      borderSubtle: dark ? const Color(0xFF393432) : const Color(0xFFE8E4E1),
    );
  }
}

ThemeData buildTheme(Brightness brightness) {
  final ColorScheme generatedScheme = ColorScheme.fromSeed(
    seedColor: brandRed,
    brightness: brightness,
    dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
  );
  final ColorScheme scheme = generatedScheme.copyWith(
    primary: brandRed,
    onPrimary: Colors.white,
    primaryContainer: brightness == Brightness.dark
        ? const Color(0xFF641C1A)
        : const Color(0xFFF9DEDA),
    onPrimaryContainer: brightness == Brightness.dark
        ? const Color(0xFFFFDAD5)
        : const Color(0xFF410002),
    secondary: brandRed,
    onSecondary: Colors.white,
    secondaryContainer: brightness == Brightness.dark
        ? const Color(0xFF641C1A)
        : const Color(0xFFF9DEDA),
    onSecondaryContainer: brightness == Brightness.dark
        ? const Color(0xFFFFDAD5)
        : const Color(0xFF410002),
  );
  final AppColors c = AppColors.fromScheme(scheme);

  final ThemeData base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: c.background,
    colorScheme: scheme,
    appBarTheme: AppBarTheme(
      backgroundColor: c.background,
      foregroundColor: c.text,
      toolbarHeight: 80,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleSpacing: 16,
      shape: Border(bottom: BorderSide(color: c.borderSubtle)),
    ),
    cardTheme: CardThemeData(
      color: c.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: c.borderSubtle),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: c.borderSubtle),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      modalBackgroundColor: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: c.borderSubtle),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surfaceMuted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.primary, width: 1.5),
      ),
      hintStyle: TextStyle(color: c.textTertiary),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: c.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.primary,
        side: BorderSide(color: c.primary.withValues(alpha: 0.45)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: c.primary,
        backgroundColor: c.surfaceMuted,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: c.surfaceMuted,
      selectedColor: c.primary.withValues(alpha: 0.14),
      side: BorderSide(color: c.border),
      labelStyle: TextStyle(color: c.text, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
    dividerTheme: DividerThemeData(color: c.borderSubtle, thickness: 1),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: c.primary),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.dmSans(
        color: c.text,
        fontWeight: FontWeight.w800,
      ),
      displayMedium: GoogleFonts.dmSans(
        color: c.text,
        fontWeight: FontWeight.w800,
      ),
      displaySmall: GoogleFonts.dmSans(
        color: c.text,
        fontWeight: FontWeight.w800,
      ),
      headlineLarge: GoogleFonts.dmSans(
        color: c.text,
        fontWeight: FontWeight.w800,
      ),
      headlineMedium: GoogleFonts.dmSans(
        color: c.text,
        fontWeight: FontWeight.w800,
      ),
      headlineSmall: GoogleFonts.dmSans(
        color: c.text,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: GoogleFonts.dmSans(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: c.text,
      ),
      titleMedium: GoogleFonts.dmSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: c.text,
      ),
      titleSmall: GoogleFonts.dmSans(
        color: c.text,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.dmSans(color: c.text, fontWeight: FontWeight.w500),
      bodyMedium: GoogleFonts.dmSans(
        color: c.text,
        fontWeight: FontWeight.w500,
      ),
      bodySmall: GoogleFonts.dmSans(
        color: c.textSecondary,
        fontWeight: FontWeight.w500,
      ),
      labelLarge: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
      labelMedium: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
      labelSmall: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.surface,
      contentTextStyle: TextStyle(color: c.text),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.surface.withValues(alpha: 0.94),
      indicatorColor: c.primary.withValues(alpha: 0.16),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStatePropertyAll<TextStyle>(
        TextStyle(color: c.textSecondary, fontWeight: FontWeight.w600),
      ),
      iconTheme: WidgetStatePropertyAll<IconThemeData>(
        IconThemeData(color: c.textSecondary),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
        TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
        TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
      },
    ),
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: GoogleFonts.dmSans().fontFamily,
    ),
    appBarTheme: base.appBarTheme.copyWith(
      titleTextStyle: GoogleFonts.dmSans(
        color: c.text,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

AppColors appColors(BuildContext context) {
  return AppColors.fromScheme(Theme.of(context).colorScheme);
}
