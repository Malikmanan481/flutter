class MapReportTypes {
  // ignore: non_constant_identifier_names
  final String GENERAL_INFORMATION = 'GENERAL_INFO';

  // ignore: non_constant_identifier_names
  final String GENERAL_INFORMATION_MERGED = 'GENERAL_INFO_MERGED';

  // ignore: non_constant_identifier_names
  final String OBJECT_INFORMATION = 'OBJECT_INFO';

  // ignore: non_constant_identifier_names
  final String DRIVES_AND_STOPS = 'DRIVES_AND_STOPS';

  // ignore: non_constant_identifier_names
  final String TRAVEL_SHEET = 'TRAVEL_SHEET';

  // ignore: non_constant_identifier_names
  final String ZONE_IN_OUT = 'ZONE_IN_OUT';

  // ignore: non_constant_identifier_names
  final String OVERSPEEDS = 'OVERSPEEDS';

  // ignore: non_constant_identifier_names
  final String UNDERSPEEDS = 'UNDERSPEEDS';

  // ignore: non_constant_identifier_names
  final String EVENTS = 'EVENTS';

  // ignore: non_constant_identifier_names
  final String SERVICE = 'SERVICE';

  // ignore: non_constant_identifier_names
  final String DRIVER_BEHAVIOR_RAG = 'DRIVER_BEHAVIOR_RAG';

  // ignore: non_constant_identifier_names
  final String FUEL_FILLINGS = 'FUEL_FILLINGS';

  // ignore: non_constant_identifier_names
  final String FUEL_THEFTS = 'FUEL_THEFTS';

  // ignore: non_constant_identifier_names
  final String LOGIC_SENSORS = 'LOGIC_SENSORS';

  // ignore: non_constant_identifier_names
  final String IGNITION_ACC = 'IGNITION_ACC';

  // ignore: non_constant_identifier_names
  final String FUEL_LEVEL_GRAPH = 'FUEL_LEVEL_GRAPH';

  // ignore: non_constant_identifier_names
  final String TEMPERATURE_GRAPH = 'TEMPERATURE_GRAPH';

  // ignore: non_constant_identifier_names
  final String SENSOR_GRAPH = 'SENSOR_GRAPH';

  // ignore: non_constant_identifier_names
  final String SPEED_GRAPH = 'SPEED_GRAPH';

  // ignore: non_constant_identifier_names
  final String ALTITUDE_GRAPH = 'ALTITUDE_GRAPH';

  // ignore: non_constant_identifier_names
  final String CURRENT_POSITION = 'CURRENT_POSITION';

  // ignore: non_constant_identifier_names
  final String CURRENT_POSITION_OFFLINE = 'CURRENT_POSITION_OFFLINE';

  // ignore: non_constant_identifier_names
  final String MILEAGE_DAILY = 'MILEAGE_DAILY';

  // ignore: non_constant_identifier_names
  final String DRIVER_BEHAVIOR_RAG_BY_DRIVER = 'DRIVER_BEHAVIOR_RAG_BY_DRIVER';

  // ignore: non_constant_identifier_names
  final String DRIVER_BEHAVIOR_RAG_BY_OBJECT = 'DRIVER_BEHAVIOR_RAG_BY_OBJECT';

  // ignore: non_constant_identifier_names
  final String TASKS = 'TASKS';

  // ignore: non_constant_identifier_names
  final String RFID_AND_IBUTTON_LOGBOOK = 'RFID_AND_IBUTTON_LOGBOOK';

  // ignore: non_constant_identifier_names
  final String DIAGNOSTIC_TROUBLE_CODES = 'DIAGNOSTIC_TROUBLE_CODES';

  // ignore: non_constant_identifier_names
  final String ROUTES = 'ROUTES';

  // ignore: non_constant_identifier_names
  final String ROUTES_WITH_STOPS = 'ROUTES_WITH_STOPS';

  // ignore: non_constant_identifier_names
  final String IMAGE_GALLERY = 'IMAGE_GALLERY';

  String? getReportTypeValues(Map<String, String> object, String key) {
    try {
      Map<String?, String> hashMap = {};
      hashMap[object[GENERAL_INFORMATION]] = 'general';
      hashMap[object[GENERAL_INFORMATION_MERGED]] = 'general_merged';
      hashMap[object[OBJECT_INFORMATION]] = 'object_info';
      hashMap[object[CURRENT_POSITION]] = 'current_position';
      hashMap[object[CURRENT_POSITION_OFFLINE]] = 'current_position_off';
      hashMap[object[DRIVES_AND_STOPS]] = 'drives_stops';
      hashMap[object[TRAVEL_SHEET]] = 'travel_sheet';
      hashMap[object[MILEAGE_DAILY]] = 'mileage_daily';
      hashMap[object[OVERSPEEDS]] = 'overspeed';
      hashMap[object[UNDERSPEEDS]] = 'underspeed';
      hashMap[object[ZONE_IN_OUT]] = 'zone_in_out';
      hashMap[object[EVENTS]] = 'events';
      hashMap[object[SERVICE]] = 'service';
      hashMap[object[FUEL_FILLINGS]] = 'fuelfillings';
      hashMap[object[FUEL_THEFTS]] = 'fuelthefts';
      hashMap[object[LOGIC_SENSORS]] = 'logic_sensors';
      hashMap[object[DRIVER_BEHAVIOR_RAG_BY_DRIVER]] = 'rag';
      hashMap[object[DRIVER_BEHAVIOR_RAG_BY_OBJECT]] = 'rag_driver';
      hashMap[object[TASKS]] = 'tasks';
      hashMap[object[RFID_AND_IBUTTON_LOGBOOK]] = 'rilogbook';
      hashMap[object[DIAGNOSTIC_TROUBLE_CODES]] = 'dtc';
      hashMap[object[SPEED_GRAPH]] = 'speed_graph';
      hashMap[object[ALTITUDE_GRAPH]] = 'altitude_graph';
      hashMap[object[IGNITION_ACC]] = 'acc_graph';
      hashMap[object[FUEL_LEVEL_GRAPH]] = 'fuellevel_graph';
      hashMap[object[TEMPERATURE_GRAPH]] = 'temperature_graph';
      hashMap[object[SENSOR_GRAPH]] = 'sensor_graph';
      hashMap[object[ROUTES]] = 'routes';
      hashMap[object[ROUTES_WITH_STOPS]] = 'routes_stops';
      hashMap[object[IMAGE_GALLERY]] = 'image_gallery';
      return hashMap[key]!;
    } catch (e) {}
    return null;
  }

  List<String?> getReportTypes(Map<String, String> object) {
    // Create an empty list
    List<String?> arr = [];

    // Add elements to the list instead of assigning by index
    arr.add(object[GENERAL_INFORMATION]);
    arr.add(object[GENERAL_INFORMATION_MERGED]);
    arr.add(object[OBJECT_INFORMATION]);
    arr.add(object[CURRENT_POSITION]);
    arr.add(object[CURRENT_POSITION_OFFLINE]);
    arr.add(object[DRIVES_AND_STOPS]);
    arr.add(object[TRAVEL_SHEET]);
    arr.add(object[MILEAGE_DAILY]);
    arr.add(object[OVERSPEEDS]);
    arr.add(object[UNDERSPEEDS]);
    arr.add(object[ZONE_IN_OUT]);
    arr.add(object[EVENTS]);
    arr.add(object[SERVICE]);
    arr.add(object[FUEL_FILLINGS]);
    arr.add(object[FUEL_THEFTS]);
    arr.add(object[LOGIC_SENSORS]);
    arr.add(object[DRIVER_BEHAVIOR_RAG_BY_DRIVER]);
    arr.add(object[DRIVER_BEHAVIOR_RAG_BY_OBJECT]);
    arr.add(object[TASKS]);
    arr.add(object[RFID_AND_IBUTTON_LOGBOOK]);
    arr.add(object[DIAGNOSTIC_TROUBLE_CODES]);
    arr.add(object[SPEED_GRAPH]);
    arr.add(object[ALTITUDE_GRAPH]);
    arr.add(object[IGNITION_ACC]);
    arr.add(object[FUEL_LEVEL_GRAPH]);
    arr.add(object[TEMPERATURE_GRAPH]);
    arr.add(object[SENSOR_GRAPH]);
    arr.add(object[ROUTES]);
    arr.add(object[ROUTES_WITH_STOPS]);
    arr.add(object[IMAGE_GALLERY]);

    // Return the populated list
    return arr;
  }

  // ==========================================
  // TRACCAR REST API BACKEND INTEGRATION
  // ==========================================

  /// Maps internal report key to the exact Traccar REST API Endpoint path
  String getTraccarReportEndpoint(String reportKey) {
    switch (reportKey) {
      case 'GENERAL_INFO':
      case 'GENERAL_INFO_MERGED':
      case 'MILEAGE_DAILY':
      case 'TRAVEL_SHEET':
        return 'api/reports/summary';

      case 'DRIVES_AND_STOPS':
      case 'ROUTES_WITH_STOPS':
        return 'api/reports/trips';

      case 'ROUTES':
      case 'SPEED_GRAPH':
      case 'ALTITUDE_GRAPH':
      case 'FUEL_LEVEL_GRAPH':
      case 'TEMPERATURE_GRAPH':
      case 'SENSOR_GRAPH':
      case 'IGNITION_ACC':
        return 'api/reports/route';

      case 'EVENTS':
      case 'OVERSPEEDS':
      case 'UNDERSPEEDS':
      case 'ZONE_IN_OUT':
        return 'api/reports/events';

      case 'CURRENT_POSITION':
      case 'CURRENT_POSITION_OFFLINE':
        return 'api/positions';

      default:
        return 'api/reports/summary';
    }
  }

  /// Builds URL Query Parameters for Traccar REST Report API Requests
  Map<String, String> buildTraccarQueryParams({
    required List<int> deviceIds,
    required DateTime fromTime,
    required DateTime toTime,
    List<int>? groupIds,
  }) {
    Map<String, String> queryParams = {
      'from': fromTime.toUtc().toIso8601String(),
      'to': toTime.toUtc().toIso8601String(),
    };

    if (deviceIds.isNotEmpty) {
      queryParams['deviceId'] = deviceIds.join('&deviceId=');
    }

    if (groupIds != null && groupIds.isNotEmpty) {
      queryParams['groupId'] = groupIds.join('&groupId=');
    }

    return queryParams;
  }
}
