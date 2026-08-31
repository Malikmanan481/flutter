import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:speedotrack/activity/activity_about_us.dart';
import 'package:speedotrack/model/model_command_history.dart' as CH;
import 'package:speedotrack/network/network_api_request.dart';

import '../globals.dart';

class CommandHistoryItem {
  final String name;
  final String command;
  final String dateTime;
  final String commandName;

  CommandHistoryItem(this.name, this.command, this.dateTime, this.commandName);
}

class CommandHistoryActivity extends StatefulWidget {
  @override
  _CommandHistoryActivityState createState() => _CommandHistoryActivityState();
}

class _CommandHistoryActivityState extends State<CommandHistoryActivity> {
  List<CommandHistoryItem> commandHistoryList = [];

  CH.CommandHistory commandHistoryFromJson(String str) =>
      CH.CommandHistory.fromJson(json.decode(str));

  // ==================== TRACCAR API INTEGRATION ====================
  void fetchData() async {
    commandHistoryList.clear();
    try {
      DateTime now = DateTime.now();
      DateTime fromDate = now.subtract(Duration(days: 30));

      String fromIso = fromDate.toUtc().toIso8601String();
      String toIso = now.toUtc().toIso8601String();

      // Traccar REST API Call for command events/history
      var response = await NetworkHelper().requestDataFromNetworkWithTimeoutGET(
        urlFile: 'api/reports/events?from=$fromIso&to=$toIso&type=commandResult',
        context: context,
      );

      if (response != null && response.isNotEmpty) {
        var parsed = response is String ? jsonDecode(response) : response;
        if (parsed is List) {
          for (var item in parsed) {
            String eventTimeStr = item['eventTime'] ?? '';
            String formattedDate = '';

            if (eventTimeStr.isNotEmpty) {
              try {
                DateTime dt = DateTime.parse(eventTimeStr).toLocal();
                formattedDate =
                    intl.DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
              } catch (_) {
                formattedDate = eventTimeStr.replaceAll('T', ' ').split('.')[0];
              }
            } else {
              formattedDate = intl.DateFormat('yyyy-MM-dd HH:mm:ss')
                  .format(DateTime.now());
            }

            Map<String, dynamic> attributes =
                item['attributes'] is Map ? item['attributes'] : {};

            String cmdText = attributes['data'] ??
                attributes['result'] ??
                item['type'] ??
                'Command';
            String cmdResult = attributes['result'] ??
                attributes['data'] ??
                'Executed';
            String cmdType = item['type'] ?? 'GPRS';

            commandHistoryList.add(CommandHistoryItem(
              cmdResult,
              cmdText,
              formattedDate,
              cmdType,
            ));
          }
        }
      }
    } catch (e) {
      // Handle error gracefully without crashing
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Globals.appColor,
        elevation: 0.0,
        title: Text(
          'commandHistory'.tr,
          style:
              TextStyle(color: Color(0xFFF6F6F6), fontFamily: 'Baloo_Thambi_2'),
        ),
        iconTheme: IconThemeData(
          color: Color(0xFFF6F6F6), //change your color here
        ),
      ),
      body: Container(
        color: Color(0xFFF6F6F6),
        child: ListView.builder(
          addAutomaticKeepAlives: false,
          itemCount: commandHistoryList.length,
          physics: BouncingScrollPhysics(),
          shrinkWrap: true,
          scrollDirection: Axis.vertical,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.only(left: 5, right: 5, top: 5, bottom: 5),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5))),
                color: Color(0xFFF6F6F6),
                child: Container(
                  padding: const EdgeInsets.all(10.0),
                  height: 70,
                  child: Row(
                    children: <Widget>[
                      Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            commandHistoryList[index].command,
                            textAlign: TextAlign.start,
                            style: TextStyle(
                                color: Color(0xFF7E8188),
                                fontSize: 12,
                                letterSpacing: 1.3,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Montserrat'),
                          ),
                          SizedBox(
                            height: 5,
                          ),
                          Text(
                            commandHistoryList[index].name,
                            textAlign: TextAlign.start,
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                letterSpacing: 1.3,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Montserrat'),
                          ),
                        ],
                      ),
                      Spacer(),
                      Container(
                        child: Image.asset('images/lock.png'),
                        height: 30,
                        width: 30,
                      ),
                      SizedBox(
                        width: 20,
                      ),
                      Text(
                        '${commandHistoryList[index].dateTime.toString().split(' ')[0]}\n${commandHistoryList[index].dateTime.toString().split(' ')[1]}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Color(0xFF7E8188),
                            fontSize: 12,
                            letterSpacing: 1.3,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
