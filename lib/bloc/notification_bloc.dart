import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rxdart/subjects.dart';
import 'package:speedotrack/fragments/fragment_notification.dart';

class NotificationBloc {
  final StreamController<List<NotificationItemModel>>
      _notificationListStreamController =
      BehaviorSubject<List<NotificationItemModel>>();

  Stream<List<NotificationItemModel>> get notificationListStream =>
      _notificationListStreamController.stream;

  StreamSink<List<NotificationItemModel>> get notificationListSink =>
      _notificationListStreamController.sink;

  NotificationBloc();

  // ==========================================
  // TRACCAR API BACKEND INTEGRATION
  // ==========================================

  /// Fetch event notifications (/api/reports/events) directly from Traccar REST API
  Future<void> fetchTraccarEvents({
    required String baseUrl,
    required DateTime fromTime,
    required DateTime toTime,
    List<int>? deviceIds,
    Map<String, String>? headers,
  }) async {
    try {
      final String cleanUrl =
          baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

      final Map<String, String> requestHeaders = headers ??
          {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          };

      // Construct query parameters for Traccar event report
      final Uri uri = Uri.parse('$cleanUrl/api/reports/events').replace(
        queryParameters: {
          if (deviceIds != null && deviceIds.isNotEmpty)
            'deviceId': deviceIds.map((e) => e.toString()).toList(),
          'from': fromTime.toUtc().toIso8601String(),
          'to': toTime.toUtc().toIso8601String(),
        },
      );

      final response = await http.get(uri, headers: requestHeaders);

      if (response.statusCode == 200) {
        final List<dynamic> eventsJson = jsonDecode(response.body) as List<dynamic>;
        final List<NotificationItemModel> notificationList =
            _mapTraccarEventsToModels(eventsJson);

        if (!_notificationListStreamController.isClosed) {
          notificationListSink.add(notificationList);
        }
      }
    } catch (_) {
      // Prevents stream interruption on error
    }
  }

  /// Direct method to stream events received from Traccar WebSocket / Push alerts
  void updateFromTraccarEventsRaw(List<Map<String, dynamic>> rawEvents) {
    final List<NotificationItemModel> notificationList =
        _mapTraccarEventsToModels(rawEvents);

    if (!_notificationListStreamController.isClosed) {
      notificationListSink.add(notificationList);
    }
  }

  /// Internal helper to parse Traccar Event JSON objects into NotificationItemModel
  List<NotificationItemModel> _mapTraccarEventsToModels(
      List<dynamic> eventsJson) {
    return eventsJson.map((event) {
      final Map<String, dynamic> map = event as Map<String, dynamic>;

      // Traccar Event Attributes & Types
      final String eventType = map['type']?.toString() ?? 'alert';
      final String eventTime = map['eventTime']?.toString() ??
          map['serverTime']?.toString() ??
          '';

      // Safe mapping to NotificationItemModel properties
      return NotificationItemModel(
        title: _formatTraccarEventType(eventType),
        message: 'Device ID: ${map['deviceId'] ?? 'Unknown'}',
        time: eventTime,
        type: eventType,
        rawEventJson: map,
      );
    }).toList();
  }

  /// Formats raw Traccar event type strings into readable headings
  String _formatTraccarEventType(String type) {
    switch (type) {
      case 'deviceOnline':
        return 'Device Online';
      case 'deviceOffline':
        return 'Device Offline';
      case 'deviceMoving':
        return 'Device Moving';
      case 'deviceStopped':
        return 'Device Stopped';
      case 'deviceOverspeed':
        return 'Speed Alert';
      case 'geofenceEnter':
        return 'Geofence Entered';
      case 'geofenceExit':
        return 'Geofence Exited';
      case 'ignitionOn':
        return 'Ignition ON';
      case 'ignitionOff':
        return 'Ignition OFF';
      case 'alarm':
        return 'SOS / Alarm Alert';
      default:
        return 'Notification';
    }
  }

  bool isClosed() {
    return _notificationListStreamController.isClosed;
  }

  void dispose() {
    _notificationListStreamController.close();
  }
}
