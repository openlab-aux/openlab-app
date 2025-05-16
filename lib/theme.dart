import 'package:flutter/material.dart';

class OpenLabTheme {
  // Custom Brand Colors
  static const Color green = Color(0xFF006845);
  static const Color red = Color(0xFFE52A1A);
  static const Color yellow = Color(0xFFFFAA00);
  static const Color white = Color(0xFFFFFFFF);
  static const Color darkBackground = Color(0xFF121212);

  static const String fontFamily = 'DroidSans';
  static const String monoFontFamily = 'DroidSansMono';

  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: green,
    scaffoldBackgroundColor: white,
    fontFamily: fontFamily,
    colorScheme: ColorScheme.light(
      primary: green,
      secondary: yellow,
      error: red,
      background: white,
      onBackground: Colors.black87,
      onPrimary: white,
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.black, fontFamily: fontFamily),
      bodyMedium: TextStyle(color: Colors.black87, fontFamily: fontFamily),
      titleLarge: TextStyle(fontWeight: FontWeight.bold),
      labelLarge: TextStyle(color: green),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: green,
      foregroundColor: white,
      elevation: 2,
      titleTextStyle: TextStyle(
        fontFamily: fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: white,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: yellow,
      foregroundColor: Colors.black,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(),
      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: green)),
    ),
  );

  // Dark Theme
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: green,
    scaffoldBackgroundColor: darkBackground,
    fontFamily: fontFamily,
    colorScheme: ColorScheme.dark(
      primary: green,
      secondary: yellow,
      error: red,
      background: darkBackground,
      onBackground: white,
      onPrimary: white,
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: white, fontFamily: fontFamily),
      bodyMedium: TextStyle(color: Colors.white70, fontFamily: fontFamily),
      titleLarge: TextStyle(fontWeight: FontWeight.bold),
      labelLarge: TextStyle(color: yellow),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: green,
      foregroundColor: white,
      elevation: 2,
      titleTextStyle: TextStyle(
        fontFamily: fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: white,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: yellow,
      foregroundColor: Colors.black,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(),
      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: yellow)),
    ),
  );
}

/// A modern theme inspired by DaisyUI's design principles for Flutter applications
/// Supports both light and dark modes with consistent color palette
class DaisyUITheme {
  // Primary accent colors
  static const Color _primaryLight = Color(0xFF570DF8); // DaisyUI primary
  static const Color _primaryDark = Color(0xFF661AE6);

  // Secondary colors
  static const Color _secondaryLight = Color(0xFFF000B8); // DaisyUI secondary
  static const Color _secondaryDark = Color(0xFFD946EF);

  // Accent colors
  static const Color _accentLight = Color(0xFF37CDBE); // DaisyUI accent
  static const Color _accentDark = Color(0xFF1FB2A6);

  // Neutral colors for backgrounds and surfaces
  static const Color _neutralBgLight = Color(0xFFF3F4F6);
  static const Color _neutralFgLight = Color(0xFF1F2937);
  static const Color _neutralBgDark = Color(0xFF1F2937);
  static const Color _neutralFgDark = Color(0xFFF3F4F6);

  // Success, warning, error colors
  static const Color _successLight = Color(0xFF36D399);
  static const Color _successDark = Color(0xFF2BD999);
  static const Color _warningLight = Color(0xFFFBBD23);
  static const Color _warningDark = Color(0xFFFFD261);
  static const Color _errorLight = Color(0xFFF87272);
  static const Color _errorDark = Color(0xFFFF5757);

  // Get light theme
  static ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: _primaryLight,
        secondary: _secondaryLight,
        tertiary: _accentLight,
        background: _neutralBgLight,
        surface: Colors.white,
        onBackground: _neutralFgLight,
        onSurface: _neutralFgLight,
        error: _errorLight,
      ),
      scaffoldBackgroundColor: _neutralBgLight,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: _neutralFgLight,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryLight,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryLight,
          side: BorderSide(color: _primaryLight, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryLight,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _primaryLight,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      tabBarTheme: TabBarTheme(
        labelColor: _primaryLight,
        unselectedLabelColor: _neutralFgLight.withOpacity(0.7),
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: _primaryLight, width: 2),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: _neutralFgLight.withOpacity(0.15),
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _neutralBgLight,
        disabledColor: _neutralBgLight.withOpacity(0.5),
        selectedColor: _primaryLight.withOpacity(0.2),
        secondarySelectedColor: _primaryLight,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _neutralFgLight.withOpacity(0.2)),
        ),
        labelStyle: TextStyle(color: _neutralFgLight),
        secondaryLabelStyle: TextStyle(color: Colors.white),
        brightness: Brightness.light,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _neutralFgLight,
        contentTextStyle: TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: _primaryLight,
        unselectedItemColor: _neutralFgLight.withOpacity(0.6),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return _primaryLight;
          }
          return Colors.grey;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return _primaryLight.withOpacity(0.5);
          }
          return Colors.grey.withOpacity(0.3);
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        checkColor: MaterialStateProperty.all(Colors.white),
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return _primaryLight;
          }
          return Colors.transparent;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide(color: _neutralFgLight.withOpacity(0.5), width: 1.5),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _neutralFgLight.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _neutralFgLight.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _errorLight, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _errorLight, width: 2),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
      ),
    );
  }

  // Get dark theme
  static ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: _primaryDark,
        secondary: _secondaryDark,
        tertiary: _accentDark,
        background: _neutralBgDark,
        surface: Color(0xFF2A3441),
        onBackground: _neutralFgDark,
        onSurface: _neutralFgDark,
        error: _errorDark,
      ),
      scaffoldBackgroundColor: _neutralBgDark,
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF2A3441),
        foregroundColor: _neutralFgDark,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardTheme(
        color: Color(0xFF2A3441),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryDark,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryDark,
          side: BorderSide(color: _primaryDark, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryDark,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _primaryDark,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      tabBarTheme: TabBarTheme(
        labelColor: _primaryDark,
        unselectedLabelColor: _neutralFgDark.withOpacity(0.7),
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: _primaryDark, width: 2),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: _neutralFgDark.withOpacity(0.15),
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Color(0xFF374151),
        disabledColor: Color(0xFF374151).withOpacity(0.5),
        selectedColor: _primaryDark.withOpacity(0.3),
        secondarySelectedColor: _primaryDark,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _neutralFgDark.withOpacity(0.2)),
        ),
        labelStyle: TextStyle(color: _neutralFgDark),
        secondaryLabelStyle: TextStyle(color: _neutralFgDark),
        brightness: Brightness.dark,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Color(0xFF374151),
        contentTextStyle: TextStyle(color: _neutralFgDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: Color(0xFF2A3441),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF2A3441),
        selectedItemColor: _primaryDark,
        unselectedItemColor: _neutralFgDark.withOpacity(0.6),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return _primaryDark;
          }
          return Colors.grey;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return _primaryDark.withOpacity(0.5);
          }
          return Colors.grey.withOpacity(0.3);
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        checkColor: MaterialStateProperty.all(Colors.white),
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return _primaryDark;
          }
          return Colors.transparent;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide(color: _neutralFgDark.withOpacity(0.5), width: 1.5),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF2A3441),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _neutralFgDark.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _neutralFgDark.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _primaryDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _errorDark, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _errorDark, width: 2),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Color(0xFF2A3441),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
      ),
    );
  }
}
