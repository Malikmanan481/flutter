import 'package:flutter/material.dart';

class SensorModel {
  final Image iconName;
  final Text text;

  SensorModel(this.iconName, this.text);

  /// Single Sensor Factory (Traccar Key-Value attributes parsing)
  factory SensorModel.fromKeyValue({
    required String key,
    required String value,
    String iconPath = 'assets/icons/default_sensor.png',
    TextStyle? textStyle,
  }) {
    return SensorModel(
      Image.asset(
        iconPath,
        width: 24,
        height: 24,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.sensors, size: 24) as dynamic,
      ),
      Text(
        '$key: $value',
        style: textStyle ?? const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  /// Traccar Attributes Parser (/api/positions or /api/devices position payload)
  /// Converts position `attributes` Map directly into a list of [SensorModel] UI widgets.
  static List<SensorModel> fromTraccarAttributes(Map<String, dynamic>? attributes) {
    if (attributes == null || attributes.isEmpty) return [];

    List<SensorModel> sensorList = [];

    // Ignition / ACC Sensor
    if (attributes.containsKey('ignition') || attributes.containsKey('acc')) {
      bool isIgnition = attributes['ignition'] == true || attributes['acc'] == true || attributes['acc'] == '1';
      sensorList.add(
        SensorModel(
          Image.asset('assets/icons/engine.png', width: 24, height: 24),
          Text('ACC: ${isIgnition ? "ON" : "OFF"}'),
        ),
      );
    }

    // Fuel Sensor (Fuel level / Fuel percentage)
    if (attributes.containsKey('fuel') || attributes.containsKey('fuel1')) {
      var fuelVal = attributes['fuel'] ?? attributes['fuel1'];
      sensorList.add(
        SensorModel(
          Image.asset('assets/icons/fuel.png', width: 24, height: 24),
          Text('Fuel: $fuelVal L'),
        ),
      );
    }

    // Battery / Power Level
    if (attributes.containsKey('batteryLevel') || attributes.containsKey('battery')) {
      var battery = attributes['batteryLevel'] ?? attributes['battery'];
      sensorList.add(
        SensorModel(
          Image.asset('assets/icons/battery.png', width: 24, height: 24),
          Text('Battery: $battery%'),
        ),
      );
    }

    // Motion Sensor
    if (attributes.containsKey('motion')) {
      bool isMotion = attributes['motion'] == true;
      sensorList.add(
        SensorModel(
          Image.asset('assets/icons/motion.png', width: 24, height: 24),
          Text('Motion: ${isMotion ? "Moving" : "Stopped"}'),
        ),
      );
    }

    // Odometer / Total Distance (Meters to KM Conversion)
    if (attributes.containsKey('odometer') || attributes.containsKey('totalDistance')) {
      var rawOdo = attributes['odometer'] ?? attributes['totalDistance'];
      double km = (double.tryParse(rawOdo.toString()) ?? 0.0) / 1000.0;
      sensorList.add(
        SensorModel(
          Image.asset('assets/icons/odometer.png', width: 24, height: 24),
          Text('Odometer: ${km.toStringAsFixed(1)} km'),
        ),
      );
    }

    // Satellites Sensor
    if (attributes.containsKey('sat')) {
      sensorList.add(
        SensorModel(
          Image.asset('assets/icons/satellite.png', width: 24, height: 24),
          Text('Satellites: ${attributes['sat']}'),
        ),
      );
    }

    // Temperature Sensor
    if (attributes.containsKey('temp') || attributes.containsKey('temp1')) {
      var temp = attributes['temp'] ?? attributes['temp1'];
      sensorList.add(
        SensorModel(
          Image.asset('assets/icons/temp.png', width: 24, height: 24),
          Text('Temp: $temp°C'),
        ),
      );
    }

    return sensorList;
  }
}
