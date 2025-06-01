import 'package:flutter/material.dart';

/// OpenLab Augsburg themed Flutter application
/// Based on the official website design at https://www.openlab-augsburg.de/
class OpenLabTheme {
  // Brand Colors from OpenLab Augsburg website
  static const Color primaryBlue = Color(0xFF1E3A8A); // Deep blue from header
  static const Color secondaryBlue = Color(0xFF3B82F6); // Lighter blue accent
  static const Color accentOrange = Color(0xFFEA580C); // Orange accent color
  static const Color lightGray = Color(0xFFF8FAFC); // Light background
  static const Color mediumGray = Color(0xFF64748B); // Text gray
  static const Color darkGray = Color(0xFF1E293B); // Dark text
  static const Color white = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Typography - modern, clean font stack
  static const String fontFamily = 'Inter';
  static const String displayFont = 'Inter';

  // Light Theme - matches the clean, modern website design
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: white,
    fontFamily: fontFamily,

    colorScheme: ColorScheme.light(
      primary: primaryBlue,
      onPrimary: white,
      secondary: accentOrange,
      onSecondary: white,
      tertiary: secondaryBlue,
      surface: white,
      onSurface: darkGray,
      background: lightGray,
      onBackground: darkGray,
      error: error,
      onError: white,
      outline: mediumGray.withOpacity(0.3),
    ),

    // App Bar - clean header style like the website
    appBarTheme: AppBarTheme(
      backgroundColor: white,
      foregroundColor: darkGray,
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 1,
      shadowColor: mediumGray.withOpacity(0.1),
      titleTextStyle: TextStyle(
        fontFamily: displayFont,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: darkGray,
      ),
      iconTheme: IconThemeData(color: darkGray),
    ),

