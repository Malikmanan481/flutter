import 'dart:convert';

import 'package:custom_progress_button/custom_progress_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rounded_date_picker/flutter_rounded_date_picker.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:speedotrack/activity/activity_report_view.dart';
import 'package:speedotrack/network/network_api_request.dart';

import '../globals.dart';

class ReportActivity extends StatefulWidget {
  final String? name;
  final String? imei;

  const ReportActivity({
    Key? key,
    this.name,
    this.imei,
  }) : super(key: key);

  @override
  _ReportActivityState createState() => _ReportActivityState(name, imei);
}

class _ReportActivityState extends State<ReportActivity> {
  _ReportActivityState(this.finalName, this.finalImei);

  List<String> reportTypeList = [];
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
  final String? finalName;
  final String? finalImei;
  int? traccarDeviceId;
  bool coordinatesString = false;
  bool addressString = false;
  bool zonesString = false;
  int indexTime = 1;
  String? reportTypeDefault;
  String reportStopDefault = '> 1 min';
  String reportPreTimeDefault = 'today'.tr;
  String? dtf, dtt;
  String format = 'html';
  bool isLoading = false;

  /// Traccar Device ID lookup by IMEI / UniqueId
  Future<int?> _fetchTraccarDeviceId() async {
    if (traccarDeviceId != null) return traccarDeviceId;
    try {
      var response = await NetworkHelper().requestDataFromNetworkWithTimeoutGET(
        urlFile: '/api/devices',
        body: {'uniqueId': finalImei},
        context: context,
      );

      if (response != null && response.isNotEmpty) {
        var devices = json.decode(response);
        if (devices is List && devices.isNotEmpty) {
          traccarDeviceId = devices[0]['id'];
          return traccarDeviceId;
        }
      }
    } catch (e) {
      debugPrint('Error fetching Traccar device ID: $e');
    }
    return null;
  }

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

  /// ISO 8601 UTC formatter for Traccar REST API
  String formatToTraccarIso(String dateStr) {
    try {
      DateTime dt = DateTime.parse(dateStr);
      return dt.toUtc().toIso8601String();
    } catch (e) {
      return dateStr;
    }
  }

  /// Maps selected UI report type to corresponding Traccar API endpoint
  String getReportEndpoint(String reportType) {
    switch (reportType.toLowerCase()) {
      case 'trips':
        return '/api/reports/trips';
      case 'stops':
        return '/api/reports/stops';
      case 'summary':
        return '/api/reports/summary';
      case 'events':
        return '/api/reports/events';
      case 'route':
      default:
        return '/api/reports/route';
    }
  }

  Future<String> fetchReport() async {
    int? devId = await _fetchTraccarDeviceId();
    if (devId == null) {
      return 'false';
    }

    String endpoint = getReportEndpoint(reportTypeDefault ?? 'Trips');
    String isoFrom = formatToTraccarIso(dtf!);
    String isoTo = formatToTraccarIso(dtt!);

    try {
      var response = await NetworkHelper().requestDataFromNetworkWithTimeoutGET(
        urlFile: endpoint,
        headers: {'Accept': 'text/html'},
        body: {
          'deviceId': '$devId',
          'from': isoFrom,
          'to': isoTo,
        },
        context: context,
      );

      if (response != null && response.isNotEmpty && response != 'false') {
        return response;
      }
    } catch (e) {
      debugPrint('Error fetching report from Traccar: $e');
    }
    return 'false';
  }

  void fetchReportList() {
    reportTypeList = ['Trips', 'Stops', 'Summary', 'Route', 'Events'];
    if (reportTypeList.isNotEmpty) {
      reportTypeDefault = reportTypeList.first;
    }
    setState(() {});
  }

