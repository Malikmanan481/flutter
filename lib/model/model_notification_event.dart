import 'dart:convert';

class NotificationEventModel {
  String? name;
  String? imei;
  String? eventDesc;
  DateTime? dtServer;
  DateTime? dtTracker;
  String? lat;
  String? lng;
  String? altitude;
  String? angle;
  int? speed;
  Params? params;

  NotificationEventModel({
    this.name,
    this.imei,
    this.eventDesc,
    this.dtServer,
    this.dtTracker,
    this.lat,
    this.lng,
    this.altitude,
    this.angle,
    this.speed,
    this.params,
  });

  factory NotificationEventModel.fromJson(Map<String, dynamic> json) => NotificationEventModel(
        name: json["name"],
        imei: json["imei"],
        eventDesc: json["event_desc"],
        dtServer: json["dt_server"] != null ? DateTime.tryParse(json["dt_server"]) : null,
        dtTracker: json["dt_tracker"] != null ? DateTime.tryParse(json["dt_tracker"]) : null,
        lat: json["lat"]?.toString(),
        lng: json["lng"]?.toString(),
        altitude: json["altitude"]?.toString(),
        angle: json["angle"]?.toString(),
        speed: json["speed"] is int ? json["speed"] : int.tryParse(json["speed"]?.toString() ?? '0'),
        params: json["params"] != null ? Params.fromJson(json["params"]) : null,
      );

  /// Traccar REST API Parser (/api/reports/events or websocket event stream)
  factory NotificationEventModel.fromTraccarEvent({
    required Map<String, dynamic> eventJson,
    Map<String, dynamic>? positionJson,
    Map<String, dynamic>? deviceJson,
  }) {
    var attributes = eventJson['attributes'] is Map<String, dynamic> ? eventJson['attributes'] : {};
    var posAttributes = positionJson?['attributes'] is Map<String, dynamic> ? positionJson!['attributes'] : {};

    DateTime serverTime = DateTime.tryParse(eventJson['eventTime']?.toString() ?? positionJson?['serverTime']?.toString() ?? '') ?? DateTime.now();
    DateTime trackerTime = DateTime.tryParse(positionJson?['fixTime']?.toString() ?? positionJson?['deviceTime']?.toString() ?? '') ?? serverTime;

    double rawSpeedKnots = double.tryParse(positionJson?['speed']?.toString() ?? attributes['speed']?.toString() ?? '0') ?? 0.0;
    int speedKmh = (rawSpeedKnots * 1.852).round();

    String rawType = eventJson['type']?.toString() ?? 'unknown';

    return NotificationEventModel(
      name: deviceJson?['name']?.toString() ?? 'Device #${eventJson['deviceId']}',
      imei: deviceJson?['uniqueId']?.toString() ?? '',
      eventDesc: _formatTraccarEventType(rawType),
      dtServer: serverTime,
      dtTracker: trackerTime,
      lat: positionJson?['latitude']?.toString() ?? '0.0',
      lng: positionJson?['longitude']?.toString() ?? '0.0',
      altitude: positionJson?['altitude']?.toString() ?? '0',
      angle: positionJson?['course']?.toString() ?? '0',
      speed: speedKmh,
      params: Params.fromTraccarAttributes(posAttributes.isNotEmpty ? posAttributes : attributes),
    );
  }

  Map<String, dynamic> toJson() => {
        "name": name,
        "imei": imei,
        "event_desc": eventDesc,
        "dt_server": dtServer?.toIso8601String(),
        "dt_tracker": dtTracker?.toIso8601String(),
        "lat": lat,
        "lng": lng,
        "altitude": altitude,
        "angle": angle,
        "speed": speed,
        "params": params?.toJson(),
      };
}

class Params {
  String? fuel1;
  String? acc;

  Params({
    this.fuel1,
    this.acc,
  });

  factory Params.fromJson(Map<String, dynamic> json) => Params(
        fuel1: json["fuel1"]?.toString(),
        acc: json["acc"]?.toString(),
      );

  /// Parse attributes directly from Traccar position attributes object
  factory Params.fromTraccarAttributes(Map<String, dynamic> attributes) {
    bool isIgnition = attributes['ignition'] == true || attributes['acc'] == true;
    String fuelVal = attributes['fuel1']?.toString() ?? attributes['fuel']?.toString() ?? '0';

    return Params(
      fuel1: fuelVal,
      acc: isIgnition ? '1' : '0',
    );
  }

  Map<String, dynamic> toJson() => {
        "fuel1": fuel1,
        "acc": acc,
      };
}

class NotificationScreenEvent {
  String? eventId;
  String? userId;
  String? type;
  String? eventDesc;
  String? notifySystem;
  String? notifyPush;
  String? notifyArrow;
  String? notifyArrowColor;
  String? notifyOhc;
  String? notifyOhcColor;
  String? imei;
  String? name;
  String? dtServer;
  String? dtTracker;
  String? lat;
  String? lng;
  String? altitude;
  String? angle;
  String? speed;
  Map<String, dynamic>? params;

