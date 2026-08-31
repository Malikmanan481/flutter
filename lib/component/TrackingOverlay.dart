import 'package:flutter/material.dart';
import 'package:speedotrack/activity/activity_tracking.dart';

class TrackingOverlay {
  OverlayEntry? _overlayEntry;

  void showTrackingOverlay({
    required BuildContext context,
    required String lat,
    required String lng,
    required int speed,
    required String angle,
    required String name,
    required String imei,
    required String status,
    required String statusMessage,
    int? deviceId,
  }) {
    // Prevent duplicate overlays from stacking
    if (_overlayEntry != null) {
      hideTrackingOverlay();
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          TrackingActivity(
            lat: lat,
            lng: lng,
            speed: speed,
            angle: angle,
            name: name,
            imei: imei,
            status: status,
            statusMessage: statusMessage,
          ),
        ],
      ),
    );

    Overlay.of(context)?.insert(_overlayEntry!);
  }

  /// Direct helper method to launch tracking overlay using Traccar API responses
  /// Map data directly from Traccar GET /api/devices and GET /api/positions or WebSockets
  void showFromTraccar({
    required BuildContext context,
    required Map<String, dynamic> device,
    Map<String, dynamic>? position,
  }) {
    // Traccar speed comes in knots from /api/positions. Multiply by 1.852 for km/h.
    double speedInKnots = (position?['speed'] ?? 0).toDouble();
    int speedKmH = (speedInKnots * 1.852).round();

    showTrackingOverlay(
      context: context,
      lat: (position?['latitude'] ?? 0.0).toString(),
      lng: (position?['longitude'] ?? 0.0).toString(),
      speed: speedKmH,
      angle: (position?['course'] ?? 0).toString(),
      name: device['name'] ?? 'Unknown Device',
      imei: device['uniqueId'] ?? '',
      status: device['status'] ?? 'unknown',
      statusMessage: position?['attributes']?['alarm'] ??
          (device['status'] == 'online' ? 'Moving' : 'Stopped'),
      deviceId: device['id'],
    );
  }

  void hideTrackingOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
