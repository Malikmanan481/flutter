import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StaticVarMethod {

  // static String listimageurl= 'assets/appsicon/roadpoint.jpeg';
  // static String loginimageurl= 'assets/appsicon/roadpoint.jpeg';
  // static String splashimageurl= 'assets/appsicon/roadpoint.jpeg';

  // static String listimageurl= 'assets/appsicon/wonderlevel.jpg';
  // static String loginimageurl= 'assets/appsicon/wonderlevel.jpg';
  // static String splashimageurl= 'assets/appsicon/wonderlevel.jpg';

  static String listimageurl = 'assets/appsicon/appIcon.png';
  static String loginimageurl = 'assets/appsicon/appIcon.png';
  static String splashimageurl = 'assets/appsicon/appIcon.png';

  // ==========================================
  // TRACCAR REST API SERVER & ENDPOINTS CONFIG
  // ==========================================

  /// Traccar Base URL Configuration
  static String baseurl = 'https://demo.traccar.org/';

  /// Authentication & Session Endpoints
  static String apiSession = 'api/session';
  static String apiSessionToken = 'api/session/token';
  static String apiPasswordReset = 'api/password/reset';

  /// Core Telematics Endpoints
  static String apiDevices = 'api/devices';
  static String apiPositions = 'api/positions';
  static String apiEvents = 'api/events';
  static String apiGeofences = 'api/geofences';
  static String apiCommandsSend = 'api/commands/send';
  static String apiDrivers = 'api/drivers';
  static String apiMaintenance = 'api/maintenance';

  /// Reports Endpoints
  static String apiReportsSummary = 'api/reports/summary';
  static String apiReportsTrips = 'api/reports/trips';
  static String apiReportsStops = 'api/reports/stops';
  static String apiReportsRoute = 'api/reports/route';
  static String apiReportsEvents = 'api/reports/events';
  static String apiReportsGeofences = 'api/reports/geofences';

  /// Notifications Endpoints
  static String apiNotifications = 'api/notifications';

  /// SharedPreferences Storage Keys
  static const String keyUserEmail = 'user_email';
  static const String keyUserPassword = 'user_password';
  static const String keyUserToken = 'user_token';
  static const String keySessionCookie = 'session_cookie';
  static const String keyIsLoggedIn = 'is_logged_in';

  // ==========================================
  // TRACCAR AUTHENTICATION & HEADER HELPERS
  // ==========================================

  /// Generates Basic Auth header for Traccar login (`/api/session`)
  static Map<String, String> getBasicAuthHeader(String email, String password) {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$email:$password'));
    return {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Authorization': basicAuth,
    };
  }

  /// Generates Standard API Request Headers (Using Session Cookie or Bearer Token)
  static Map<String, String> getTraccarHeaders({String? sessionCookie, String? userToken}) {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (sessionCookie != null && sessionCookie.isNotEmpty) {
      headers['Cookie'] = sessionCookie;
    } else if (userToken != null && userToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $userToken';
    }

    return headers;
  }

  /// Builds WebSocket live update URL using Traccar Server Base URL
  static String getWebSocketUrl({required String serverBaseUrl, String? sessionCookie}) {
    String wsBase = serverBaseUrl.replaceAll('http://', 'ws://').replaceAll('https://', 'wss://');
    if (!wsBase.endsWith('/')) {
      wsBase += '/';
    }
    return '${wsBase}api/socket';
  }
}
