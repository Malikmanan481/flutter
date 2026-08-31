import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:html/parser.dart';
import 'package:intl/intl.dart' as intl;
import 'package:speedotrack/activity/activity_about_us.dart';
import 'package:speedotrack/globals.dart';
import 'package:speedotrack/network/network_api_request.dart';

class VehicleDashModel {
  final String name;
  final String data;
  final String image;

  VehicleDashModel(this.name, this.data, this.image);
}

class DashboardActivity extends StatefulWidget {
  final String? name;
  final String? imei;

  const DashboardActivity({Key? key, this.name, this.imei}) : super(key: key);

  @override
  _DashboardActivityState createState() =>
      _DashboardActivityState(name!, imei!);
}

class _DashboardActivityState extends State<DashboardActivity> {
  _DashboardActivityState(this.name, this.imei);

  final String name;
  final String imei;
  String? dtf, dtt;
  String today = 'fetching'.tr;
  String zeroTime = '00:00:00';
  List<VehicleDashModel> vehicleDashModelArray = [];
  bool loading = false, error = true;
  int indexTime = 1;
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      new GlobalKey<ScaffoldMessengerState>();
  List<String> preTimeList = [
    'lasthour'.tr,
    'today'.tr,
    'yesterday'.tr,
    'before2days'.tr,
    'before3days'.tr,
    'thisweek'.tr,
    'lastweek'.tr,
    'thismonth'.tr,
    'lastmonth'.tr
  ];
  String reportPreTimeDefault = 'today'.tr;

  differentTimes() {
    String zeroTime = '00:00:00';
    var formatterForHour = new intl.DateFormat('yyyy-MM-dd HH:mm:ss');
    var formatter = new intl.DateFormat('yyyy-MM-dd');
    switch (indexTime) {
      case 0:
        dtf = formatterForHour
            .format(DateTime.now().subtract(Duration(hours: 1)));
        dtt = formatterForHour.format(DateTime.now());
        break;
      case 1:
        dtf = '${formatter.format(DateTime.now())} $zeroTime';
        dtt =
            '${formatter.format(DateTime.now().add(Duration(days: 1)))} $zeroTime';
        break;
      case 2:
        dtf =
            '${formatter.format(DateTime.now().subtract(Duration(days: 1)))} $zeroTime';
        dtt = '${formatter.format(DateTime.now())} $zeroTime';
        break;
      case 3:
        dtf =
            '${formatter.format(DateTime.now().subtract(Duration(days: 2)))} $zeroTime';
        dtt = '${formatter.format(DateTime.now())} $zeroTime';
        break;
      case 4:
        dtf =
            '${formatter.format(DateTime.now().subtract(Duration(days: 3)))} $zeroTime';
        dtt = '${formatter.format(DateTime.now())} $zeroTime';
        break;
      case 5:
        dtf =
            '${formatter.format(DateTime.now().subtract(Duration(days: 7)))} $zeroTime';
        dtt = '${formatter.format(DateTime.now())} $zeroTime';
        break;
      case 6:
        dtf =
            '${formatter.format(DateTime.now().subtract(Duration(days: 14)))} $zeroTime';
        dtt =
            '${formatter.format(DateTime.now().subtract(Duration(days: 7)))} $zeroTime';
        break;
      case 7:
        dtf =
            '${formatter.format(DateTime.now().subtract(Duration(days: DateTime.now().day - 1)))} $zeroTime';
        dtt = '${formatter.format(DateTime.now())} $zeroTime';
        break;
      case 8:
        dtf =
            '${formatter.format(DateTime.now().subtract(Duration(days: DateTime.now().day + (daysInMonth(DateTime.now().subtract(Duration(days: DateTime.now().day))) - 1))))} $zeroTime';
        dtt =
            '${formatter.format(DateTime.now().subtract(Duration(days: DateTime.now().day)))} $zeroTime';
        break;
    }
    setState(() {});
  }

  DropdownButton<String> androidPreTimeDropdown() {
    List<DropdownMenuItem<String>> dropdownItems = [];
    for (int i = 0; i < preTimeList.length; i++) {
      var newItem = DropdownMenuItem(
        value: preTimeList[i],
        child: Text(preTimeList[i]),
      );
      dropdownItems.add(newItem);
    }

    return DropdownButton<String>(
      value: reportPreTimeDefault,
      items: dropdownItems,
      dropdownColor: Colors.white,
      onChanged: (value) {
        indexTime = preTimeList.indexOf(value!);
        differentTimes();
        setState(() {
          reportPreTimeDefault = value;
          loading = false;
          error = true;
          fetchData(dtf!, dtt!);
        });
      },
    );
  }

  int daysInMonth(DateTime date) {
    var firstDayThisMonth = new DateTime(date.year, date.month, date.day);
    var firstDayNextMonth = new DateTime(firstDayThisMonth.year,
        firstDayThisMonth.month + 1, firstDayThisMonth.day);
    return firstDayNextMonth.difference(firstDayThisMonth).inDays;
  }

