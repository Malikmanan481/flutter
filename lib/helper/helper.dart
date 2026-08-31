import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart' as intl;
import 'package:speedotrack/bloc/bloc_home_item.dart';
import 'package:speedotrack/config/size_config.dart';
import 'package:speedotrack/globals.dart';
import 'package:speedotrack/model/model_object_fn.dart';
import 'package:speedotrack/model/model_sensor.dart';
import 'package:speedotrack/model/model_sensor_home.dart';
import 'package:speedotrack/model/model_settings_fn.dart';

import 'package:speedotrack/sharedPrefs/main_prefs.dart';
import 'package:stack/stack.dart' as stackJava;

class Helper {
  var formatter = new intl.DateFormat('dd MMM yyyy');

  String twoDigitString(int number) {
    if (number == 0) {
      return "00";
    }

    if (number / 10 == 0) {
      return '0$number';
    }

    return number.toString();
  }

  String getDurationString(String string) {
    int seconds = int.parse(string);
    int hours = (seconds / 3600).round();
    int minutes = ((seconds % 3600) / 60).round();
    seconds = seconds % 60;
    return twoDigitString(hours) +
        " h " +
        twoDigitString(minutes) +
        " m " +
        twoDigitString(seconds) +
        " s";
  }

  // ==========================================
  // TRACCAR BACKEND INTEGRATION ADAPTERS
  // ==========================================

  /// Converts Traccar Device and Position object into a unified status code
  /// Returns 'm' (moving), 's' (stopped), 'i' (idle), 'off' (offline), or 'false'
  String getTraccarVehicleStatus(Map<String, dynamic> device, Map<String, dynamic>? position) {
    String deviceStatus = (device['status'] ?? 'offline').toString().toLowerCase();
    
    if (deviceStatus == 'offline') {
      return 'off';
    }

    if (position == null) {
      return 'false';
    }

    double speedInKnots = (position['speed'] ?? 0).toDouble();
    double speedKmH = speedInKnots * 1.852;
    Map<String, dynamic> attributes = position['attributes'] ?? {};
    bool ignition = attributes['ignition'] ?? false;

    if (speedKmH > 1.0) {
      return 'm';
    } else if (ignition) {
      return 'i';
    } else {
      return 's';
    }
  }

  /// Sets up HomeItem list directly using Traccar `/api/devices` and `/api/positions` payload
  List<HomeItem> homeScreenSetupFromTraccar(
      List<dynamic> traccarDevices, Map<int, dynamic> traccarPositionsMap) {
    List<HomeItem> homeItemList = [];

    for (var device in traccarDevices) {
      try {
        int deviceId = device['id'];
        String name = device['name'] ?? 'Unknown Vehicle';
        String imei = device['uniqueId'] ?? deviceId.toString();
        bool disabled = device['disabled'] ?? false;
        String category = device['category'] ?? 'car';

        Map<String, dynamic>? position = traccarPositionsMap[deviceId];

        String statusCode = getTraccarVehicleStatus(device, position);
        String statusText = statusCode == 'm'
            ? 'Moving'
            : statusCode == 's'
                ? 'Stopped'
                : statusCode == 'i'
                    ? 'Idle'
                    : statusCode == 'off'
                        ? 'Offline'
                        : 'No Data';

        double lat = position != null ? (position['latitude'] ?? 20.5937).toDouble() : 20.5937;
        double lng = position != null ? (position['longitude'] ?? 78.9629).toDouble() : 78.9629;
        double speedKmH = position != null ? ((position['speed'] ?? 0).toDouble() * 1.852) : 0.0;
        double course = position != null ? (position['course'] ?? 0).toDouble() : 0.0;

        Map<String, dynamic> attributes = position != null ? (position['attributes'] ?? {}) : {};
        bool hasFuelSensor = attributes.containsKey('fuel') || attributes.containsKey('fuel2');

        String expireText = device['expirationTime'] != null
            ? formatter.format(DateTime.parse(device['expirationTime']))
            : 'Active';

        String markerIconPath = 'images/${getMarkerName(statusCode, category)}';

        homeItemList.add(HomeItem(
          hasFuelSensor,
          lat.toString(),
          lng.toString(),
          statusText,
          statusCode,
          course.toInt(),
          name,
          speedKmH.toStringAsFixed(0),
          imei,
          !disabled,
          expireText,
          category,
          markerIconPath,
        ));
      } catch (e) {
        continue;
      }
    }
    return homeItemList;
  }

