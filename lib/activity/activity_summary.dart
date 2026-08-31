import 'dart:async';
import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:custom_progress_button/custom_progress_button.dart';
import 'package:flutter_rounded_date_picker/flutter_rounded_date_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart' as intl;
import 'package:speedotrack/component/component_summary_widget.dart';
import 'package:speedotrack/network/network_api_request.dart';

import '../globals.dart';

class SummaryActivity extends StatefulWidget {
  final String? name;
  final String? imei;
  final String? from;

  const SummaryActivity({Key? key, this.name, this.imei, this.from})
      : super(key: key);

  @override
  _SummaryActivityState createState() =>
      _SummaryActivityState(name!, imei!, from!);
}

class _SummaryActivityState extends State<SummaryActivity> {
  final String? name;
  final String? imei;
  final String? from;
  String? dtf, dtt;
  String today = 'Fetching';
  String yesterday = 'Fetching';
  String before2days = 'Fetching';
  String before3days = 'Fetching';
  String before4days = 'Fetching';
  String lastweek = 'Fetching';
  String week = 'Fetching';
  String month = 'Fetching';
  String result = 'GO';
  String zeroTime = '00:00:00';
  var formatter = new intl.DateFormat('yyyy-MM-dd');

  _SummaryActivityState(this.name, this.imei, this.from);

  /// Fetch data directly from Traccar Summary API
  Future<String> fetchData(String dtf, String dtt) async {
    try {
      // 1. Convert local date string ('yyyy-MM-dd HH:mm:ss') to UTC ISO 8601 standard required by Traccar
      DateTime fromDate = DateTime.parse(dtf);
      DateTime toDate = DateTime.parse(dtt);

      String fromIso = fromDate.toUtc().toIso8601String();
      String toIso = toDate.toUtc().toIso8601String();

      // 2. Call Traccar REST API endpoint: /api/reports/summary
      var response = await NetworkHelper().requestDataFromNetworkWithTimeout(
        urlFile: '/api/reports/summary?deviceId=$imei&from=$fromIso&to=$toIso',
        context: context,
      );

      // 3. Decode Response
      dynamic data;
      if (response is String) {
        data = json.decode(response);
      } else {
        data = response;
      }

      // 4. Parse distance (meters to KM) or engineHours (ms to Hours)
      if (data != null && data is List && data.isNotEmpty) {
        var summary = data[0];

        if (from == 'engine_hours') {
          num engineHoursMs = summary['engineHours'] ?? 0;
          Duration duration = Duration(milliseconds: engineHoursMs.toInt());
          int hours = duration.inHours;
          int minutes = duration.inMinutes.remainder(60);
          return '${hours}h ${minutes}m';
        } else {
          num distanceMeters = summary['distance'] ?? 0;
          double distanceKm = distanceMeters / 1000;
          return '${distanceKm.toStringAsFixed(2)} km';
        }
      } else {
        return from == 'engine_hours' ? '0h 0m' : '0.00 km';
      }
    } catch (e) {
      print('Traccar API Error: $e');
      return 'No Data';
    }
  }

  @override
  void initState() {
    super.initState();
    dtf = '${formatter.format(DateTime.now())} $zeroTime';
    dtt =
        '${formatter.format(DateTime.now().add(Duration(days: 1)))} $zeroTime';
    initData();
  }

  void initData() async {
    fetchData('${formatter.format(DateTime.now())} $zeroTime',
            '${formatter.format(DateTime.now().add(Duration(days: 1)))} $zeroTime')
        .then((value) {
      if (mounted) {
        setState(() {
          today = '$value\nToday';
        });
      }
    });
    fetchData(
            '${formatter.format(DateTime.now().subtract(Duration(days: 1)))} $zeroTime',
            '${formatter.format(DateTime.now())} $zeroTime')
        .then((value) {
      if (mounted) {
        setState(() {
          yesterday = '$value\nYesterday';
        });
      }
    });
    fetchData(
            '${formatter.format(DateTime.now().subtract(Duration(days: 2)))} $zeroTime',
            '${formatter.format(DateTime.now())} $zeroTime')
        .then((value) {
      if (mounted) {
        setState(() {
          before2days = '$value\nLast 2 days';
        });
      }
    });
    fetchData(
            '${formatter.format(DateTime.now().subtract(Duration(days: 3)))} $zeroTime',
            '${formatter.format(DateTime.now())} $zeroTime')
        .then((value) {
      if (mounted) {
        setState(() {
          before3days = '$value\nLast 3 days';
        });
      }
    });
    fetchData(
            '${formatter.format(DateTime.now().subtract(Duration(days: 4)))} $zeroTime',
            '${formatter.format(DateTime.now())} $zeroTime')
        .then((value) {
      if (mounted) {
        setState(() {
          before4days = '$value\nLast 4 days';
        });
      }
    });
    fetchData(
            '${formatter.format(DateTime.now().subtract(Duration(days: 7)))} $zeroTime',
            '${formatter.format(DateTime.now())} $zeroTime')
        .then((value) {
      if (mounted) {
        setState(() {
          week = '$value\nThis Week';
        });
      }
    });
    fetchData(
            '${formatter.format(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day - 7))} $zeroTime',
            '${formatter.format(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day - 14))} $zeroTime')
        .then((value) {
      if (mounted) {
        setState(() {
          lastweek = '$value\nLast Week';
        });
      }
    });

    fetchData(
            '${formatter.format(DateTime.now().subtract(Duration(days: 30)))} $zeroTime',
            '${formatter.format(DateTime.now())} $zeroTime')
        .then((value) {
      if (mounted) {
        setState(() {
          month = '$value\nLast 30 Days';
        });
      }
    });
  }

