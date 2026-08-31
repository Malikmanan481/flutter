import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MainPrefsObject {
  static String isLoggedIn = 'is_logged_in';
  static String fnObjects = 'fn_objects';
  static String fnSettings = 'fn_settings';
  static String notificationPrefs = 'notification_pref';
  static String keyIMEI = 'imei';
  static String appFirstTime = 'app_first_time';
  static String isFirstTime = 'IS_FIRST_TIME';

  // ==========================================
  // TRACCAR API BACKEND OBJECT CACHE KEYS
  // ==========================================
  static String cachedDevices = 'traccar_cached_devices';
  static String cachedPositions = 'traccar_cached_positions';
  static String cachedGeofences = 'traccar_cached_geofences';
  static String cachedUserObject = 'traccar_cached_user';

  Future<SharedPreferences> setMainPrefsObjects() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs;
  }

  // ==========================================
  // TRACCAR API BACKEND OBJECT HELPER METHODS
  // ==========================================

  /// Traccar `/api/devices` se mili devices list ko offline cache me save karna
  static Future<void> saveCachedDevices(List<dynamic> devicesList) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(cachedDevices, jsonEncode(devicesList));
  }

  /// Offline cache se Traccar devices list get karna
  static Future<List<dynamic>> getCachedDevices() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(cachedDevices);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        return jsonDecode(jsonStr) as List<dynamic>;
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  /// Traccar `/api/positions` data cache me store karna
  static Future<void> saveCachedPositions(List<dynamic> positionsList) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(cachedPositions, jsonEncode(positionsList));
  }

  /// Offline cache se last known Traccar positions get karna
  static Future<List<dynamic>> getCachedPositions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(cachedPositions);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        return jsonDecode(jsonStr) as List<dynamic>;
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  /// Traccar `/api/users/{id}` ya session user object cache me store karna
  static Future<void> saveCachedUser(Map<String, dynamic> userMap) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(cachedUserObject, jsonEncode(userMap));
  }

  /// Cached Traccar user object fetch karna
  static Future<Map<String, dynamic>?> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(cachedUserObject);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        return jsonDecode(jsonStr) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Cached Traccar data reset/clear karne ke liye
  static Future<void> clearCachedObjects() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(cachedDevices);
    await prefs.remove(cachedPositions);
    await prefs.remove(cachedGeofences);
    await prefs.remove(cachedUserObject);
    await prefs.remove(fnObjects);
  }
}
