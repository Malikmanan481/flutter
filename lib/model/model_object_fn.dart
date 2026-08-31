import 'dart:convert';

class ObjectDataModel {
  dynamic v;
  dynamic f;
  dynamic s;
  dynamic evt;
  dynamic evtac;
  dynamic evtohc;
  dynamic a;
  List<dynamic>? l;
  List<List<dynamic>>? d;
  List<D>? dData;
  dynamic lif;
  dynamic st;
  dynamic ststr;
  dynamic p;
  dynamic cn;
  dynamic o;
  dynamic eh;
  List<dynamic>? sr;

  ObjectDataModel({
    this.v,
    this.f,
    this.s,
    this.evt,
    this.evtac,
    this.evtohc,
    this.a,
    this.l,
    this.d,
    this.dData,
    this.lif,
    this.st,
    this.ststr,
    this.p,
    this.cn,
    this.o,
    this.eh,
    this.sr,
  });

  /// Original JSON Factory (Safeguarded against null pointer & type mismatch errors)
  factory ObjectDataModel.fromJson(Map<String, dynamic> json) {
    List<List<dynamic>> parsedD = [];
    List<D> parsedDData = [];

    if (json["d"] != null && json["d"] is List) {
      for (var item in json["d"]) {
        if (item is List) {
          parsedD.add(List<dynamic>.from(item.map((x) => x)));
          parsedDData.add(D.fromJson(List<dynamic>.from(item)));
        } else if (item is Map<String, dynamic>) {
          parsedDData.add(D.fromMap(item));
        }
      }
    }

    return ObjectDataModel(
      v: json["v"] ?? false,
      f: json["f"] ?? false,
      s: json["s"] ?? false,
      evt: json["evt"] ?? false,
      evtac: json["evtac"] ?? false,
      evtohc: json["evtohc"] ?? false,
      a: json["a"]?.toString() ?? '',
      l: json["l"] != null && json["l"] is List ? List<dynamic>.from(json["l"].map((x) => x)) : [],
      d: parsedD,
      dData: parsedDData,
      lif: json['lif']?.toString() ?? '',
      st: json["st"] == false ? "off" : (json["st"]?.toString() ?? "on"),
      ststr: json["ststr"]?.toString() ?? '',
      p: json["p"]?.toString() ?? '',
      cn: json["cn"] is int ? json["cn"] : int.tryParse(json["cn"]?.toString() ?? '0') ?? 0,
      o: json["o"] is int ? json["o"] : int.tryParse(json["o"]?.toString() ?? '0') ?? 0,
      eh: json["eh"]?.toString() ?? '',
      sr: json["sr"] != null && json["sr"] is List ? List<dynamic>.from(json["sr"].map((x) => x)) : [],
    );
  }

  /// Traccar REST API Parser for Route History (/api/reports/route or /api/positions)
  factory ObjectDataModel.fromTraccarPositions(List<dynamic> positionsList, {Map<String, dynamic>? deviceJson}) {
    List<D> dList = [];
    List<List<dynamic>> dRawList = [];

    for (var pos in positionsList) {
      if (pos is Map<String, dynamic>) {
        D dObj = D.fromTraccarPosition(pos);
        dList.add(dObj);
        dRawList.add(dObj.toJson());
      }
    }

    bool isOnline = deviceJson?['status'] == 'online';
    String statusStr = deviceJson?['status']?.toString() ?? (positionsList.isNotEmpty ? 'online' : 'offline');

    return ObjectDataModel(
      v: true,
      f: true,
      s: isOnline,
      evt: false,
      evtac: false,
      evtohc: false,
      a: deviceJson?['name']?.toString() ?? '',
      l: [],
      d: dRawList,
      dData: dList,
      lif: positionsList.isNotEmpty ? positionsList.last['fixTime']?.toString() : '',
      st: isOnline ? "on" : "off",
      ststr: statusStr,
      p: deviceJson?['uniqueId']?.toString() ?? '',
      cn: positionsList.length,
      o: 0,
      eh: '',
      sr: [],
    );
  }

