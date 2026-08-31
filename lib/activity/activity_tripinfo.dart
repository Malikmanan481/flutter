import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:custom_progress_button/custom_progress_button.dart';
import 'package:flutter_rounded_date_picker/flutter_rounded_date_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart' as intl;
import 'package:intl/intl.dart';
import 'package:speedotrack/model/model_tripinfo.dart';
import 'package:speedotrack/network/network_api_request.dart';

import '../globals.dart';
import 'activity_tripinfolist.dart';

class TripInfoActivity extends StatefulWidget {
  final String? name;
  final String? imei;

  const TripInfoActivity({Key? key, this.name, this.imei}) : super(key: key);

  @override
  _TripInfoActivityState createState() => _TripInfoActivityState(name!, imei!);
}

class _TripInfoActivityState extends State<TripInfoActivity> {
  final String? name;
  final String? imei;
  bool? isLoading = false;
  List<String> stopsList = [
    '> 1 min',
    '> 2 min',
    '> 5 min',
    '> 10 min',
    '> 20 min',
    '> 30 min',
    '> 1 hr',
    '> 2 hr',
    '> 5 hr'
  ];
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
  List<TripInfoModel> tripInfoModel = [];
  int indexTime = 1;
  String reportStopDefault = '> 1 min';
  String reportPreTimeDefault = 'today'.tr;
  String? dtf, dtt;
  String buttonText = 'viewTripInfo'.tr;

  resetResultTimer() {
    Timer(Duration(seconds: 5), () {
      setState(() {
        buttonText = 'viewTripInfo'.tr;
      });
    });
  }

  List<Trip> tripList = [];

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

  int daysInMonth(DateTime date) {
    var firstDayThisMonth = new DateTime(date.year, date.month, date.day);
    var firstDayNextMonth = new DateTime(firstDayThisMonth.year,
        firstDayThisMonth.month + 1, firstDayThisMonth.day);
    return firstDayNextMonth.difference(firstDayThisMonth).inDays;
  }

  _TripInfoActivityState(this.name, this.imei);

  DropdownButton<String> androidStopDropdown() {
    List<DropdownMenuItem<String>> dropdownItems = [];
    for (int i = 0; i < stopsList.length; i++) {
      var newItem = DropdownMenuItem(
        child: Text(stopsList[i]),
        value: stopsList[i],
      );
      dropdownItems.add(newItem);
    }

    return DropdownButton<String>(
      value: reportStopDefault,
      items: dropdownItems,
      dropdownColor: Colors.white,
      onChanged: (value) {
        setState(() {
          reportStopDefault = value!;
        });
      },
    );
  }

