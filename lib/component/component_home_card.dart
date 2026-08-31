import 'dart:convert';
import 'dart:math' as math;
import 'dart:math';
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
import 'package:speedotrack/lib_map/map.dart' as map;
import 'package:speedotrack/helper/static.dart';
import 'package:speedotrack/lib_map/src/provider.dart';
import 'package:speedotrack/model/model_object_fn.dart';
import 'package:speedotrack/model/model_sensor_home.dart';
import 'package:speedotrack/model/model_settings_fn.dart';
import '../lib_latlng/src/latlng.dart';
import 'package:intl/intl.dart' as intl;

enum ColorCard { color }

class HomeCardWidget extends StatelessWidget {
  final int? index;
  final BuildContext? context;
  final HomeItem? homeItemList;

  HomeCardWidget({this.index, this.context, this.homeItemList});

  String ignition = '';
  String serverTime = '';
  String deviceTime = '';
  String? gpsCn;

  List<SensorModelHome> sensorModelAboveLocal = [
    SensorModelHome('images/ignitionIcon.png', 'Fetching', Colors.grey),
    SensorModelHome('images/gpsIcon.png', 'Fetching', Colors.grey),
    SensorModelHome('images/speedIcon.png', 'Fetching', Globals.appColor),
    SensorModelHome('images/odometerIcon.png', 'Fetching', Globals.appColor),
    SensorModelHome('images/engineHourIcon.png', 'Fetching', Globals.appColor)
  ];
  List<SensorModelHome> sensorModelBelowLocal = [];

  List<SensorModelHome> sensorModelBelowLocalAll = [];
  String engineHoursString = '';

