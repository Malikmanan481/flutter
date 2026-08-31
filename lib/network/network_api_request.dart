import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:requests/requests.dart';
import '../globals.dart';

class NetworkHelper {
  /// Per-attempt timeout for normal requests. A mobile request must never
  /// hang longer than this. The old value here was 3600s (1 HOUR) — a single
  /// stuck request froze the UI on an infinite loading spinner, which is
  /// exactly what App Store users were seeing.
  static const int _attemptTimeoutSeconds = 30;

  /// Per-attempt timeout for the explicitly "long-running" request variants
  /// (the *WithTimeout* methods exist on purpose for heavier endpoints).
  /// Still bounded — generous, but never an hour.
  static const int _longAttemptTimeoutSeconds = 90;

  /// Total attempts = 1 initial try + retries.
  static const int _maxAttempts = 3;

  /// Runs [attempt] up to [_maxAttempts] times, consulting [_retryPolicy]
  /// between failures. Returns the response body, or '' if every attempt
  /// fails. The '' fallback intentionally preserves the previous return
  /// contract so no existing caller needs to change.
  Future<dynamic> _withRetry(Future<Response> Function() attempt) async {
    for (var n = 1; n <= _maxAttempts; n++) {
      try {
        final response = await attempt();
        return response.body;
      } catch (e) {
        final Duration? wait = _retryPolicy(n, e);
        if (wait == null || n == _maxAttempts) {
          // Surface the real cause in logs instead of silently discarding it.
          debugPrint('NetworkHelper: giving up after attempt $n — $e');
          return '';
        }
        debugPrint('NetworkHelper: attempt $n failed ($e) — retrying in $wait');
        await Future.delayed(wait);
      }
    }
    return '';
  }

  /// Decide whether — and how long to wait before — retrying a failed request.
  static Duration? _retryPolicy(int attempt, Object error) {
    final errStr = error.toString().toLowerCase();

    // Fast-fail on non-retriable authentication, authorization, or unreachable route errors
    if (errStr.contains('401') ||
        errStr.contains('403') ||
        errStr.contains('404') ||
        errStr.contains('no route to host') ||
        errStr.contains('socketexception')) {
      return null;
    }

    // Exponential backoff: 500ms -> 1000ms -> 2000ms
    return Duration(milliseconds: 500 * (1 << (attempt - 1)));
  }

  Future<dynamic> requestDataFromNetwork(
      {String? urlFile, dynamic body, BuildContext? context}) {
    final baseURL = '${Globals.baseUrl}/$urlFile';
    return _withRetry(() => Requests.post(baseURL,
        body: body,
        timeoutSeconds: _attemptTimeoutSeconds,
        persistCookies: true));
  }

  Future<dynamic> requestDataFromNetworkWithTimeout(
      {String? urlFile, dynamic body, BuildContext? context}) {
    final baseURL = '${Globals.baseUrl}/$urlFile';
    return _withRetry(() => Requests.post(baseURL,
        body: body, timeoutSeconds: _longAttemptTimeoutSeconds));
  }

  Future<dynamic> requestDataFromNetworkWithTimeoutGET(
      {String? urlFile, dynamic body, BuildContext? context}) {
    final baseURL = '${Globals.baseUrl}/$urlFile';
    return _withRetry(() => Requests.get(baseURL,
        queryParameters: body, timeoutSeconds: _longAttemptTimeoutSeconds));
  }

  Future<dynamic> requestWeatherFromNetworkGET(
      {String? lat, String? lng, BuildContext? context}) {
    final baseURL =
        'http://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lng&units=metric&appid=7de33ca156c91dcf5c030b105acad0bd';
    return _withRetry(() =>
        Requests.get(baseURL, timeoutSeconds: _attemptTimeoutSeconds));
  }

  // ==========================================
  // TRACCAR REST API BACKEND INTEGRATION
  // ==========================================

  /// Base Traccar API execution helper with session persistence
  Future<dynamic> traccarGet(String endpoint,
      {Map<String, dynamic>? queryParams}) {
    final cleanEndpoint =
        endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    final url = '${Globals.baseUrl}/$cleanEndpoint';

    return _withRetry(() => Requests.get(
          url,
          queryParameters: queryParams,
          timeoutSeconds: _attemptTimeoutSeconds,
          persistCookies: true,
          headers: {'Accept': 'application/json'},
        ));
  }

  /// Traccar POST API helper (Supports JSON payload & urlencoded session logins)
  Future<dynamic> traccarPost(String endpoint, {dynamic body}) {
    final cleanEndpoint =
        endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    final url = '${Globals.baseUrl}/$cleanEndpoint';

    return _withRetry(() => Requests.post(
          url,
          body: body,
          bodyEncoding: RequestBodyEncoding.FormURLEncoded,
          timeoutSeconds: _attemptTimeoutSeconds,
          persistCookies: true,
          headers: {'Accept': 'application/json'},
        ));
  }

  /// Traccar PUT API helper (For updating devices, users, geofences)
  Future<dynamic> traccarPut(String endpoint, {dynamic body}) {
    final cleanEndpoint =
        endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    final url = '${Globals.baseUrl}/$cleanEndpoint';

    return _withRetry(() => Requests.put(
          url,
          body: body,
          bodyEncoding: RequestBodyEncoding.JSON,
          timeoutSeconds: _attemptTimeoutSeconds,
          persistCookies: true,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
          },
        ));
  }

  /// Traccar DELETE API helper
  Future<dynamic> traccarDelete(String endpoint) {
    final cleanEndpoint =
        endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    final url = '${Globals.baseUrl}/$cleanEndpoint';

    return _withRetry(() => Requests.delete(
          url,
          timeoutSeconds: _attemptTimeoutSeconds,
          persistCookies: true,
        ));
  }

  /// Authenticate session with Traccar (`/api/session`)
  Future<dynamic> traccarLogin(String email, String password) {
    return traccarPost('api/session', body: {
      'email': email,
      'password': password,
    });
  }

  /// Fetch devices list (`/api/devices`)
  Future<dynamic> traccarGetDevices() {
    return traccarGet('api/devices');
  }

  /// Fetch latest positions (`/api/positions`)
  Future<dynamic> traccarGetPositions({int? deviceId}) {
    return traccarGet('api/positions',
        queryParams: deviceId != null ? {'deviceId': deviceId} : null);
  }

  /// Send commands to device (`/api/commands/send`)
  Future<dynamic> traccarSendCommand(Map<String, dynamic> commandJson) {
    return traccarPost('api/commands/send', body: commandJson);
  }

  /// Fetch Traccar Reports (`/api/reports/route`, `/api/reports/trips`, `/api/reports/stops`, etc.)
  Future<dynamic> traccarGetReport(String reportType,
      {required int deviceId, required String from, required String to}) {
    return traccarGet('api/reports/$reportType', queryParams: {
      'deviceId': deviceId,
      'from': from,
      'to': to,
    });
  }
}
