import 'package:google_maps_flutter/google_maps_flutter.dart';

class EventsData {
  String? object, position, altitude, angle, time, event, speed;
  LatLng? latLng;

  EventsData({
    this.angle,
    this.altitude,
    this.event,
    this.speed,
    this.time,
    this.object,
    this.position,
    this.latLng,
  });

  /// Original JSON Constructor (Preserved for backward compatibility)
  EventsData.fromJson(Map<String, dynamic> json) {
    object = json["title"] ?? json["object"];
    position = json["position"];
    altitude = json["altitude"]?.toString();
    angle = json["angle"]?.toString();
    time = json["time"];
    event = json["event"];
    speed = json["speed"]?.toString();

    if (json['latitude'] != null && json['longitude'] != null) {
      double? lat = double.tryParse(json['latitude'].toString());
      double? lng = double.tryParse(json['longitude'].toString());
      if (lat != null && lng != null) {
        latLng = LatLng(lat, lng);
      }
    }
  }

  /// Traccar REST API & WebSocket Parser (/api/reports/events & /api/positions)
  factory EventsData.fromTraccarJson(
    Map<String, dynamic> eventJson, {
    Map<String, dynamic>? positionJson,
    String? deviceName,
  }) {
    // Extract Latitude & Longitude for Google Maps LatLng
    LatLng? coordinates;
    var latVal = positionJson?['latitude'] ?? eventJson['latitude'];
    var lngVal = positionJson?['longitude'] ?? eventJson['longitude'];
    if (latVal != null && lngVal != null) {
      double? lat = double.tryParse(latVal.toString());
      double? lng = double.tryParse(lngVal.toString());
      if (lat != null && lng != null) {
        coordinates = LatLng(lat, lng);
      }
    }

    // Convert Speed from Knots (Traccar default) to km/h
    String speedInKmH = '0';
    var rawSpeed = positionJson?['speed'] ?? eventJson['speed'];
    if (rawSpeed != null) {
      double? speedKnots = double.tryParse(rawSpeed.toString());
      if (speedKnots != null) {
        speedInKmH = (speedKnots * 1.852).roundToDouble().toStringAsFixed(0);
      }
    }

    return EventsData(
      object: deviceName ?? eventJson['deviceName']?.toString() ?? eventJson['title']?.toString() ?? 'Device #${eventJson['deviceId'] ?? ''}',
      event: eventJson['type']?.toString() ?? eventJson['event']?.toString() ?? 'event',
      time: eventJson['eventTime']?.toString() ?? eventJson['serverTime']?.toString() ?? eventJson['fixTime']?.toString() ?? eventJson['time']?.toString() ?? '',
      position: positionJson?['address']?.toString() ?? eventJson['address']?.toString() ?? eventJson['position']?.toString() ?? '',
      altitude: (positionJson?['altitude'] ?? eventJson['altitude'] ?? '0').toString(),
      angle: (positionJson?['course'] ?? eventJson['course'] ?? eventJson['angle'] ?? '0').toString(),
      speed: speedInKmH,
      latLng: coordinates,
    );
  }

  Map<String, dynamic> toJson() => {
        'object': object,
        'position': position,
        'altitude': altitude,
        'angle': angle,
        'time': time,
        'event': event,
        'speed': speed,
        'latitude': latLng?.latitude,
        'longitude': latLng?.longitude,
      };
}