  @override
  Widget build(BuildContext context) {
    VehicleSettingsModel vehicleSettingsModel = VehicleSettingsModel.fromJson(
        jsonDecode(
            Globals.prefs!.getString('${homeItemList!.imei}_settings')!));
    ObjectDataModel? objectDataModel = ObjectDataModel.fromJson(
        jsonDecode(Globals.prefs!.getString('${homeItemList!.imei}_objects')!));

    try {
      Map<String, Sensors>? sensorsJsonObject = {};
      try {
        sensorsJsonObject = vehicleSettingsModel.sensors!;
      } catch (e) {}

      List<String> sensorsKeysJsonArray = [];
      if (sensorsJsonObject != null) {
        sensorsKeysJsonArray = sensorsJsonObject.keys.toList();
      }
      List<dynamic> d0Array = objectDataModel.d![0];
      sensorModelAboveLocal[3] = SensorModelHome(
          'images/speedIcon.png', 'Speed:\n${d0Array[6]}km', Globals.appColor);

      engineHoursString = objectDataModel.eh;
      sensorModelAboveLocal[4] = SensorModelHome('images/engineHourIcon.png',
          'Engine hour:\n${engineHoursString}h', Globals.appColor);
      gpsCn = objectDataModel.cn.toString();
      serverTime = d0Array[0];
      deviceTime = d0Array[1];
      for (int j = 0; j < sensorsKeysJsonArray.length; j++) {
        String sensorID = sensorsKeysJsonArray[j];
        Sensors sensorJsonObject = sensorsJsonObject![sensorID]!;
        String sensorName = sensorJsonObject.name!;
        String sensorType = sensorJsonObject.resultType!;
        String sensorFinalValue = "";
        if (sensorName.toUpperCase() == 'IGNITION' ||
            sensorName.toUpperCase() == 'ENGINE') {
          switch (sensorType) {
            case "percentage":
              {
                sensorFinalValue = Helper()
                    .getSensorValueForResultTypePercentage(
                        sensorJsonObject, d0Array);
              }
              break;
            case "value":
              {
                sensorFinalValue = Helper().getSensorValueForResultTypeValue(
                    sensorJsonObject, d0Array);
              }
              break;
            case "logic":
              {
                sensorFinalValue = Helper().getSensorValueForResultTypeLogic(
                    sensorJsonObject, d0Array);
              }
              break;
          }
          if (sensorFinalValue.contains(' ')) {
            ignition = sensorFinalValue.replaceAll(' ', '');
          } else {
            ignition = sensorFinalValue;
          }
          sensorModelAboveLocal[0] = SensorModelHome(
              'images/ignitionIcon.png',
              ignition.toLowerCase() == 'on'
                  ? 'Ignition:\nOn'
                  : 'Ignition:\nOff',
              ignition.toLowerCase() == 'on' ? Globals.appColor : Colors.grey);
          TrackingActivity.ignitionAvailable =
              sensorModelAboveLocal[0].text == 'Fetching' ? false : true;
        } else if (sensorName.toUpperCase() == 'FUEL LEVEL' ||
            sensorName.toUpperCase() == 'FUEL') {
          String sensorFinalValue = "NA";
          String units = sensorJsonObject.units!;
          switch (sensorType) {
            case "percentage":
              {
                sensorFinalValue = Helper()
                    .getSensorValueForResultTypePercentage(
                        sensorJsonObject, d0Array);
              }
              break;
            case "value":
              {
                sensorFinalValue = Helper().getSensorValueForResultTypeValue(
                    sensorJsonObject, d0Array);
              }
              break;
            case "logic":
              {
                sensorFinalValue = Helper().getSensorValueForResultTypeLogic(
                    sensorJsonObject, d0Array);
              }
              break;
          }
          sensorFinalValue = '$sensorFinalValue $units';
          sensorModelBelowLocal.add(SensorModelHome(
              Helper().getDrawable(sensorName),
              '$sensorName : ' '$sensorFinalValue',
              Globals.appColor));
        } else {
          sensorModelBelowLocalAll.addAll(
              Helper().checkAndSetSensorHome(j, sensorsJsonObject, d0Array));
        }
      }
    } catch (e) {}
    sensorModelBelowLocal.addAll(sensorModelBelowLocalAll);
    sensorModelAboveLocal[1] = SensorModelHome(
        'images/gpsIcon.png',
        gpsCn == '2' ? 'GPS:\nOn' : 'GPS:\nOff',
        gpsCn == '2' ? Globals.appColor : Colors.grey);
    sensorModelAboveLocal[2] = SensorModelHome('images/odometerIcon.png',
        'Odometer:\n${objectDataModel.o.toString()}km', Globals.appColor);
    try {
      DateTime serverTimeFormat = DateTime.parse(serverTime);
      String formattedDate =
          intl.DateFormat('dd-MM-yy HH:mm').format(serverTimeFormat);
      sensorModelBelowLocal.add(SensorModelHome('images/serverIcon.png',
          'Time (Server): $formattedDate', Globals.appColor));

      DateTime deviceTimeFormat = DateTime.parse(deviceTime);
      String formattedDeviceDate =
          intl.DateFormat('dd-MM-yy HH:mm').format(deviceTimeFormat);
      sensorModelBelowLocal.add(SensorModelHome('images/deviceTime.png',
          'Time (Device): $formattedDeviceDate', Globals.appColor));
    } catch (e) {}

    bool mapType = false; //Globals.prefs.getBool('mapHybrid');
    Color color1 = mapType ? Colors.white : Colors.black;
    Color color2 = mapType ? Colors.white : Colors.green;
    return Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(5))),
      elevation: 5,
      color: Colors.white,
      child: Container(
        decoration:
            BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(5))),
        height: 280,
        width: double.infinity,
        child: Stack(
          children: <Widget>[
            InkWell(
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
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(5),
                      topRight: Radius.circular(5)),
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => TrackingActivity(
                            lat: homeItemList!.lat,
                            lng: homeItemList!.lng,
                            speed: homeItemList!.speed,
                            angle: homeItemList!.angle,
                            name: homeItemList!.name,
                            imei: homeItemList!.imei,
                            status: homeItemList!.status,
                            statusMessage: homeItemList!.statusMessage))),
                    child: map.Map(
                      controller: map.MapController(
                          location: CustomLatLng(
                        double.parse(homeItemList!.lat),
                        double.parse(homeItemList!.lng),
                      )),
                      provider: const CachedGoogleMapProvider(),
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
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
              child: Wrap(
                children: <Widget>[
                  Container(
                    height: 80,
                    width: double.infinity,
                    alignment: Alignment.topLeft,
                    padding: EdgeInsets.only(top: 10, left: 10, right: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                          child: Column(
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
                              homeItemList!.speed > 0
                                  ? AutoSizeText(
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
                                    )
                                  : Container(),
                              homeItemList!.speed > 0
                                  ? SizedBox(
                                      height: 2.5,
                                    )
                                  : Container(),
                              AutoSizeText(
                                '${homeItemList!.statusMessage}',
                                minFontSize: 10,
                                maxLines: 1,
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  color: mapType
                                      ? Colors.white
                                      : Helper()
                                          .getTextColor(homeItemList!.status),
                                  fontSize: 12,
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.bold,
                                  shadows: <Shadow>[
                                    Shadow(
                                      offset: Offset(1.0, 1.0),
                                      blurRadius: 3.0,
                                      color: Colors.white,
                                    ),
                                    Shadow(
                                      offset: Offset(2.0, 2.0),
                                      blurRadius: 3.0,
                                      color: Colors.white,
                                    ),
                                    Shadow(
                                      offset: Offset(3.0, 3.0),
                                      blurRadius: 3.0,
                                      color: Colors.white,
                                    ),
                                    Shadow(
                                      offset: Offset(4.0, 4.0),
                                      blurRadius: 3.0,
                                      color: Colors.white,
                                    ),
                                    Shadow(
                                      offset: Offset(-1.0, -1.0),
                                      blurRadius: 3.0,
                                      color: Colors.white,
                                    ),
                                    Shadow(
                                      offset: Offset(-2.0, -2.0),
                                      blurRadius: 3.0,
                                      color: Colors.white,
                                    ),
                                    Shadow(
                                      offset: Offset(-3.0, -3.0),
                                      blurRadius: 3.0,
                                      color: Colors.white,
                                    ),
                                    Shadow(
                                      offset: Offset(-4.0, -4.0),
                                      blurRadius: 3.0,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          flex: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Center(
              child: Container(
                margin: EdgeInsets.only(bottom: 40),
                child: Transform.rotate(
                  angle: double.parse(homeItemList!.angle) * math.pi / 180,
                  child: Image.asset(
                    homeItemList!.imageName,
                    height: 40,
                  ),
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
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white10,
                              Colors.white,
                              Colors.white,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: SingleChildScrollView(
                            child: HomeSenorListWidget(
                                sensorModel: sensorModelAboveLocal))),
                    Container(
                      padding: EdgeInsets.only(bottom: 5, right: 10, left: 10),
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
                                      builder: (context) => FuelReportActivity(
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
                                    statusMessage: homeItemList!.statusMessage);
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
            Visibility(
              visible: homeItemList!.status == 'false',
              child: Container(
                  height: 300,
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.all(Radius.circular(5))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(StaticVarMethod.listimageurl, height: 60),
                      SizedBox(
                        height: 10,
                      ),
                      AutoSizeText(
                        'Your device ${homeItemList!.name} with IMEI ${homeItemList!.imei} is'
                        ' not connected.',
                        minFontSize: 10,
                        maxLines: 5,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Montserrat'),
                      ),
                    ],
                  )),
            )
          ],
        ),
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

/// You can enable caching by using [CachedNetworkImageProvider] from cached_network_image package.
class CachedGoogleMapProvider extends MapProvider {
  const CachedGoogleMapProvider();

  @override
  ImageProvider getTile(int x, int y, int z) {
    return ExtendedNetworkImageProvider(
        'https://www.google.com/maps/vt/pb=!1m4!1m3!1i$z!2i$x!3i$y!2m3!1e0!2sm!3i420120488!3m7!2sen!5e1105!12m4!1e68!2m2!1sset!2sRoadmap!4e0!5m1!1e0!23i4111425');
  }
}

class HomeSenorListWidget extends StatelessWidget {
  final List<SensorModelHome>? sensorModel;

  const HomeSenorListWidget({Key? key, this.sensorModel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      child: ListView.builder(
        shrinkWrap: true,
        addAutomaticKeepAlives: false,
        scrollDirection: Axis.horizontal,
        itemCount: sensorModel!.length,
        itemBuilder: (BuildContext context, int index) => Padding(
          padding: const EdgeInsets.only(top: 5, bottom: 5),
          child: Container(
            width: MediaQuery.of(context).size.width / 1 / 5,
            child: Center(
                child: Column(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Container(
                  child: Center(
                      child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Image.asset(sensorModel![index].image,
                              color: sensorModel![index].color))),
                  width: 30,
                  height: 40,
                ),
                Padding(
                    padding:
                        const EdgeInsets.only(bottom: 2, left: 2, right: 2),
                    child: AutoSizeText(
                      sensorModel![index].text,
                      maxLines: 2,
                      minFontSize: 6,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 9.0,
                          color: sensorModel![index].color,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Montserrat'),
                    )),
              ],
            )),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// TRACCAR HOME CARD BACKEND SERVICE
// ==========================================

class TraccarHomeCardBackend {
  /// Traccar REST API (`/api/positions` & `/api/devices/{id}`) se HomeCard Data fetch karna
  static Future<Map<String, dynamic>?> fetchTraccarDeviceData({
    required String baseUrl,
    required String sessionCookie,
    required int deviceId,
  }) async {
    final cleanUrl =
        baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

    try {
      final headers = {
        'Accept': 'application/json',
        'Cookie': sessionCookie,
      };

      // 1. Fetch Position details (`/api/positions?deviceId={id}`)
      final posResponse = await http.get(
        Uri.parse('$cleanUrl/api/positions?deviceId=$deviceId'),
        headers: headers,
      );

      // 2. Fetch Device details (`/api/devices/{id}`)
      final devResponse = await http.get(
        Uri.parse('$cleanUrl/api/devices/$deviceId'),
        headers: headers,
      );

      if (posResponse.statusCode == 200 && devResponse.statusCode == 200) {
        final List positions = jsonDecode(posResponse.body);
        final Map<String, dynamic> device = jsonDecode(devResponse.body);

        if (positions.isNotEmpty) {
          final Map<String, dynamic> pos = positions.first;
          final Map<String, dynamic> attributes = pos['attributes'] ?? {};

          // Convert Traccar response to HomeItem compatible format
          return {
            'lat': pos['latitude'].toString(),
            'lng': pos['longitude'].toString(),
            'speed': ((pos['speed'] ?? 0.0) * 1.852).round(), // Knots to Km/h
            'angle': pos['course'].toString(),
            'name': device['name'],
            'imei': device['uniqueId'],
            'status': device['status'] == 'online' ? 'true' : 'false',
            'statusMessage': device['status'] ?? 'offline',
            'ignition': attributes['ignition'] == true ? 'On' : 'Off',
            'odometer': ((attributes['totalDistance'] ?? 0) / 1000).toStringAsFixed(1),
            'engineHours': ((attributes['hours'] ?? 0) / 3600000).toStringAsFixed(1),
            'fuel': attributes['fuel'] != null ? '${attributes['fuel']} L' : 'NA',
            'serverTime': pos['serverTime'],
            'deviceTime': pos['deviceTime'],
            'validGps': pos['valid'] == true ? '2' : '0',
          };
        }
      }
    } catch (_) {}
    return null;
  }
}
