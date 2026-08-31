import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPrefs {
  // ignore: non_constant_identifier_names
  String MOVING_VEHICLE = 'moving_color';

  // ignore: non_constant_identifier_names
  String STOPPED_VEHICLE = 'stopped_color';

  // ignore: non_constant_identifier_names
  String OFFLINE_VEHICLE = 'offine_color';

  // ignore: non_constant_identifier_names
  String NO_DATA_VEHICLE = 'no_data_color';

  // ignore: non_constant_identifier_names
  String IDLE_VEHICLE = 'offline_color';

  // ignore: non_constant_identifier_names
  String IS_NOTIFICATION = 'is_notification';

  // ignore: non_constant_identifier_names
  String THEME_COLOR = 'themeColor';

  // ignore: non_constant_identifier_names
  String CHOOSE_ICON = 'choose_icon';

  // ignore: non_constant_identifier_names
  String UNIQUE_NUMBER = 'unique_number';

  // ignore: non_constant_identifier_names
  String MAP_TYPE = 'map_type';

  // ignore: non_constant_identifier_names
  String ISNOTIFICATION = 'is_notification';

  // ignore: non_constant_identifier_names
  String LOCALE = 'locale';

  // ignore: non_constant_identifier_names
  String IS_CUSTOM_MARKER = 'is_custom_marker';

  Future<SharedPreferences> setSettingsPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs;
  }

  // ==========================================
  // TRACCAR API BACKEND SETTINGS INTEGRATION
  // ==========================================

  /// Traccar user/session response (`/api/session`, `/api/users/{id}`) se preferences sync karna
  static Future<void> syncWithTraccarUser(Map<String, dynamic> userJson) async {
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsPrefs();

    if (userJson.containsKey('attributes') && userJson['attributes'] is Map) {
      final attrs = userJson['attributes'] as Map<String, dynamic>;

      if (attrs.containsKey('movingColor')) {
        await prefs.setString(settings.MOVING_VEHICLE, attrs['movingColor'].toString());
      }
      if (attrs.containsKey('stoppedColor')) {
        await prefs.setString(settings.STOPPED_VEHICLE, attrs['stoppedColor'].toString());
      }
      if (attrs.containsKey('offlineColor')) {
        await prefs.setString(settings.OFFLINE_VEHICLE, attrs['offlineColor'].toString());
      }
      if (attrs.containsKey('idleColor')) {
        await prefs.setString(settings.IDLE_VEHICLE, attrs['idleColor'].toString());
      }
      if (attrs.containsKey('mapType')) {
        await prefs.setString(settings.MAP_TYPE, attrs['mapType'].toString());
      }
      if (attrs.containsKey('themeColor')) {
        await prefs.setString(settings.THEME_COLOR, attrs['themeColor'].toString());
      }
    }

    if (userJson.containsKey('userLanguage') || userJson.containsKey('lang')) {
      final lang = userJson['userLanguage'] ?? userJson['lang'];
      if (lang != null) {
        await prefs.setString(settings.LOCALE, lang.toString());
      }
    }
  }

  /// Traccar Device Status (`online`, `offline`, `unknown`, `moving`, `stopped`, `idle`) ke mutabiq status color code fetch karna
  static Future<String> getVehicleStatusColor(String status, {double speed = 0.0}) async {
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsPrefs();

    final normalizedStatus = status.toLowerCase();

    if (normalizedStatus == 'online' || normalizedStatus == 'moving') {
      if (speed > 0) {
        return prefs.getString(settings.MOVING_VEHICLE) ?? '#4CAF50'; // Green
      } else {
        return prefs.getString(settings.IDLE_VEHICLE) ?? '#FF9800'; // Orange
      }
    } else if (normalizedStatus == 'stopped') {
      return prefs.getString(settings.STOPPED_VEHICLE) ?? '#F44336'; // Red
    } else if (normalizedStatus == 'offline') {
      return prefs.getString(settings.OFFLINE_VEHICLE) ?? '#9E9E9E'; // Grey
    } else {
      return prefs.getString(settings.NO_DATA_VEHICLE) ?? '#607D8B'; // Blue Grey
    }
  }

  /// Local settings preferences ko Traccar backend attributes format (`/api/users/{id}` PUT request) me format करना
  static Future<Map<String, dynamic>> toTraccarAttributesMap() async {
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsPrefs();

    return {
      'movingColor': prefs.getString(settings.MOVING_VEHICLE),
      'stoppedColor': prefs.getString(settings.STOPPED_VEHICLE),
      'offlineColor': prefs.getString(settings.OFFLINE_VEHICLE),
      'idleColor': prefs.getString(settings.IDLE_VEHICLE),
      'mapType': prefs.getString(settings.MAP_TYPE),
      'themeColor': prefs.getString(settings.THEME_COLOR),
      'isCustomMarker': prefs.getBool(settings.IS_CUSTOM_MARKER),
      'isNotification': prefs.getBool(settings.IS_NOTIFICATION),
    };
  }
}
