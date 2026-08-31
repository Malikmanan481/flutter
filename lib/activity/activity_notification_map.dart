import 'dart:convert';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:get/get_common/get_reset.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:speedotrack/globals.dart';
import 'package:speedotrack/helper/helper.dart';
import 'package:speedotrack/model/model_sensor.dart';
import 'package:speedotrack/network/network_api_request.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationMapActivity extends StatefulWidget {
  final String? id;

  const NotificationMapActivity({Key? key, this.id}) : super(key: key);

  @override
  _NotificationMapActivityState createState() =>
      _NotificationMapActivityState(id);
}

class _NotificationMapActivityState extends State<NotificationMapActivity> {
  final String? id;

  _NotificationMapActivityState(this.id);

  List<SensorModel> sensorModelAbove = [], sensorModelBelow = [];
  Color colorPolyline = Globals.appColor;
  GoogleMapController? _controller;
  String? lat;
  String? lng;
  LatLng? latLng;
  bool loading = true;
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  bool trafficStatus = false,
      mapTypeEnabled = Globals.prefs!.getBool('mapHybrid')!;

  void fetchData() async {
    try {
      String eventType = 'Event';
      String eventTimeStr = '';
      int deviceId = 0;
      int positionId = 0;

      // 1. Fetch Event details from Traccar API
      var eventResp = await NetworkHelper().requestDataFromNetworkWithTimeoutGET(
        urlFile: '/api/events/$id',
        body: {},
        context: context,
      );

      if (eventResp != null && eventResp.isNotEmpty) {
        var eventData = json.decode(eventResp);
        eventType = eventData['type'] ?? 'Event';
        eventTimeStr = eventData['eventTime'] ?? eventData['serverTime'] ?? '';
        deviceId = eventData['deviceId'] ?? 0;
        positionId = eventData['positionId'] ?? 0;
      }

      // 2. Fetch Position details
      double posLat = 0.0;
      double posLng = 0.0;
      double rawSpeed = 0.0;
      int course = 0;

      Map<String, String> posParams =
          positionId > 0 ? {'id': '$positionId'} : {'id': '$id'};

      var posResp = await NetworkHelper().requestDataFromNetworkWithTimeoutGET(
        urlFile: '/api/positions',
        body: posParams,
        context: context,
      );

      if (posResp != null && posResp.isNotEmpty) {
        var posList = json.decode(posResp);
        var posData = (posList is List && posList.isNotEmpty)
            ? posList[0]
            : (posList is Map ? posList : null);

        if (posData != null) {
          posLat = (posData['latitude'] as num?)?.toDouble() ?? 0.0;
          posLng = (posData['longitude'] as num?)?.toDouble() ?? 0.0;
          rawSpeed = (posData['speed'] as num?)?.toDouble() ?? 0.0; // speed in knots
          course = (posData['course'] as num?)?.toInt() ?? 0;

          if (eventTimeStr.isEmpty) {
            eventTimeStr = posData['fixTime'] ?? posData['deviceTime'] ?? '';
          }
          if (deviceId == 0) {
            deviceId = posData['deviceId'] ?? 0;
          }
        }
      }

      lat = posLat.toString();
      lng = posLng.toString();

      // 3. Fetch Device details (for Name and IMEI/uniqueId)
      String deviceName = 'Device';
      String imei = '$deviceId';

      if (deviceId > 0) {
        var devResp = await NetworkHelper().requestDataFromNetworkWithTimeoutGET(
          urlFile: '/api/devices/$deviceId',
          body: {},
          context: context,
        );

        if (devResp != null && devResp.isNotEmpty) {
          var devData = json.decode(devResp);
          deviceName = devData['name'] ?? 'Device';
          imei = devData['uniqueId'] ?? '$deviceId';
        }
      }

      // 4. Fetch Address via Traccar Reverse Geocode API
      String address = '';
      var responseAddress = await NetworkHelper().requestDataFromNetwork(
        urlFile: '/api/server/geocode',
        body: {'latitude': lat, 'longitude': lng},
        context: context,
      );

      if (responseAddress != null && responseAddress.isNotEmpty) {
        address = responseAddress.replaceAll('\\', '').replaceAll('"', '');
      }

      // Speed calculation (Traccar speed in knots to km/h)
      int speedKmh = (rawSpeed * 1.852).round();
      String speedStr = '${speedKmh}km/h';

      // Format Date
      String formattedDate = '';
      if (eventTimeStr.isNotEmpty) {
        try {
          DateTime time = DateTime.parse(eventTimeStr).toLocal();
          formattedDate = DateFormat('dd-MM-yyyy HH:mm:ss').format(time);
        } catch (_) {
          formattedDate = eventTimeStr;
        }
      }

      latLng = LatLng(posLat, posLng);
      final MarkerId markerId = MarkerId(imei);

      String iconKey = Globals.prefs!.getString('${imei}_icons') ?? 'default';

      BitmapDescriptor bitmapDescriptor = await Helper().getMarker(
        context,
        'm',
        'Object:  $deviceName \n Event:   $eventType \n Address: $address \n Speed:   $speedStr \n Time:    $formattedDate',
        course,
        speedKmh,
        'images/${Helper().getMarkerName('m', iconKey)}',
      );

      markers.removeWhere((key, value) => key == markerId);
      markers[markerId] = Marker(
        position: latLng!,
        icon: bitmapDescriptor,
        anchor: Offset(0.5, 0.675),
        markerId: markerId,
      );

      try {
        CameraPosition cPosition = CameraPosition(zoom: 17, target: latLng!);
        _controller?.animateCamera(CameraUpdate.newCameraPosition(cPosition));
      } catch (e) {}
    } catch (e) {
      debugPrint('Error fetching notification event details: $e');
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        title: Text(
          'notification'.tr,
          style: TextStyle(
              color: mapTypeEnabled ? Color(0xFFF6F6F6) : Globals.appColor,
              fontFamily: 'Baloo_Thambi_2'),
        ),
        iconTheme: IconThemeData(
          color: mapTypeEnabled
              ? Color(0xFFF6F6F6)
              : Globals.appColor, //change your color here
        ),
      ),
      body: Stack(
        children: <Widget>[
          GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(20.5937, 78.9629),
              ),
              compassEnabled: false,
              buildingsEnabled: true,
              mapToolbarEnabled: false,
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
                new Factory<OneSequenceGestureRecognizer>(
                  () => new EagerGestureRecognizer(),
                ),
              ].toSet(),
              markers: Set<Marker>.of(markers.values),
              // YOUR MARKS IN MAP
              mapType: mapTypeEnabled ? MapType.hybrid : MapType.normal,
              zoomControlsEnabled: false,
              trafficEnabled: trafficStatus,
              myLocationButtonEnabled: false,
              onMapCreated: (GoogleMapController controller) {
                _controller = controller;
              }),
          Container(
            margin: EdgeInsets.only(top: 70),
            alignment: Alignment.topRight,
            child: Column(
              children: <Widget>[
                Container(
                  width: 40.0,
                  height: 40.0,
                  margin: EdgeInsets.only(right: 10, top: 10),
                  child: new RawMaterialButton(
                    shape: new CircleBorder(),
                    elevation: 15.0,
                    fillColor:
                        mapTypeEnabled ? Globals.appColor : Color(0xFFF6F6F6),
                    child: Image.asset(
                      'images/mapType.png',
                      height: 15,
                      width: 15,
                      color:
                          mapTypeEnabled ? Color(0xFFF6F6F6) : Globals.appColor,
                    ),
                    onPressed: () {
                      mapTypeEnabled
                          ? Globals.prefs!.setBool('mapHybrid', false)
                          : Globals.prefs!.setBool('mapHybrid', true);
                      setState(() {
                        mapTypeEnabled = Globals.prefs!.getBool('mapHybrid')!;
                      });
                    },
                  ),
                ),
                Container(
                  width: 40.0,
                  height: 40.0,
                  margin: EdgeInsets.only(right: 10, top: 10),
                  child: new RawMaterialButton(
                    shape: new CircleBorder(),
                    elevation: 15.0,
                    fillColor:
                        trafficStatus ? Globals.appColor : Color(0xFFF6F6F6),
                    child: Icon(
                      Icons.traffic,
                      color:
                          trafficStatus ? Color(0xFFF6F6F6) : Globals.appColor,
                      size: 15,
                    ),
                    onPressed: () {
                      setState(() {
                        trafficStatus = !trafficStatus;
                      });
                    },
                  ),
                ),
                Container(
                  width: 40.0,
                  height: 40.0,
                  margin: EdgeInsets.only(right: 10, top: 10),
                  child: new RawMaterialButton(
                    shape: new CircleBorder(),
                    elevation: 15.0,
                    fillColor: Color(0xFFF6F6F6),
                    child: Icon(
                      FontAwesomeIcons.directions,
                      color: Globals.appColor,
                      size: 15,
                    ),
                    onPressed: () =>
                        openMap(double.parse(lat!), double.parse(lng!)),
                  ),
                ),
                Container(
                  width: 40.0,
                  height: 40.0,
                  margin: EdgeInsets.only(right: 10, top: 10),
                  child: new RawMaterialButton(
                    shape: new CircleBorder(),
                    elevation: 15.0,
                    fillColor: Color(0xFFF6F6F6),
                    child: Icon(
                      FontAwesomeIcons.streetView,
                      color: Globals.appColor,
                      size: 15,
                    ),
                    onPressed: () =>
                        openMapStreet(double.parse(lat!), double.parse(lng!)),
                  ),
                ),
              ],
            ),
          ),
          Visibility(
              visible: loading,
              child: Center(
                child: CircularProgressIndicator(
                    valueColor: new AlwaysStoppedAnimation<Color>(
                  Globals.appColor,
                )),
              ))
        ],
      ),
    );
  }

  static Future<void> openMap(double latitude, double longitude) async {
    String googleUrl =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    if (await canLaunch(googleUrl)) {
      await launch(googleUrl);
    } else {
      throw 'Could not open the map.';
    }
  }

  static Future<void> openMapStreet(double latitude, double longitude) async {
    String googleUrl = 'google.streetview:cbll=$latitude,$longitude';
    if (await canLaunch(googleUrl)) {
      await launch(googleUrl);
    } else {
      throw 'Could not open the map.';
    }
  }
}