  DropdownButton<String> androidReportDropdown() {
    List<DropdownMenuItem<String>> dropdownItems = [];
    for (int i = 0; i < reportTypeList.length; i++) {
      var newItem = DropdownMenuItem(
        child: Text(reportTypeList[i]),
        value: reportTypeList[i],
      );
      dropdownItems.add(newItem);
    }

    return DropdownButton<String>(
      value: reportTypeDefault,
      items: dropdownItems,
      dropdownColor: Colors.white,
      onChanged: (value) {
        setState(() {
          reportTypeDefault = value;
        });
      },
    );
  }

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
          fetchReport();
        });
      },
    );
  }

  @override
  void initState() {
    super.initState();
    fetchReportList();
    differentTimes();
    _fetchTraccarDeviceId();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Globals.appColor,
        elevation: 0.0,
        title: Text(
          '${finalName!}',
          style:
              TextStyle(color: Color(0xFFF6F6F6), fontFamily: 'Baloo_Thambi_2'),
        ),
        iconTheme: IconThemeData(
          color: Color(0xFFF6F6F6),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.only(bottom: 10),
          color: Color(0xFFF6F6F6),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Container(
                margin:
                    EdgeInsets.only(left: 25, right: 25, top: 25, bottom: 5),
                width: double.infinity,
                child: Text('reportType'.tr,
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
                  child: Center(child: androidReportDropdown()),
                ),
              ),
              Container(
                margin:
                    EdgeInsets.only(left: 25, right: 25, top: 10, bottom: 5),
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
                margin:
                    EdgeInsets.only(left: 25, right: 25, top: 10, bottom: 5),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    Text('showCoordinates'.tr,
                        style: TextStyle(
                            color: Colors.grey,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    Spacer(),
                    Switch(
                        activeColor: Color(0xFFF6F6F6),
                        activeTrackColor: Colors.green,
                        inactiveThumbColor: Color(0xFFF6F6F6),
                        inactiveTrackColor: Colors.red,
                        value: coordinatesString,
                        onChanged: (value) {
                          setState(() {
                            coordinatesString = !coordinatesString;
                          });
                        })
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    Text('showAddress'.tr,
                        style: TextStyle(
                            color: Colors.grey,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    Spacer(),
                    Switch(
                        activeColor: Color(0xFFF6F6F6),
                        activeTrackColor: Colors.green,
                        inactiveThumbColor: Color(0xFFF6F6F6),
                        inactiveTrackColor: Colors.red,
                        value: addressString,
                        onChanged: (value) {
                          setState(() {
                            addressString = !addressString;
                          });
                        })
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    Text('zonesIAddress'.tr,
                        style: TextStyle(
                            color: Colors.grey,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    Spacer(),
                    Switch(
                        activeColor: Color(0xFFF6F6F6),
                        activeTrackColor: Colors.green,
                        inactiveThumbColor: Color(0xFFF6F6F6),
                        inactiveTrackColor: Colors.red,
                        value: zonesString,
                        onChanged: (value) {
                          setState(() {
                            zonesString = !zonesString;
                          });
                        })
                  ],
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 1,
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
                        child: Column(
                          children: <Widget>[
                            Image.asset('images/calendarIcon.png',
                                height: 60, width: 60, color: Globals.appColor),
                            SizedBox(
                              height: 10,
                            ),
                            Text(
                                '${dtf!.split(' ')[0]} - ${dtt!.split(' ')[0]}',
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
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
                            ));
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
                              ));
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
                        child: Column(
                          children: <Widget>[
                            Image.asset(
                              'images/deviceTime.png',
                              color: Globals.appColor,
                              height: 60,
                              width: 60,
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Text(
                                '${dtf!.split(' ')[1]} - ${dtt!.split(' ')[1]}',
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 50,
              ),
              Center(
                child: CustomProgressButton(
                  onPressed: () async {
                    setState(() {
                      isLoading = true;
                    });
                    String result = await fetchReport();
                    if (result != 'false') {
                      setState(() {
                        isLoading = false;
                      });
                      Navigator.push(
                          context,
                          CupertinoPageRoute(
                              builder: (context) => ReportViewActivity(
                                    htmlDocument: result,
                                  )));
                    } else {
                      setState(() {
                        isLoading = false;
                      });
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
                      'viewReport'.tr,
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                    ButtonState.idle: Text(
                      'viewReport'.tr,
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
              SizedBox(
                height: 15,
              ),
              isLoading
                  ? CircularProgressIndicator(
                      backgroundColor: Globals.appColor,
                      valueColor:
                          new AlwaysStoppedAnimation<Color>(Colors.white))
                  : Container()
            ],
          ),
        ),
      ),
    );
  }
}
