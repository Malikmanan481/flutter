import 'package:flutter/material.dart';
import 'package:speedotrack/data/data_onboard_page.dart';

class ColorProvider with ChangeNotifier {
  Color _color = onboardData[0].accentColor;

  Color get color => _color;

  set color(Color color) {
    _color = color;
    notifyListeners();
  }

  // ==========================================
  // TRACCAR API BACKEND COLOR & THEME INTEGRATION
  // ==========================================

  /// Hex string (e.g. "#FF5722" ya "FF5722") ko Flutter Color me parse aur update karne ka helper
  void setColorFromHex(String hexString) {
    try {
      final buffer = StringBuffer();
      String cleanHex = hexString.replaceFirst('#', '');
      if (cleanHex.length == 6) {
        buffer.write('ff'); // default full opacity
      }
      buffer.write(cleanHex);
      _color = Color(int.parse(buffer.toString(), radix: 16));
      notifyListeners();
    } catch (e) {
      debugPrint('ColorProvider: Error parsing hex color from Traccar attributes - $e');
    }
  }

  /// Traccar `/api/session` ya `/api/users` response ke attributes se custom user accent color sync karna
  void syncWithTraccarUser(Map<String, dynamic> userJson) {
    if (userJson.containsKey('attributes') && userJson['attributes'] is Map) {
      final attrs = userJson['attributes'] as Map<String, dynamic>;
      final hexColor = attrs['accentColor'] ?? attrs['color'] ?? attrs['userColor'];
      if (hexColor != null && hexColor.toString().isNotEmpty) {
        setColorFromHex(hexColor.toString());
      }
    }
  }

  /// Traccar `/api/server` response se server-wide branding color load karna
  void syncWithTraccarServer(Map<String, dynamic> serverJson) {
    if (serverJson.containsKey('attributes') && serverJson['attributes'] is Map) {
      final attrs = serverJson['attributes'] as Map<String, dynamic>;
      final hexColor = attrs['colorPrimary'] ?? attrs['accentColor'] ?? attrs['colorPrimaryHex'];
      if (hexColor != null && hexColor.toString().isNotEmpty) {
        setColorFromHex(hexColor.toString());
      }
    }
  }
}
