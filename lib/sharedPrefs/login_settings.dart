import 'package:shared_preferences/shared_preferences.dart';

class LoginSettings {
  static String email = 'email';
  static String password = 'pswd';
  static String notificationToken = 'token';

  // ==========================================
  // TRACCAR API SESSION & PREFERENCE KEYS
  // ==========================================
  static String serverUrl = 'server_url';
  static String userToken = 'user_token';
  static String userId = 'user_id';
  static String isLoggedIn = 'is_logged_in';
  static String userCookie = 'user_cookie';

  Future<SharedPreferences> setLoginPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs;
  }

  // ==========================================
  // TRACCAR API BACKEND SESSION INTEGRATION
  // ==========================================

  /// Traccar Session credentials aur server endpoint persistent storage me save karna
  static Future<void> saveTraccarSession({
    required String userEmail,
    required String userPassword,
    String? baseUrl,
    int? id,
    String? token,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(email, userEmail);
    await prefs.setString(password, userPassword);
    await prefs.setBool(isLoggedIn, true);

    if (baseUrl != null) {
      await prefs.setString(serverUrl, baseUrl);
    }
    if (id != null) {
      await prefs.setInt(userId, id);
    }
    if (token != null) {
      await prefs.setString(userToken, token);
    }
  }

  /// Traccar Session token revoke / logout (`/api/session/token/revoke`) par prefs clear karna
  static Future<void> clearTraccarSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(email);
    await prefs.remove(password);
    await prefs.remove(userToken);
    await prefs.remove(userId);
    await prefs.remove(userCookie);
    await prefs.setBool(isLoggedIn, false);
  }

  /// Stored Traccar Server Base URL get karne ka helper (`/api/server`)
  static Future<String> getTraccarServerUrl({String defaultUrl = 'https://demo.traccar.org'}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(serverUrl) ?? defaultUrl;
  }
}