  /// Parses Traccar Position attributes into Home Sensors list
  List<SensorModelHome> parseTraccarSensorsHome(Map<String, dynamic>? positionAttributes) {
    List<SensorModelHome> sensorList = [];
    if (positionAttributes == null) return sensorList;

    if (positionAttributes.containsKey('ignition')) {
      bool ignition = positionAttributes['ignition'] == true;
      sensorList.add(SensorModelHome(
        getDrawable('Ignition'),
        'Ignition : ${ignition ? "ON" : "OFF"}',
        Globals.appColor,
      ));
    }

    if (positionAttributes.containsKey('batteryLevel')) {
      sensorList.add(SensorModelHome(
        getDrawable('Battery Level'),
        'Battery : ${positionAttributes['batteryLevel']}%',
        Globals.appColor,
      ));
    }

    if (positionAttributes.containsKey('power')) {
      sensorList.add(SensorModelHome(
        getDrawable('External Battery'),
        'External Power : ${positionAttributes['power']} V',
        Globals.appColor,
      ));
    }

    if (positionAttributes.containsKey('fuel')) {
      sensorList.add(SensorModelHome(
        getDrawable('Fuel Level'),
        'Fuel : ${positionAttributes['fuel']} L',
        Globals.appColor,
      ));
    }

    if (positionAttributes.containsKey('temp1')) {
      sensorList.add(SensorModelHome(
        getDrawable('Temperature'),
        'Temp : ${positionAttributes['temp1']} °C',
        Globals.appColor,
      ));
    }

    return sensorList;
  }

  // ==========================================
  // LEGACY SENSOR & FORMULA PARSING LOGIC
  // ==========================================

  String getSensorValueForResultTypeLogic(
      Sensors sensorJsonObject, List<dynamic> dArray) {
    String sensorFinalValue = "";
    try {
      String text_0 = sensorJsonObject.text0!;
      String text_1 = sensorJsonObject.text1!;
      String param = sensorJsonObject.param!;
      String value = dArray[7][param];
      if (value == '1') {
        sensorFinalValue = text_1;
      } else {
        sensorFinalValue = text_0;
      }
    } catch (e) {}
    return sensorFinalValue;
  }

  List<Calibration> sortJsonArray(List<Calibration> jsonArrayFuelCalib) {
    List<Calibration> sortedJsonArray = [];
    List<Calibration> jsonValues = [];
    for (int i = 0; i < jsonArrayFuelCalib.length; i++) {
      try {
        jsonValues.add(jsonArrayFuelCalib[i]);
      } catch (e) {}
    }
    jsonValues.sort((a, b) => a.x.compareTo(b.x));

    for (int i = 0; i < jsonArrayFuelCalib.length; i++) {
      sortedJsonArray.add(jsonValues[i]);
    }
    return sortedJsonArray;
  }

  String getSensorValueForResultTypeValue(
      Sensors sensorJsonObject, List<dynamic> dArray) {
    dynamic sensorFinalValue = '';
    try {
      dynamic param = sensorJsonObject.param;
      double value = double.parse(dArray[7][param]);
      dynamic sensorName = sensorJsonObject.name;
      dynamic fuelFormula = "";
      List<Calibration>? calibrationJsonArray = sensorJsonObject.calibration;

      if (calibrationJsonArray!.length != 0) {
        calibrationJsonArray = sortJsonArray(calibrationJsonArray);
        if (double.parse(calibrationJsonArray[0].x) >
            double.parse(calibrationJsonArray[1].x)) {
          calibrationJsonArray = calibrationJsonArray.reversed.toList();
        }
        for (int i = 0; i < calibrationJsonArray.length - 1; i++) {
          double x1 = double.parse(calibrationJsonArray[i].x);
          double x2 = double.parse(calibrationJsonArray[i + 1].x);
          double y1 = double.parse(calibrationJsonArray[i].y);
          double y2 = double.parse(calibrationJsonArray[i + 1].y);
          if (x1 < value && x2 > value) {
            sensorFinalValue = getCalibratedValue(x1, x2, y1, y2, value);
            break;
          } else if (x1 == value) {
            sensorFinalValue = y1.toString();
            break;
          } else if (x2 == value) {
            sensorFinalValue = y2.toString();
            break;
          } else if (value > x2) {
            if (sensorName == 'Fuel Level') {
              sensorFinalValue = y2.toString();
            }
          }
        }
        if (sensorFinalValue == '') {
          double x1 = double.parse(calibrationJsonArray[0].x);
          double x2 = double.parse(calibrationJsonArray[1].x);
          double y1 = double.parse(calibrationJsonArray[0].y);
          double y2 = double.parse(calibrationJsonArray[1].y);

          if (value > x2) {
            sensorFinalValue = y2.toString();
          } else if (value < x1) {
            sensorFinalValue = y1.toString();
          }
        }

        try {
          List<Dictionary>? dictionaryJsonArray = sensorJsonObject.dictionary;
          for (int i = 0; i < dictionaryJsonArray!.length; i++) {
            if (dictionaryJsonArray[i].value.toString() ==
                double.parse(sensorFinalValue.toString()).toStringAsFixed(0)) {
              sensorFinalValue = dictionaryJsonArray[i].text;
            }
          }
        } catch (e) {}
      } else {
        fuelFormula = sensorJsonObject.formula;
        if (fuelFormula != '') {
          fuelFormula = fuelFormula.replaceAll('x', value.toStringAsFixed(0));
          sensorFinalValue = evalExp(fuelFormula);
        } else {
          sensorFinalValue = dArray[7][sensorJsonObject.param];
        }
      }
    } catch (e) {
      sensorFinalValue = '0';
    }
    return sensorFinalValue;
  }

