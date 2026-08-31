import 'package:flutter/material.dart';

abstract class MapProvider {
  const MapProvider();

  ImageProvider getTile(int x, int y, int z);
}

class OsmProvider extends MapProvider {
  const OsmProvider();

  @override
  ImageProvider getTile(int x, int y, int z) {
    return NetworkImage('http://a.tile.osm.org/$z/$x/$y.png');
  }
}

class GoogleMapProvider extends MapProvider {
  const GoogleMapProvider();

  @override
  ImageProvider getTile(int x, int y, int z) {
    return NetworkImage(
        'https://www.google.com/maps/vt/pb=!1m4!1m3!1i$z!2i$x!3i$y!2m3!1e0!2sm!3i420120488!3m7!2sen!5e1105!12m4!1e68!2m2!1sset!2sRoadmap!4e0!5m1!1e0!23i4111425');
  }
}

// ==========================================
// TRACCAR API MAP TILE SERVER INTEGRATION
// ==========================================

/// Dynamic tile provider connected to Traccar Server attributes (`/api/server` mapUrl setting)
class TraccarMapProvider extends MapProvider {
  final String tileUrlTemplate;
  final Map<String, String>? headers;

  const TraccarMapProvider({
    required this.tileUrlTemplate,
    this.headers,
  });

  /// Factory constructor to auto-configure tile provider directly from Traccar `/api/server` response
  factory TraccarMapProvider.fromTraccarServerJson(Map<String, dynamic> serverJson) {
    String tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    if (serverJson.containsKey('mapUrl') &&
        serverJson['mapUrl'] != null &&
        serverJson['mapUrl'].toString().isNotEmpty) {
      tileUrl = serverJson['mapUrl'].toString();
    } else if (serverJson.containsKey('attributes') &&
        serverJson['attributes'] is Map) {
      final attrs = serverJson['attributes'] as Map<String, dynamic>;
      if (attrs.containsKey('mapUrl') && attrs['mapUrl'] != null) {
        tileUrl = attrs['mapUrl'].toString();
      }
    }

    return TraccarMapProvider(tileUrlTemplate: tileUrl);
  }

  @override
  ImageProvider getTile(int x, int y, int z) {
    // Replaces standard Traccar map tile placeholders {x}, {y}, {z}
    final url = tileUrlTemplate
        .replaceAll('{x}', x.toString())
        .replaceAll('{y}', y.toString())
        .replaceAll('{z}', z.toString());

    return NetworkImage(url, headers: headers);
  }
}
