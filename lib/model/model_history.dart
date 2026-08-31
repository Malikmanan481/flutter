import 'dart:convert';

String historyModelToJson(HistoryModel data) => json.encode(data.toJson());

class HistoryModel {
  HistoryModel({
    this.route,
    this.stops,
    this.drives,
    this.events,
    this.routeLength,
    this.topSpeed,
    this.fuelConsumption,
    this.fuelCost,
    this.stopsDurationTime,
    this.stopsDuration,
    this.drivesDurationTime,
    this.drivesDuration,
    this.avgSpeed,
    this.engineWorkTime,
    this.engineIdleTime,
    this.engineWork,
    this.engineIdle,
    this.fuelConsumptionPer100Km,
    this.fuelConsumptionMpg,
  });

  List<List<dynamic>>? route;
  List<dynamic>? stops;
  List<List<dynamic>>? drives;
  List<dynamic>? events;
  dynamic routeLength;
  dynamic topSpeed;
  dynamic fuelConsumption;
  dynamic fuelCost;
  dynamic stopsDurationTime;
  dynamic stopsDuration;
  dynamic drivesDurationTime;
  String? drivesDuration;
  dynamic avgSpeed;
  dynamic engineWorkTime;
  dynamic engineIdleTime;
  String? engineWork;
  String? engineIdle;
  dynamic fuelConsumptionPer100Km;
  dynamic fuelConsumptionMpg;

  /// Original JSON Factory (Safeguarded against null pointer errors)
  factory HistoryModel.fromJson(Map<String, dynamic> json) => HistoryModel(
        route: json["route"] != null
            ? List<List<dynamic>>.from(json["route"].map((x) => List<dynamic>.from(x.map((x) => x))))
            : null,
        stops: json["stops"] != null ? List<dynamic>.from(json["stops"].map((x) => x)) : null,
        drives: json["drives"] != null
            ? List<List<dynamic>>.from(
                json["drives"].map((x) => List<dynamic>.from(x.map((x) => x))))
            : null,
        events: json["events"] != null ? List<dynamic>.from(json["events"].map((x) => x)) : null,
        routeLength: json["route_length"],
        topSpeed: json["top_speed"],
        fuelConsumption: json["fuel_consumption"],
        fuelCost: json["fuel_cost"],
        stopsDurationTime: json["stops_duration_time"],
        stopsDuration: json["stops_duration"],
        drivesDurationTime: json["drives_duration_time"],
        drivesDuration: json["drives_duration"],
        avgSpeed: json["avg_speed"],
        engineWorkTime: json["engine_work_time"],
        engineIdleTime: json["engine_idle_time"],
        engineWork: json["engine_work"],
        engineIdle: json["engine_idle"],
        fuelConsumptionPer100Km: json["fuel_consumption_per_100km"],
        fuelConsumptionMpg: json["fuel_consumption_mpg"],
      );

  /// Traccar REST API Reports Parser (/api/reports/route, summary, trips, stops, events)
  factory HistoryModel.fromTraccarReports({
    List<dynamic>? positions,
    List<dynamic>? summaries,
    List<dynamic>? trips,
    List<dynamic>? stopsList,
    List<dynamic>? eventsList,
  }) {
    // 1. Parse Route Points [lat, lng, altitude, speed(km/h), course, time, address]
    List<List<dynamic>> parsedRoute = [];
    if (positions != null) {
      for (var pos in positions) {
        if (pos is Map<String, dynamic>) {
          double lat = double.tryParse(pos['latitude']?.toString() ?? '0') ?? 0.0;
          double lng = double.tryParse(pos['longitude']?.toString() ?? '0') ?? 0.0;
          double speedKnots = double.tryParse(pos['speed']?.toString() ?? '0') ?? 0.0;
          double speedKmh = (speedKnots * 1.852).roundToDouble();
          double altitude = double.tryParse(pos['altitude']?.toString() ?? '0') ?? 0.0;
          double course = double.tryParse(pos['course']?.toString() ?? '0') ?? 0.0;
          String time = pos['fixTime']?.toString() ?? pos['deviceTime']?.toString() ?? '';
          String address = pos['address']?.toString() ?? '';

          parsedRoute.add([lat, lng, altitude, speedKmh, course, time, address]);
        }
      }
    }

    // 2. Parse Summary details
    dynamic length = '0.00';
    dynamic topSpd = 0;
    dynamic averageSpd = 0;
    dynamic engWorkMs = 0;

    if (summaries != null && summaries.isNotEmpty && summaries.first is Map<String, dynamic>) {
      var summary = summaries.first;
      double distMeters = double.tryParse(summary['distance']?.toString() ?? '0') ?? 0.0;
      length = (distMeters / 1000).toStringAsFixed(2); // Meters to KM

      double maxSpdKnots = double.tryParse(summary['maxSpeed']?.toString() ?? '0') ?? 0.0;
      topSpd = (maxSpdKnots * 1.852).roundToDouble();

      double avgSpdKnots = double.tryParse(summary['averageSpeed']?.toString() ?? '0') ?? 0.0;
      averageSpd = (avgSpdKnots * 1.852).roundToDouble();

      engWorkMs = summary['engineHours'] ?? 0;
    }

    // 3. Parse Trips / Drives
    List<List<dynamic>> parsedDrives = [];
    if (trips != null) {
      for (var trip in trips) {
        if (trip is Map<String, dynamic>) {
          parsedDrives.add([
            trip['startTime']?.toString() ?? '',
            trip['endTime']?.toString() ?? '',
            ((double.tryParse(trip['distance']?.toString() ?? '0') ?? 0) / 1000).toStringAsFixed(2),
            ((double.tryParse(trip['averageSpeed']?.toString() ?? '0') ?? 0) * 1.852).roundToDouble(),
            trip['duration']?.toString() ?? '',
          ]);
        }
      }
    }

    return HistoryModel(
      route: parsedRoute,
      stops: stopsList ?? [],
      drives: parsedDrives,
      events: eventsList ?? [],
      routeLength: length,
      topSpeed: topSpd,
      avgSpeed: averageSpd,
      engineWorkTime: engWorkMs,
      engineWork: '${(engWorkMs / (1000 * 60 * 60)).toStringAsFixed(1)} h',
    );
  }

