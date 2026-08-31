import 'dart:convert';

class VehicleSettingsModel {
  String? protocol;
  String? groupID;
  String? driverID;
  String? trailerID;
  String? name;
  String? icon;
  MapArrow? mapArrow;
  String? mapIcon;
  String? tailColor;
  String? tailPoints;
  String? device;
  String? simNumber;
  String? model;
  String? vin;
  String? plateNumber;
  String? odometerType;
  String? engineHourType;
  int? odometer;
  int? engineHours;
  FCR? fcr;
  String? timeAdj;
  Accuracy? accuracy;
  String? false1;
  String? false2;
  ParamAccvirt? paramAccvirt;
  String? false3;
  String? emptyString;
  Map<String, Sensors>? sensors;
  List<dynamic>? emptyList;
  dynamic emptyList1;
  List<dynamic>? stringVariable;
  bool? active;
  bool? objectExpire;
  String? objectExpireDate;

  VehicleSettingsModel(
    this.protocol,
    this.groupID,
    this.driverID,
    this.trailerID,
    this.name,
    this.icon,
    this.mapArrow,
    this.mapIcon,
    this.tailColor,
    this.tailPoints,
    this.device,
    this.simNumber,
    this.model,
    this.vin,
    this.plateNumber,
    this.odometerType,
    this.engineHourType,
    this.odometer,
    this.engineHours,
    this.fcr,
    this.timeAdj,
    this.accuracy,
    this.false1,
    this.false2,
    this.paramAccvirt,
    this.false3,
    this.emptyString,
    this.sensors,
    this.emptyList,
    this.emptyList1,
    this.stringVariable,
    this.active,
    this.objectExpire,
    this.objectExpireDate,
  );

  /// Legacy Array-based JSON Parser (Intact for backward compatibility)
  VehicleSettingsModel.fromJson(List<dynamic> json)
      : protocol = json.length > 0 ? json[0] ?? '' : '',
        groupID = json.length > 1 ? json[1] ?? '' : '',
        driverID = json.length > 2 ? json[2] ?? '' : '',
        trailerID = json.length > 3 ? json[3] ?? '' : '',
        name = json.length > 4 ? json[4] ?? '' : '',
        icon = json.length > 5 ? json[5] ?? '' : '',
        mapArrow = MapArrow.fromJson(json.length > 6 && json[6] != null ? json[6] : {}),
        mapIcon = json.length > 7 ? json[7] ?? '' : '',
        tailColor = json.length > 8 ? json[8] ?? '' : '',
        tailPoints = json.length > 9 ? json[9] ?? '' : '',
        device = json.length > 10 ? json[10] ?? '' : '',
        simNumber = json.length > 11 ? json[11] ?? '' : '',
        model = json.length > 12 ? json[12] ?? '' : '',
        vin = json.length > 13 ? json[13] ?? '' : '',
        plateNumber = json.length > 14 ? json[14] ?? '' : '',
        odometerType = json.length > 15 ? json[15] ?? '' : '',
        engineHourType = json.length > 16 ? json[16] ?? '' : '',
        odometer = json.length > 17 ? (json[17] is int ? json[17] : int.tryParse(json[17]?.toString() ?? '0')) : 0,
        engineHours = json.length > 18 ? (json[18] is int ? json[18] : int.tryParse(json[18]?.toString() ?? '0')) : 0,
        fcr = FCR.fromJson(json.length > 19 && json[19] != null ? json[19] : {}),
        timeAdj = json.length > 20 ? json[20] ?? '' : '',
        accuracy = Accuracy.fromJson(json.length > 21 && json[21] != null ? json[21] : {}),
        false1 = json.length > 22 ? json[22] ?? 'false' : 'false',
        false2 = json.length > 23 ? json[23] ?? 'false' : 'false',
        paramAccvirt = ParamAccvirt.fromJson(json.length > 24 && json[24] != null ? json[24] : {}),
        false3 = json.length > 25 ? json[25] ?? 'false' : 'false',
        emptyString = json.length > 26 ? json[26] ?? '' : '',
        sensors = (json.length > 27 && json[27] is List && (json[27] as List).isEmpty)
            ? {}
            : (json.length > 27 && json[27] is Map<String, dynamic>
                ? (json[27] as Map<String, dynamic>).map((key, value) => MapEntry(key, Sensors.fromJson(value)))
                : {}),
        emptyList = json.length > 28 ? json[28] ?? [] : [],
        emptyList1 = json.length > 29 ? json[29] : null,
        stringVariable = json.length > 30 ? json[30] ?? [] : [],
        active = json.length > 31 ? (json[31] == 'false' || json[31] == false ? false : true) : true,
        objectExpire = json.length > 32 ? (json[32] == 'false' || json[32] == false ? false : true) : true,
        objectExpireDate = json.length > 33 ? json[33] ?? '' : '';