    // Cards - modern, subtle elevation
    cardTheme: CardThemeData(
      // Changed from CardTheme to CardThemeData
      color: white,
      elevation: 2,
      shadowColor: mediumGray.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    // Buttons - matching website's button styles
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: white,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryBlue,
        side: BorderSide(color: primaryBlue, width: 1.5),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryBlue,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    // FAB with accent color
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accentOrange,
      foregroundColor: white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // Input fields - clean, modern styling
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightGray,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: mediumGray.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: mediumGray.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: error),
      ),
      labelStyle: TextStyle(color: mediumGray, fontFamily: fontFamily),
      hintStyle: TextStyle(
        color: mediumGray.withOpacity(0.7),
        fontFamily: fontFamily,
      ),
    ),

    // Navigation
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: white,
      selectedItemColor: primaryBlue,
      unselectedItemColor: mediumGray,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w400,
      ),
    ),

    // Text Theme - clean, readable typography
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontFamily: displayFont,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: darkGray,
        height: 1.2,
      ),
      displayMedium: TextStyle(
        fontFamily: displayFont,
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: darkGray,
        height: 1.3,
      ),
      displaySmall: TextStyle(
        fontFamily: displayFont,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: darkGray,
        height: 1.3,
      ),
      headlineLarge: TextStyle(
        fontFamily: displayFont,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: darkGray,
        height: 1.4,
      ),
      headlineMedium: TextStyle(
        fontFamily: displayFont,
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: darkGray,
        height: 1.4,
      ),
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: darkGray,
        height: 1.4,
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: darkGray,
        height: 1.5,
      ),
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: darkGray,
        height: 1.6,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: mediumGray,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: mediumGray,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: primaryBlue,
      ),
    ),

    // Additional components
    chipTheme: ChipThemeData(
      backgroundColor: lightGray,
      selectedColor: primaryBlue.withOpacity(0.1),
      side: BorderSide(color: mediumGray.withOpacity(0.3)),
      labelStyle: TextStyle(color: darkGray, fontFamily: fontFamily),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),

    dividerTheme: DividerThemeData(
      color: mediumGray.withOpacity(0.2),
      thickness: 1,
      space: 1,
    ),

    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) return white;
        return mediumGray;
      }),
      trackColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) return primaryBlue;
        return mediumGray.withOpacity(0.3);
      }),
    ),
  );

  // Dark Theme - modern dark mode
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: secondaryBlue,
    scaffoldBackgroundColor: Color(0xFF0F172A),
    fontFamily: fontFamily,

    colorScheme: ColorScheme.dark(
      primary: secondaryBlue,
      onPrimary: white,
      secondary: accentOrange,
      onSecondary: white,
      tertiary: Color(0xFF60A5FA),
      surface: Color(0xFF1E293B),
      onSurface: Color(0xFFF1F5F9),
      background: Color(0xFF0F172A),
      onBackground: Color(0xFFF1F5F9),
      error: Color(0xFFF87171),
      onError: white,
      outline: Color(0xFF475569),
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF1E293B),
      foregroundColor: Color(0xFFF1F5F9),
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 1,
      shadowColor: Colors.black.withOpacity(0.3),
      titleTextStyle: TextStyle(
        fontFamily: displayFont,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Color(0xFFF1F5F9),
      ),
      iconTheme: IconThemeData(color: Color(0xFFF1F5F9)),
    ),

    cardTheme: CardThemeData(
      // Changed from CardTheme to CardThemeData
      color: Color(0xFF1E293B),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: secondaryBlue,
        foregroundColor: white,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: secondaryBlue,
        side: BorderSide(color: secondaryBlue, width: 1.5),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: secondaryBlue,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accentOrange,
      foregroundColor: white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF334155),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Color(0xFF475569)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Color(0xFF475569)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: secondaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Color(0xFFF87171)),
      ),
      labelStyle: TextStyle(color: Color(0xFF94A3B8), fontFamily: fontFamily),
      hintStyle: TextStyle(color: Color(0xFF64748B), fontFamily: fontFamily),
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E293B),
      selectedItemColor: secondaryBlue,
      unselectedItemColor: Color(0xFF64748B),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w400,
      ),
    ),

    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontFamily: displayFont,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: Color(0xFFF1F5F9),
        height: 1.2,
      ),
      displayMedium: TextStyle(
        fontFamily: displayFont,
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: Color(0xFFF1F5F9),
        height: 1.3,
      ),
      displaySmall: TextStyle(
        fontFamily: displayFont,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Color(0xFFF1F5F9),
        height: 1.3,
      ),
      headlineLarge: TextStyle(
        fontFamily: displayFont,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Color(0xFFF1F5F9),
        height: 1.4,
      ),
      headlineMedium: TextStyle(
        fontFamily: displayFont,
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: Color(0xFFF1F5F9),
        height: 1.4,
      ),
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: Color(0xFFF1F5F9),
        height: 1.4,
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Color(0xFFF1F5F9),
        height: 1.5,
      ),
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: Color(0xFFF1F5F9),
        height: 1.6,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Color(0xFF94A3B8),
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: Color(0xFF64748B),
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: secondaryBlue,
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: Color(0xFF334155),
      selectedColor: secondaryBlue.withOpacity(0.2),
      side: BorderSide(color: Color(0xFF475569)),
      labelStyle: TextStyle(color: Color(0xFFF1F5F9), fontFamily: fontFamily),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),

    dividerTheme: DividerThemeData(
      color: Color(0xFF475569),
      thickness: 1,
      space: 1,
    ),

    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) return white;
        return Color(0xFF64748B);
      }),
      trackColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) return secondaryBlue;
        return Color(0xFF475569);
      }),
    ),
  );

  // Utility methods for accessing theme colors
  static Color getPrimaryColor(bool isDark) =>
      isDark ? secondaryBlue : primaryBlue;
  static Color getBackgroundColor(bool isDark) =>
      isDark ? Color(0xFF0F172A) : white;
  static Color getSurfaceColor(bool isDark) =>
      isDark ? Color(0xFF1E293B) : white;
  static Color getTextColor(bool isDark) =>
      isDark ? Color(0xFFF1F5F9) : darkGray;
}
