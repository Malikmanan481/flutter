import 'dart:ui';

class SensorModelHome {
  final String image;
  final String text;
  final Color color;

  SensorModelHome(this.image, this.text, this.color);

  /// JSON Factory for local data or custom API parsing
  factory SensorModelHome.fromJson(Map<String, dynamic> json) {
    return SensorModelHome(
      json['image']?.toString() ?? 'assets/icons/sensor.png',
      json['text']?.toString() ?? '',
      _parseColor(json['color'], const Color(0xFF4CAF50)),
    );
  }

  Map<String, dynamic> toJson() => {
        'image': image,
        'text': text,
        'color': color.value,
      };

  /// Traccar API Parser for positions (/api/positions) and devices (/api/devices)
  /// Converts Traccar telemetry attributes & status into UI-ready SensorModelHome instances.
  static List<SensorModelHome> fromTraccarAttributes(
    Map<String, dynamic>? attributes, {
    Map<String, dynamic>? deviceJson,
  }) {
    List<SensorModelHome> sensorList = [];

    // 1. Connection Status (Online / Offline)
    if (deviceJson != null && deviceJson.containsKey('status')) {
      bool isOnline = deviceJson['status'] == 'online';
      sensorList.add(
        SensorModelHome(
          'assets/icons/status.png',
          isOnline ? 'Online' : 'Offline',
          isOnline ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
        ),
      );
    }

    if (attributes == null || attributes.isEmpty) return sensorList;

    // 2. Ignition / ACC Status
    if (attributes.containsKey('ignition') || attributes.containsKey('acc')) {
      bool isAccOn = attributes['ignition'] == true || attributes['acc'] == true || attributes['acc'] == '1';
      sensorList.add(
        SensorModelHome(
          'assets/icons/engine.png',
          isAccOn ? 'ACC ON' : 'ACC OFF',
          isAccOn ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
        ),
      );
    }

    // 3. Motion Status
    if (attributes.containsKey('motion')) {
      bool isMoving = attributes['motion'] == true;
      sensorList.add(
        SensorModelHome(
          'assets/icons/motion.png',
          isMoving ? 'Moving' : 'Stopped',
          isMoving ? const Color(0xFF2196F3) : const Color(0xFF9E9E9E),
        ),
      );
    }

    // 4. Engine Cutoff / Immobilizer Status
    if (attributes.containsKey('blocked')) {
      bool isBlocked = attributes['blocked'] == true;
      sensorList.add(
        SensorModelHome(
          'assets/icons/cut.png',
          isBlocked ? 'Engine Cut' : 'Engine Active',
          isBlocked ? const Color(0xFFF44336) : const Color(0xFF4CAF50),
        ),
      );
    }

    // 5. Battery / Power Level
    if (attributes.containsKey('batteryLevel') || attributes.containsKey('battery')) {
      var battery = attributes['batteryLevel'] ?? attributes['battery'];
      sensorList.add(
        SensorModelHome(
          'assets/icons/battery.png',
          'Battery: $battery%',
          const Color(0xFFFF9800),
        ),
      );
    }

    // 6. External Power Voltage
    if (attributes.containsKey('power')) {
      var power = attributes['power'];
      sensorList.add(
        SensorModelHome(
          'assets/icons/power.png',
          'Power: ${power}V',
          const Color(0xFF00BCD4),
        ),
      );
    }

    // 7. Fuel Level
    if (attributes.containsKey('fuel') || attributes.containsKey('fuel1')) {
      var fuel = attributes['fuel'] ?? attributes['fuel1'];
      sensorList.add(
        SensorModelHome(
          'assets/icons/fuel.png',
          'Fuel: $fuel L',
          const Color(0xFF9C27B0),
        ),
      );
    }

    return sensorList;
  }

  /// Helper to convert Color integers or Hex strings (#4CAF50) to Flutter Color
  static Color _parseColor(dynamic val, Color fallback) {
    if (val == null) return fallback;
    if (val is int) return Color(val);
    if (val is String) {
      String hex = val.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      int? colorInt = int.tryParse(hex, radix: 16);
      if (colorInt != null) return Color(colorInt);
    }
    return fallback;
  }
}
