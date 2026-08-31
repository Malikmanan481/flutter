import 'dart:math';

import 'latlng.dart';
import 'tile_index.dart';

abstract class Projection {
  const Projection();

  /// Converts a [LatLng] to its corresponing X-Y screen coordinates.
  TileIndex fromLngLatToTileIndex(CustomLatLng location);

  /// Converts a [TileIndex] to its corresponing geo-coordinates.
  CustomLatLng fromTileIndexToLngLat(TileIndex tile);

  TileIndex fromLngLatToTileIndexWithZoom(CustomLatLng location, double zoom) {
    var ret = fromLngLatToTileIndex(location);

    var mapSize = pow(2.0, zoom);

    return new TileIndex(ret.x! * mapSize, ret.y! * mapSize);
  }

  CustomLatLng fromTileIndexToLngLatWithZoom(TileIndex tile, double zoom) {
    var mapSize = pow(2, zoom);

    final x = tile.x! / mapSize;
    final y = tile.y! / mapSize;

    final normalTile = new TileIndex(x, y);

    return fromTileIndexToLngLat(normalTile);
  }

  // ==========================================
  // TRACCAR API POSITIONS & TILE HELPERS
  // ==========================================

  /// Converts a raw Traccar position JSON object (`/api/positions` or `/api/socket`)
  /// directly to a [TileIndex] at standard level.
  TileIndex? fromTraccarPositionToTileIndex(Map<String, dynamic> positionJson) {
    if (positionJson.containsKey('latitude') &&
        positionJson.containsKey('longitude')) {
      final double? lat =
          double.tryParse(positionJson['latitude']?.toString() ?? '');
      final double? lng =
          double.tryParse(positionJson['longitude']?.toString() ?? '');
      if (lat != null && lng != null) {
        return fromLngLatToTileIndex(CustomLatLng(lat, lng));
      }
    }
    return null;
  }

  /// Converts a raw Traccar position JSON object (`/api/positions` or `/api/socket`)
  /// to a [TileIndex] with the specified map zoom level.
  TileIndex? fromTraccarPositionToTileIndexWithZoom(
      Map<String, dynamic> positionJson, double zoom) {
    if (positionJson.containsKey('latitude') &&
        positionJson.containsKey('longitude')) {
      final double? lat =
          double.tryParse(positionJson['latitude']?.toString() ?? '');
      final double? lng =
          double.tryParse(positionJson['longitude']?.toString() ?? '');
      if (lat != null && lng != null) {
        return fromLngLatToTileIndexWithZoom(CustomLatLng(lat, lng), zoom);
      }
    }
    return null;
  }

  /// Converts a list of Traccar position JSON objects (`/api/reports/route`)
  /// to a list of [TileIndex] at a specified zoom level.
  List<TileIndex> parseTraccarPositionsToTileIndices(
      List<dynamic> positionsList, double zoom) {
    final List<TileIndex> indices = [];
    for (var pos in positionsList) {
      if (pos is Map<String, dynamic>) {
        final tile = fromTraccarPositionToTileIndexWithZoom(pos, zoom);
        if (tile != null) {
          indices.add(tile);
        }
      }
    }
    return indices;
  }
}

/// The Mercator projection is a cylindrical map projection presented
/// by Flemish geographer and cartographer Gerardus Mercator in 1569.
/// It became the standard map projection for navigation because of
/// its unique property of representing any course of constant bearing
/// as a straight segment.
class EPSG4326 extends Projection {
  static const EPSG4326 instance = EPSG4326();

  const EPSG4326();

  @override
  TileIndex fromLngLatToTileIndex(CustomLatLng location) {
    final lng = location.longitude;
    final lat = location.latitude;

    double x = (lng! + 180.0) / 360.0;
    double sinLatitude = sin(lat! * pi / 180.0);
    double y =
        0.5 - log((1.0 + sinLatitude) / (1.0 - sinLatitude)) / (4.0 * pi);

    return new TileIndex(x, y);
  }

  @override
  CustomLatLng fromTileIndexToLngLat(TileIndex tile) {
    final x = tile.x;
    final y = tile.y;

    final xx = x! - 0.5;
    final yy = 0.5 - y!;

    final lat = 90.0 - 360.0 * atan(exp(-yy * 2.0 * pi)) / pi;
    final lng = 360.0 * xx;

    return CustomLatLng(lat, lng);
  }
}
