class HomeItem {
  final bool fuel;
  final String lat;
  final String lng;
  final String statusMessage;
  final String status;
  final int speed;
  final String name;
  final String angle;
  final String imei;
  final bool expired;
  final String expiredText;
  final String brandImage;
  final String imageName;

  HomeItem(
      this.fuel,
      this.lat,
      this.lng,
      this.statusMessage,
      this.status,
      this.speed,
      this.name,
      this.angle,
      this.imei,
      this.expired,
      this.expiredText,
      this.brandImage,
      this.imageName);

  /// Factory constructor to connect directly with Traccar REST API
  /// Maps data from `/api/devices` (deviceJson) and `/api/positions` (positionJson)
  factory HomeItem.fromTraccar({
    required Map<String, dynamic> deviceJson,
    Map<String, dynamic>? positionJson,
  }) {
    final positionAttrs =
        (positionJson?['attributes'] as Map<String, dynamic>?) ?? {};

    // Coordinates string parsing
    final String latitude = positionJson?['latitude']?.toString() ?? '0.0';
    final String longitude = positionJson?['longitude']?.toString() ?? '0.0';

    // Traccar speed is in knots (1 knot = 1.852 km/h)
    final double speedKnots = ((positionJson?['speed'] ?? 0) as num).toDouble();
    final int speedKmh = (speedKnots * 1.852).round();

    // Device course / heading angle
    final String courseAngle = (positionJson?['course'] ?? 0).toString();

    // Check expiration date from Traccar device payload
    bool isExpiredDevice = false;
    String formattedExpText = 'Active';
    if (deviceJson['expirationTime'] != null) {
      final DateTime? expDate =
          DateTime.tryParse(deviceJson['expirationTime'].toString());
      if (expDate != null) {
        isExpiredDevice = DateTime.now().isAfter(expDate);
        formattedExpText = isExpiredDevice
            ? 'Expired'
            : expDate.toIso8601String().split('T').first;
      }
    }

    // Fuel telemetry attribute check
    final bool hasFuelSensor = positionAttrs.containsKey('fuel') ||
        positionAttrs.containsKey('fuelLevel');

    // Engine status calculation
    String calculatedStatusMsg = deviceJson['status']?.toString() ?? 'unknown';
    if (positionAttrs.containsKey('ignition')) {
      final bool ignition = positionAttrs['ignition'] == true;
      calculatedStatusMsg = ignition ? 'Engine ON' : 'Engine OFF';
    }

    // Category / vehicle image icon mapping
    final String vehicleCategory =
        deviceJson['category']?.toString() ?? 'default';

    return HomeItem(
      hasFuelSensor,
      latitude,
      longitude,
      calculatedStatusMsg,
      deviceJson['status']?.toString() ?? 'offline',
      speedKmh,
      deviceJson['name']?.toString() ?? 'Unknown Device',
      courseAngle,
      deviceJson['uniqueId']?.toString() ?? '', // UniqueId maps to IMEI
      isExpiredDevice,
      formattedExpText,
      vehicleCategory, // brandImage
      vehicleCategory, // imageName
    );
  }
}
