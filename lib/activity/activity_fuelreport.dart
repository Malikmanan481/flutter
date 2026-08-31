import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:custom_progress_button/custom_progress_button.dart';
import 'package:flutter_rounded_date_picker/flutter_rounded_date_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart' as intl;
import 'package:speedotrack/globals.dart';
import 'package:speedotrack/helper/helper.dart';
import 'package:speedotrack/network/network_api_request.dart';

class FuelModel {
  final String time;
  final String addresslink;
  final String address;
  final String before;
  final String after;
  final String filled;

  FuelModel(this.time, this.addresslink, this.address, this.before, this.after,
      this.filled);
}

class FuelReportActivity extends StatefulWidget {
  final String? name;
  final String? imei;

  const FuelReportActivity({Key? key, this.name, this.imei}) : super(key: key);

  @override
  _FuelReportActivityState createState() =>
      _FuelReportActivityState(name!, imei!);
}

class _FuelReportActivityState extends State<FuelReportActivity> {
  final String name;
  final String imei;

  _FuelReportActivityState(this.name, this.imei);

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
  String? reportTypeValue, dataItems;
  List<String> reportTypeList = ['fuelFillings'.tr, 'fuelTheft'.tr];
  String reportStopDefault = '> 1 min';
  String reportPreTimeDefault = 'today'.tr;
  String? dtf, dtt;
  bool isLoading = false;
  int indexTime = 1;
  String buttonText = 'viewReport'.tr;
  Map<String, String>? language;
  String format = 'html';
  String reportTypeDefault = 'fuelFillings'.tr;
  List<FuelModel> fuelModelList = [];

  DropdownButton<String> androidReportDropdown() {
    List<DropdownMenuItem<String>> dropdownItems = [];
    for (int i = 0; i < reportTypeList.length; i++) {
      var newItem = DropdownMenuItem(
        value: reportTypeList[i],
        child: Text(reportTypeList[i]),
      );
      dropdownItems.add(newItem);
    }

    return DropdownButton<String>(
      value: reportTypeDefault,
      items: dropdownItems,
      dropdownColor: Colors.white,
      onChanged: (value) {
        setState(() {
          reportTypeDefault = value!;
        });
      },
    );
  }

  differentTimes() {
    String zeroTime = '00:00:00';
    var formatterForHour = intl.DateFormat('yyyy-MM-dd HH:mm:ss');
    var formatter = intl.DateFormat('yyyy-MM-dd');
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
    var firstDayThisMonth = DateTime(date.year, date.month, date.day);
    var firstDayNextMonth = DateTime(firstDayThisMonth.year,
        firstDayThisMonth.month + 1, firstDayThisMonth.day);
    return firstDayNextMonth.difference(firstDayThisMonth).inDays;
  }