  Map<String, dynamic> toJson() => {
        "v": v,
        "f": f,
        "s": s,
        "evt": evt,
        "evtac": evtac,
        "evtohc": evtohc,
        "a": a,
        "l": l != null ? List<dynamic>.from(l!.map((x) => x)) : [],
        "d": dData != null && dData!.isNotEmpty
            ? dData!.map((item) => item.toJson()).toList()
            : (d != null ? List<dynamic>.from(d!.map((x) => List<dynamic>.from(x.map((x) => x)))) : []),
        "lif": lif,
        "st": st,
        "ststr": ststr,
        "p": p,
        "cn": cn,
        "o": o,
        "eh": eh,
        "sr": sr != null ? List<dynamic>.from(sr!.map((x) => x)) : [],
      };
}

class D {
  final String? date;
  final String? time;
  final String? latitude;
  final String? longitude;
  final String? zero1;
  final String? zero2;
  final int? zero3;
  final InnerData? innerData;

  D({
    this.date,
    this.time,
    this.latitude,
    this.longitude,
    this.zero1,
    this.zero2,
    this.zero3,
    this.innerData,
  });

  /// Factory for legacy array format `[date, time, lat, lng, zero1, zero2, zero3, innerDataMap]`
  factory D.fromJson(List<dynamic> json) {
    return D(
      date: json.length > 0 ? json[0]?.toString() : '',
      time: json.length > 1 ? json[1]?.toString() : '',
      latitude: json.length > 2 ? json[2]?.toString() : '',
      longitude: json.length > 3 ? json[3]?.toString() : '',
      zero1: json.length > 4 ? json[4]?.toString() : '',
      zero2: json.length > 5 ? json[5]?.toString() : '',
      zero3: json.length > 6 ? (json[6] is int ? json[6] : int.tryParse(json[6]?.toString() ?? '0') ?? 0) : 0,
      innerData: json.length > 7 && json[7] != null ? InnerData.fromJson(Map<String, dynamic>.from(json[7])) : null,
    );
  }

  factory D.fromMap(Map<String, dynamic> json) {
    return D(
      date: json['date']?.toString(),
      time: json['time']?.toString(),
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      zero1: json['zero1']?.toString(),
      zero2: json['zero2']?.toString(),
      zero3: json['zero3'] is int ? json['zero3'] : int.tryParse(json['zero3']?.toString() ?? '0'),
      innerData: json['innerData'] != null ? InnerData.fromJson(json['innerData']) : null,
    );
  }

  /// Traccar Position Object Parser (/api/positions)
  factory D.fromTraccarPosition(Map<String, dynamic> posJson) {
    String fixTimeStr = posJson['fixTime']?.toString() ?? posJson['serverTime']?.toString() ?? '';
    DateTime? dt = DateTime.tryParse(fixTimeStr);
    
    String dateStr = dt != null ? "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}" : '';
    String timeStr = dt != null ? "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}" : '';

    double rawSpeedKnots = double.tryParse(posJson['speed']?.toString() ?? '0') ?? 0.0;
    int speedKmh = (rawSpeedKnots * 1.852).round();

    var attributes = posJson['attributes'] is Map<String, dynamic> ? posJson['attributes'] : <String, dynamic>{};

    return D(
      date: dateStr,
      time: timeStr,
      latitude: posJson['latitude']?.toString() ?? '0.0',
      longitude: posJson['longitude']?.toString() ?? '0.0',
      zero1: speedKmh.toString(),
      zero2: posJson['altitude']?.toString() ?? '0',
      zero3: (posJson['course'] as num?)?.toInt() ?? 0,
      innerData: InnerData.fromTraccarAttributes(attributes),
    );
  }

  List<dynamic> toJson() {
    return [
      date,
      time,
      latitude,
      longitude,
      zero1,
      zero2,
      zero3,
      innerData?.toJson(),
    ];
  }
}

class InnerData {
  final String? acc;
  final String? charge;
  final String? distance;
  final String? fuel;
  final String? hours;
  final String? ignition;
  final String? in2;
  final String? motion;
  final String? odometer;
  final String? out2;
  final String? panic;
  final String? totalDistance;
  final String? batteryLevel;
  final String? blocked;
  final String? event;
  final String? hdop;
  final String? io200;
  final String? io68;
  final String? io69;
  final String? operator;
  final String? pdop;
  final String? power;
  final String? priority;
  final String? rssi;
  final String? sat;
  final String? status;