  resetResultTimer() {
    Timer(Duration(seconds: 5), () {
      setState(() {
        result = 'GO';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Globals.appColor,
        elevation: 0.0,
        title: Text(
          from == 'engine_hours' ? 'ENGINE HOURS' : 'KM SUMMARY',
          style:
              TextStyle(color: Color(0xFFF6F6F6), fontFamily: 'Baloo_Thambi_2'),
        ),
        iconTheme: IconThemeData(
          color: Color(0xFFF6F6F6),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          color: Color(0xFFF6F6F6),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Container(
                width: double.infinity,
                alignment: Alignment.topLeft,
                padding: EdgeInsets.only(top: 50, left: 25, bottom: 50),
                child: AutoSizeText(
                  '${name!.toUpperCase()}',
                  minFontSize: 10,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SummaryWidget(text: today),
                  SizedBox(
                    width: 100,
                  ),
                  SummaryWidget(text: yesterday),
                ],
              ),
              SizedBox(
                height: 50,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SummaryWidget(text: before2days),
                  SizedBox(
                    width: 100,
                  ),
                  SummaryWidget(text: before3days),
                ],
              ),
              SizedBox(
                height: 50,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SummaryWidget(text: before4days),
                  SizedBox(
                    width: 100,
                  ),
                  SummaryWidget(text: week),
                ],
              ),
              SizedBox(
                height: 50,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SummaryWidget(text: lastweek),
                  SizedBox(
                    width: 100,
                  ),
                  SummaryWidget(text: month),
                ],
              ),
              Padding(
                padding:
                    EdgeInsets.only(top: 50, left: 25, bottom: 10, right: 25),
                child: Row(
                  children: <Widget>[
                    Container(
                      child: AutoSizeText(
                        from == 'engine_hours'
                            ? 'Custom Engine Hour'
                            : 'Custom Km Hour',
                        minFontSize: 10,
                        maxLines: 1,
                        textAlign: TextAlign.start,
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat'),
                      ),
                    ),
                    Spacer(),
                    InkWell(
                      onTap: () {
                        var formatter = new intl.DateFormat('yyyy-MM-dd');
                        setState(() {
                          dtf = '${formatter.format(DateTime.now())} $zeroTime';
                          dtt =
                              '${formatter.format(DateTime.now().add(Duration(days: 1)))} $zeroTime';
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.only(right: 10),
                        child: AutoSizeText(
                          'Reset',
                          minFontSize: 10,
                          maxLines: 1,
                          textAlign: TextAlign.end,
                          style: TextStyle(
                              color: Globals.appColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Montserrat'),
                        ),
                      ),
                    ),
                  ],
                ),
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
                      DateTime? newDateTime = await showRoundedDatePicker(
                          context: context,
                          description: 'FROM',
                          theme: ThemeData(
                            primaryColor: Globals.appColor,
                            dialogBackgroundColor: Color(0xFFF6F6F6),
                            disabledColor: Globals.appColor,
                          ));
                      if (newDateTime != null) {
                        var formatter = new intl.DateFormat('yyyy-MM-dd');
                        DateTime? newDateTimeTo = await showRoundedDatePicker(
                            context: context,
                            description: 'TO',
                            theme: ThemeData(
                              primaryColor: Globals.appColor,
                              dialogBackgroundColor: Color(0xFFF6F6F6),
                              disabledColor: Globals.appColor,
                            ));
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
                        leftBtn: 'FROM',
                        onLeftBtn: () {},
                        context: context,
                        initialTime: TimeOfDay.now(),
                        theme: ThemeData(
                          primaryColor: Globals.appColor,
                          dialogBackgroundColor: Color(0xFFF6F6F6),
                          disabledColor: Globals.appColor,
                        ),
                      );
                      TimeOfDay? timePickedTo;
                      if (timePicked != null) {
                        timePickedTo = await showRoundedTimePicker(
                          leftBtn: 'TO',
                          onLeftBtn: () {},
                          context: context,
                          initialTime: TimeOfDay.now(),
                          theme: ThemeData(
                            primaryColor: Globals.appColor,
                            dialogBackgroundColor: Color(0xFFF6F6F6),
                            disabledColor: Globals.appColor,
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
                      String results = await fetchData(dtf!, dtt!);
                      setState(() {
                        result = results;
                      });
                      resetResultTimer();
                    },
                    height: 45,
                    maxWidth: 240,
                    progressWidget: CircularProgressIndicator(
                        backgroundColor: Globals.appColor,
                        valueColor:
                            new AlwaysStoppedAnimation<Color>(Colors.white)),
                    stateWidgets: {
                      ButtonState.success: Text(
                        'Success',
                        style: TextStyle(fontSize: 20),
                      ),
                      ButtonState.fail: Text(
                        'Fail',
                        style: TextStyle(fontSize: 20),
                      ),
                      ButtonState.loading: Text(
                        '$result',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                      ButtonState.idle: Text(
                        '$result',
                        style: TextStyle(fontSize: 20),
                      ),
                    },
                    stateColors: {
                      ButtonState.success: Colors.green,
                      ButtonState.fail: Colors.redAccent,
                      ButtonState.loading: Colors.red,
                      ButtonState.idle: Colors.blue,
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
