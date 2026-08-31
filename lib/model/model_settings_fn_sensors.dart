import 'dart:convert';

Map<String, SensorsJsonObject> sensorsJsonObjectFromJson(String str) => Map.from(json.decode(str))
    .map((k, v) => MapEntry<String, SensorsJsonObject>(k, SensorsJsonObject.fromJson(v)));

String sensorsJsonObjectToJson(Map<String, SensorsJsonObject> data) =>
    json.encode(Map.from(data).map((k, v) => MapEntry<String, dynamic>(k, v.toJson())));

class SensorsJsonObject {
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
  List<dynamic>? calibration;
  List<dynamic>? dictionary;

  SensorsJsonObject({
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

  factory SensorsJsonObject.fromJson(Map<String, dynamic> json) => SensorsJsonObject(
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
            ? List<dynamic>.from((json["calibration"] as List).map((x) => x))
            : [],
        dictionary: json["dictionary"] != null && json["dictionary"] is List
            ? List<dynamic>.from((json["dictionary"] as List).map((x) => x))
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
        "calibration": calibration != null ? List<dynamic>.from(calibration!.map((x) => x)) : [],
        "dictionary": dictionary != null ? List<dynamic>.from(dictionary!.map((x) => x)) : [],
      };

  /// Parses Traccar Computed Attributes API (/api/attributes/computed) into SensorsJsonObject
  factory SensorsJsonObject.fromTraccarComputedAttribute(Map<String, dynamic> json) {
    return SensorsJsonObject(
      name: json['description']?.toString() ?? json['attribute']?.toString() ?? '',
      type: json['type']?.toString() ?? 'expression',
      param: json['attribute']?.toString() ?? '',
      formula: json['expression']?.toString() ?? '',
      resultType: json['type']?.toString() ?? 'string',
      calibration: [],
      dictionary: [],
    );
  }

  /// Maps dynamic position telemetry attributes from (/api/positions) to Map<String, SensorsJsonObject>
  static Map<String, SensorsJsonObject> mapFromTraccarPositionAttributes(Map<String, dynamic>? attributes) {
    Map<String, SensorsJsonObject> sensorMap = {};
    if (attributes == null || attributes.isEmpty) return sensorMap;

    attributes.forEach((key, value) {
      sensorMap[key] = SensorsJsonObject(
        name: key,
        type: value is bool ? 'logic' : (value is num ? 'numeric' : 'text'),
        param: key,
        formula: value.toString(),
        units: _inferTraccarUnits(key),
        calibration: [],
        dictionary: [],
      );
    });

    return sensorMap;
  }

  /// Exports local sensor object to Traccar Computed Attribute payload (POST /api/attributes/computed)
  Map<String, dynamic> toTraccarComputedAttributePayload() {
    return {
      "description": name ?? param ?? '',
      "attribute": param ?? 'custom',
      "expression": formula ?? '',
      "type": resultType ?? 'number'
    };
  }

  static String _inferTraccarUnits(String attributeKey) {
    switch (attributeKey.toLowerCase()) {
      case 'power':
      case 'adc1':
      case 'adc2':
        return 'V';
      case 'batterylevel':
      case 'battery':
        return '%';
      case 'fuel':
      case 'fuel1':
        return 'L';
      case 'temp1':
      case 'temp2':
        return '°C';
      case 'distance':
      case 'totaldistance':
        return 'm';
      default:
        return '';
    }
  }
}
