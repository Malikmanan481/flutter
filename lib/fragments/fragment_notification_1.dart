import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:speedotrack/activity/activity_notification_map.dart';
import 'package:speedotrack/component/component_home_screen.dart';
import 'package:speedotrack/globals.dart';
import 'package:speedotrack/model/model_notification_event.dart';

class NotificationItemModel {
  final dynamic? dateTime;
  final String? name;
  final String? status;
  final String? image;
  final String? id;

  NotificationItemModel(
      {this.dateTime, this.name, this.status, this.image, this.id});
}

class NotificationFragment extends StatefulWidget {
  @override
  _NotificationFragmentState createState() => _NotificationFragmentState();
}

class _NotificationFragmentState extends State<NotificationFragment> {
  bool isSearching = false;
  List<NotificationScreenEvent> rows = [];

  List<NotificationItemModel> notificationItemModel = [];
  List<NotificationItemModel> n = [];
  BuildContext? context1;
  Timer? _timer;

  // Traccar raw event types ko readable text me convert karne ke liye helper
  String _formatEventType(String? type) {
    if (type == null) return 'General Notification';
    switch (type) {
      case 'deviceOnline':
        return 'Device Online';
      case 'deviceOffline':
        return 'Device Offline';
      case 'deviceMoving':
        return 'Vehicle Moving';
      case 'deviceStopped':
        return 'Vehicle Stopped';
      case 'deviceOverspeed':
        return 'Speed Limit Exceeded';
      case 'geofenceEnter':
        return 'Entered Geofence';
      case 'geofenceExit':
        return 'Exited Geofence';
      case 'ignitionOn':
        return 'Ignition ON';
      case 'ignitionOff':
        return 'Ignition OFF';
      case 'alarm':
        return 'Alarm Alert';
      default:
        return type.replaceAll(RegExp(r'(?<!^)(?=[A-Z])'), ' ');
    }
  }

  // ISO DateTime String to standard format conversion
  String _formatDateTime(String? isoDateTime) {
    if (isoDateTime == null || isoDateTime.isEmpty) return 'N/A N/A';
    try {
      DateTime parsedDate = DateTime.parse(isoDateTime).toLocal();
      String dateStr =
          "${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}";
      String timeStr =
          "${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}:${parsedDate.second.toString().padLeft(2, '0')}";
      return "$dateStr $timeStr";
    } catch (e) {
      return isoDateTime.contains('T')
          ? isoDateTime.replaceAll('T', ' ').split('.')[0]
          : isoDateTime;
    }
  }

  void fetchData() async {
    try {
      String baseUrl = Globals.baseUrl ?? 'https://demo.traccar.org';
      String basicAuth = Globals.basicAuth ?? '';

      Map<String, String> headers = {
        'Accept': 'application/json',
        if (basicAuth.isNotEmpty) 'Authorization': 'Basic $basicAuth',
      };

      // 1. Fetch devices map (deviceId -> deviceName)
      var devicesResponse = await http.get(
        Uri.parse('$baseUrl/api/devices'),
        headers: headers,
      );

      Map<int, String> deviceNamesMap = {};
      if (devicesResponse.statusCode == 200) {
        List<dynamic> devicesJson = jsonDecode(devicesResponse.body);
        for (var dev in devicesJson) {
          if (dev['id'] != null) {
            deviceNamesMap[dev['id']] = dev['name'] ?? 'Device ${dev['id']}';
          }
        }
      }

      // 2. Fetch events report from Traccar API for the last 24 hours
      DateTime now = DateTime.now().toUtc();
      DateTime fromTime = now.subtract(Duration(hours: 24));

      Uri eventsUri = Uri.parse('$baseUrl/api/reports/events').replace(
        queryParameters: {
          'from': fromTime.toIso8601String(),
          'to': now.toIso8601String(),
        },
      );

      var eventsResponse = await http.get(eventsUri, headers: headers);

      if (eventsResponse.statusCode == 200 &&
          eventsResponse.body.isNotEmpty &&
          mounted) {
        List<dynamic> jsonEvents = jsonDecode(eventsResponse.body);

        for (var item in jsonEvents) {
          int deviceId = item['deviceId'] ?? 0;
          String deviceName = deviceNamesMap[deviceId] ?? 'Device $deviceId';
          String rawType = item['type'] ?? 'notification';
          String eventDesc = _formatEventType(rawType);
          String eventTimeFormatted = _formatDateTime(item['eventTime']);

          NotificationScreenEvent event = NotificationScreenEvent.fromJson({
            'eventId': item['id']?.toString() ?? '0',
            'name': deviceName,
            'type': eventDesc,
            'eventDesc': eventDesc,
            'dtTracker': eventTimeFormatted,
            'dtServer': eventTimeFormatted,
            'speed': (item['attributes']?['speed'] ?? '0').toString(),
            'lat': (item['attributes']?['latitude'] ?? '0.0').toString(),
            'lng': (item['attributes']?['longitude'] ?? '0.0').toString(),
          });

          int index = rows.indexWhere((e) => e.eventId == event.eventId);
          if (index == -1) {
            rows.add(event);
          } else if (rows[index] != event) {
            rows[index] = event;
          }
        }

        if (rows.isNotEmpty) {
          updateUI();
        }
      }
    } catch (e) {
      print("Error fetching Traccar data: $e");
    }
  }

