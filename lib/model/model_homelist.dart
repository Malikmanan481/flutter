import 'package:speedotrack/model/model_object_fn.dart';
import 'package:speedotrack/model/model_sensor_home.dart';

class HomeListItem {
  final bool fuel;
  final String lat;
  final String lng;
  final String statusMessage;
  final String status;
  final int speed;
  final String name;
  final String angle;
  final String engineHoursString;
  final String imei;
  final String gps;
  final String connection;
  final List<SensorModelHome> sensorModelAbove;
  final bool expired;
  final String expiredText;
  final List<dynamic> fnSettingString;
  final ObjectDataModel objectDataModel;
  final String imageName;

  HomeListItem(
      this.fuel,
      this.lat,
      this.lng,
      this.statusMessage,
      this.status,
      this.speed,
      this.name,
      this.angle,
      this.engineHoursString,
      this.imei,
      this.gps,
      this.connection,
      this.sensorModelAbove,
      this.expired,
      this.expiredText,
      this.fnSettingString,
      this.objectDataModel,
      this.imageName);

  /// Factory Constructor for Traccar API Backend (/api/devices & /api/positions)
  factory HomeListItem.fromTraccarJson({
    required Map<String, dynamic> deviceJson,
    Map<String, dynamic>? positionJson,
  }) {
    var deviceAttributes = deviceJson['attributes'] is Map<String, dynamic> ? deviceJson['attributes'] : {};
    var posAttributes = positionJson?['attributes'] is Map<String, dynamic> ? positionJson!['attributes'] : {};

    // 1. Coordinates & Speed
    String latVal = positionJson?['latitude']?.toString() ?? '0.0';
    String lngVal = positionJson?['longitude']?.toString() ?? '0.0';
    
    double rawSpeedKnots = double.tryParse(positionJson?['speed']?.toString() ?? '0') ?? 0.0;
    int calculatedSpeedKmh = (rawSpeedKnots * 1.852).round();

    // 2. Status & Connection
    String deviceStatus = deviceJson['status']?.toString() ?? 'unknown';
    bool isIgnitionOn = posAttributes['ignition'] == true || posAttributes['acc'] == true;
    
    String parsedStatusMessage = 'Offline';
    if (deviceStatus == 'online') {
      parsedStatusMessage = isIgnitionOn ? (calculatedSpeedKmh > 0 ? 'Moving' : 'Engine Idle') : 'Stopped';
    }

    // 3. Expiration Check
    bool isExpired = deviceJson['disabled'] == true;
    String expireText = 'Active';
    if (deviceJson['expirationTime'] != null) {
      DateTime? expDate = DateTime.tryParse(deviceJson['expirationTime'].toString());
      if (expDate != null && expDate.isBefore(DateTime.now())) {
        isExpired = true;
        expireText = 'Expired';
      }
    }

    // 4. Fuel & Engine Hours
    bool hasFuelSensor = posAttributes.containsKey('fuel') || posAttributes.containsKey('fuel1') || posAttributes.containsKey('io207');
    
    double rawEngineMs = double.tryParse(posAttributes['hours']?.toString() ?? deviceAttributes['hours']?.toString() ?? '0') ?? 0.0;
    String engineHrs = '${(rawEngineMs / (1000 * 60 * 60)).toStringAsFixed(1)} h';

    // 5. Category / Vehicle Icon
    String categoryIcon = deviceJson['category']?.toString() ?? 'car';

    return HomeListItem(
      hasFuelSensor,
      latVal,
      lngVal,
      parsedStatusMessage,
      deviceStatus,
      calculatedSpeedKmh,
      deviceJson['name']?.toString() ?? 'Unnamed Device',
      positionJson?['course']?.toString() ?? '0',
      engineHrs,
      deviceJson['uniqueId']?.toString() ?? '',
      posAttributes['sat']?.toString() ?? '0',
      deviceStatus,
      [], // SensorModelHome empty list for API fallback
      isExpired,
      expireText,
      [],
      ObjectDataModel.fromTraccarJson(deviceJson: deviceJson, positionJson: positionJson),
      categoryIcon,
    );
  }
}