  NotificationScreenEvent({
    this.eventId,
    this.userId,
    this.type,
    this.eventDesc,
    this.notifySystem,
    this.notifyPush,
    this.notifyArrow,
    this.notifyArrowColor,
    this.notifyOhc,
    this.notifyOhcColor,
    this.imei,
    this.name,
    this.dtServer,
    this.dtTracker,
    this.lat,
    this.lng,
    this.altitude,
    this.angle,
    this.speed,
    this.params,
  });

  factory NotificationScreenEvent.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? parsedParams;
    if (json['params'] != null) {
      if (json['params'] is String) {
        parsedParams = jsonDecode(json['params']);
      } else if (json['params'] is Map<String, dynamic>) {
        parsedParams = json['params'];
      }
    }

    return NotificationScreenEvent(
      eventId: json['event_id']?.toString(),
      userId: json['user_id']?.toString(),
      type: json['type']?.toString(),
      eventDesc: json['event_desc']?.toString(),
      notifySystem: json['notify_system']?.toString(),
      notifyPush: json['notify_push']?.toString(),
      notifyArrow: json['notify_arrow']?.toString(),
      notifyArrowColor: json['notify_arrow_color']?.toString(),
      notifyOhc: json['notify_ohc']?.toString(),
      notifyOhcColor: json['notify_ohc_color']?.toString(),
      imei: json['imei']?.toString(),
      name: json['name']?.toString(),
      dtServer: json['dt_server']?.toString(),
      dtTracker: json['dt_tracker']?.toString(),
      lat: json['lat']?.toString(),
      lng: json['lng']?.toString(),
      altitude: json['altitude']?.toString(),
      angle: json['angle']?.toString(),
      speed: json['speed']?.toString(),
      params: parsedParams,
    );
  }

  /// Traccar event parser for Notification Screen list view
  factory NotificationScreenEvent.fromTraccarEvent({
    required Map<String, dynamic> eventJson,
    Map<String, dynamic>? positionJson,
    Map<String, dynamic>? deviceJson,
  }) {
    String rawType = eventJson['type']?.toString() ?? '';
    double rawSpeedKnots = double.tryParse(positionJson?['speed']?.toString() ?? '0') ?? 0.0;
    int speedKmh = (rawSpeedKnots * 1.852).round();

    return NotificationScreenEvent(
      eventId: eventJson['id']?.toString(),
      userId: eventJson['deviceId']?.toString(),
      type: rawType,
      eventDesc: _formatTraccarEventType(rawType),
      notifySystem: '1',
      notifyPush: '1',
      notifyArrow: '1',
      notifyArrowColor: '#FF0000',
      notifyOhc: '1',
      notifyOhcColor: '#00FF00',
      imei: deviceJson?['uniqueId']?.toString() ?? '',
      name: deviceJson?['name']?.toString() ?? 'Device #${eventJson['deviceId']}',
      dtServer: eventJson['eventTime']?.toString() ?? positionJson?['serverTime']?.toString(),
      dtTracker: positionJson?['fixTime']?.toString() ?? eventJson['eventTime']?.toString(),
      lat: positionJson?['latitude']?.toString() ?? '0.0',
      lng: positionJson?['longitude']?.toString() ?? '0.0',
      altitude: positionJson?['altitude']?.toString() ?? '0',
      angle: positionJson?['course']?.toString() ?? '0',
      speed: speedKmh.toString(),
      params: positionJson?['attributes'] is Map<String, dynamic>
          ? positionJson!['attributes']
          : (eventJson['attributes'] is Map<String, dynamic> ? eventJson['attributes'] : {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'user_id': userId,
      'type': type,
      'event_desc': eventDesc,
      'notify_system': notifySystem,
      'notify_push': notifyPush,
      'notify_arrow': notifyArrow,
      'notify_arrow_color': notifyArrowColor,
      'notify_ohc': notifyOhc,
      'notify_ohc_color': notifyOhcColor,
      'imei': imei,
      'name': name,
      'dt_server': dtServer,
      'dt_tracker': dtTracker,
      'lat': lat,
      'lng': lng,
      'altitude': altitude,
      'angle': angle,
      'speed': speed,
      'params': jsonEncode(params),
    };
  }
}

class NotificationDetailEvent {
  String? eventId;
  String? userId;
  String? type;
  String? eventDesc;
  String? notifySystem;
  String? notifyPush;
  String? notifyArrow;
  String? notifyArrowColor;
  String? notifyOhc;
  String? notifyOhcColor;
  String? imei;
  String? name;
  String? dtServer;
  String? dtTracker;
  String? lat;
  String? lng;
  String? altitude;
  String? angle;
  int? speed;
  Map<String, dynamic>? params;

  NotificationDetailEvent({
    this.eventId,
    this.userId,
    this.type,
    this.eventDesc,
    this.notifySystem,
    this.notifyPush,
    this.notifyArrow,
    this.notifyArrowColor,
    this.notifyOhc,
    this.notifyOhcColor,
    this.imei,
    this.name,
    this.dtServer,
    this.dtTracker,
    this.lat,
    this.lng,
    this.altitude,
    this.angle,
    this.speed,
    this.params,
  });

  factory NotificationDetailEvent.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? parsedParams;
    if (json['params'] != null) {
      if (json['params'] is String) {
        parsedParams = jsonDecode(json['params']);
      } else if (json['params'] is Map<String, dynamic>) {
        parsedParams = json['params'];
      }
    }

    return NotificationDetailEvent(
      eventId: json['event_id']?.toString(),
      userId: json['user_id']?.toString(),
      type: json['type']?.toString(),
      eventDesc: json['event_desc']?.toString(),
      notifySystem: json['notify_system']?.toString(),
      notifyPush: json['notify_push']?.toString(),
      notifyArrow: json['notify_arrow']?.toString(),
      notifyArrowColor: json['notify_arrow_color']?.toString(),
      notifyOhc: json['notify_ohc']?.toString(),
      notifyOhcColor: json['notify_ohc_color']?.toString(),
      imei: json['imei']?.toString(),
      name: json['name']?.toString(),
      dtServer: json['dt_server']?.toString(),
      dtTracker: json['dt_tracker']?.toString(),
      lat: json['lat']?.toString(),
      lng: json['lng']?.toString(),
      altitude: json['altitude']?.toString(),
      angle: json['angle']?.toString(),
      speed: json['speed'] is int ? json['speed'] : int.tryParse(json['speed']?.toString() ?? '0'),
      params: parsedParams,
    );
  }

  /// Traccar event parser for Event Detail Screen
  factory NotificationDetailEvent.fromTraccarEvent({
    required Map<String, dynamic> eventJson,
    Map<String, dynamic>? positionJson,
    Map<String, dynamic>? deviceJson,
  }) {
    String rawType = eventJson['type']?.toString() ?? '';
    double rawSpeedKnots = double.tryParse(positionJson?['speed']?.toString() ?? '0') ?? 0.0;
    int speedKmh = (rawSpeedKnots * 1.852).round();

    return NotificationDetailEvent(
      eventId: eventJson['id']?.toString(),
      userId: eventJson['deviceId']?.toString(),
      type: rawType,
      eventDesc: _formatTraccarEventType(rawType),
      notifySystem: '1',
      notifyPush: '1',
      notifyArrow: '1',
      notifyArrowColor: '#FF0000',
      notifyOhc: '1',
      notifyOhcColor: '#00FF00',
      imei: deviceJson?['uniqueId']?.toString() ?? '',
      name: deviceJson?['name']?.toString() ?? 'Device #${eventJson['deviceId']}',
      dtServer: eventJson['eventTime']?.toString() ?? positionJson?['serverTime']?.toString(),
      dtTracker: positionJson?['fixTime']?.toString() ?? eventJson['eventTime']?.toString(),
      lat: positionJson?['latitude']?.toString() ?? '0.0',
      lng: positionJson?['longitude']?.toString() ?? '0.0',
      altitude: positionJson?['altitude']?.toString() ?? '0',
      angle: positionJson?['course']?.toString() ?? '0',
      speed: speedKmh,
      params: positionJson?['attributes'] is Map<String, dynamic>
          ? positionJson!['attributes']
          : (eventJson['attributes'] is Map<String, dynamic> ? eventJson['attributes'] : {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'user_id': userId,
      'type': type,
      'event_desc': eventDesc,
      'notify_system': notifySystem,
      'notify_push': notifyPush,
      'notify_arrow': notifyArrow,
      'notify_arrow_color': notifyArrowColor,
      'notify_ohc': notifyOhc,
      'notify_ohc_color': notifyOhcColor,
      'imei': imei,
      'name': name,
      'dt_server': dtServer,
      'dt_tracker': dtTracker,
      'lat': lat,
      'lng': lng,
      'altitude': altitude,
      'angle': angle,
      'speed': speed,
      'params': jsonEncode(params),
    };
  }
}

/// Helper function to convert Traccar event type strings to clear human-readable titles
String _formatTraccarEventType(String type) {
  switch (type) {
    case 'deviceOnline':
      return 'Device Online';
    case 'deviceOffline':
      return 'Device Offline';
    case 'deviceMoving':
      return 'Vehicle Moving';
    case 'deviceStopped':
      return 'Vehicle Stopped';
    case 'deviceOverspeed':
      return 'Overspeed Alert';
    case 'geofenceEnter':
      return 'Geofence Entered';
    case 'geofenceExit':
      return 'Geofence Exited';
    case 'alarm':
      return 'SOS / Alarm Triggered';
    case 'ignitionOn':
      return 'ACC ON (Engine Started)';
    case 'ignitionOff':
      return 'ACC OFF (Engine Stopped)';
    case 'commandResult':
      return 'Command Executed';
    default:
      return type;
  }
}