  String? getCalibratedValue(
      double x1, double x2, double y1, double y2, double value) {
    double midX = (x1 + x2) / 2;
    double midY = (y1 + y2) / 2;

    while (x1 <= x2) {
      if (midX > value) {
        x2 = midX;
        y2 = midY;
      } else if (midX == value) {
        return midY.toStringAsFixed(2);
      } else {
        x1 = midX;
        y1 = midY;
      }
      midX = (x1 + x2) / 2;
      midY = (y1 + y2) / 2;
    }
    return null;
  }

  String evalExp(String input) {
    stackJava.Stack<int> op = stackJava.Stack<int>();
    stackJava.Stack<double> val = stackJava.Stack<double>();
    stackJava.Stack<int> optmp = stackJava.Stack<int>();
    stackJava.Stack<double> valtmp = stackJava.Stack<double>();

    input = "0" + input;
    input = input.replaceAll("-", "+-");
    String temp = "";
    for (int i = 0; i < input.length; i++) {
      var ch = input[i];
      if (ch == '-')
        temp = "-" + temp;
      else if (ch != '+' && ch != '*' && ch != '/')
        temp = temp + ch;
      else {
        val.push(double.parse(temp));
        op.push(ch.codeUnitAt(0));
        temp = "";
      }
    }
    val.push(double.parse(temp));
    var operators = [47, 42, 43];
    for (int i = 0; i < 3; i++) {
      bool it = false;
      while (op.isNotEmpty) {
        int optr = op.pop();
        double v1 = val.pop();
        double v2 = val.pop();
        if (optr == operators[i]) {
          if (i == 0) {
            valtmp.push(v2 / v1);
            it = true;
            break;
          } else if (i == 1) {
            valtmp.push(v2 * v1);
            it = true;
            break;
          } else if (i == 2) {
            valtmp.push(v2 + v1);
            it = true;
            break;
          }
        } else {
          valtmp.push(v1);
          val.push(v2);
          optmp.push(optr);
        }
      }
      while (valtmp.isNotEmpty) val.push(valtmp.pop());
      while (optmp.isNotEmpty) op.push(optmp.pop());
      if (it) i--;
    }
    return val.pop().toStringAsFixed(2);
  }

  String getSensorValueForResultTypePercentage(
      Sensors sensorJsonObjects, List<dynamic> dArray) {
    String sensorFinalValue = "";
    try {
      var value = sensorJsonObjects.param;
      dynamic sensorValue = dArray[7][value];
      if (sensorValue.contains('%') || sensorValue == '') {
        sensorFinalValue = sensorValue;
      } else {
        double hv = double.parse(sensorJsonObjects.hv!);
        double lv = double.parse(sensorJsonObjects.lv!);
        double sensorValueDouble = double.parse(sensorValue);
        if (sensorValueDouble > lv && sensorValueDouble < hv) {
          double a = sensorValueDouble - lv;
          double b = hv - lv;
          double percent = (a / b) * 100;
          if (percent > 100) {
            percent = 100;
          }
          sensorFinalValue = percent.toString();
        } else if (sensorValueDouble <= lv) {
          sensorFinalValue = "0";
        } else if (sensorValueDouble >= hv) {
          sensorFinalValue = "100";
        }
      }
    } catch (e) {}
    return sensorFinalValue;
  }

