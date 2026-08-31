import 'dart:math';

class TileIndex {
  double? x;
  double? y;

  TileIndex(this.x, this.y);

  // ==========================================
  // TRACCAR API POSITIONS TO TILE CONVERSION
  // ==========================================

  /// Creates a [TileIndex] directly from a Traccar position JSON object (`/api/positions` or `/api/socket`)
  /// at a given map zoom level using Mercator projection EPSG:4326.
  factory TileIndex.fromTraccarPosition(
    Map<String, dynamic> positionJson, {
    double zoom = 0.0,
  }) {
    if (positionJson.containsKey('latitude') &&
        positionJson.containsKey('longitude')) {
      final double? lat =
          double.tryParse(positionJson['latitude']?.toString() ?? '');
      final double? lng =
          double.tryParse(positionJson['longitude']?.toString() ?? '');

      if (lat != null && lng != null) {
        final double normX = (lng + 180.0) / 360.0;
        final double sinLatitude = sin(lat * pi / 180.0);
        final double normY =
            0.5 - log((1.0 + sinLatitude) / (1.0 - sinLatitude)) / (4.0 * pi);

        final double mapSize = pow(2.0, zoom).toDouble();
        return TileIndex(normX * mapSize, normY * mapSize);
      }
    }
    return TileIndex(0.0, 0.0);
  }

  /// Parses a list of Traccar position JSON objects (`/api/reports/route`) to `List<TileIndex>`
  static List<TileIndex> parseTraccarPositions(
    List<dynamic> jsonList, {
    double zoom = 0.0,
  }) {
    final List<TileIndex> tileIndices = [];
    for (var item in jsonList) {
      if (item is Map<String, dynamic>) {
        tileIndices.add(TileIndex.fromTraccarPosition(item, zoom: zoom));
      }
    }
    return tileIndices;
  }

  @override
  String toString() => 'TileIndex(x: $x, y: $y)';
}
