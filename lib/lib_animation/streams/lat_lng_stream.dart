import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;

class LatLngStream {
  final _controller = StreamController<LatLng>.broadcast();

  Stream<LatLng> get stream => _controller.stream;

  void addLatLng(latLng) {
    if (latLng is LatLng) {
      _controller.sink.add(latLng);
    }
  }

  // ==========================================
  // TRACCAR REST API & WEBSOCKET INTEGRATION
  // ==========================================

  /// Parses raw position JSON from Traccar (`/api/positions` or `/api/socket`) and pushes to stream
  void addTraccarPosition(Map<String, dynamic> positionJson) {
    if (positionJson.containsKey('latitude') && positionJson.containsKey('longitude')) {
      final double? lat = double.tryParse(positionJson['latitude']?.toString() ?? '');
      final double? lng = double.tryParse(positionJson['longitude']?.toString() ?? '');

      if (lat != null && lng != null) {
        _controller.sink.add(LatLng(lat, lng));
      }
    }
  }

  /// Streams multiple position coordinates from Traccar historical route reports (`/api/reports/route`)
  void addTraccarPositionsList(List<dynamic> positionsList) {
    for (var pos in positionsList) {
      if (pos is Map<String, dynamic>) {
        addTraccarPosition(pos);
      }
    }
  }

  dispose() {
    _controller.close();
  }
}