  DropdownButton<String> androidStopDropdown() {
    List<DropdownMenuItem<String>> dropdownItems = [];
    for (int i = 0; i < stopsList.length; i++) {
      var newItem = DropdownMenuItem(
        value: stopsList[i],
        child: Text(stopsList[i]),
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
        });
      },
    );
  }

  resetResultTimer() {
    Timer(Duration(seconds: 5), () {
      setState(() {
        buttonText = 'viewReport'.tr;
      });
    });
  }

  /// Connected to Traccar REST API GET /api/reports/events
  Future<bool> fetchData(String dtf, String dtt) async {
    fuelModelList.clear();

    String eventType = (reportTypeDefault == "fuelFillings".tr)
        ? 'fuelIncrease'
        : 'fuelDrop';

    // Convert local dates to UTC ISO 8601 strings expected by Traccar
    String isoDtf = '';
    String isoDtt = '';
    try {
      DateTime parsedFrom = intl.DateFormat('yyyy-MM-dd HH:mm:ss').parse(dtf);
      DateTime parsedTo = intl.DateFormat('yyyy-MM-dd HH:mm:ss').parse(dtt);
      isoDtf = parsedFrom.toUtc().toIso8601String();
      isoDtt = parsedTo.toUtc().toIso8601String();
    } catch (_) {
      isoDtf = dtf;
      isoDtt = dtt;
    }

    try {
      var response = await NetworkHelper().requestDataFromNetworkWithTimeout(
          urlFile:
              '/api/reports/events?deviceId=$imei&from=$isoDtf&to=$isoDtt&type=$eventType',
          context: context);

      if (response != null && response.isNotEmpty) {
        dynamic decoded = response is String ? jsonDecode(response) : response;

        if (decoded is List && decoded.isNotEmpty) {
          for (var item in decoded) {
            String rawTime = item['eventTime'] ?? item['serverTime'] ?? '';
            String formattedTime = rawTime;

            if (rawTime.isNotEmpty) {
              try {
                DateTime parsedDate = DateTime.parse(rawTime).toLocal();
                formattedTime = intl.DateFormat('yyyy-MM-dd HH:mm:ss')
                    .format(parsedDate);
              } catch (_) {}
            }

            var attributes = item['attributes'] ?? {};
            String address = attributes['address'] ?? item['address'] ?? 'N/A';
            String addressLink =
                "https://maps.google.com/?q=${attributes['latitude'] ?? 0},${attributes['longitude'] ?? 0}";

            String before =
                "${attributes['before'] ?? attributes['startFuel'] ?? '0'} L";
            String after =
                "${attributes['after'] ?? attributes['endFuel'] ?? '0'} L";
            String filled =
                "${attributes['amount'] ?? attributes['fuel'] ?? '0'} L";

            fuelModelList.add(FuelModel(
                formattedTime, addressLink, address, before, after, filled));
          }
          return fuelModelList.isNotEmpty;
        }
      }
    } catch (e) {
      // Return false on network or parsing error
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    differentTimes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          color: Color(0xFFF6F6F6), //change your color here
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 25, right: 25, top: 25, bottom: 5),
              width: double.infinity,
              child: Text('reportType'.tr,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                      color: Colors.black,
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
              margin: EdgeInsets.only(left: 25, right: 25, top: 10, bottom: 5),
              width: double.infinity,
              child: Text('filter'.tr,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                      color: Colors.black,
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
              child: Text('customTime'.tr,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                      color: Colors.black,
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
                                primary: Globals
                                    .appColor, // Change the primary color (header and selected time)
                                onSurface: Colors
                                    .black, // Color of unselected time text
                                onBackground: Colors
                                    .orange, // Color of the cancel and ok buttons
                              ),
                            ),
                            child: child!,
                          );
                        },
                        lastDate: DateTime(2101));
                    if (newDateTime != null) {
                      var formatter = intl.DateFormat('yyyy-MM-dd');
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
                                  primary: Globals
                                      .appColor, // Change the primary color (header and selected time)
                                  onSurface: Colors
                                      .black, // Color of unselected time text
                                  onBackground: Colors
                                      .orange, // Color of the cancel and ok buttons
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
                  child: SizedBox(
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
                            primary: Colors
                                .white, // Change the primary color (header and selected time)
                            onSurface:
                                Colors.black, // Color of unselected time text
                            onPrimary:
                                Globals.appColor, // Color on primary elements
                            onBackground: Colors
                                .orange, // Color of the cancel and ok buttons
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
                              primary: Colors
                                  .white, // Change the primary color (header and selected time)
                              onSurface:
                                  Colors.black, // Color of unselected time text
                              onPrimary:
                                  Globals.appColor, // Color on primary elements
                              onBackground: Colors
                                  .orange, // Color of the cancel and ok buttons
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
                  child: SizedBox(
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
                      isLoading = false;
                    });
                    bool results = await fetchData(dtf!, dtt!);
                    if (results) {
                      setState(() {
                        isLoading = true;
                      });
                    } else {
                      setState(() {
                        buttonText = 'noDataItem'.tr;
                      });
                      resetResultTimer();
                    }
                  },
                  height: 45,
                  maxWidth: 240,
                  progressWidget: CircularProgressIndicator(
                      backgroundColor: Globals.appColor,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                  stateColors: {
                    ButtonState.success: Colors.green,
                    ButtonState.fail: Colors.redAccent,
                    ButtonState.loading: Colors.red,
                    ButtonState.idle: Globals.appColor,
                  },
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
                      buttonText,
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                    ButtonState.idle: Text(
                      buttonText,
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  },
                ),
              ),
            ),
            isLoading
                ? Container(
                    color: Color(0xFFF6F6F6),
                    child: ListView.builder(
                      itemCount: fuelModelList.length,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      scrollDirection: Axis.vertical,
                      itemBuilder: (context, index) {
                        return Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5))),
                          color: Color(0xFFF6F6F6),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: [
                                    Icon(
                                      FontAwesomeIcons.clock,
                                      color: Color(0xFF7E8188),
                                      size: 15,
                                    ),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    Text(
                                      fuelModelList[index].time,
                                      textAlign: TextAlign.start,
                                      style: TextStyle(
                                          color: Color(0xFF7E8188),
                                          fontSize: 12,
                                          letterSpacing: 1.3,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Montserrat'),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 5,
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Icon(
                                      FontAwesomeIcons.mapMarkerAlt,
                                      color: Color(0xFF7E8188),
                                      size: 15,
                                    ),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        fuelModelList[index].address,
                                        textAlign: TextAlign.start,
                                        maxLines: 5,
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 14,
                                            letterSpacing: 1,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Montserrat'),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Expanded(
                                      flex: 5,
                                      child: Container(
                                        padding: EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(5)),
                                            color: Colors.orange),
                                        child: Center(
                                            child: Text(
                                                '${'before'.tr}\n${fuelModelList[index].before}',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: 'Montserrat'))),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: SizedBox(
                                        height: 5,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 5,
                                      child: Container(
                                        padding: EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(5)),
                                            color: Colors.blue),
                                        child: Center(
                                            child: Text(
                                                '${'after'.tr}\n${fuelModelList[index].after}',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: 'Montserrat'))),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: SizedBox(
                                        height: 5,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 5,
                                      child: Container(
                                        padding: EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(5)),
                                            color: Colors.green),
                                        child: Center(
                                            child: Text(
                                                reportTypeValue ==
                                                        'fuelfillings'
                                                    ? '${'filled'.tr}\n${fuelModelList[index].filled}'
                                                    : '${'stolen'.tr}\n${fuelModelList[index].filled}',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: 'Montserrat'))),
                                      ),
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }
}