  DropdownButton<String> androidPreTimeDropdown() {
    List<DropdownMenuItem<String>> dropdownItems = [];
    for (int i = 0; i < preTimeList.length; i++) {
      var newItem = DropdownMenuItem(
        child: Text(preTimeList[i]),
        value: preTimeList[i],
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
        });
      },
    );
  }

  /// Fetch trip report and polyline points directly from Traccar API
  Future<bool> fetchData(String dtf, String dtt) async {
    try {
      // 1. Convert local date string ('yyyy-MM-dd HH:mm:ss') to UTC ISO 8601
      DateTime fromDate = DateTime.parse(dtf);
      DateTime toDate = DateTime.parse(dtt);

      String fromIso = fromDate.toUtc().toIso8601String();
      String toIso = toDate.toUtc().toIso8601String();

      // 2. Fetch Trips report from Traccar REST API
      var tripsResponse = await NetworkHelper().requestDataFromNetworkWithTimeout(
        urlFile: '/api/reports/trips?deviceId=$imei&from=$fromIso&to=$toIso',
        context: context,
      );

      // 3. Fetch Route positions for map polyline points
      var routeResponse = await NetworkHelper().requestDataFromNetworkWithTimeout(
        urlFile: '/api/reports/route?deviceId=$imei&from=$fromIso&to=$toIso',
        context: context,
      );

      tripList.clear();

      List<dynamic> tripsData = [];
      if (tripsResponse is String) {
        tripsData = json.decode(tripsResponse);
      } else if (tripsResponse is List) {
        tripsData = tripsResponse;
      }

      List<dynamic> routeData = [];
      if (routeResponse is String) {
        routeData = json.decode(routeResponse);
      } else if (routeResponse is List) {
        routeData = routeResponse;
      }

      if (tripsData.isNotEmpty) {
        DateFormat displayFormat = DateFormat("yyyy-MM-dd HH:mm:ss");

        for (var tripJson in tripsData) {
          String startTimeRaw = tripJson['startTime'] ?? '';
          String endTimeRaw = tripJson['endTime'] ?? '';

          DateTime tripStart = DateTime.parse(startTimeRaw).toLocal();
          DateTime tripEnd = DateTime.parse(endTimeRaw).toLocal();

          String startTimeStr = displayFormat.format(tripStart);
          String endTimeStr = displayFormat.format(tripEnd);

          // Map positions corresponding to this trip interval
          List<LatLng> routePoints = [];
          double? minLat, maxLat, minLng, maxLng;

          for (var pos in routeData) {
            String fixTimeRaw = pos['fixTime'] ?? pos['deviceTime'] ?? '';
            if (fixTimeRaw.isNotEmpty) {
              DateTime posTime = DateTime.parse(fixTimeRaw).toLocal();
              if ((posTime.isAfter(tripStart) || posTime.isAtSameMomentAs(tripStart)) &&
                  (posTime.isBefore(tripEnd) || posTime.isAtSameMomentAs(tripEnd))) {
                double lat = (pos['latitude'] as num).toDouble();
                double lng = (pos['longitude'] as num).toDouble();
                LatLng latLng = LatLng(lat, lng);

                if (minLat == null) {
                  minLat = maxLat = lat;
                  minLng = maxLng = lng;
                } else {
                  if (lat > maxLat!) maxLat = lat;
                  if (lat < minLat) minLat = lat;
                  if (lng > maxLng!) maxLng = lng;
                  if (lng < minLng) minLng = lng;
                }

                if (routePoints.isEmpty || routePoints.last != latLng) {
                  routePoints.add(latLng);
                }
              }
            }
          }

          // Traccar distance is in meters -> convert to KM
          double distanceKm = ((tripJson['distance'] ?? 0) as num).toDouble() / 1000.0;
          
          // Traccar speed is in knots -> convert to KM/H (1 knot = 1.852 km/h)
          int avgSpeedKmH = (((tripJson['averageSpeed'] ?? 0) as num).toDouble() * 1.852).round();
          int maxSpeedKmH = (((tripJson['maxSpeed'] ?? 0) as num).toDouble() * 1.852).round();

          // Duration conversion from milliseconds
          num durationMs = tripJson['duration'] ?? 0;
          Duration dur = Duration(milliseconds: durationMs.toInt());
          String durationStr = "${dur.inHours}h ${dur.inMinutes.remainder(60)}m ${dur.inSeconds.remainder(60)}s";

          tripList.add(Trip(
            start: startTimeStr,
            end: endTimeStr,
            duration: durationStr,
            length: double.parse(distanceKm.toStringAsFixed(2)),
            avgSpeed: avgSpeedKmH,
            topSpeed: maxSpeedKmH,
            routePoints: routePoints,
            southWest: LatLng(minLat ?? 0, minLng ?? 0),
            northeast: LatLng(maxLat ?? 0, maxLng ?? 0),
          ));
        }
      }

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      return tripList.isNotEmpty;
    } catch (e) {
      print("Traccar Trip API Error: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    differentTimes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Globals.appColor,
          elevation: 0.0,
          title: Text(
            '${name!}',
            style: TextStyle(
                color: Color(0xFFF6F6F6), fontFamily: 'Baloo_Thambi_2'),
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
              child: Text('stops'.tr,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                      color: Colors.grey,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ),
            Container(
              margin: EdgeInsets.only(left: 25, right: 25),
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                  border: Border.all(color: Globals.appColor, width: 2),
                  borderRadius: BorderRadius.all(Radius.circular(5))),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Center(child: androidStopDropdown()),
              ),
            ),
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Center(child: androidPreTimeDropdown()),
              ),
            ),
            Container(
              margin: EdgeInsets.only(left: 25, right: 25, top: 10, bottom: 5),
              width: double.infinity,
              child: Text('Select Custom Time',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                      color: Colors.grey,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ),
            Container(
              margin: EdgeInsets.only(left: 25, right: 25),
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                  border: Border.all(color: Globals.appColor, width: 2),
                  borderRadius: BorderRadius.all(Radius.circular(5))),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: InkWell(
                  onTap: () async {
                    DateTime? newDateTime = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2015, 8),
                        builder: (BuildContext context, Widget? child) {
                          return Theme(
                            data: ThemeData.light().copyWith(
                              useMaterial3: false,
                              dialogBackgroundColor: Colors.white,
                              primaryColor: Globals.appColor,
                              timePickerTheme: TimePickerThemeData(
                                  dialHandColor: Globals.appColor),
                              textTheme: TextTheme(),
                              colorScheme: ColorScheme.light(
                                primary: Globals.appColor,
                                onSurface: Colors.black,
                                onBackground: Colors.orange,
                              ),
                            ),
                            child: child!,
                          );
                        },
                        lastDate: DateTime(2101));
                    if (newDateTime != null) {
                      var formatter = new intl.DateFormat('yyyy-MM-dd');
                      DateTime? newDateTimeTo = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2015, 8),
                          builder: (BuildContext context, Widget? child) {
                            return Theme(
                              data: ThemeData.light().copyWith(
                                useMaterial3: false,
                                dialogBackgroundColor: Colors.white,
                                primaryColor: Globals.appColor,
                                timePickerTheme: TimePickerThemeData(
                                    dialHandColor: Globals.appColor),
                                textTheme: TextTheme(),
                                colorScheme: ColorScheme.light(
                                  primary: Globals.appColor,
                                  onSurface: Colors.black,
                                  onBackground: Colors.orange,
                                ),
                              ),
                              child: child!,
                            );
                          },
                          lastDate: DateTime(2101));
                      setState(() {
                        dtf =
                            '${formatter.format(newDateTime)} ${dtf!.split(' ')[1]}';
                        if (newDateTimeTo != null) {
                          dtt =
                              '${formatter.format(newDateTimeTo)} ${dtt!.split(' ')[1]}';
                        }
                      });
                    }
                  },
                  child: Container(
                    height: double.infinity,
                    child: Row(
                      children: <Widget>[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                              '${dtf!.split(' ')[0]} to ${dtt!.split(' ')[0]}',
                              style: TextStyle(
                                  color: Color(0xFF7E8188),
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                        ),
                        Spacer(),
                        Icon(
                          FontAwesomeIcons.calendarAlt,
                          size: 25,
                          color: Color(0xFF7E8188),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(left: 25, right: 25, top: 10),
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                  border: Border.all(color: Globals.appColor, width: 2),
                  borderRadius: BorderRadius.all(Radius.circular(5))),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: InkWell(
                  onTap: () async {
                    String regex = ' ';
                    final timePicked = await showRoundedTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                      theme: ThemeData(
                        useMaterial3: false,
                        primaryColor: Colors.white,
                        dialogBackgroundColor: Globals.appColor,
                        disabledColor: Globals.appColor,
                        textTheme: TextTheme(
                          titleLarge: TextStyle(
                            color: Globals.appColor,
                          ),
                          titleMedium: TextStyle(
                            color: Globals.appColor,
                          ),
                          titleSmall: TextStyle(
                            color: Globals.appColor,
                          ),
                        ),
                        colorScheme: ColorScheme.light(
                          primary: Colors.white,
                          onSurface: Colors.black,
                          onPrimary: Globals.appColor,
                          onBackground: Colors.orange,
                        ),
                      ),
                    );
                    TimeOfDay? timePickedTo;
                    if (timePicked != null) {
                      timePickedTo = await showRoundedTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                        theme: ThemeData(
                          useMaterial3: false,
                          primaryColor: Colors.white,
                          dialogBackgroundColor: Globals.appColor,
                          disabledColor: Globals.appColor,
                          textTheme: TextTheme(
                            titleLarge: TextStyle(
                              color: Globals.appColor,
                            ),
                            titleMedium: TextStyle(
                              color: Globals.appColor,
                            ),
                            titleSmall: TextStyle(
                              color: Globals.appColor,
                            ),
                          ),
                          colorScheme: ColorScheme.light(
                            primary: Colors.white,
                            onSurface: Colors.black,
                            onPrimary: Globals.appColor,
                            onBackground: Colors.orange,
                          ),
                        ),
                      );
                    }
                    setState(() {
                      if (timePicked != null) {
                        dtf =
                            '${dtf!.split(regex)[0]} ${timePicked.hour}:${timePicked.minute}:00';
                      }
                      if (timePickedTo != null) {
                        dtt =
                            '${dtt!.split(regex)[0]} ${timePickedTo.hour}:${timePickedTo.minute}:00';
                      }
                    });
                  },
                  child: Container(
                    height: double.infinity,
                    child: Row(
                      children: <Widget>[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                              '${dtf!.split(' ')[1]} to ${dtt!.split(' ')[1]}',
                              style: TextStyle(
                                  color: Color(0xFF7E8188),
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                        ),
                        Spacer(),
                        Icon(
                          FontAwesomeIcons.clock,
                          size: 25,
                          color: Color(0xFF7E8188),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: CustomProgressButton(
                  onPressed: () async {
                    setState(() {
                      isLoading = true;
                    });
                    bool results = await fetchData(dtf!, dtt!);
                    if (results) {
                      Navigator.push(
                          context,
                          CupertinoPageRoute(
                              builder: (context) => TripInfoListActivity(
                                    tripInfoModel: tripList,
                                    name: name!,
                                    imei: imei!,
                                  )));
                    } else {
                      setState(() {
                        buttonText = 'NO TRIP INFO';
                      });
                      resetResultTimer();
                    }
                  },
                  height: 45,
                  maxWidth: 240,
                  progressWidget: CircularProgressIndicator(
                      backgroundColor: Globals.appColor,
                      valueColor:
                          new AlwaysStoppedAnimation<Color>(Colors.white)),
                  stateWidgets: {
                    ButtonState.success: Text(
                      'success'.tr,
                      style: TextStyle(fontSize: 20),
                    ),
                    ButtonState.fail: Text(
                      'failure'.tr,
                      style: TextStyle(fontSize: 20),
                    ),
                    ButtonState.loading: Text(
                      '$buttonText',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                    ButtonState.idle: Text(
                      '$buttonText',
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  },
                  stateColors: {
                    ButtonState.success: Colors.green,
                    ButtonState.fail: Colors.redAccent,
                    ButtonState.loading: Colors.red,
                    ButtonState.idle: Globals.appColor,
                  },
                ),
              ),
            ),
            SizedBox(height: 10),
            isLoading!
                ? CircularProgressIndicator(
                    backgroundColor: Globals.appColor,
                    valueColor: new AlwaysStoppedAnimation<Color>(Colors.white))
                : Container()
          ],
        ));
  }
}

class Trip {
  final String? start, end, duration;
  final dynamic length;
  final int? topSpeed, avgSpeed;
  final List<LatLng>? routePoints;
  final LatLng? southWest, northeast;

  Trip(
      {this.duration,
      this.southWest,
      this.northeast,
      this.topSpeed,
      this.avgSpeed,
      this.end,
      this.routePoints,
      this.length,
      this.start});
}