  List<SensorModel> checkAndSetSensor(
      int j, Map<String, dynamic> sensorsJsonObject, List<dynamic> jdArray) {
    List<SensorModel> sensorModel = [];
    List<String> sensorsKeysJsonArray = [];
    if (sensorsJsonObject != null) {
      sensorsKeysJsonArray = sensorsJsonObject.keys.toList();
    }
    String sensorID = sensorsKeysJsonArray[j];
    Sensors sensorJsonObject = sensorsJsonObject[sensorID];
    String sensorName = sensorJsonObject.name!;
    String sensorType = sensorJsonObject.resultType!;
    String units = sensorJsonObject.units!;

    String sensorFinalValue = "NA";
    switch (sensorType) {
      case "percentage":
        sensorFinalValue = getSensorValueForResultTypePercentage(sensorJsonObject, jdArray);
        break;
      case "value":
        sensorFinalValue = getSensorValueForResultTypeValue(sensorJsonObject, jdArray);
        break;
      case "logic":
        sensorFinalValue = getSensorValueForResultTypeLogic(sensorJsonObject, jdArray);
        break;
    }

    sensorFinalValue = '$sensorFinalValue $units';

    if (sensorFinalValue != 'NA') {
      sensorModel.add(SensorModel(
          Image.asset(getDrawable(sensorName)),
          Text(
            '$sensorName : $sensorFinalValue',
            maxLines: 2,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.0,
              color: Globals.appColor,
              fontWeight: FontWeight.bold,
            ),
          )));
    }
    return sensorModel;
  }

  List<SensorModelHome> checkAndSetSensorHome(
      int j, Map<String, Sensors?> sensorsJsonObject, List<dynamic> jdArray) {
    List<SensorModelHome> sensorModel = [];
    List<String> sensorsKeysJsonArray = [];
    if (sensorsJsonObject != null) {
      sensorsKeysJsonArray = sensorsJsonObject.keys.toList();
    }
    String sensorID = sensorsKeysJsonArray[j];
    Sensors sensorJsonObject = sensorsJsonObject[sensorID]!;
    String sensorName = sensorJsonObject.name!;
    String sensorType = sensorJsonObject.resultType!;
    String units = sensorJsonObject.units!;

    String sensorFinalValue = "NA";
    switch (sensorType) {
      case "percentage":
        sensorFinalValue = getSensorValueForResultTypePercentage(sensorJsonObject, jdArray);
        break;
      case "value":
        sensorFinalValue = getSensorValueForResultTypeValue(sensorJsonObject, jdArray);
        break;
      case "logic":
        sensorFinalValue = getSensorValueForResultTypeLogic(sensorJsonObject, jdArray);
        break;
    }

    sensorFinalValue = '$sensorFinalValue $units';

    if (sensorFinalValue != 'NA') {
      sensorModel.add(SensorModelHome(
          getDrawable(sensorName), '$sensorName : $sensorFinalValue', Globals.appColor));
    }
    return sensorModel;
  }

  List<HomeItem> homeScreenSetup(List<String> _iMEIArray) {
    List<String> _sortedIMEIArray = [];
    List<String> _movingIMEIArray = [];
    List<String> _stoppedIMEIArray = [];
    List<String> _idleIMEIArray = [];
    List<String> _noDataIMEIArray = [];
    List<String> _offlineIMEIArray = [];
    List<String> _expireIMEIArray = [];
    List<HomeItem> _homeItemList = [];

    if (_iMEIArray != null && _iMEIArray.isNotEmpty) {
      for (int index = 0; index < _iMEIArray.length; index++) {
        try {
          VehicleSettingsModel vehicleSettingsStrings = VehicleSettingsModel.fromJson(
              jsonDecode(Globals.prefs!.getString('${_iMEIArray[index]}_settings')!));

          if (!vehicleSettingsStrings.active!) {
            _expireIMEIArray.add(_iMEIArray[index]);
          } else {
            ObjectDataModel objectDataModel = ObjectDataModel.fromJson(
                jsonDecode(Globals.prefs!.getString('${_iMEIArray[index]}_objects')!));
            if (objectDataModel.toString().isNotEmpty) {
              String st = objectDataModel.st.toString();
              switch (st) {
                case "m":
                  _movingIMEIArray.add(_iMEIArray[index]);
                  break;
                case "s":
                  _stoppedIMEIArray.add(_iMEIArray[index]);
                  break;
                case "i":
                  _idleIMEIArray.add(_iMEIArray[index]);
                  break;
                case "off":
                  _offlineIMEIArray.add(_iMEIArray[index]);
                  break;
                case "false":
                  _noDataIMEIArray.add(_iMEIArray[index]);
                  break;
              }
            }
          }
        } catch (e) {
          continue;
        }
      }

      _sortedIMEIArray.addAll(_expireIMEIArray);
      _sortedIMEIArray.addAll(_movingIMEIArray);
      _sortedIMEIArray.addAll(_idleIMEIArray);
      _sortedIMEIArray.addAll(_stoppedIMEIArray);
      _sortedIMEIArray.addAll(_offlineIMEIArray);
      _sortedIMEIArray.addAll(_noDataIMEIArray);

      for (int index = 0; index < _sortedIMEIArray.length; index++) {
        VehicleSettingsModel? vehicleSettingsStrings;
        ObjectDataModel? objectDataModel;

        try {
          vehicleSettingsStrings = VehicleSettingsModel.fromJson(jsonDecode(
              Globals.prefs!.getString('${_sortedIMEIArray[index]}_settings')!));
          objectDataModel = ObjectDataModel.fromJson(jsonDecode(
              Globals.prefs!.getString('${_sortedIMEIArray[index]}_objects')!));
        } catch (e) {}

        if (vehicleSettingsStrings != null) {
          String expiredText =
              formatter.format(DateTime.parse(vehicleSettingsStrings.objectExpireDate!));
          bool expired = vehicleSettingsStrings.active!;
          bool fuel = false;

          if (objectDataModel != null && objectDataModel.toString().isNotEmpty) {
            List<dynamic> dArray = objectDataModel.d ?? [];
            if (dArray.isNotEmpty) {
              List<dynamic> d0Array = dArray[0];
              try {
                for (int j = 0; j < vehicleSettingsStrings.sensors!.keys.length; j++) {
                  String sensorID = vehicleSettingsStrings.sensors!.keys.elementAt(j);
                  Sensors? s = vehicleSettingsStrings.sensors![sensorID];
                  if (s?.name == 'Fuel Level') fuel = true;
                }
              } catch (e) {}

              _homeItemList.add(HomeItem(
                  fuel,
                  d0Array[2],
                  d0Array[3],
                  objectDataModel.ststr,
                  objectDataModel.st.toString(),
                  d0Array[6],
                  vehicleSettingsStrings.name!,
                  d0Array[5],
                  _sortedIMEIArray[index],
                  expired,
                  expiredText,
                  vehicleSettingsStrings.icon!,
                  'images/${getMarkerName(objectDataModel.st.toString(), Globals.prefs!.getString('${_sortedIMEIArray[index]}_icons')!)}'));
            } else {
              _homeItemList.add(HomeItem(
                  fuel,
                  '20.5937',
                  '78.9629',
                  objectDataModel.ststr,
                  objectDataModel.st.toString(),
                  0,
                  vehicleSettingsStrings.name!,
                  '0',
                  _sortedIMEIArray[index],
                  expired,
                  expiredText,
                  vehicleSettingsStrings.icon!,
                  'images/${getMarkerName('off', Globals.prefs!.getString('${_sortedIMEIArray[index]}_icons')!)}'));
            }
          }
        }
      }
      return _homeItemList;
    }
    return [];
  }

  // ==========================================
  // ICON & DRAWABLE MAPPING UTILITIES
  // ==========================================

  String getDrawable(String sensorName) {
    switch (sensorName.toLowerCase()) {
      case 'ignition key':
        return 'images/ignitionKeyIcon.png';
      case 'air condition':
      case 'ac':
      case 'air conditioner':
      case 'air con':
        return 'images/acIcon.png';
      case 'battery level':
      case 'battery':
      case 'vehicle battery':
      case 'battery voltage':
      case 'battery voltage level':
      case 'internal battery level':
      case 'internal battery':
      case 'device battery':
      case 'device battery level':
      case 'ad1 voltage':
      case 'ad2 voltage':
      case 'vehicle battery level':
      case 'external battery level':
      case 'external battery':
      case 'external battery voltage':
      case 'external voltage':
      case 'internal battery voltage':
      case 'internal battery status':
        return 'images/batteryLevelIcon.png';
      case 'battery charging':
      case 'battery charging status':
      case 'battery charge':
      case 'charging status':
      case 'battery status':
        return 'images/batteryChargeIcon.png';
      case 'fuel level':
      case 'fuel':
      case 'oil level':
      case 'lpg level':
      case 'cng level':
      case 'lpg':
      case 'cng':
        return 'images/fuelIcon.png';
      case 'weight':
      case 'load sensor':
      case 'load':
      case 'weight level':
        return 'images/weightIcon.png';
      case 'humidity':
      case 'humidity level':
        return 'images/humidityIcon.png';
      case 'defense mode':
      case 'defense':
      case 'defence mode':
      case 'defence':
        return 'images/defense.png';
      case 'engine status':
      case 'engine':
      case 'ignition':
      case 'ignition status':
        return 'images/engineHelperIcon.png';
      case 'door status':
      case 'door sensor':
      case 'door':
        return 'images/doorIcon.png';
      case 'gps level':
      case 'gps signal':
      case 'gps':
        return 'images/gpsSignalIcon.png';
      case 'lights':
      case 'vehicle lights':
        return 'images/lightIcon.png';
      case 'camera attached':
      case 'camera':
        return 'images/cameraIcon.png';
      case 'gsm signal':
      case 'gsm level':
      case 'gsm':
        return 'images/gsmIcon.png';
      case 'moving status':
      case 'moving':
        return 'images/movingIcon.png';
      case 'temperature':
      case 'temperature sensor':
        return 'images/temperatureIcon.png';
      case 'generator status':
      case 'generator':
        return 'images/generatorIcon.png';
      case 'tyre pressure':
        return 'images/tyrePressureIcon.png';
      case 'electricity':
      case 'electricity status':
      case 'main line':
        return 'images/electricityIcon.png';
      default:
        return 'images/sensorIcon.png';
    }
  }

  // ==========================================
  // MAP CANVAS & MARKER GENERATORS
  // ==========================================

  Future<BitmapDescriptor> getMarkerIcon(BuildContext context, String imageName,
      Size size, String title, String angle, Color color) async {
    double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    double scaleFactor = 3.0;

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    Paint tagPaintBack = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.text = TextSpan(
      text: ' $title ',
      style: TextStyle(
        fontSize: 25.0 * devicePixelRatio * 0.4,
        color: color,
        fontFamily: 'Montserrat',
        fontWeight: ui.FontWeight.w600,
      ),
    );
    textPainter.layout();

    Rect rect2() => Rect.fromLTWH(0, 0, textPainter.width + 12 * scaleFactor,
        textPainter.height + 12 * scaleFactor);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect2(), Radius.circular(4 * scaleFactor)),
      tagPaintBack,
    );

    Rect rect() => Rect.fromLTWH(
        3 * scaleFactor,
        3 * scaleFactor,
        textPainter.width + 6 * scaleFactor,
        textPainter.height + 6 * scaleFactor);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect(), Radius.circular(1 * scaleFactor)),
      Paint()..color = Colors.white,
    );

    textPainter.paint(canvas, Offset(7 * scaleFactor, 7 * scaleFactor));

    double byFourOffset = (textPainter.width.round() + 20 * scaleFactor) / 2 -
        (size.width * scaleFactor / 2);

    Rect oval = Rect.fromLTWH(
      byFourOffset,
      textPainter.height + 18 * scaleFactor,
      size.width * scaleFactor,
      size.height * scaleFactor,
    );

    canvas.clipPath(Path()..addOval(oval));

    ui.Image image =
        await getUiImage(imageName, double.parse(angle) * math.pi / 180);

    paintImage(
      canvas: canvas,
      image: image,
      rect: oval,
      fit: BoxFit.cover,
    );

    final ui.Image markerAsImage = await pictureRecorder.endRecording().toImage(
          (textPainter.width.round() + 20 * scaleFactor).toInt(),
          (textPainter.height.round() + 32 * scaleFactor + 40 * scaleFactor).toInt(),
        );

    final ByteData? byteData =
        await markerAsImage.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }

  Future<BitmapDescriptor> getMarkerIconPlayBack(String imageName, Size size,
      String title, String angle, Color color) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    double scaleFactor = 3.0;

    Paint tagPaintBack = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.text = TextSpan(
      text: ' $title ',
      style: TextStyle(
        fontSize: 12.0 * scaleFactor,
        color: color,
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();

    Rect rect2() => Rect.fromLTWH(0, 0, textPainter.width + 20 * scaleFactor,
        textPainter.height + 22 * scaleFactor);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect2(), Radius.circular(5 * scaleFactor)),
      tagPaintBack,
    );

    Rect rect() => Rect.fromLTWH(
        4 * scaleFactor,
        4 * scaleFactor,
        textPainter.width + 10 * scaleFactor,
        textPainter.height + 12 * scaleFactor);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect(), Radius.circular(5 * scaleFactor)),
      Paint()..color = Colors.white,
    );

    textPainter.paint(canvas, Offset(12 * scaleFactor, 12 * scaleFactor));

    double byFourOffset = (textPainter.width.round() + 20 * scaleFactor) / 2 -
        (size.width * scaleFactor / 2);

    Rect oval = Rect.fromLTWH(
      byFourOffset,
      textPainter.height + 32 * scaleFactor,
      size.width * scaleFactor,
      size.height * scaleFactor,
    );

    canvas.clipPath(Path()..addOval(oval));

    ui.Image image =
        await getUiImage(imageName, double.parse(angle) * math.pi / 180);

    paintImage(
      canvas: canvas,
      image: image,
      rect: oval,
      fit: BoxFit.cover,
    );

    final ui.Image markerAsImage = await pictureRecorder.endRecording().toImage(
          (textPainter.width.round() + 20 * scaleFactor).toInt(),
          (textPainter.height.round() + 32 * scaleFactor + 40 * scaleFactor).toInt(),
        );

    final ByteData? byteData =
        await markerAsImage.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }

  Future<Uint8List> getMarkerIconTracking(String imageName, Size size,
      String title, String angle, Color color) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    double scaleFactor = 3.0;

    Paint tagPaintBack = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.text = TextSpan(
      text: ' $title ',
      style: TextStyle(
        fontSize: 30.0 * scaleFactor,
        color: color,
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();

    Rect rect2() => Rect.fromLTWH(0, 0, textPainter.width + 20 * scaleFactor,
        textPainter.height + 22 * scaleFactor);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect2(), Radius.circular(5 * scaleFactor)),
      tagPaintBack,
    );

    Rect rect() => Rect.fromLTWH(
        4 * scaleFactor,
        4 * scaleFactor,
        textPainter.width + 10 * scaleFactor,
        textPainter.height + 12 * scaleFactor);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect(), Radius.circular(5 * scaleFactor)),
      Paint()..color = Colors.white,
    );

    textPainter.paint(canvas, Offset(12 * scaleFactor, 12 * scaleFactor));

    double byFourOffset = (textPainter.width.round() + 20 * scaleFactor) / 2 -
        (size.width * scaleFactor / 2);

    Rect oval = Rect.fromLTWH(
      byFourOffset,
      textPainter.height + 32 * scaleFactor,
      size.width * scaleFactor,
      size.height * scaleFactor,
    );

    canvas.clipPath(Path()..addOval(oval));

    ui.Image image =
        await getUiImage(imageName, double.parse(angle) * math.pi / 180);

    paintImage(
      canvas: canvas,
      image: image,
      rect: oval,
      fit: BoxFit.cover,
    );

    final ui.Image markerAsImage = await pictureRecorder.endRecording().toImage(
          (textPainter.width.round() + 20 * scaleFactor).toInt(),
          (textPainter.height.round() + 32 * scaleFactor + 40 * scaleFactor).toInt(),
        );

    final ByteData? byteData =
        await markerAsImage.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<ui.Image> getUiImage(String imageName, double rotation) async {
    final ByteData data = await rootBundle.load(imageName);
    final Uint8List bytes = data.buffer.asUint8List();
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(bytes, (ui.Image img) {
      completer.complete(img);
    });
    final ui.Image originalImage = await completer.future;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final Size size =
        Size(originalImage.width.toDouble(), originalImage.height.toDouble());
    final Paint paint = Paint()..isAntiAlias = true;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(rotation);
    canvas.translate(-size.width / 2, -size.height / 2);
    canvas.drawImage(originalImage, Offset.zero, paint);
    canvas.restore();

    final picture = recorder.endRecording();
    return await picture.toImage(size.width.toInt(), size.height.toInt());
  }

  Future<Uint8List> getMarkerTracking(String status, String deviceName,
      String angle, int speed, String image) async {
    switch (status ?? 'false') {
      case 'm':
        return await Helper().getMarkerIconTracking(image, Size(40.0, 40.0),
            '$deviceName (${speed.toString()}km/h)', angle, Colors.green);
      case 's':
        return await Helper().getMarkerIconTracking(
            image, Size(40.0, 40.0), deviceName, angle, Colors.red);
      case 'i':
        return await Helper().getMarkerIconTracking(
            image, Size(40.0, 40.0), deviceName, angle, Color(0xFFF7BA44));
      case 'off':
        return await Helper().getMarkerIconTracking(
            image, Size(40.0, 40.0), deviceName, angle, Colors.grey);
      default:
        return await Helper().getMarkerIconTracking(
            image, Size(40.0, 40.0), deviceName, angle, Colors.transparent);
    }
  }

  Future<BitmapDescriptor> getMarker(BuildContext context, String status,
      String deviceName, String angle, int speed, String image) async {
    switch (status ?? 'false') {
      case 'm':
        return await Helper().getMarkerIcon(
            context,
            image,
            Size(40.0, 40.0),
            speed != 0 ? '$deviceName (${speed.toString()}km/h)' : deviceName,
            angle,
            Colors.green);
      case 's':
        return await Helper().getMarkerIcon(
            context, image, Size(40.0, 40.0), deviceName, angle, Colors.red);
      case 'i':
        return await Helper().getMarkerIcon(context, image, Size(40.0, 40.0),
            deviceName, angle, Color(0xFFF7BA44));
      case 'off':
        return await Helper().getMarkerIcon(
            context, image, Size(40.0, 40.0), deviceName, angle, Colors.red);
      default:
        return await Helper().getMarkerIcon(context, image, Size(40.0, 40.0),
            deviceName, angle, Colors.transparent);
    }
  }

  Future<BitmapDescriptor> getMarkerPlayback(String status, String deviceName,
      String angle, int speed, String image) async {
    switch (status ?? 'false') {
      case 'm':
        return await Helper().getMarkerIconPlayBack(
            image,
            Size(40.0, 40.0),
            speed != 0 ? '$deviceName (${speed.toString()}km/h)' : deviceName,
            angle,
            Colors.green);
      case 's':
        return await Helper().getMarkerIconPlayBack(
            image, Size(40.0, 40.0), deviceName, angle, Colors.red);
      case 'i':
        return await Helper().getMarkerIconPlayBack(
            image, Size(40.0, 40.0), deviceName, angle, Color(0xFFF7BA44));
      case 'off':
        return await Helper().getMarkerIconPlayBack(
            image, Size(40.0, 40.0), deviceName, angle, Colors.red);
      default:
        return await Helper().getMarkerIconPlayBack(
            image, Size(40.0, 40.0), deviceName, angle, Colors.transparent);
    }
  }

  Future<BitmapDescriptor> getMarkerIconWithInfo(
      String imagePath,
      String infoText,
      TextSpan rightInfoText,
      Color color,
      double rotateDegree) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    Size markerSize = Size(
        15 * SizeConfig.heightMultiplier!, 15 * SizeConfig.heightMultiplier!);

    TextPainter infoTextPainter = TextPainter(
        textDirection: TextDirection.ltr, textAlign: TextAlign.center);
    infoTextPainter.text = TextSpan(
      text: infoText,
      style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 3.2 * SizeConfig.heightMultiplier!,
          fontWeight: FontWeight.w600,
          color: color),
    );
    infoTextPainter.layout();

    final double infoHeight = 5 * SizeConfig.heightMultiplier!;
    final double infoTextWidth =
        (infoText.length * 2 * SizeConfig.heightMultiplier!) >
                19 * SizeConfig.heightMultiplier!
            ? (infoText.length * 2 * SizeConfig.heightMultiplier!) + 3
            : 19 * SizeConfig.heightMultiplier!;
    final double rightInfoWidth = 0;
    final double infoBorder = 1.3 * SizeConfig.heightMultiplier!;
    final gapBetweenInfoAndMarker = 5 * SizeConfig.heightMultiplier!;

    Size canvasSize = Size(infoTextWidth + rightInfoWidth + infoBorder + 5,
        infoHeight + markerSize.height + gapBetweenInfoAndMarker - 20);
    final Paint infoPaint = Paint()..color = Colors.white;
    final Paint infoShadowPaint = Paint()
      ..color = Colors.black.withOpacity(.5)
      ..maskFilter =
          MaskFilter.blur(BlurStyle.normal, gapBetweenInfoAndMarker / 4);
    final double shadowWidth = 2.5 * SizeConfig.heightMultiplier!;

    canvas.translate(canvasSize.width / 2,
        canvasSize.height / 2 + infoHeight / 2 + gapBetweenInfoAndMarker / 2);

    Rect rectMiddle = Rect.fromLTWH(
        -markerSize.width / 2 + .5 * shadowWidth,
        -markerSize.height / 2 + .5 * shadowWidth,
        markerSize.width - shadowWidth,
        markerSize.height - shadowWidth);

    canvas.save();
    double rotateRadian = (pi / 180.0) * rotateDegree;
    canvas.rotate(rotateRadian);

    ui.Image image = await getImageFromPath(imagePath);
    paintImage(
        canvas: canvas, image: image, rect: rectMiddle, fit: BoxFit.fitHeight);
    canvas.restore();

    canvas.drawRRect(
        RRect.fromLTRBR(
            -infoTextWidth / 2 - rightInfoWidth / 2 - infoBorder / 2,
            -canvasSize.height / 2 - infoHeight / 2 / 4 + 1,
            infoTextWidth / 2 + rightInfoWidth / 2 + infoBorder / 2,
            -canvasSize.height / 2 + infoHeight / 2 + 1,
            Radius.circular(1.875 * SizeConfig.heightMultiplier!)),
        infoShadowPaint);

    canvas.drawRRect(
        RRect.fromLTRBR(
            -infoTextWidth / 2 - rightInfoWidth / 2 - infoBorder,
            -canvasSize.height / 2 -
                infoHeight / 2 -
                gapBetweenInfoAndMarker / 2 +
                1,
            infoTextWidth / 2 + rightInfoWidth / 2 + infoBorder,
            -canvasSize.height / 2 + infoHeight / 2 + 1,
            Radius.circular(1.875 * SizeConfig.heightMultiplier!)),
        infoPaint);
    infoTextPainter.paint(
        canvas,
        Offset(
            -infoTextPainter.width / 2 - rightInfoWidth / 2,
            -canvasSize.height / 2 -
                gapBetweenInfoAndMarker / 2 -
                infoHeight / 2 +
                infoBorder));
    canvas.restore();

    final ui.Image markerAsImage = await pictureRecorder
        .endRecording()
        .toImage(canvasSize.width.toInt(), canvasSize.height.toInt());
    final ByteData? byteData =
        await markerAsImage.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  Future<ui.Image> getImageFromPath(String imagePath) async {
    var bd = await rootBundle.load(imagePath);
    Uint8List imageBytes = Uint8List.view(bd.buffer);
    final Completer<ui.Image> completer = new Completer();
    ui.decodeImageFromList(imageBytes, (ui.Image img) {
      return completer.complete(img);
    });
    return completer.future;
  }

  String? getDataItem(String s) {
    Map<String, String> stringMap = {
      'general':
          'route_start,route_end,route_length,move_duration,stop_duration,stop_count,top_speed,avg_speed,overspeed_count,fuel_consumption,fuel_cost,engine_work,engine_idle,odometer,engine_hours,driver,trailer',
      'object_info':
          'imei,transport_model,vin,plate_number,odometer,engine_hours,driver,trailer,gps_device,sim_card_number',
      'current_position':
          'time,position,speed,altitude,angle,status,odometer,engine_hours',
      'events': 'time,event,event_position,total',
    };
    return stringMap[s];
  }

  Color getTextColor(String status) {
    switch (status ?? 'false') {
      case 'm':
        return Colors.green;
      case 's':
        return Colors.red;
      case 'i':
        return Color(0xFFF7BA44);
      case 'off':
        return Colors.red;
      default:
        return Colors.transparent;
    }
  }

  String getMarkerName(String status, String choseIcon) {
    String marker = '';
    switch (status) {
      case "m":
        marker = '${choseIcon}grn.png';
        break;
      case "s":
        marker = '${choseIcon}red.png';
        break;
      case "i":
        marker = '${choseIcon}or.png';
        break;
      case "off":
        marker = '${choseIcon}red.png';
        break;
      default:
        marker = '${choseIcon}red.png';
        break;
    }
    return marker;
  }

  String charAt(String subject, int position) {
    if (subject is! String ||
        subject.length <= position ||
        subject.length + position < 0) {
      return '';
    }
    int _realPosition = position < 0 ? subject.length + position : position;
    return subject[_realPosition];
  }
}
