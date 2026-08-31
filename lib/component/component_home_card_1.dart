import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:simple_animations/simple_animations.dart';
import 'package:speedotrack/activity/activity_dashboard.dart';
import 'package:speedotrack/activity/activity_fuelreport.dart';
import 'package:speedotrack/activity/activity_playback.dart';
import 'package:speedotrack/activity/activity_tracking.dart';
import 'package:speedotrack/activity/activity_webview.dart';
import 'package:speedotrack/bloc/bloc_home_item.dart';
import 'package:speedotrack/component/component_bottom_sheet.dart';
import 'package:speedotrack/globals.dart';
import 'package:speedotrack/helper/helper.dart';
import 'package:speedotrack/helper/static.dart';
import 'package:supercharged/supercharged.dart';

enum ColorCard { color }

class HomeCard extends StatelessWidget {
  final int? index;
  final BuildContext? context;
  final HomeItem? homeItemList;

  HomeCard({this.index, this.context, this.homeItemList});

  @override
  Widget build(BuildContext context) {
    bool mapType = true; //Globals.prefs.getBool('mapHybrid');
    Color color1 = mapType ? Colors.white : Colors.black;
    Color color2 = mapType ? Colors.white : Colors.green;

    String Status = "Moving";

    switch (homeItemList!.status) {
      case "m":
        Status = "Moving";
        break;
      case "s":
        Status = "Stopped";
        break;
      case "i":
        Status = "Idle";
        break;
      case "off":
        Status = "Offline";
        break;
      case "false":
        Status = "No Data";
        break;
    }

    return Container(
      margin: EdgeInsets.fromLTRB(3, 0, 3, 0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 2,
        color: Colors.red,
        child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(10.0)),
            ),
            margin: EdgeInsets.only(left: 7, right: 7),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: InkWell(
                    onTap: () {
                      BottomSheetComponent().modalBottomSheetMenu(
                          context: context,
                          lat: homeItemList!.lat,
                          lng: homeItemList!.lng,
                          speed: homeItemList!.speed,
                          angle: homeItemList!.angle,
                          deviceName: homeItemList!.name,
                          iMEI: homeItemList!.imei,
                          status: homeItemList!.status,
                          statusMessage: homeItemList!.statusMessage);
                    },
                    child: Column(
                      children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  AutoSizeText(
                                    '${homeItemList!.name}',
                                    minFontSize: 10,
                                    maxLines: 1,
                                    textAlign: TextAlign.start,
                                    style: TextStyle(
                                        color: color1,
                                        fontSize: 16,
                                        letterSpacing: 1,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Baloo_Thambi_2'),
                                  ),
                                ],
                              ),
                              AutoSizeText(
                                homeItemList!.expiredText.contains('0001')
                                    ? ''
                                    : (homeItemList!.expired
                                        ? 'Expired on ${homeItemList!.expiredText}'
                                        : 'Expires on ${homeItemList!.expiredText}'),
                                minFontSize: 10,
                                maxLines: 1,
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  color: mapType
                                      ? Colors.white
                                      : (homeItemList!.expired
                                          ? Colors.red
                                          : Colors.green),
                                  fontSize: 12,
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ]),
                        SizedBox(
                          height: 15,
                        ),
                        Container(
                            child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                                margin: EdgeInsets.only(top: 0),
                                padding: EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Color(0xffF5F5F5),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(2)),
                                ),
                                child: Image.asset("assets/car.png",
                                    height: 50, width: 80)),
                            SizedBox(
                              width: 40,
                            ),
                            Column(
                              children: [
                                Container(
                                  margin: EdgeInsets.only(top: 10),
                                  height: 15,
                                  width: 120,
                                  child: AutoSizeText(
                                    '${homeItemList!.statusMessage}',
                                    minFontSize: 10,
                                    maxLines: 1,
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      color: mapType
                                          ? Colors.white
                                          : Helper().getTextColor(
                                              homeItemList!.status),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  height: 15,
                                  width: 120,
                                  margin: EdgeInsets.only(top: 2),
                                  child: Text(
                                    Status,
                                    maxLines: 1,
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              margin: EdgeInsets.only(right: 10, left: 10),
                              padding: EdgeInsets.all(2),
                              height: 60,
                              width: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius:
                                    BorderRadius.all(Radius.circular(5)),
                              ),
                            ),
                            Container(
                                height: 60,
                                width: 90,
                                margin: EdgeInsets.only(top: 0),
                                padding: EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Color(0xffF5F5F5),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(2)),
                                ),
                                child: Stack(
                                  children: [
                                    Image.asset("assets/speedometer.png",
                                        height: 50, width: 80),
                                    Container(
                                      margin: EdgeInsets.fromLTRB(0, 40, 5, 0),
                                      alignment: Alignment.center,
                                      child: AutoSizeText(
                                        '${homeItemList!.speed}km/h',
                                        minFontSize: 10,
                                        maxLines: 1,
                                        textAlign: TextAlign.end,
                                        style: TextStyle(
                                          color: color2,
                                          fontSize: 12,
                                          letterSpacing: 1,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  ],
                                )),
                          ],
                        )),
                        SizedBox(
                          height: 15,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Image.asset("assets/power.png",
                                height: 20, width: 20),
                            Container(
                              margin: EdgeInsets.only(left: 0, right: 0),
                              height: 20,
                              width: 28,
                              child: Text(
                                "Ignition",
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Image.asset("assets/battery.png",
                                height: 20, width: 20),
                            Container(
                              margin: EdgeInsets.only(left: 5, right: 5),
                              height: 20,
                              width: 20,
                              child: Text(
                                "BTR 100%",
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Image.asset("assets/electricbatery.png",
                                height: 20, width: 20),
                            Container(
                              margin: EdgeInsets.only(left: 5, right: 5),
                              height: 20,
                              width: 20,
                              child: Text(
                                "BTR CRG",
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Image.asset("assets/sensor.png",
                                height: 20, width: 20),
                            Container(
                              margin: EdgeInsets.only(left: 5, right: 5),
                              height: 20,
                              width: 45,
                              child: Text(
                                "Battery Volt 9.96",
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Image.asset("assets/sattelite.png",
                                height: 20, width: 20),
                            Container(
                              margin: EdgeInsets.only(left: 5, right: 5),
                              height: 20,
                              width: 20,
                              child: Text(
                                "GPS 1.5",
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Image.asset("assets/antenna.png",
                                height: 20, width: 20),
                            Container(
                              margin: EdgeInsets.only(left: 5, right: 5),
                              height: 20,
                              width: 20,
                              child: Text(
                                "GSM 1.2",
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 10,
                        ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: InkWell(
                    onTap: () {
                      BottomSheetComponent().modalBottomSheetMenu(
                          context: context,
                          lat: homeItemList!.lat,
                          lng: homeItemList!.lng,
                          speed: homeItemList!.speed,
                          angle: homeItemList!.angle,
                          deviceName: homeItemList!.name,
                          iMEI: homeItemList!.imei,
                          status: homeItemList!.status,
                          statusMessage: homeItemList!.statusMessage);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          padding:
                              EdgeInsets.only(bottom: 0, right: 10, left: 10),
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(5),
                                bottomRight: Radius.circular(5)),
                          ),
                          width: double.infinity,
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            mainAxisSize: MainAxisSize.max,
                            children: <Widget>[
                              CardButton(
                                  flexSize: 4,
                                  onClickMethod: MaterialPageRoute(
                                      builder: (context) => TrackingActivity(
                                          lat: homeItemList!.lat,
                                          lng: homeItemList!.lng,
                                          speed: homeItemList!.speed,
                                          angle: homeItemList!.angle,
                                          name: homeItemList!.name,
                                          imei: homeItemList!.imei,
                                          status: homeItemList!.status,
                                          statusMessage:
                                              homeItemList!.statusMessage)),
                                  name: 'Live Tracking',
                                  icon: Icons.pin_drop),
                              CardButton(
                                  flexSize: 3,
                                  onClickMethod: MaterialPageRoute(
                                      builder: (context) => PlaybackActivity(
                                          name: homeItemList!.name,
                                          imei: homeItemList!.imei,
                                          lat: homeItemList!.lat,
                                          lng: homeItemList!.lng,
                                          status: homeItemList!.status,
                                          speed: homeItemList!.speed,
                                          angle: homeItemList!.angle)),
                                  name: 'Playback',
                                  icon: Icons.play_circle_filled),
                              CardButton(
                                  flexSize: 4,
                                  onClickMethod: MaterialPageRoute(
                                      builder: (context) => DashboardActivity(
                                            name: homeItemList!.name,
                                            imei: homeItemList!.imei,
                                          )),
                                  icon: Icons.dashboard,
                                  name: 'Dashboard'),
                              homeItemList!.fuel
                                  ? CardButton(
                                      flexSize: 4,
                                      onClickMethod: MaterialPageRoute(
                                          builder: (context) =>
                                              FuelReportActivity(
                                                  name: homeItemList!.name,
                                                  imei: homeItemList!.imei)),
                                      name: 'Fuel Reports',
                                      icon: Icons.local_gas_station)
                                  : SizedBox(
                                      width: 0,
                                    ),
                              Flexible(
                                flex: 1,
                                child: InkWell(
                                  onTap: () {
                                    BottomSheetComponent().modalBottomSheetMenu(
                                        context: context,
                                        lat: homeItemList!.lat,
                                        lng: homeItemList!.lng,
                                        speed: homeItemList!.speed,
                                        angle: homeItemList!.angle,
                                        deviceName: homeItemList!.name,
                                        iMEI: homeItemList!.imei,
                                        status: homeItemList!.status,
                                        statusMessage:
                                            homeItemList!.statusMessage);
                                  },
                                  child: Container(
                                      child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.max,
                                    children: <Widget>[
                                      Icon(
                                        Icons.menu,
                                        size: 20,
                                        color: Color(0xFF7E8188),
                                      ),
                                    ],
                                  )),
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                Divider(
                  thickness: 2,
                  color: Colors.grey[500],
                ),
              ],
            )),
      ),
    );
  }
}

class CardButton extends StatelessWidget {
  final Route? onClickMethod;
  final String? name;
  final IconData? icon;
  final int? flexSize;

  const CardButton(
      {Key? key,
      @required this.onClickMethod,
      @required this.name,
      @required this.icon,
      @required this.flexSize})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: flexSize!,
      child: InkWell(
        onTap: () => Navigator.push(context, onClickMethod!),
        child: Container(
          height: 50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Expanded(
                child: Icon(
                  icon,
                  size: 20,
                  color: Color(0xFF7E8188),
                ),
                flex: 1,
              ),
              Expanded(
                child: AutoSizeText(
                  name!,
                  minFontSize: 6,
                  maxLines: 2,
                  softWrap: true,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF7E8188),
                    fontSize: 12,
                  ),
                ),
                flex: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================================================
// TRACCAR REST API BACKEND SERVICE CONNECTOR
// ======================================================

class TraccarHomeCardBackend {
  /// Traccar `/api/devices` aur `/api/positions` endpoints se direct data fetch karna
  static Future<HomeItem?> fetchTraccarHomeItem({
    required String baseUrl,
    required String cookieHeader,
    required int deviceId,
  }) async {
    final cleanUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

    try {
      final headers = {
        'Accept': 'application/json',
        'Cookie': cookieHeader,
      };

      // 1. Fetch Device details (`/api/devices/{id}`)
      final deviceResponse = await http.get(
        Uri.parse('$cleanUrl/api/devices/$deviceId'),
        headers: headers,
      );

      // 2. Fetch Position details (`/api/positions?deviceId={id}`)
      final positionResponse = await http.get(
        Uri.parse('$cleanUrl/api/positions?deviceId=$deviceId'),
        headers: headers,
      );

      if (deviceResponse.statusCode == 200 && positionResponse.statusCode == 200) {
        final Map<String, dynamic> deviceData = jsonDecode(deviceResponse.body);
        final List<dynamic> positionList = jsonDecode(positionResponse.body);

        if (positionList.isNotEmpty) {
          final Map<String, dynamic> pos = positionList.first;
          final Map<String, dynamic> attributes = pos['attributes'] ?? {};

          // Convert Traccar speed (knots to km/h)
          final double speedKmH = ((pos['speed'] ?? 0.0) * 1.852);

          // Map Traccar device status to app status code ('m', 's', 'i', 'off')
          String status = 'off';
          if (deviceData['status'] == 'online') {
            if (speedKmH > 0) {
              status = 'm'; // Moving
            } else if (attributes['ignition'] == true) {
              status = 'i'; // Idle
            } else {
              status = 's'; // Stopped
            }
          } else {
            status = 'off'; // Offline
          }

          // Return formatted HomeItem object for UI consumption
          return HomeItem(
            name: deviceData['name'] ?? '',
            imei: deviceData['uniqueId'] ?? '',
            lat: pos['latitude'].toString(),
            lng: pos['longitude'].toString(),
            speed: speedKmH.round(),
            angle: pos['course'].toString(),
            status: status,
            statusMessage: deviceData['status'] ?? 'offline',
            expired: deviceData['disabled'] ?? false,
            expiredText: deviceData['expirationTime'] ?? '',
            fuel: attributes.containsKey('fuel'),
          );
        }
      }
    } catch (_) {}
    return null;
  }
}
