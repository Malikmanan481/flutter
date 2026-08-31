import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;

class LatLngDelta {
  final LatLng? from;
  final LatLng? to;
  double? rotation;

  LatLngDelta({this.from, this.to, this.rotation});

  // ==========================================
  // TRACCAR API POSITIONS & ANIMATION HELPERS
  // ==========================================

  /// Creates a [LatLngDelta] from previous [LatLng] and new Traccar position JSON (`/api/positions` or `/api/socket`)
  factory LatLngDelta.fromTraccarPosition({
    LatLng? previousLatLng,
    required Map<String, dynamic> newPositionJson,
  }) {
    double? lat = double.tryParse(newPositionJson['latitude']?.toString() ?? '');
    double? lng = double.tryParse(newPositionJson['longitude']?.toString() ?? '');
    double? course = double.tryParse(newPositionJson['course']?.toString() ?? '');

    LatLng? targetLatLng = (lat != null && lng != null) ? LatLng(lat, lng) : null;

    return LatLngDelta(
      from: previousLatLng,
      to: targetLatLng ?? previousLatLng,
      rotation: course,
    );
  }

  /// Creates a [LatLngDelta] directly from two Traccar position JSON payloads
  factory LatLngDelta.fromTraccarPayloads(
    Map<String, dynamic>? oldPositionJson,
    Map<String, dynamic> newPositionJson,
  ) {
    LatLng? oldLatLng;
    if (oldPositionJson != null) {
      double? oldLat = double.tryParse(oldPositionJson['latitude']?.toString() ?? '');
      double? oldLng = double.tryParse(oldPositionJson['longitude']?.toString() ?? '');
      if (oldLat != null && oldLng != null) {
        oldLatLng = LatLng(oldLat, oldLng);
      }
    }

    return LatLngDelta.fromTraccarPosition(
      previousLatLng: oldLatLng,
      newPositionJson: newPositionJson,
    );
  }
}
