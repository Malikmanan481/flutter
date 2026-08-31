import 'dart:convert';
import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:speedotrack/activity/activity_lock.dart';
import 'package:speedotrack/activity/activity_report.dart';
import 'package:speedotrack/activity/activity_sensor_summary.dart';
import 'package:speedotrack/activity/activity_summary.dart';
import 'package:speedotrack/activity/activity_tracking.dart';
import 'package:speedotrack/activity/activity_tripinfo.dart';
import 'package:speedotrack/activity/activity_vehicle.dart';

// ==========================================
// TRACCAR API BACKEND SERVICE FOR BOTTOM SHEET
// ==========================================
class TraccarBottomSheetService {
  /// Send Engine Lock / Unlock Command via Traccar REST API `/api/commands/send`
  static Future<bool> sendEngineCommand({
    required String baseUrl,
    required String sessionCookie,
    required int deviceId,
    required bool lockEngine,
  }) async {
    try {
      final cleanUrl = baseUrl.endsWith('/')
          ? baseUrl.substring(0, baseUrl.length - 1)
          : baseUrl;
      final uri = Uri.parse('$cleanUrl/api/commands/send');

      final body = jsonEncode({
        'deviceId': deviceId,
        'type': lockEngine ? 'engineStop' : 'engineResume',
      });

      final response = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Cookie': sessionCookie,
        },
        body: body,
      );

      return response.statusCode == 200 || response.statusCode == 202;
    } catch (_) {
      return false;
    }
  }

  /// Fetch Live Device Data via Traccar API `/api/devices/{id}`
  static Future<Map<String, dynamic>?> fetchTraccarDevice({
    required String baseUrl,
    required String sessionCookie,
    required int deviceId,
  }) async {
    try {
      final cleanUrl = baseUrl.endsWith('/')
          ? baseUrl.substring(0, baseUrl.length - 1)
          : baseUrl;
      final uri = Uri.parse('$cleanUrl/api/devices/$deviceId');

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Cookie': sessionCookie,
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }
}

class BottomSheetComponent {
  MaterialPageRoute sensorDuration(String deviceName, String imei, {int? deviceId}) {
    return MaterialPageRoute(
        builder: (context) => SensorSummaryActivity(
            name: deviceName, imei: imei, from: 'engine_hours'));
  }

  MaterialPageRoute vehicleInfo(String deviceName, String iMEI, {int? deviceId}) {
    return MaterialPageRoute(
        builder: (context) => VehicleActivity(name: deviceName, imei: iMEI));
  }

  void modalBottomSheetMenu(
      {BuildContext? context,
      String? deviceName,
      String? lat,
      String? lng,
      int? speed,
      String? angle,
      String? iMEI,
      String? status,
      String? statusMessage,
      int? deviceId}) {
    showModalBottomSheet(
        context: context!,
        elevation: 5,
        builder: (builder) {
          return Container(
            height: 225.0,
            color: Color(0xFF737373),
            //so you don't have to change MaterialApp canvasColor
            child: new Container(
                decoration: new BoxDecoration(
                    color: Colors.white,
                    borderRadius: new BorderRadius.only(
                        topLeft: const Radius.circular(10.0),
                        topRight: const Radius.circular(10.0))),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    children: <Widget>[
                      Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                            color: Color(0xFF7E8188),
                            borderRadius: BorderRadius.all(Radius.circular(5))),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Container(
                        width: double.infinity,
                        alignment: Alignment.topLeft,
                        child: AutoSizeText(
                          '${deviceName!.toUpperCase()}',
                          minFontSize: 10,
                          maxLines: 1,
                          textAlign: TextAlign.start,
                          style: TextStyle(
                              color: Color(0xFF7E8188),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Montserrat'),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Container(
                        width: double.infinity,
                        child: Row(
                          children: <Widget>[
                            BottomItemWidget(
                                onClickMethod: MaterialPageRoute(
                                    builder: (context) => TrackingActivity(
                                        lat: lat!,
                                        lng: lng!,
                                        speed: speed!,
                                        angle: angle!,
                                        name: deviceName,
                                        imei: iMEI!,
                                        status: status!,
                                        statusMessage: statusMessage!)),
                                image: 'images/tracking.png',
                                name: 'Live Tracking'),
                            BottomItemWidget(
                                onClickMethod: vehicleInfo(deviceName, iMEI!, deviceId: deviceId),
                                image: 'images/vehicle.png',
                                name: 'Vehicle Info'),
                            BottomItemWidget(
                                onClickMethod: MaterialPageRoute(
                                    builder: (context) => TripInfoActivity(
                                          name: deviceName,
                                          imei: iMEI,
                                        )),
                                image: 'images/tripinfo.png',
                                name: 'Trip Info'),
                            BottomItemWidget(
                              onClickMethod: MaterialPageRoute(
                                  builder: (context) => LockActivity(
                                      imei: iMEI, name: deviceName)),
                              image: 'images/lock.png',
                              name: 'Lock',
                            )
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Container(
                        width: double.infinity,
                        child: Row(
                          children: <Widget>[
                            BottomItemWidget(
                                onClickMethod: MaterialPageRoute(
                                    builder: (context) => SummaryActivity(
                                        name: deviceName,
                                        imei: iMEI,
                                        from: 'km_summary')),
                                name: 'Km Summary',
                                image: 'images/odometerIcon.png'),
                            BottomItemWidget(
                                onClickMethod: MaterialPageRoute(
                                    builder: (context) => SummaryActivity(
                                        name: deviceName,
                                        imei: iMEI,
                                        from: 'engine_hours')),
                                image: 'images/enginehour.png',
                                name: 'Engine Hours'),
                            BottomItemWidget(
                                onClickMethod: sensorDuration(deviceName, iMEI, deviceId: deviceId),
                                image: 'images/sensor.png',
                                name: 'Sensor Duration'),
                            BottomItemWidget(
                                onClickMethod: MaterialPageRoute(
                                    builder: (context) => ReportActivity(
                                        name: deviceName, imei: iMEI)),
                                image: 'images/report.png',
                                name: 'Report'),
                          ],
                        ),
                      )
                    ],
                  ),
                )),
          );
        });
  }
}

class BottomItemWidget extends StatelessWidget {
  final Route? onClickMethod;
  final String? name;
  final String? image;

  const BottomItemWidget({Key? key, this.onClickMethod, this.name, this.image})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: () {
          try {
            Navigator.of(context)
              ..pop()
              ..push(onClickMethod!);
          } catch (e) {}
        },
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Image.asset(
                image!,
                height: 30,
                width: 30,
              ),
            ),
            AutoSizeText(
              name!,
              minFontSize: 10,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Color(0xFF7E8188),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat'),
            ),
          ],
        ),
      ),
      flex: 1,
    );
  }
}