  /// Traccar Device REST API Parser (/api/devices or /api/devices/{id})
  factory VehicleSettingsModel.fromTraccarDevice(Map<String, dynamic> deviceJson) {
    var attributes = deviceJson['attributes'] is Map<String, dynamic> ? deviceJson['attributes'] : {};

    int parsedOdo = 0;
    if (attributes.containsKey('odometer')) {
      parsedOdo = (double.tryParse(attributes['odometer'].toString()) ?? 0.0).round();
    }

    int parsedHours = 0;
    if (attributes.containsKey('engineHours')) {
      parsedHours = (double.tryParse(attributes['engineHours'].toString()) ?? 0.0).round();
    }

    String expireDate = deviceJson['expirationTime']?.toString() ?? attributes['expirationDate']?.toString() ?? '';
    bool isExpired = expireDate.isNotEmpty ? (DateTime.tryParse(expireDate)?.isBefore(DateTime.now()) ?? false) : false;

    return VehicleSettingsModel(
      deviceJson['protocol']?.toString() ?? 'osmand',
      deviceJson['groupId']?.toString() ?? '',
      attributes['driverId']?.toString() ?? '',
      attributes['trailerId']?.toString() ?? '',
      deviceJson['name']?.toString() ?? '',
      attributes['icon']?.toString() ?? deviceJson['category']?.toString() ?? 'car',
      MapArrow(
        arrowNoConnection: attributes['arrowNoConnection']?.toString() ?? 'red',
        arrowStopped: attributes['arrowStopped']?.toString() ?? 'yellow',
        arrowMoving: attributes['arrowMoving']?.toString() ?? 'green',
        arrowEngineIdle: attributes['arrowEngineIdle']?.toString() ?? 'blue',
      ),
      attributes['mapIcon']?.toString() ?? 'default',
      attributes['tailColor']?.toString() ?? '#0000FF',
      attributes['tailPoints']?.toString() ?? '15',
      deviceJson['uniqueId']?.toString() ?? '',
      deviceJson['phone']?.toString() ?? attributes['simNumber']?.toString() ?? '',
      deviceJson['model']?.toString() ?? attributes['model']?.toString() ?? '',
      attributes['vin']?.toString() ?? '',
      attributes['plateNumber']?.toString() ?? attributes['licensePlate']?.toString() ?? '',
      attributes['odometerType']?.toString() ?? 'gps',
      attributes['engineHourType']?.toString() ?? 'ignition',
      parsedOdo,
      parsedHours,
      FCR(
        source: attributes['fcrSource']?.toString() ?? 'rates',
        measurement: attributes['fcrMeasurement']?.toString() ?? 'l100',
        cost: attributes['fcrCost']?.toString() ?? '0',
        summer: attributes['fcrSummer']?.toString() ?? '0',
        winter: attributes['fcrWinter']?.toString() ?? '0',
        winterStart: attributes['fcrWinterStart']?.toString() ?? '12-01',
        winterEnd: attributes['fcrWinterEnd']?.toString() ?? '02-28',
      ),
      attributes['timeAdj']?.toString() ?? '0',
      Accuracy(),
      'false',
      'false',
      ParamAccvirt(),
      'false',
      '',
      {},
      [],
      null,
      [],
      deviceJson['disabled'] != true,
      isExpired,
      expireDate,
    );
  }

  /// Exports model to Traccar REST API compatible payload for device updates (PUT /api/devices/{id})
  Map<String, dynamic> toTraccarDevicePayload({required int deviceId}) {
    return {
      "id": deviceId,
      "name": name ?? '',
      "uniqueId": device ?? '',
      "status": active == true ? "online" : "offline",
      "disabled": active == false,
      "phone": simNumber ?? '',
      "model": model ?? '',
      "groupId": int.tryParse(groupID ?? '0') ?? 0,
      "attributes": {
        "vin": vin ?? '',
        "plateNumber": plateNumber ?? '',
        "odometer": odometer ?? 0,
        "engineHours": engineHours ?? 0,
        "icon": icon ?? 'car',
        "tailColor": tailColor ?? '#0000FF',
        "tailPoints": tailPoints ?? '15',
        "driverId": driverID ?? '',
        "trailerId": trailerID ?? '',
      }
    };
  }

  List<dynamic> toJson() => [
        protocol,
        groupID,
        driverID,
        trailerID,
        name,
        icon,
        mapArrow?.toJson(),
        mapIcon,
        tailColor,
        tailPoints,
        device,
        simNumber,
        model,
        vin,
        plateNumber,
        odometerType,
        engineHourType,
        odometer,
        engineHours,
        fcr?.toJson(),
        timeAdj,
        accuracy?.toJson(),
        false1,
        false2,
        paramAccvirt?.toJson(),
        false3,
        emptyString,
        sensors?.map((key, value) => MapEntry(key, value.toJson())),
        emptyList,
        emptyList1,
        stringVariable,
        active,
        objectExpire,
        objectExpireDate,
      ];

