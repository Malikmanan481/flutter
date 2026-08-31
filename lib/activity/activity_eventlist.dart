import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:progress_dialog_null_safe/progress_dialog_null_safe.dart';
import 'package:rxdart/subjects.dart';
import 'package:speedotrack/activity/activity_about_us.dart';
import 'package:speedotrack/globals.dart';
import 'package:speedotrack/network/network_api_request.dart';

class EventList {
  final String id;
  final String name;
  final bool active;
  final Map<String, dynamic>? rawData;

  EventList(this.id, this.name, this.active, {this.rawData});
}

class EventListActivity extends StatefulWidget {
  @override
  _EventListActivityState createState() => _EventListActivityState();
}

class _EventListActivityState extends State<EventListActivity> {
  StreamController<List<EventList>> _eventListStreamController =
      BehaviorSubject();

  Stream<List<EventList>> get eventListStream =>
      _eventListStreamController.stream;

  StreamSink<List<EventList>> get eventListSink =>
      _eventListStreamController.sink;
  List<EventList> eventList = [];
  List<String> nameList = [];
  Map<String, EventList> zoneList = {};

  /// Connected to Traccar REST API GET /api/notifications
  void fetchData() async {
    try {
      var response = await NetworkHelper().requestDataFromNetwork(
          urlFile: '/api/notifications',
          context: context);

      eventList.clear();
      nameList.clear();

      if (response != null) {
        dynamic decoded = response is String ? jsonDecode(response) : response;

        if (decoded is List) {
          for (var item in decoded) {
            String id = item['id'].toString();
            String name = item['type'] ?? 'Notification';
            bool active = item['always'] ?? true;

            nameList.add(name.toLowerCase());
            eventList.add(EventList(id, name, active, rawData: Map<String, dynamic>.from(item)));
          }
        }
      }
    } catch (e) {
      // Handle network errors silently to maintain app stability
    }

    eventListSink.add(eventList);
    if (pr != null && pr!.isShowing()) {
      pr!.hide();
    }
  }

  ProgressDialog? pr;
  @override
  void initState() {
    super.initState();
    pr = new ProgressDialog(context,
        type: ProgressDialogType.normal, isDismissible: false, showLogs: false);
    fetchData();
  }

  @override
  void dispose() {
    _eventListStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Globals.appColor,
        elevation: 0.0,
        title: Text(
          'notificationSettings'.tr,
          style:
              TextStyle(color: Color(0xFFF6F6F6), fontFamily: 'Baloo_Thambi_2'),
        ),
        iconTheme: IconThemeData(
          color: Color(0xFFF6F6F6), //change your color here
        ),
      ),
      body: Container(
        color: Color(0xFFF6F6F6),
        child: StreamBuilder<List<EventList>>(
            stream: eventListStream,
            builder: (context, snapshot) {
              if (snapshot.data == null || snapshot.hasError) {
                return Center(
                    child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'fetchData'.tr,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Globals.appColor,
                          fontSize: 14,
                          decoration: TextDecoration.none,
                          letterSpacing: 1,
                          fontFamily: 'Montserrat'),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 10, left: 40, right: 40),
                      child: CircularProgressIndicator(
                        backgroundColor: Colors.transparent,
                        strokeWidth: 3,
                        valueColor:
                            new AlwaysStoppedAnimation<Color>(Globals.appColor),
                      ),
                    ),
                  ],
                ));
              }
              if (snapshot.data!.length == 0) {
                return Center(
                    child: Text(
                  'noEventDataFound'.tr,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Globals.appColor,
                      fontSize: 14,
                      decoration: TextDecoration.none,
                      letterSpacing: 1,
                      fontFamily: 'Montserrat'),
                ));
              } else {
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  scrollDirection: Axis.vertical,
                  addAutomaticKeepAlives: true,
                  physics: BouncingScrollPhysics(),
                  cacheExtent: 10000,
                  itemBuilder: (context, index) {
                    bool last = snapshot.data!.length == (index + 1);
                    return Padding(
                      padding: last
                          ? EdgeInsets.only(bottom: 60)
                          : EdgeInsets.only(bottom: 0),
                      child: InkWell(
                          onTap: () {},
                          child: Card(
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(5))),
                            elevation: 5,
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Container(
                                height: 50,
                                child: Row(
                                  children: [
                                    Text(
                                      snapshot.data![index].name,
                                      textAlign: TextAlign.start,
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                          letterSpacing: 1.3,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Montserrat'),
                                    ),
                                    Spacer(),
                                    Spacer(),
                                    Switch(
                                        activeColor: Color(0xFFF6F6F6),
                                        activeTrackColor: Colors.green,
                                        inactiveThumbColor: Color(0xFFF6F6F6),
                                        inactiveTrackColor: Colors.red,
                                        value: snapshot.data![index].active,
                                        onChanged: (value) async {
                                          pr!.show();

                                          Map<String, dynamic> updateBody =
                                              snapshot.data![index].rawData != null
                                                  ? Map<String, dynamic>.from(snapshot.data![index].rawData!)
                                                  : {
                                                      'id': int.tryParse(snapshot.data![index].id),
                                                      'type': snapshot.data![index].name,
                                                    };

                                          updateBody['always'] = value;

                                          /// Connected to Traccar PUT /api/notifications/{id}
                                          var response = await NetworkHelper()
                                              .requestDataFromNetwork(
                                                  urlFile:
                                                      '/api/notifications/${snapshot.data![index].id}',
                                                  body: updateBody,
                                                  context: context);

                                          if (response != null &&
                                              response.toString().toLowerCase() != 'error') {
                                            fetchData();
                                          } else {
                                            if (pr!.isShowing()) pr!.hide();
                                          }
                                        })
                                  ],
                                ),
                              ),
                            ),
                          )),
                    );
                  },
                );
              }
            }),
      ),
    );
  }
}