  Map<String, dynamic> toJson() => {
        "route": route != null ? List<dynamic>.from(route!.map((x) => List<dynamic>.from(x.map((x) => x)))) : [],
        "stops": stops != null ? List<dynamic>.from(stops!.map((x) => x)) : [],
        "drives": drives != null ? List<dynamic>.from(drives!.map((x) => List<dynamic>.from(x.map((x) => x)))) : [],
        "events": events != null ? List<dynamic>.from(events!.map((x) => x)) : [],
        "route_length": routeLength,
        "top_speed": topSpeed,
        "fuel_consumption": fuelConsumption,
        "fuel_cost": fuelCost,
        "stops_duration_time": stopsDurationTime,
        "stops_duration": stopsDuration,
        "drives_duration_time": drivesDurationTime,
        "drives_duration": drivesDuration,
        "avg_speed": avgSpeed,
        "engine_work_time": engineWorkTime,
        "engine_idle_time": engineIdleTime,
        "engine_work": engineWork,
        "engine_idle": engineIdle,
        "fuel_consumption_per_100km": fuelConsumptionPer100Km,
        "fuel_consumption_mpg": fuelConsumptionMpg,
      };
}

class RouteClass {
  RouteClass({
    this.gpslev,
    this.mcc,
    this.mnc,
    this.lac,
    this.cellid,
    this.acc,
    this.pump,
    this.track,
    this.bats,
    this.defense,
    this.batl,
    this.gsmlev,
  });

  String? gpslev;
  String? mcc;
  String? mnc;
  String? lac;
  String? cellid;
  String? acc;
  String? pump;
  String? track;
  String? bats;
  String? defense;
  String? batl;
  String? gsmlev;

  factory RouteClass.fromJson(Map<String, dynamic> json) => RouteClass(
        gpslev: json["gpslev"]?.toString(),
        mcc: json["mcc"]?.toString(),
        mnc: json["mnc"]?.toString(),
        lac: json["lac"]?.toString(),
        cellid: json["cellid"]?.toString(),
        acc: json["acc"]?.toString(),
        pump: json["pump"]?.toString(),
        track: json["track"]?.toString(),
        bats: json["bats"]?.toString(),
        defense: json["defense"]?.toString(),
        batl: json["batl"]?.toString(),
        gsmlev: json["gsmlev"]?.toString(),
      );

  /// Traccar Position attributes Parser (/api/positions)
  factory RouteClass.fromTraccarPosition(Map<String, dynamic> positionJson) {
    var attributes = positionJson['attributes'] is Map<String, dynamic> ? positionJson['attributes'] : {};

    return RouteClass(
      gpslev: attributes['sat']?.toString() ?? '0',
      gsmlev: attributes['rssi']?.toString() ?? '0',
      acc: (attributes['ignition'] == true || attributes['acc'] == true) ? '1' : '0',
      batl: attributes['batteryLevel']?.toString() ?? attributes['battery']?.toString() ?? '0',
      bats: attributes['charge'] == true ? '1' : '0',
      defense: attributes['armed'] == true ? '1' : '0',
      mcc: attributes['mcc']?.toString(),
      mnc: attributes['mnc']?.toString(),
      lac: attributes['lac']?.toString(),
      cellid: attributes['cid']?.toString() ?? attributes['cellid']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        "gpslev": gpslev,
        "mcc": mcc,
        "mnc": mnc,
        "lac": lac,
        "cellid": cellid,
        "acc": acc,
        "pump": pump,
        "track": track,
        "bats": bats,
        "defense": defense,
        "batl": batl,
        "gsmlev": gsmlev,
      };
}