  static String parseDate(dynamic date) {
    if (date == null || date.toString().isEmpty) {
      return '0000-00-00';
    }
    try {
      DateTime parsedDate = DateTime.parse(date.toString());
      return parsedDate.toIso8601String();
    } catch (e) {
      return '0000-00-00';
    }
  }
}

class StringVariable {
  String? acc;
  String? batteryLevel;
  String? distance;
  String? ignition;
  String? motion;
  String? rssi;
  String? sat;
  String? status;
  String? totalDistance;

  StringVariable({
    this.acc,
    this.batteryLevel,
    this.distance,
    this.ignition,
    this.motion,
    this.rssi,
    this.sat,
    this.status,
    this.totalDistance,
  });

  factory StringVariable.fromJson(Map<String, dynamic> json) {
    return StringVariable(
      acc: json['acc']?.toString(),
      batteryLevel: json['batteryLevel']?.toString(),
      distance: json['distance']?.toString(),
      ignition: json['ignition']?.toString(),
      motion: json['motion']?.toString(),
      rssi: json['rssi']?.toString(),
      sat: json['sat']?.toString(),
      status: json['status']?.toString(),
      totalDistance: json['totalDistance']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'acc': acc,
      'batteryLevel': batteryLevel,
      'distance': distance,
      'ignition': ignition,
      'motion': motion,
      'rssi': rssi,
      'sat': sat,
      'status': status,
      'totalDistance': totalDistance,
    };
  }
}

class ParamAccvirt {
  String? param;
  String? accvirt1Cn;
  String? accvirt0Cn;
  int? accvirt1Val;
  int? accvirt0Val;

  ParamAccvirt({
    this.param,
    this.accvirt1Cn,
    this.accvirt0Cn,
    this.accvirt1Val,
    this.accvirt0Val,
  });

  factory ParamAccvirt.fromJson(Map<String, dynamic> json) => ParamAccvirt(
        param: json['param']?.toString(),
        accvirt1Cn: json['accvirt_1_cn']?.toString(),
        accvirt0Cn: json['accvirt_0_cn']?.toString(),
        accvirt1Val: json['accvirt_1_val'] is int ? json['accvirt_1_val'] : int.tryParse(json['accvirt_1_val']?.toString() ?? '0'),
        accvirt0Val: json['accvirt_0_val'] is int ? json['accvirt_0_val'] : int.tryParse(json['accvirt_0_val']?.toString() ?? '0'),
      );

  Map<String, dynamic> toJson() => {
        "param": param,
        "accvirt_1_cn": accvirt1Cn,
        "accvirt_0_cn": accvirt0Cn,
        "accvirt_1_val": accvirt1Val,
        "accvirt_0_val": accvirt0Val,
      };
}

class Sensors {
  Sensors({
    this.name,
    this.type,
    this.param,
    this.dataList,
    this.popup,
    this.resultType,
    this.text1,
    this.text0,
    this.units,
    this.lv,
    this.hv,
    this.accIgnore,
    this.formula,
    this.calibration,
    this.dictionary,
  });

  String? name;
  String? type;
  String? param;
  String? dataList;
  String? popup;
  String? resultType;
  String? text1;
  String? text0;
  String? units;
  String? lv;
  String? hv;
  String? accIgnore;
  String? formula;
  List<Calibration>? calibration;
  List<Dictionary>? dictionary;

  factory Sensors.fromJson(Map<String, dynamic> json) => Sensors(
        name: json["name"]?.toString(),
        type: json["type"]?.toString(),
        param: json["param"]?.toString(),
        dataList: json["data_list"]?.toString(),
        popup: json["popup"]?.toString(),
        resultType: json["result_type"]?.toString(),
        text1: json["text_1"]?.toString(),
        text0: json["text_0"]?.toString(),
        units: json["units"]?.toString(),
        lv: json["lv"]?.toString(),
        hv: json["hv"]?.toString(),
        accIgnore: json["acc_ignore"]?.toString(),
        formula: json["formula"]?.toString(),
        calibration: json["calibration"] != null && json["calibration"] is List
            ? List<Calibration>.from((json["calibration"] as List).map((x) => Calibration.fromJson(x)))
            : [],
        dictionary: json["dictionary"] != null && json["dictionary"] is List
            ? List<Dictionary>.from((json["dictionary"] as List).map((x) => Dictionary.fromJson(x)))
            : [],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "type": type,
        "param": param,
        "data_list": dataList,
        "popup": popup,
        "result_type": resultType,
        "text_1": text1,
        "text_0": text0,
        "units": units,
        "lv": lv,
        "hv": hv,
        "acc_ignore": accIgnore,
        "formula": formula,
        "calibration": calibration != null ? List<dynamic>.from(calibration!.map((x) => x.toJson())) : [],
        "dictionary": dictionary != null ? List<dynamic>.from(dictionary!.map((x) => x.toJson())) : [],
      };
}

