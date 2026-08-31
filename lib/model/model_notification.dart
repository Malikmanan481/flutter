class NotificationModel {
  String? page;
  int? total;
  int? records;
  List<Row>? rows;

  NotificationModel({
    this.page,
    this.total,
    this.records,
    this.rows,
  });

  /// Original JSON Factory (Safeguarded against null & type mismatch errors)
  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
        page: json["page"]?.toString(),
        total: json["total"] is int ? json["total"] : int.tryParse(json["total"]?.toString() ?? '1'),
        records: json["records"] is int ? json["records"] : int.tryParse(json["records"]?.toString() ?? '0'),
        rows: json["rows"] != null && json["rows"] is List
            ? List<Row>.from(json["rows"].map((x) => Row.fromJson(x)))
            : [],
      );

  /// Traccar REST API Parser for Events / Alerts (/api/reports/events)
  factory NotificationModel.fromTraccarEvents(List<dynamic> jsonList, {Map<int, String>? deviceMap}) {
    List<Row> parsedRows = [];
    for (var item in jsonList) {
      if (item is Map<String, dynamic>) {
        int devId = item['deviceId'] is int ? item['deviceId'] : int.tryParse(item['deviceId']?.toString() ?? '0') ?? 0;
        String devName = deviceMap?[devId] ?? 'Device #$devId';
        parsedRows.add(Row.fromTraccarEvent(item, deviceName: devName));
      }
    }
    return NotificationModel(
      page: "1",
      total: 1,
      records: parsedRows.length,
      rows: parsedRows,
    );
  }

  /// Traccar REST API Parser for Notification Settings (/api/notifications)
  factory NotificationModel.fromTraccarNotifications(List<dynamic> jsonList) {
    List<Row> parsedRows = [];
    for (var item in jsonList) {
      if (item is Map<String, dynamic>) {
        parsedRows.add(Row.fromTraccarNotification(item));
      }
    }
    return NotificationModel(
      page: "1",
      total: 1,
      records: parsedRows.length,
      rows: parsedRows,
    );
  }

  Map<String, dynamic> toJson() => {
        "page": page,
        "total": total,
        "records": records,
        "rows": rows != null ? List<dynamic>.from(rows!.map((x) => x.toJson())) : [],
      };
}

class Row {
  String? id;
  List<dynamic>? cell;

  Row({
    this.id,
    this.cell,
  });

  /// Original JSON Factory (Safeguarded against null pointer)
  factory Row.fromJson(Map<String, dynamic> json) => Row(
        id: json["id"]?.toString(),
        cell: json["cell"] != null && json["cell"] is List
            ? List<dynamic>.from(json["cell"].map((x) => x))
            : [],
      );

  /// Traccar Event Log Parser (/api/reports/events)
  factory Row.fromTraccarEvent(Map<String, dynamic> eventJson, {String deviceName = ''}) {
    String eventId = eventJson['id']?.toString() ?? '';
    String eventType = eventJson['type']?.toString() ?? 'unknown';
    String eventTime = eventJson['eventTime']?.toString() ?? eventJson['serverTime']?.toString() ?? '';
    String positionId = eventJson['positionId']?.toString() ?? '0';
    String geofenceId = eventJson['geofenceId']?.toString() ?? '0';
    
    String formattedMessage = _formatTraccarEventType(eventType);

    return Row(
      id: eventId,
      cell: [
        eventId,          // Cell 0: Event ID
        deviceName,       // Cell 1: Device Name
        formattedMessage, // Cell 2: Event Alert Description
        eventTime,        // Cell 3: Timestamp
        eventType,        // Cell 4: Event Type Key
        positionId,       // Cell 5: Position ID
        geofenceId,       // Cell 6: Geofence ID
      ],
    );
  }

  /// Traccar Notification Rule Parser (/api/notifications)
  factory Row.fromTraccarNotification(Map<String, dynamic> notifJson) {
    String notifId = notifJson['id']?.toString() ?? '';
    String type = notifJson['type']?.toString() ?? '';
    bool always = notifJson['always'] == true;
    String notificators = notifJson['notificators']?.toString() ?? 'web,push';

    return Row(
      id: notifId,
      cell: [
        notifId,      // Cell 0: Rule ID
        type,         // Cell 1: Notification Type
        always,       // Cell 2: Send Always (Bool)
        notificators, // Cell 3: Channels
      ],
    );
  }

  /// Format raw Traccar event types to human readable strings
  static String _formatTraccarEventType(String type) {
    switch (type) {
      case 'deviceOnline':
        return 'Online';
      case 'deviceOffline':
        return 'Offline';
      case 'deviceMoving':
        return 'Moving';
      case 'deviceStopped':
        return 'Stopped';
      case 'deviceOverspeed':
        return 'Overspeed Alert';
      case 'geofenceEnter':
        return 'Entered Geofence';
      case 'geofenceExit':
        return 'Exited Geofence';
      case 'alarm':
        return 'SOS / Alarm Triggered';
      case 'ignitionOn':
        return 'ACC ON (Engine Started)';
      case 'ignitionOff':
        return 'ACC OFF (Engine Stopped)';
      default:
        return type;
    }
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "cell": cell != null ? List<dynamic>.from(cell!.map((x) => x)) : [],
      };
}
