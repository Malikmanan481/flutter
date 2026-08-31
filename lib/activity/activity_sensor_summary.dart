import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:custom_progress_button/custom_progress_button.dart';
import 'package:flutter_rounded_date_picker/flutter_rounded_date_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:speedotrack/component/component_summary_widget.dart';
import 'package:speedotrack/model/model_settings_fn.dart';
import 'package:speedotrack/network/network_api_request.dart';

import '../globals.dart';

class SensorSummaryActivity extends StatefulWidget {
  final String? name;
  final String? imei;
  final String? from;

  const SensorSummaryActivity({Key? key, this.name, this.imei, this.from})
      : super(key: key);

  @override
  _SensorSummaryActivityState createState() => _SensorSummaryActivityState();
}

class _SensorSummaryActivityState extends State<SensorSummaryActivity> {
  List<String> sensorList = [];
  String? dtf, dtt;
  String today = 'loading'.tr;
  String yesterday = 'loading'.tr;
  String week = 'loading'.tr;
  String month = 'loading'.tr;
  String result = 'GO';
  String zeroTime = '00:00:00';
  var formatter = intl.DateFormat('yyyy-MM-dd');
  String sensorName = '';

  DropdownButton<String> androidSensorDropDown() {
    List<DropdownMenuItem<String>> dropdownItems = [];
    for (int i = 0; i < sensorList.length; i++) {
      var newItem = DropdownMenuItem(
        child: Text(sensorList[i]),
        value: sensorList[i],
      );
      dropdownItems.add(newItem);
    }

    return DropdownButton<String>(
      value: sensorName,
      items: dropdownItems,
      dropdownColor: Colors.white,
      onChanged: (value) {
        if (value != null) {
          setState(() {
            sensorName = value;
          });
          initData();
        }
      },
    );
  }

  // Directly Connects to Traccar REST API (/api/reports/summary)
  Future<String> fetchData(String dtfStr, String dttStr) async {
    try {
      // Parse local string dates to UTC ISO 8601 strings required by Traccar API
      DateTime fromDate = intl.DateFormat('yyyy-MM-dd HH:mm:ss').parse(dtfStr).toUtc();
      DateTime toDate = intl.DateFormat('yyyy-MM-dd HH:mm:ss').parse(dttStr).toUtc();

      String fromIso = fromDate.toIso8601String();
      String toIso = toDate.toIso8601String();

      // Traccar REST API endpoint query
      String url = '/api/reports/summary?deviceId=${widget.imei}&from=$fromIso&to=$toIso';

      var response = await NetworkHelper().requestDataFromNetworkWithTimeout(
        urlFile: url,
        body: {},
        context: context,
      );

      if (response != null && response.isNotEmpty) {
        var decodedData = jsonDecode(response);
        if (decodedData is List && decodedData.isNotEmpty) {
          var summaryItem = decodedData.first;
          
          // Traccar returns engineHours in milliseconds
          int engineHoursMs = summaryItem['engineHours'] ?? summaryItem['duration'] ?? 0;

          if (engineHoursMs > 0) {
            Duration duration = Duration(milliseconds: engineHoursMs);
            int totalHours = duration.inHours;
            int minutes = duration.inMinutes.remainder(60);
            int seconds = duration.inSeconds.remainder(60);

            return '$totalHours H $minutes M $seconds S';
          }
        }
      }
      return 'noDataItem'.tr;
    } catch (e) {
      return 'noDataItem'.tr;
    }
  }

  @override
  void initState() {
    super.initState();

    String? settingsPref = Globals.prefs!.getString('${widget.imei}_settings');
    if (settingsPref != null) {
      try {
        VehicleSettingsModel vehicleSettingsModel =
            VehicleSettingsModel.fromJson(jsonDecode(settingsPref));

        Map<String, Sensors> sensorsJsonObject = vehicleSettingsModel.sensors ?? {};
        List<String> sensorsKeysJsonArray = sensorsJsonObject.keys.toList();

        for (int j = 0; j < sensorsKeysJsonArray.length; j++) {
          String sensorID = sensorsKeysJsonArray[j];
          Sensors sensorJsonObject = sensorsJsonObject[sensorID]!;
          String sensorNameT = sensorJsonObject.name ?? '';
          String sensorType = sensorJsonObject.resultType ?? '';
          if (sensorType == 'logic') {
            sensorList.add(sensorNameT);
          }
        }
      } catch (e) {
        // Fallback if sensor JSON parsing fails
      }
    }

    if (sensorList.isNotEmpty) {
      sensorName = sensorList[0];
    }

    dtf = '${formatter.format(DateTime.now())} $zeroTime';
    dtt = '${formatter.format(DateTime.now().add(const Duration(days: 1)))} $zeroTime';
    initData();
  }