class Calibration {
  Calibration({
    this.x,
    this.y,
  });

  dynamic x;
  dynamic y;

  factory Calibration.fromJson(Map<String, dynamic> json) => Calibration(
        x: json["x"],
        y: json["y"],
      );

  Map<String, dynamic> toJson() => {
        "x": x,
        "y": y,
      };
}

class Dictionary {
  Dictionary({
    this.value,
    this.text,
  });

  dynamic value;
  dynamic text;

  factory Dictionary.fromJson(Map<String, dynamic> json) => Dictionary(
        value: json["value"],
        text: json["text"],
      );

  Map<String, dynamic> toJson() => {
        "value": value,
        "text": text,
      };
}

class FCR {
  String? source;
  String? measurement;
  String? cost;
  String? summer;
  String? winter;
  String? winterStart;
  String? winterEnd;

  FCR({
    this.source,
    this.measurement,
    this.cost,
    this.summer,
    this.winter,
    this.winterStart,
    this.winterEnd,
  });

  factory FCR.fromJson(Map<String, dynamic> json) => FCR(
        source: json["source"]?.toString(),
        measurement: json["measurement"]?.toString(),
        cost: json["cost"]?.toString(),
        summer: json["summer"]?.toString(),
        winter: json["winter"]?.toString(),
        winterStart: json["winter_start"]?.toString(),
        winterEnd: json["winter_end"]?.toString(),
      );

  Map<String, dynamic> toJson() => {
        "source": source,
        "measurement": measurement,
        "cost": cost,
        "summer": summer,
        "winter": winter,
        "winter_start": winterStart,
        "winter_end": winterEnd,
      };
}

class MapArrow {
  String? arrowNoConnection;
  String? arrowStopped;
  String? arrowMoving;
  String? arrowEngineIdle;

  MapArrow({
    this.arrowNoConnection,
    this.arrowStopped,
    this.arrowMoving,
    this.arrowEngineIdle,
  });

  factory MapArrow.fromJson(Map<String, dynamic> json) => MapArrow(
        arrowNoConnection: json["arrow_no_connection"]?.toString(),
        arrowStopped: json["arrow_stopped"]?.toString(),
        arrowMoving: json["arrow_moving"]?.toString(),
        arrowEngineIdle: json["arrow_engine_idle"]?.toString(),
      );

  Map<String, dynamic> toJson() => {
        "arrow_no_connection": arrowNoConnection,
        "arrow_stopped": arrowStopped,
        "arrow_moving": arrowMoving,
        "arrow_engine_idle": arrowEngineIdle,
      };
}

class Accuracy {
  Accuracy({
    this.stops,
    this.routeLenght,
    this.minMovingSpeed,
    this.minIdleSpeed,
    this.minDiffPoints,
    this.useGpslev,
    this.minGpslev,
    this.useHdop,
    this.maxHdop,
    this.ignFuelConsStops,
    this.minFuelSpeed,
    this.minFf,
    this.minFt,
  });

  dynamic stops;
  dynamic routeLenght;
  dynamic minMovingSpeed;
  dynamic minIdleSpeed;
  dynamic minDiffPoints;
  bool? useGpslev;
  dynamic minGpslev;
  bool? useHdop;
  dynamic maxHdop;
  bool? ignFuelConsStops;
  dynamic minFuelSpeed;
  dynamic minFf;
  dynamic minFt;

  factory Accuracy.fromJson(Map<String, dynamic> json) => Accuracy(
        stops: json["stops"],
        minMovingSpeed: json["min_moving_speed"],
        minIdleSpeed: json["min_idle_speed"],
        minDiffPoints: json["min_diff_points"],
        useGpslev: json["use_gpslev"],
        minGpslev: json["min_gpslev"],
        useHdop: json["use_hdop"],
        maxHdop: json["max_hdop"],
        minFuelSpeed: json["min_fuel_speed"],
        minFf: json["min_ff"],
        minFt: json["min_ft"],
      );

  Map<String, dynamic> toJson() => {
        "stops": stops,
        "min_moving_speed": minMovingSpeed,
        "min_idle_speed": minIdleSpeed,
        "min_diff_points": minDiffPoints,
        "use_gpslev": useGpslev,
        "min_gpslev": minGpslev,
        "use_hdop": useHdop,
        "max_hdop": maxHdop,
        "min_fuel_speed": minFuelSpeed,
        "min_ff": minFf,
        "min_ft": minFt,
      };
}
