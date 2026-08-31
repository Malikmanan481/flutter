library latlng;

// Core Geometry & Projection Exports
export 'src/latlng.dart';
export 'src/projection.dart';
export 'src/tile_index.dart';

// ==========================================
// TRACCAR API POSITIONS & ROUTE ADAPTERS
// ==========================================

import 'src/latlng.dart';
import 'src/tile_index.dart';

/// Traccar REST API & WebSocket payload parser for [CustomLatLng] and [TileIndex]
extension TraccarLatLngExtension on CustomLatLng {
  /// Converts Traccar API position JSON (`/api/positions`, `/api/socket`) to [CustomLatLng]
  static CustomLatLng? fromTraccarPosition(Map<String, dynamic> json) {
    if (json.containsKey('latitude') && json.containsKey('longitude')) {
      final double? lat = double.tryParse(json['latitude']?.toString() ?? '');
      final double? lng = double.tryParse(json['longitude']?.toString() ?? '');
      if (lat != null && lng != null) {
        return CustomLatLng(lat, lng);
      }
    }
    return null;
  }

  /// Parses list of positions from Traccar historical route reports (`/api/reports/route`)
  static List<CustomLatLng> parseTraccarRouteReport(List<dynamic> jsonList) {
    final List<CustomLatLng> points = [];
    for (var item in jsonList) {
      if (item is Map<String, dynamic>) {
        final point = fromTraccarPosition(item);
        if (point != null) points.add(point);
      }
    }
    return points;
  }
}
