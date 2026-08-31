import 'package:flutter/material.dart';

ThemeData appTheme() {
  return ThemeData(
    primarySwatch: Colors.blue,
    textTheme: TextTheme(
      titleSmall: TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Color(0xFF425398),
      ),
      displayMedium: TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Color(0xFF425398),
      ),
      titleLarge: TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Color(0xFF425398),
      ),
      titleMedium: TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 17,
        fontWeight: FontWeight.normal,
        color: Color(0xFF425398),
      ),
    ),
  );
}

// ==========================================
// TRACCAR API BACKEND THEME INTEGRATION
// ==========================================

class TraccarThemeBackend {
  /// Traccar `/api/server` ya `/api/users/{id}` response ke `attributes` se dynamic theme update karne ka method
  static ThemeData dynamicAppTheme(Map<String, dynamic>? attributes) {
    Color primaryColor = const Color(0xFF425398); // Default original theme color

    // Traccar server/user attributes se primary color fetch karna
    if (attributes != null && attributes.containsKey('primaryColor')) {
      final colorHex = attributes['primaryColor'].toString();
      primaryColor = _parseColorHex(colorHex, fallback: primaryColor);
    }

    return ThemeData(
      primaryColor: primaryColor,
      primarySwatch: _createMaterialColor(primaryColor),
      textTheme: TextTheme(
        titleSmall: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 17,
          fontWeight: FontWeight.normal,
          color: primaryColor,
        ),
      ),
    );
  }

  /// Traccar server attributes Hex color code (e.g. "#425398") parse karne ka helper
  static Color _parseColorHex(String hexString, {Color fallback = const Color(0xFF425398)}) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  /// Primary color se custom MaterialColor palette generate karna
  static MaterialColor _createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
}