  String formatMs(double ms) {
    int seconds = (ms / 1000).round();
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // ==================== TRACCAR API INTEGRATION ====================
  void fetchData(String dtf, String dtt) async {
    vehicleDashModelArray.clear();

    try {
      // Dates to ISO-8601 UTC format for Traccar API
      DateTime fromDt = DateTime.parse(dtf);
      DateTime toDt = DateTime.parse(dtt);
      String fromIso = fromDt.toUtc().toIso8601String();
      String toIso = toDt.toUtc().toIso8601String();

      // Retrieve deviceId for Traccar
      int? deviceId;
      try {
        String? settingsStr = Globals.prefs!.getString('${imei}_settings');
        if (settingsStr != null) {
          var decoded = jsonDecode(settingsStr);
          deviceId = decoded['id'];
        }
      } catch (_) {}

      if (deviceId == null) {
        var devRes = await NetworkHelper().requestDataFromNetworkWithTimeout(
          urlFile: 'api/devices?uniqueId=$imei',
          httpMethod: 'GET',
          context: context,
        );
        if (devRes != null && devRes.isNotEmpty) {
          var parsed = devRes is String ? jsonDecode(devRes) : devRes;
          if (parsed is List && parsed.isNotEmpty) {
            deviceId = parsed[0]['id'];
          }
        }
      }

      if (deviceId == null) {
        setState(() {
          error = false;
        });
        _scaffoldKey.currentState
            ?.showSnackBar(new SnackBar(content: new Text('noDataFilter'.tr)));
        return;
      }

      // 1. Fetch Summary Report from Traccar REST API
      var summaryRes = await NetworkHelper().requestDataFromNetworkWithTimeout(
        urlFile: 'api/reports/summary?deviceId=$deviceId&from=$fromIso&to=$toIso',
        httpMethod: 'GET',
        context: context,
      );

      // 2. Fetch Trips Report for duration and stop count calculations
      var tripsRes = await NetworkHelper().requestDataFromNetworkWithTimeout(
        urlFile: 'api/reports/trips?deviceId=$deviceId&from=$fromIso&to=$toIso',
        httpMethod: 'GET',
        context: context,
      );

      var summaryData =
          summaryRes is String ? jsonDecode(summaryRes) : summaryRes;
      var tripsData = tripsRes is String ? jsonDecode(tripsRes) : tripsRes;

      if (summaryData is List && summaryData.isNotEmpty) {
        var item = summaryData[0];

        double distance = (item['distance'] ?? 0).toDouble(); // meters
        double maxSpeed = (item['maxSpeed'] ?? 0).toDouble(); // knots
        double avgSpeed = (item['averageSpeed'] ?? 0).toDouble(); // knots
        double engineHoursMs = (item['engineHours'] ?? 0).toDouble(); // ms
        double spentFuel = (item['spentFuel'] ?? 0).toDouble(); // Liters
        double endOdometer = (item['endOdometer'] ?? 0).toDouble(); // meters

        // Convert speed (knots to km/h) & distance (meters to km)
        double maxSpeedKmh = maxSpeed * 1.852;
        double avgSpeedKmh = avgSpeed * 1.852;
        double distanceKm = distance / 1000;
        double odometerKm = endOdometer / 1000;

        int stopCount = 0;
        double totalMoveDurationMs = 0;
        if (tripsData is List) {
          stopCount = tripsData.length > 0 ? tripsData.length - 1 : 0;
          for (var trip in tripsData) {
            totalMoveDurationMs += (trip['duration'] ?? 0).toDouble();
          }
        }

        double totalPeriodMs =
            toDt.difference(fromDt).inMilliseconds.toDouble();
        double totalStopDurationMs = totalPeriodMs - totalMoveDurationMs;
        if (totalStopDurationMs < 0) totalStopDurationMs = 0;

        vehicleDashModelArray.add(VehicleDashModel(
          'Route length',
          '${distanceKm.toStringAsFixed(2)} km',
          getImage('Route length'),
        ));
        vehicleDashModelArray.add(VehicleDashModel(
          'Top speed',
          '${maxSpeedKmh.toStringAsFixed(1)} km/h',
          getImage('Top speed'),
        ));
        vehicleDashModelArray.add(VehicleDashModel(
          'Average speed',
          '${avgSpeedKmh.toStringAsFixed(1)} km/h',
          getImage('Average speed'),
        ));
        vehicleDashModelArray.add(VehicleDashModel(
          'Odometer',
          '${odometerKm.toStringAsFixed(1)} km',
          getImage('Odometer'),
        ));
        vehicleDashModelArray.add(VehicleDashModel(
          'Engine hours',
          '${(engineHoursMs / 3600000).toStringAsFixed(1)} hrs',
          getImage('Engine hours'),
        ));
        vehicleDashModelArray.add(VehicleDashModel(
          'Fuel consumption',
          '${spentFuel.toStringAsFixed(1)} L',
          getImage('Fuel consumption'),
        ));
        vehicleDashModelArray.add(VehicleDashModel(
          'Move duration',
          formatMs(totalMoveDurationMs),
          getImage('Move duration'),
        ));
        vehicleDashModelArray.add(VehicleDashModel(
          'Stop duration',
          formatMs(totalStopDurationMs),
          getImage('Stop duration'),
        ));
        vehicleDashModelArray.add(VehicleDashModel(
          'Stop count',
          '$stopCount',
          getImage('Stop count'),
        ));

        setState(() {
          loading = true;
        });
      } else {
        _scaffoldKey.currentState!
            .showSnackBar(new SnackBar(content: new Text('noDataFilter'.tr)));
        setState(() {
          error = false;
        });
      }
    } catch (e) {
      _scaffoldKey.currentState!
          .showSnackBar(new SnackBar(content: new Text('noDataFilter'.tr)));
      setState(() {
        error = false;
      });
    }
  }

  String getImage(String title) {
    switch (title) {
      case 'Route length':
      case 'Route start':
      case 'Route end':
        return 'images/routeIcon.png';
      case 'Top speed':
        return 'images/topSpeedIcon.png';
      case 'Overspeed count':
      case 'Average speed':
        return 'images/averageSpeedIcon.png';
      case 'Fuel cost':
        return 'images/fuelIcon.png';
      case 'Avg. fuel cons. (100 km)':
      case 'Fuel consumption':
        return 'images/fuelConsumedIcon.png';
      case 'Odometer':
        return 'images/odometerIcon.png';
      case 'Driver':
        return 'images/driverIcon.png';
      case 'Move duration':
        return 'images/movingIcon.png';
      case 'Stop count':
      case 'Stop duration':
        return 'images/stopCountIcon.png';
      case 'Engine idle':
      case 'Engine hours':
      case 'Engine work':
        return 'images/engineHourIcon.png';
      default:
        return 'images/commonServiceIcon.png';
    }
  }

  @override
  void initState() {
    super.initState();
    differentTimes();
    setState(() {
      fetchData(dtf!, dtt!);
    });
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Globals.appColor,
      systemNavigationBarColor: Globals.appColor,
    ));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double _crossAxisSpacing = 0, _mainAxisSpacing = 0, _aspectRatio = 2.4;
    int _crossAxisCount = 2;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Globals.appColor,
        elevation: 0.0,
        title: Text(
          name,
          style:
              TextStyle(color: Color(0xFFF6F6F6), fontFamily: 'Baloo_Thambi_2'),
        ),
        iconTheme: IconThemeData(
          color: Color(0xFFF6F6F6),
        ),
      ),
      body: Column(
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(left: 25, right: 25, top: 10, bottom: 5),
            width: double.infinity,
            child: Text('filter'.tr,
                textAlign: TextAlign.start,
                style: TextStyle(
                    color: Colors.grey,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ),
          Container(
            margin: EdgeInsets.only(left: 25, right: 25, bottom: 10),
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
                border: Border.all(color: Globals.appColor, width: 2),
                borderRadius: BorderRadius.all(Radius.circular(5))),
            child: Material(
              elevation: 10,
              borderRadius: BorderRadius.circular(10.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Center(child: androidPreTimeDropdown()),
              ),
            ),
          ),
          Expanded(
            child: loading
                ? GridView.builder(
                    itemCount: vehicleDashModelArray.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _crossAxisCount,
                      crossAxisSpacing: _crossAxisSpacing,
                      mainAxisSpacing: _mainAxisSpacing,
                      childAspectRatio: _aspectRatio,
                    ),
                    itemBuilder: (BuildContext context, int index) {
                      return Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5))),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(left: 5.0),
                                          child: Text(
                                            vehicleDashModelArray[index].name,
                                            maxLines: 1,
                                            textAlign: TextAlign.start,
                                            style: TextStyle(
                                                color: Globals.appColor,
                                                fontSize: 12,
                                                letterSpacing: 1.3,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Montserrat'),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        height: 5,
                                      ),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(left: 5.0),
                                          child: Text(
                                            vehicleDashModelArray[index]
                                                .data
                                                .toUpperCase(),
                                            maxLines: 1,
                                            textAlign: TextAlign.start,
                                            style: TextStyle(
                                                color:
                                                    vehicleDashModelArray[index]
                                                            .data
                                                            .toUpperCase()
                                                            .contains(
                                                                'expired'.tr)
                                                        ? Colors.red
                                                        : Color(0xFF7E8188),
                                                fontSize: 10,
                                                letterSpacing: 1.3,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Montserrat'),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: SizedBox(
                                    height: 40,
                                    width: 40,
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Image.asset(
                                        vehicleDashModelArray[index].image,
                                        color: Globals.appColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : Center(
                    child: Visibility(
                      visible: error,
                      child: CircularProgressIndicator(
                          backgroundColor: Color(0xFFF6F6F6),
                          valueColor: new AlwaysStoppedAnimation<Color>(
                            Globals.appColor,
                          )),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
