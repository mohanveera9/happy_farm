import 'package:flutter/material.dart';

class AppTheme {
  // Colors based on Sabbafarm website
  static const Color primaryColor =
      Color(0xFF007B4F); // Green color from the website
  static const Color accentColor = Color(0xFF8BC34A); // Light green
  static const Color textDarkColor = Color(0xFF333333);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color secondaryColor = Colors.grey;

  // Light theme
  static final ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: accentColor,
      tertiary: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white, // White background
      elevation: 4, // Adds subtle shadow
      shadowColor: Colors.black12, // Optional: Customize shadow color
      iconTheme: IconThemeData(color: AppTheme.textDarkColor), // Dark icons
      titleTextStyle: TextStyle(
        color: AppTheme.textDarkColor, // Dark title text
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: textDarkColor,
        fontSize: 26.0,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: TextStyle(
        color: textDarkColor,
        fontSize: 22.0,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: TextStyle(
        color: textDarkColor,
        fontSize: 18.0,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(
        color: textDarkColor,
        fontSize: 16.0,
      ),
      bodyMedium: TextStyle(
        color: textDarkColor,
        fontSize: 14.0,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      ),
    ),
  );
}
