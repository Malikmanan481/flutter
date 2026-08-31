import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:speedotrack/model/model_notification_event.dart';
import 'package:speedotrack/services/network_helper.dart';

class NotificationProvider with ChangeNotifier {
  List<NotificationScreenEvent> _rows = [];
  bool _isLoading = false;

  List<NotificationScreenEvent> get rows => _rows;
  bool get isLoading => _isLoading;

  void setRows(List<NotificationScreenEvent> newRows) {
    _rows = newRows;
    notifyListeners();
  }

  void addOrUpdateEvent(NotificationScreenEvent event) {
    int index = _rows.indexWhere((e) => e.eventId == event.eventId);
    if (index == -1) {
      _rows.add(event);
    } else {
      _rows[index] = event;
    }
    notifyListeners();
  }

  // ==========================================
  // TRACCAR API & WEBSOCKET BACKEND INTEGRATION
  // ==========================================

  /// Traccar REST API (`/api/reports/events`) se events load karne ka method
  Future<void> fetchTraccarEvents({
    required int deviceId,
    required String fromIso,
    required String toIso,
    NetworkHelper? networkHelper,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final helper = networkHelper ?? NetworkHelper();
      final responseBody = await helper.traccarGetReport(
        'events',
        deviceId: deviceId,
        from: fromIso,
        to: toIso,
      );

      if (responseBody != null && responseBody.toString().isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(responseBody.toString());
        final List<NotificationScreenEvent> fetchedEvents = [];

        for (var item in jsonList) {
          if (item is Map<String, dynamic>) {
            fetchedEvents.add(_convertTraccarJsonToEvent(item));
          }
        }

        // Fresh events list apply kar rahe hain
        setRows(fetchedEvents);
      }
    } catch (e) {
      debugPrint('NotificationProvider: Error fetching Traccar events - $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Traccar WebSocket event payload received event listener helper
  void handleTraccarWebSocketEvent(Map<String, dynamic> eventJson) {
    try {
      final event = _convertTraccarJsonToEvent(eventJson);
      addOrUpdateEvent(event);
    } catch (e) {
      debugPrint('NotificationProvider: WebSocket Event parse error - $e');
    }
  }

  /// Traccar `/api/notifications` API response se user notification settings load karna
  Future<List<dynamic>> fetchUserNotifications({NetworkHelper? networkHelper}) async {
    try {
      final helper = networkHelper ?? NetworkHelper();
      final res = await helper.traccarGet('api/notifications');
      if (res != null && res.toString().isNotEmpty) {
        return jsonDecode(res.toString()) as List<dynamic>;
      }
    } catch (e) {
      debugPrint('NotificationProvider: Error fetching notifications list - $e');
    }
    return [];
  }

  /// Safe helper method to convert Traccar Event JSON to NotificationScreenEvent model
  NotificationScreenEvent _convertTraccarJsonToEvent(Map<String, dynamic> json) {
    return NotificationScreenEvent(
      eventId: json['id'] ?? 0,
      type: json['type']?.toString() ?? 'event',
      eventTime: json['eventTime']?.toString() ?? json['serverTime']?.toString() ?? '',
      deviceId: json['deviceId'] ?? 0,
      positionId: json['positionId'] ?? 0,
      geofenceId: json['geofenceId'] ?? 0,
      maintenanceId: json['maintenanceId'] ?? 0,
      attributes: json['attributes'] is Map<String, dynamic> ? json['attributes'] : {},
    );
  }

  /// Notifications clear karne ke liye
  void clearEvents() {
    _rows.clear();
    notifyListeners();
  }
}