  void updateUI() {
    if (!mounted) return;
    for (NotificationScreenEvent event in rows) {
      int index =
          notificationItemModel.indexWhere((item) => item.id == event.eventId);
      if (index == -1) {
        notificationItemModel.add(NotificationItemModel(
          dateTime: event.dtTracker.toString(),
          id: event.eventId,
          name: event.name,
          status: event.type,
          image: 'images/imeiVehicle.png',
        ));
      } else {
        notificationItemModel[index] = NotificationItemModel(
          dateTime: event.dtTracker.toString(),
          id: event.eventId,
          name: event.name,
          status: event.type,
          image: 'images/imeiVehicle.png',
        );
      }
    }
    setState(() {
      notificationItemModel = List.from(notificationItemModel);
    });
  }

  @override
  void initState() {
    super.initState();
    fetchData();
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      print("data updated");
      fetchData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context1 = context;
    var providerType = Provider.of<ProviderType>(context);
    if (providerType.searchStatus) {
      isSearching = providerType.search.isEmpty ? false : true;
      if (isSearching) {
        List<NotificationItemModel> searchFilteredList = [];
        if (rows.isNotEmpty) {
          for (int i = 0; i < rows.length; i++) {
            String name = rows[i].name ?? '';
            String status = rows[i].type ?? '';
            if (name.toLowerCase().contains(providerType.search.toLowerCase()) ||
                status.toLowerCase().contains(providerType.search.toLowerCase())) {
              searchFilteredList.add(NotificationItemModel(
                  dateTime: rows[i].dtTracker,
                  id: rows[i].eventId,
                  name: name,
                  status: status,
                  image: 'images/imeiVehicle.png'));
            }
          }
          notificationItemModel = searchFilteredList;
        }
      } else {
        updateUI();
      }
    }
    return Stack(
      children: <Widget>[
        Container(
            child: ListView.builder(
                itemCount: notificationItemModel.length,
                scrollDirection: Axis.vertical,
                physics: BouncingScrollPhysics(),
                addAutomaticKeepAlives: true,
                cacheExtent: 10000,
                itemBuilder: (context, index) {
                  bool last = notificationItemModel.length == (index + 1);
                  return Padding(
                    padding: last
                        ? EdgeInsets.only(bottom: 60)
                        : EdgeInsets.only(bottom: 0),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            CupertinoPageRoute(
                                builder: (context) => NotificationMapActivity(
                                      id: notificationItemModel[index].id!,
                                    )));
                      },
                      child: NotificationCard(
                          statusText: notificationItemModel[index].status!,
                          dateTime: notificationItemModel[index].dateTime,
                          imageURI: notificationItemModel[index].image!,
                          deviceName: notificationItemModel[index].name!),
                    ),
                  );
                })),
        Align(
          alignment: Alignment.bottomRight,
          child: Container(
              width: 50.0,
              height: 50.0,
              margin: EdgeInsets.only(bottom: 70, right: 15),
              child: new RawMaterialButton(
                  shape: new CircleBorder(),
                  elevation: 15.0,
                  fillColor: Globals.appColor,
                  child: Icon(
                    Icons.refresh,
                    size: 15,
                    color: Color(0xFFF6F6F6),
                  ),
                  onPressed: () {
                    fetchData();
                  })),
        )
      ],
    );
  }
}

class NotificationCard extends StatelessWidget {
  final String? statusText, deviceName, imageURI, dateTime;

  const NotificationCard(
      {Key? key,
      this.statusText,
      this.deviceName,
      this.imageURI,
      this.dateTime})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(5))),
      elevation: 5,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Container(
          height: 50,
          child: Row(
            children: <Widget>[
              Expanded(
                flex: 6,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      statusText!,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                      maxLines: 1,
                      style: TextStyle(
                          color: Color(0xFF7E8188),
                          fontSize: 11,
                          letterSpacing: 1.3,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Montserrat'),
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    Text(
                      deviceName!,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                      maxLines: 1,
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          letterSpacing: 1.3,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Montserrat'),
                    ),
                  ],
                ),
              ),
              Spacer(),
              Container(
                child: Image.asset(
                  "images/notify_icon.png",
                  width: 30,
                  height: 30,
                ),
              ),
              SizedBox(
                width: 20,
              ),
              Text(
                '${dateTime.toString().split(' ')[0]}\n${dateTime.toString().split(' ')[1]}',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color(0xFF7E8188),
                    fontSize: 11,
                    letterSpacing: 1.3,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Montserrat'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