  void initData() async {
    setState(() {
      today = 'loading'.tr;
      yesterday = 'loading'.tr;
      week = 'loading'.tr;
      month = 'loading'.tr;
    });

    fetchData('${formatter.format(DateTime.now())} $zeroTime',
            '${formatter.format(DateTime.now().add(const Duration(days: 1)))} $zeroTime')
        .then((value) {
      if (mounted) {
        setState(() {
          today = '$value\n${'today'.tr}';
        });
      }
    });

    fetchData(
            '${formatter.format(DateTime.now().subtract(const Duration(days: 1)))} $zeroTime',
            '${formatter.format(DateTime.now())} $zeroTime')
        .then((value) {
      if (mounted) {
        setState(() {
          yesterday = '$value\n${'yesterday'.tr}';
        });
      }
    });

    fetchData(
            '${formatter.format(DateTime.now().subtract(const Duration(days: 7)))} $zeroTime',
            '${formatter.format(DateTime.now())} $zeroTime')
        .then((value) {
      if (mounted) {
        setState(() {
          week = '$value\n${'sevendays'.tr}';
        });
      }
    });

    fetchData(
            '${formatter.format(DateTime.now().subtract(const Duration(days: 30)))} $zeroTime',
            '${formatter.format(DateTime.now())} $zeroTime')
        .then((value) {
      if (mounted) {
        setState(() {
          month = '$value\n${'threezerodays'.tr}';
        });
      }
    });
  }

  resetResultTimer() {
    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          result = 'GO'.tr;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Globals.appColor,
        elevation: 0.0,
        title: Text(
          'logicSensors'.tr,
          style: const TextStyle(
              color: Color(0xFFF6F6F6), fontFamily: 'Baloo_Thambi_2'),
        ),
        iconTheme: const IconThemeData(
          color: Color(0xFFF6F6F6),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          color: Colors.white,
          child: Column(
            children: <Widget>[
              Container(
                width: double.infinity,
                alignment: Alignment.topLeft,
                padding: const EdgeInsets.only(top: 50, left: 25, bottom: 50),
                child: Text(
                  widget.name ?? '',
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat'),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SummaryWidget(text: today),
                  const SizedBox(width: 100),
                  SummaryWidget(text: yesterday),
                ],
              ),
              const SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SummaryWidget(text: week),
                  const SizedBox(width: 100),
                  SummaryWidget(text: month),
                ],
              ),
              Container(
                padding: const EdgeInsets.only(top: 50, left: 25, bottom: 10, right: 25),
                width: double.infinity,
                child: Text(
                  'reportsType'.tr,
                  maxLines: 1,
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat'),
                ),
              ),
              if (sensorList.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(left: 25, right: 25, bottom: 10),
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                      border: Border.all(color: Globals.appColor, width: 2),
                      borderRadius: const BorderRadius.all(Radius.circular(5))),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Center(child: androidSensorDropDown()),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 10, left: 25, bottom: 10, right: 25),
                child: Row(
                  children: <Widget>[
                    Text(
                      'customSensorData'.tr,
                      maxLines: 1,
                      textAlign: TextAlign.start,
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Montserrat'),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () {
                        setState(() {
                          dtf = '${formatter.format(DateTime.now())} $zeroTime';
                          dtt = '${formatter.format(DateTime.now().add(const Duration(days: 1)))} $zeroTime';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.only(right: 10),
                        child: Text(
                          'reset'.tr,
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
                margin: const EdgeInsets.only(left: 25, right: 25),
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                    border: Border.all(color: Globals.appColor, width: 2),
                    borderRadius: const BorderRadius.all(Radius.circular(5))),
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
                          dtf = '${formatter.format(newDateTime)} ${dtf!.split(' ')[1]}';
                          if (newDateTimeTo != null) {
                            dtt = '${formatter.format(newDateTimeTo)} ${dtt!.split(' ')[1]}';
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
                                style: const TextStyle(
                                    color: Color(0xFF7E8188),
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                          ),
                          const Spacer(),
                          const Icon(
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
                margin: const EdgeInsets.only(left: 25, right: 25, top: 10),
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                    border: Border.all(color: Globals.appColor, width: 2),
                    borderRadius: const BorderRadius.all(Radius.circular(5))),
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
                          dtf = '${dtf!.split(regex)[0]} ${timePicked.hour}:${timePicked.minute}:00';
                        }
                        if (timePickedTo != null) {
                          dtt = '${dtt!.split(regex)[0]} ${timePickedTo.hour}:${timePickedTo.minute}:00';
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
                                style: const TextStyle(
                                    color: Color(0xFF7E8188),
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                          ),
                          const Spacer(),
                          const Icon(
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
                    stateColors: const {
                      ButtonState.success: Colors.green,
                      ButtonState.fail: Colors.redAccent,
                      ButtonState.loading: Colors.red,
                      ButtonState.idle: Globals.appColor,
                    },
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
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white)),
                    stateWidgets: {
                      ButtonState.success: Text(
                        'success'.tr,
                        style: const TextStyle(fontSize: 20),
                      ),
                      ButtonState.fail: Text(
                        'failure'.tr,
                        style: const TextStyle(fontSize: 20),
                      ),
                      ButtonState.loading: Text(
                        result,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                      ButtonState.idle: Text(
                        'proceed'.tr,
                        style: const TextStyle(fontSize: 20, color: Colors.white),
                      ),
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
