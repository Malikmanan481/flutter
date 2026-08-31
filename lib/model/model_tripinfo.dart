import 'dart:convert';

class TripInfoModel {
  final String start;
  final String end;
  final String duration;
  final String distance;
  final String topSpeed;
  final String avgSpeed;
  final String fuelConsumption;
  final String fuelCost;
  final String startLocation;
  final String endLocation;

  TripInfoModel(
    this.start,
    this.end,
    this.duration,
    this.distance,
    this.topSpeed,
    this.avgSpeed,
    this.fuelConsumption,
    this.fuelCost,
    this.startLocation,
    this.endLocation,
  );

  /// Factory to parse Traccar Trips API (/api/reports/trips)
  factory TripInfoModel.fromTraccarTrip(Map<String, dynamic> json, {double fuelPricePerLiter = 0.0}) {
    double distanceMeters = double.tryParse(json['distance']?.toString() ?? '0') ?? 0.0;
    double distanceKm = distanceMeters / 1000.0;

    int durationMs = int.tryParse(json['duration']?.toString() ?? '0') ?? 0;
    String formattedDuration = _formatMilliseconds(durationMs);

    double maxSpeedKnots = double.tryParse(json['maxSpeed']?.toString() ?? '0') ?? 0.0;
    double maxSpeedKmh = maxSpeedKnots * 1.852; // Convert knots to km/h if needed

    double avgSpeedKnots = double.tryParse(json['averageSpeed']?.toString() ?? '0') ?? 0.0;
    double avgSpeedKmh = avgSpeedKnots * 1.852;

    double spentFuel = double.tryParse(json['spentFuel']?.toString() ?? '0') ?? 0.0;
    double calculatedFuelCost = spentFuel * fuelPricePerLiter;

    return TripInfoModel(
      json['startTime']?.toString() ?? '',
      json['endTime']?.toString() ?? '',
      formattedDuration,
      '${distanceKm.toStringAsFixed(2)} km',
      '${maxSpeedKmh.toStringAsFixed(1)} km/h',
      '${avgSpeedKmh.toStringAsFixed(1)} km/h',
      '${spentFuel.toStringAsFixed(2)} L',
      '${calculatedFuelCost.toStringAsFixed(2)}',
      json['startAddress']?.toString() ?? json['startLat']?.toString() ?? '',
      json['endAddress']?.toString() ?? json['endLat']?.toString() ?? '',
    );
  }

  /// Convert back to Map JSON
  Map<String, dynamic> toJson() => {
        'start': start,
        'end': end,
        'duration': duration,
        'distance': distance,
        'topSpeed': topSpeed,
        'avgSpeed': avgSpeed,
        'fuelConsumption': fuelConsumption,
        'fuelCost': fuelCost,
        'startLocation': startLocation,
        'endLocation': endLocation,
      };

  static String _formatMilliseconds(int ms) {
    if (ms <= 0) return '0m';
    Duration d = Duration(milliseconds: ms);
    int hours = d.inHours;
    int minutes = d.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

class tripdetail {
  dynamic start;
  dynamic end;
  dynamic routeLength;
  dynamic topSpeed;
  dynamic avgSpeed;
  dynamic fuelConsumption;
  dynamic fuelCost;
  dynamic drivesDuration;
  dynamic engineWork;
  dynamic fuelConsumptionPer100km;
  dynamic fuelConsumptionMpg;

  tripdetail({
    this.start,
    this.end,
    this.routeLength,
    this.topSpeed,
    this.avgSpeed,
    this.fuelConsumption,
    this.fuelCost,
    this.drivesDuration,
    this.engineWork,
    this.fuelConsumptionPer100km,
    this.fuelConsumptionMpg,
  });

  /// Standard JSON Deserialization
  factory tripdetail.fromJson(Map<String, dynamic> json) {
    return tripdetail(
      start: json['start'],
      end: json['end'],
      routeLength: json['routeLength'],
      topSpeed: json['topSpeed'],
      avgSpeed: json['avgSpeed'],
      fuelConsumption: json['fuelConsumption'],
      fuelCost: json['fuelCost'],
      drivesDuration: json['drivesDuration'],
      engineWork: json['engineWork'],
      fuelConsumptionPer100km: json['fuelConsumptionPer100km'],
      fuelConsumptionMpg: json['fuelConsumptionMpg'],
    );
  }

  /// Parses Traccar Reports API (/api/reports/trips or /api/reports/summary)
  factory tripdetail.fromTraccarReport(Map<String, dynamic> json, {double fuelPricePerLiter = 0.0}) {
    double distanceMeters = double.tryParse(json['distance']?.toString() ?? '0') ?? 0.0;
    double distanceKm = distanceMeters / 1000.0;

    double spentFuel = double.tryParse(json['spentFuel']?.toString() ?? '0') ?? 0.0;

    double lPer100km = 0.0;
    if (distanceKm > 0 && spentFuel > 0) {
      lPer100km = (spentFuel / distanceKm) * 100;
    }

    double mpg = 0.0;
    if (lPer100km > 0) {
      mpg = 235.215 / lPer100km;
    }

    return tripdetail(
      start: json['startTime'] ?? json['startAddress'] ?? '',
      end: json['endTime'] ?? json['endAddress'] ?? '',
      routeLength: distanceKm,
      topSpeed: json['maxSpeed'],
      avgSpeed: json['averageSpeed'],
      fuelConsumption: spentFuel,
      fuelCost: spentFuel * fuelPricePerLiter,
      drivesDuration: json['duration'] ?? json['engineHours'],
      engineWork: json['engineHours'] ?? json['duration'],
      fuelConsumptionPer100km: lPer100km,
      fuelConsumptionMpg: mpg,
    );
  }

  Map<String, dynamic> toJson() => {
        'start': start,
        'end': end,
        'routeLength': routeLength,
        'topSpeed': topSpeed,
        'avgSpeed': avgSpeed,
        'fuelConsumption': fuelConsumption,
        'fuelCost': fuelCost,
        'drivesDuration': drivesDuration,
        'engineWork': engineWork,
        'fuelConsumptionPer100km': fuelConsumptionPer100km,
        'fuelConsumptionMpg': fuelConsumptionMpg,
      };
}