  InnerData({
    this.acc,
    this.charge,
    this.distance,
    this.fuel,
    this.hours,
    this.ignition,
    this.in2,
    this.motion,
    this.odometer,
    this.out2,
    this.panic,
    this.totalDistance,
    this.batteryLevel,
    this.blocked,
    this.event,
    this.hdop,
    this.io200,
    this.io68,
    this.io69,
    this.operator,
    this.pdop,
    this.power,
    this.priority,
    this.rssi,
    this.sat,
    this.status,
  });

  factory InnerData.fromJson(Map<String, dynamic> json) {
    return InnerData(
      acc: json['acc']?.toString(),
      charge: json['charge']?.toString(),
      distance: json['distance']?.toString(),
      fuel: json['fuel']?.toString(),
      hours: json['hours']?.toString(),
      ignition: json['ignition']?.toString(),
      in2: json['in2']?.toString(),
      motion: json['motion']?.toString(),
      odometer: json['odometer']?.toString(),
      out2: json['out2']?.toString(),
      panic: json['panic']?.toString(),
      totalDistance: json['totalDistance']?.toString(),
      batteryLevel: json['batteryLevel']?.toString(),
      blocked: json['blocked']?.toString(),
      event: json['event']?.toString(),
      hdop: json['hdop']?.toString(),
      io200: json['io200']?.toString(),
      io68: json['io68']?.toString(),
      io69: json['io69']?.toString(),
      operator: json['operator']?.toString(),
      pdop: json['pdop']?.toString(),
      power: json['power']?.toString(),
      priority: json['priority']?.toString(),
      rssi: json['rssi']?.toString(),
      sat: json['sat']?.toString(),
      status: json['status']?.toString(),
    );
  }

  /// Traccar Position Attributes Parser (`posJson['attributes']`)
  factory InnerData.fromTraccarAttributes(Map<String, dynamic> attributes) {
    bool isIgnition = attributes['ignition'] == true || attributes['acc'] == true;
    bool isMotion = attributes['motion'] == true;

    return InnerData(
      acc: isIgnition ? '1' : '0',
      charge: attributes['charge']?.toString() ?? '0',
      distance: attributes['distance']?.toString() ?? '0',
      fuel: attributes['fuel']?.toString() ?? attributes['fuel1']?.toString() ?? '0',
      hours: attributes['hours']?.toString() ?? '0',
      ignition: isIgnition ? '1' : '0',
      in2: attributes['in2']?.toString() ?? '0',
      motion: isMotion ? '1' : '0',
      odometer: attributes['odometer']?.toString() ?? '0',
      out2: attributes['out2']?.toString() ?? '0',
      panic: attributes['panic'] == true ? '1' : '0',
      totalDistance: attributes['totalDistance']?.toString() ?? '0',
      batteryLevel: attributes['batteryLevel']?.toString() ?? '0',
      blocked: attributes['blocked'] == true ? '1' : '0',
      event: attributes['event']?.toString() ?? '',
      hdop: attributes['hdop']?.toString() ?? '0',
      io200: attributes['io200']?.toString() ?? '0',
      io68: attributes['io68']?.toString() ?? '0',
      io69: attributes['io69']?.toString() ?? '0',
      operator: attributes['operator']?.toString() ?? '',
      pdop: attributes['pdop']?.toString() ?? '0',
      power: attributes['power']?.toString() ?? '0',
      priority: attributes['priority']?.toString() ?? '0',
      rssi: attributes['rssi']?.toString() ?? '0',
      sat: attributes['sat']?.toString() ?? '0',
      status: attributes['status']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'acc': acc,
      'charge': charge,
      'distance': distance,
      'fuel': fuel,
      'hours': hours,
      'ignition': ignition,
      'in2': in2,
      'motion': motion,
      'odometer': odometer,
      'out2': out2,
      'panic': panic,
      'totalDistance': totalDistance,
      'batteryLevel': batteryLevel,
      'blocked': blocked,
      'event': event,
      'hdop': hdop,
      'io200': io200,
      'io68': io68,
      'io69': io69,
      'operator': operator,
      'pdop': pdop,
      'power': power,
      'priority': priority,
      'rssi': rssi,
      'sat': sat,
      'status': status,
    };
  }
}
