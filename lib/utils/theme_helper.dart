import 'package:flutter/material.dart';

class ThemeHelper {
  // Primary text color that adapts to theme
  static Color primaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? Colors.white 
        : Colors.black87;
  }

  // Secondary text color that adapts to theme
  static Color secondaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? Colors.grey.shade300 
        : Colors.grey.shade700;
  }

  // Accent text color that adapts to theme
  static Color accentTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? Colors.blue.shade300 
        : Colors.blue.shade800;
  }

  // Header text color that adapts to theme
  static Color headerTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? Colors.white 
        : const Color(0xFF002B5B);
  }

  // Warning text color (remains consistent across themes)
  static Color warningTextColor(BuildContext context) {
    return Colors.red;
  }

  // Success text color (remains consistent across themes)
  static Color successTextColor(BuildContext context) {
    return Colors.green;
  }

  // Card background color that adapts to theme
  static Color cardBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF2D2D2D) 
        : Colors.white;
  }

  // Surface color that adapts to theme
  static Color surfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? Colors.grey.shade800 
        : Colors.grey.shade100;
  }

  // Common text styles with proper dark mode support
  static TextStyle headingStyle(BuildContext context, {double fontSize = 20}) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: headerTextColor(context),
    );
  }

  static TextStyle bodyStyle(BuildContext context, {double fontSize = 14}) {
    return TextStyle(
      fontSize: fontSize,
      color: primaryTextColor(context),
    );
  }

  static TextStyle secondaryBodyStyle(BuildContext context, {double fontSize = 14}) {
    return TextStyle(
      fontSize: fontSize,
      color: secondaryTextColor(context),
    );
  }

  static TextStyle accentStyle(BuildContext context, {double fontSize = 14}) {
    return TextStyle(
      fontSize: fontSize,
      color: accentTextColor(context),
      fontWeight: FontWeight.w500,
    );
  }

  // Enhanced theme data for better dark mode support
  static ThemeData getEnhancedDarkTheme() {
    return ThemeData.dark().copyWith(
      // Enhanced text colors for better visibility in dark mode
      textTheme: ThemeData.dark().textTheme.copyWith(
        displayLarge: ThemeData.dark().textTheme.displayLarge?.copyWith(color: Colors.white),
        displayMedium: ThemeData.dark().textTheme.displayMedium?.copyWith(color: Colors.white),
        displaySmall: ThemeData.dark().textTheme.displaySmall?.copyWith(color: Colors.white),
        headlineLarge: ThemeData.dark().textTheme.headlineLarge?.copyWith(color: Colors.white),
        headlineMedium: ThemeData.dark().textTheme.headlineMedium?.copyWith(color: Colors.white),
        headlineSmall: ThemeData.dark().textTheme.headlineSmall?.copyWith(color: Colors.white),
        titleLarge: ThemeData.dark().textTheme.titleLarge?.copyWith(color: Colors.white),
        titleMedium: ThemeData.dark().textTheme.titleMedium?.copyWith(color: Colors.white),
        titleSmall: ThemeData.dark().textTheme.titleSmall?.copyWith(color: Colors.white),
        bodyLarge: ThemeData.dark().textTheme.bodyLarge?.copyWith(color: Colors.white),
        bodyMedium: ThemeData.dark().textTheme.bodyMedium?.copyWith(color: Colors.white),
        bodySmall: ThemeData.dark().textTheme.bodySmall?.copyWith(color: Colors.white),
        labelLarge: ThemeData.dark().textTheme.labelLarge?.copyWith(color: Colors.white),
        labelMedium: ThemeData.dark().textTheme.labelMedium?.copyWith(color: Colors.white),
        labelSmall: ThemeData.dark().textTheme.labelSmall?.copyWith(color: Colors.white),
      ),
      // Enhanced list tile text colors
      listTileTheme: const ListTileThemeData(
        textColor: Colors.white,
        iconColor: Colors.white,
      ),
      // Enhanced data table text colors
      dataTableTheme: const DataTableThemeData(
        dataTextStyle: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
        headingTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        headingRowColor: WidgetStatePropertyAll(Color(0xFF1A4D8F)),
        dataRowColor: WidgetStatePropertyAll(Color(0xFF2D2D2D)),
      ),
      // Enhanced card colors
      cardTheme: const CardThemeData(
        color: Color(0xFF2D2D2D),
      ),
      // Enhanced app bar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      // Enhanced scaffold background
      scaffoldBackgroundColor: const Color(0xFF121212),
      // Enhanced input decoration theme
      inputDecorationTheme: const InputDecorationTheme(
        labelStyle: TextStyle(color: Colors.white70),
        hintStyle: TextStyle(color: Colors.white54),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white70),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white70),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue, width: 2),
        ),
      ),
    );
  }
}
