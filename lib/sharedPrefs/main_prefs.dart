import 'package:shared_preferences/shared_preferences.dart';

class MainPrefs {
  static String isLoggedIn = 'is_logged_in';
  static String fnSettings = 'fn_settings';
  static String notificationPrefs = 'notification_pref';
  static String keyIMEI = 'imei';
  static String appFirstTime = 'app_first_time';
  static String isFirstTime = 'IS_FIRST_TIME';

  // ==========================================
  // TRACCAR API BACKEND KEYS
  // ==========================================
  static String selectedDeviceId = 'traccar_selected_device_id';
  static String selectedUniqueId = 'traccar_selected_unique_id';
  static String traccarServerUrl = 'traccar_server_url';
  static String traccarSessionCookie = 'traccar_session_cookie';

  Future<SharedPreferences> setMainPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs;
  }

  // ==========================================
  // TRACCAR API BACKEND HELPER METHODS
  // ==========================================

  /// Selected Traccar Device ID & Unique ID (IMEI) persistent storage me save karne ka method
  static Future<void> setSelectedTraccarDevice({
    required int deviceId,
    required String uniqueId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(selectedDeviceId, deviceId);
    await prefs.setString(selectedUniqueId, uniqueId);
    await prefs.setString(keyIMEI, uniqueId); // Syncing with existing IMEI key
  }

  /// Currently active Traccar Device ID fetch karna (`/api/positions`, `/api/devices/{id}` calls ke liye)
  static Future<int?> getSelectedDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(selectedDeviceId);
  }

  /// Currently active Traccar Device UniqueId / IMEI get karne ka helper
  static Future<String?> getSelectedUniqueId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(selectedUniqueId) ?? prefs.getString(keyIMEI);
  }

  /// Device IMEI ko save aur Traccar UniqueId ke sath sync karne ka helper
  static Future<void> saveImei(String imei) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyIMEI, imei);
    await prefs.setString(selectedUniqueId, imei);
  }

  /// User logout ya session clear hone par main preferences reset karne ka method
  static Future<void> clearMainPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(isLoggedIn);
    await prefs.remove(selectedDeviceId);
    await prefs.remove(selectedUniqueId);
    await prefs.remove(traccarSessionCookie);
  }
}
