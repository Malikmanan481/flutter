import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart' as intl;
import 'package:latlong2/latlong.dart' as latLong;
import 'package:intl/intl.dart';
import 'package:rxdart/subjects.dart';
import 'package:speedotrack/activity/bloc/custom_info_widget.dart';
import 'package:speedotrack/component/component_speedometer.dart';
import 'package:speedotrack/globals.dart';
import 'package:speedotrack/helper/helper.dart';
import 'package:speedotrack/model/model_history.dart';
import 'package:speedotrack/network/network_api_request.dart';

class HistoryMapModel {
  final String speed;
  final String altitude;
  final String angle;
  final String time;
  final LatLng latLng;

  HistoryMapModel(
      this.speed, this.altitude, this.angle, this.time, this.latLng);
}

class HistoryTopDataModel {
  final String speed;
  final String time;
  final bool isPlaying;

  HistoryTopDataModel(this.speed, this.time, this.isPlaying);
}

class HistoryMapActivity extends StatefulWidget {
  final String? name;
  final String? imei;
  final String? stop;
  final String? from;
  final String? dtf;
  final String? dtt;
  final bool? parking;

  HistoryMapActivity(
      {Key? key,
      this.name,
      this.imei,
      this.from,
      this.dtf,
      this.dtt,
      this.stop,
      this.parking})
      : super(key: key);

  @override
  _HistoryMapActivityState createState() => _HistoryMapActivityState(
      name!, imei!, from!, dtf!, dtt!, stop!, parking);
}

class _HistoryMapActivityState extends State<HistoryMapActivity>
    with TickerProviderStateMixin {
  final String? name;
  final String? imei;
  final String? from;
  final String? dtf;
  final String? stop;
  final String? dtt;
  final bool? parking;
  double zoomLevel = 14;
  dynamic routeLength = 0.0;
  String? duration = '0h 0m';
  int? topSpeed = 0;
  int? avgSpeed = 0;
  int playSpeed = 500;
  int playPosition = 0;
  String speed = '0', time = '';
  String startAddress = 'fetching'.tr, endAddress = 'fetching'.tr;
  List<dynamic>? routeList = [];
  List<dynamic>? stopsList = [];
  List<dynamic>? driveValueList = [];
  List<dynamic>? historyList = [];
  List<HistoryMapModel>? historyMapModelList = [];
  List<MarkerId>? markerParkingList = [];
  List<LatLng>? stopsLinkedList = [];
  List<LatLng>? listPlaying = [];
  GoogleMapController? _controller;
  final Set<Polyline> _polyline = {};
  final Set<Polyline> _polylinePlaying = {};
  Color colorPolyline = Globals.appColor;
  LatLng latLng = LatLng(20.5937, 78.9629);
  bool isLoading = true;
  bool polyLineShown = false;
  int count = 0;
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  bool trafficStatus = false,
      mapTypeEnabled = Globals.prefs!.getBool('mapHybrid') ?? false;
  bool isPlaying = false, isParkingMarkerShowing = true;
  BitmapDescriptor? bitmapDescriptor;
  final MarkerId markerIdMover = MarkerId('Mover');
  Timer? _timer;
  List<LatLng>? list = [];
  Window? window;
  bool show = false;
  double currentZoom = 16;

  LatLng previousLatLng = LatLng(0.0, 0.0);
  LatLng currentLatLng = LatLng(0.0, 0.0);

  _HistoryMapActivityState(this.name, this.imei, this.from, this.dtf, this.dtt,
      this.stop, this.parking);

  StreamController<HistoryTopDataModel> _historyTopDataModelStreamController =
      BehaviorSubject();
  Stream<HistoryTopDataModel> get historyTopStream =>
      _historyTopDataModelStreamController.stream;
  StreamSink<HistoryTopDataModel> get historyTopSink =>
      _historyTopDataModelStreamController.sink;
  PublishSubject<double> eventObservable = PublishSubject();
  Completer<GoogleMapController> _googleMapController = new Completer();
  double _mapOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  LatLngBounds getBounds(List<LatLng> latLngList) {
    var lngs = latLngList.map<double>((m) => m.longitude).toList();
    var lats = latLngList.map<double>((m) => m.latitude).toList();

    double topMost = lngs.reduce(max);
    double leftMost = lats.reduce(min);
    double rightMost = lats.reduce(max);
    double bottomMost = lngs.reduce(min);

    LatLngBounds bounds = LatLngBounds(
      northeast: LatLng(rightMost, topMost),
      southwest: LatLng(leftMost, bottomMost),
    );
    return bounds;
  }

  String _formatToIsoDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      DateTime dt = DateTime.parse(dateStr);
      return dt.toUtc().toIso8601String();
    } catch (e) {
      return dateStr;
    }
  }

  String _formatMsToDuration(int ms) {
    Duration d = Duration(milliseconds: ms);
    int hours = d.inHours;
    int minutes = d.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  String _formatIsoToTimeStr(String? isoStr) {
    if (isoStr == null || isoStr.isEmpty) return '';
    try {
      DateTime dt = DateTime.parse(isoStr).toLocal();
      return intl.DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
    } catch (e) {
      return isoStr;
    }
  }

  void fetchData() async {
    String deviceId = (imei != null && imei!.isNotEmpty) ? imei! : (from ?? '');
    String fromIso = _formatToIsoDate(dtf);
    String toIso = _formatToIsoDate(dtt);

    try {
      // 1. Fetch Route Positions from Traccar API
      var routeResponse = await NetworkHelper().requestDataFromNetworkWithTimeout(
          urlFile: '/api/reports/route?deviceId=$deviceId&from=$fromIso&to=$toIso',
          body: {},
          context: context);

      // 2. Fetch Summary Statistics from Traccar API
      var summaryResponse = await NetworkHelper().requestDataFromNetworkWithTimeout(
          urlFile: '/api/reports/summary?deviceId=$deviceId&from=$fromIso&to=$toIso',
          body: {},
          context: context);

      // 3. Fetch Stops Data from Traccar API
      var stopsResponse = await NetworkHelper().requestDataFromNetworkWithTimeout(
          urlFile: '/api/reports/stops?deviceId=$deviceId&from=$fromIso&to=$toIso',
          body: {},
          context: context);

      if (routeResponse.isNotEmpty) {
        List<dynamic> positionsData = json.decode(routeResponse);
        if (positionsData.isEmpty) {
          Fluttertoast.showToast(
              msg: 'noData'.tr,
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Globals.appColor,
              textColor: Colors.white,
              fontSize: 16.0);
          Navigator.pop(context);
          return;
        }

        routeList = positionsData;

        // Parse Summary Data
        if (summaryResponse.isNotEmpty) {
          List<dynamic> summaryData = json.decode(summaryResponse);
          if (summaryData.isNotEmpty) {
            var summary = summaryData[0];
            routeLength = ((summary['distance'] ?? 0.0) / 1000.0); // Meters to KM
            topSpeed = (((summary['maxSpeed'] ?? 0.0) * 1.852)).round(); // Knots to KM/H
            avgSpeed = (((summary['averageSpeed'] ?? 0.0) * 1.852)).round(); // Knots to KM/H
            
            int engineHoursMs = (summary['engineHours'] ?? 0).toInt();
            int durationMs = engineHoursMs > 0 ? engineHoursMs : (summary['duration'] ?? 0).toInt();
            duration = _formatMsToDuration(durationMs);
          }
        }

        // Parse Stops Data
        if (stopsResponse.isNotEmpty) {
          stopsList = json.decode(stopsResponse);
          for (int i = 0; i < stopsList!.length; i++) {
            var stopItem = stopsList![i];
            double sLat = (stopItem['lat'] ?? stopItem['latitude'] ?? 0.0).toDouble();
            double sLng = (stopItem['lon'] ?? stopItem['longitude'] ?? 0.0).toDouble();
            stopsLinkedList!.add(LatLng(sLat, sLng));

            String startTime = _formatIsoToTimeStr(stopItem['startTime']);
            String stopDuration = _formatMsToDuration((stopItem['duration'] ?? 0).toInt());

            historyList!.add('2 $startTime $stopDuration');
          }
        }

        // Timeline entry for Start and End
        String startTimeStr = _formatIsoToTimeStr(positionsData.first['fixTime'] ?? positionsData.first['deviceTime']);
        String endTimeStr = _formatIsoToTimeStr(positionsData.last['fixTime'] ?? positionsData.last['deviceTime']);
        historyList!.add('4 $startTimeStr');
        historyList!.add('5 $endTimeStr');

        var timeFormatter = new intl.DateFormat('yyyy-MM-dd HH:mm:ss');
        historyList!.sort((a, b) {
          try {
            if (timeFormatter
                .parse(a.substring(2, 21))
                .subtract(Duration(seconds: 1))
                .isBefore(timeFormatter.parse(b.substring(2, 21)))) {
              return -1;
            } else {
              return 1;
            }
          } catch (e) {
            return 1;
          }
        });

        updateUI(routeList!);
      } else {
        Fluttertoast.showToast(
            msg: 'noData'.tr,
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Globals.appColor,
            textColor: Colors.white,
            fontSize: 16.0);
        Navigator.pop(context);
      }
    } catch (e) {
      Fluttertoast.showToast(
          msg: 'noData'.tr,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Globals.appColor,
          textColor: Colors.white,
          fontSize: 16.0);
      Navigator.pop(context);
    }
  }

  void updateUI(List<dynamic> routeList) async {
    final latLong.Distance distance = latLong.Distance();
    latLong.LatLng currentLocation;
    latLong.LatLng previousLocation = latLong.LatLng(0.0, 0.0);
    LatLng latLng;

    for (int i = 0; i < routeList.length; i++) {
      var routeItem = routeList[i];
      double lat = (routeItem['latitude'] as num).toDouble();
      double lng = (routeItem['longitude'] as num).toDouble();
      double speedKmh = ((routeItem['speed'] as num? ?? 0.0) * 1.852); // Knots to km/h
      double altitude = (routeItem['altitude'] as num? ?? 0.0).toDouble();
      double angle = (routeItem['course'] as num? ?? 0.0).toDouble();
      String positionTime = _formatIsoToTimeStr(routeItem['fixTime'] ?? routeItem['deviceTime']);

      currentLocation = latLong.LatLng(lat, lng);
      latLng = LatLng(lat, lng);
      eventObservable.add(speedKmh);

      if (distance(previousLocation, currentLocation) > 1) {
        previousLocation = latLong.LatLng(lat, lng);
      }
      list!.add(latLng);

      historyMapModelList!.add(HistoryMapModel(
          speedKmh.round().toString(),
          altitude.toString(),
          angle.toString(),
          positionTime,
          latLng));
    }

    final MarkerId markerIdStart = MarkerId('Start');
    markers.removeWhere((key, value) => key == markerIdStart);
    BitmapDescriptor? bitmapDescriptorStart =
        await BitmapDescriptor.fromAssetImage(
            ImageConfiguration(size: Size(20, 20)), 'images/hPlay.png');
    markers[markerIdStart] = Marker(
      position: list!.first,
      icon: bitmapDescriptorStart,
      markerId: markerIdStart,
    );

    BitmapDescriptor? bitmapDescriptorEnd =
        await BitmapDescriptor.fromAssetImage(
            ImageConfiguration(size: Size(20, 20)), 'images/hStop.png');
    final MarkerId markerIdEnd = MarkerId('End');
    markers.removeWhere((key, value) => key == markerIdEnd);
    markers[markerIdEnd] = Marker(
      position: list!.last,
      icon: bitmapDescriptorEnd,
      markerId: markerIdEnd,
    );

    fetchAddress();

    _polyline.add(Polyline(
      polylineId: PolylineId(''),
      visible: true,
      points: list!,
      jointType: JointType.round,
      endCap: Cap.roundCap,
      width: 2,
      startCap: Cap.roundCap,
      color: mapTypeEnabled ? Colors.red : Globals.appColor,
    ));

    if (_controller != null && list!.isNotEmpty) {
      _controller!.moveCamera(CameraUpdate.newLatLngBounds(getBounds(list!), 40));
    }

    if (stopsList != null) {
      for (int i = 0; i < stopsList!.length; i++) {
        var stopItem = stopsList![i];
        Map<String, String> data = Map<String, String>();
        data.putIfAbsent("Object", () => widget.name!);
        data.putIfAbsent("From", () => _formatIsoToTimeStr(stopItem['startTime']));
        data.putIfAbsent("To", () => _formatIsoToTimeStr(stopItem['endTime']));
        data.putIfAbsent("Time", () => _formatMsToDuration((stopItem['duration'] ?? 0).toInt()));

        if (widget.parking!) {
          markerParkingList!.add(MarkerId('$i'));
          BitmapDescriptor bitmapDescriptor =
              await BitmapDescriptor.fromAssetImage(
                  ImageConfiguration(size: Size(25, 25)), 'images/parking.png');
          markers[markerParkingList![i]] = Marker(
            onTap: () => _onTap(stopsLinkedList![i], data),
            position: stopsLinkedList![i],
            markerId: markerParkingList![i],
            icon: bitmapDescriptor,
          );
        }
      }
    }

    Future.delayed(Duration(milliseconds: 500), () {
      setState(() {
        isLoading = false;
        _mapOpacity = 1.0;
      });
    });
    setState(() {});
  }

  _onTap(LatLng location, Map<String, String> data) async {
    setState(() {
      show = true;
    });
    window = Window(data: data);
    await _onChange();
  }

  _onChange() async {
    if (window == null) {
      return;
    }
  }

  bool isShowing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0.0,
          title: Text(
            '',
            style: TextStyle(
                color: mapTypeEnabled ? Color(0xFFF6F6F6) : Globals.appColor,
                fontFamily: 'Baloo_Thambi_2'),
          ),
          iconTheme: IconThemeData(
            color: mapTypeEnabled
                ? Color(0xFFF6F6F6)
                : Globals.appColor,
          ),
        ),
        body: Stack(
          children: <Widget>[
            AnimatedOpacity(
                opacity: _mapOpacity,
                duration: Duration(seconds: 1),
                child: GoogleMap(
                    scrollGesturesEnabled: show ? false : true,
                    padding: EdgeInsets.only(
                      bottom: 40,
                    ),
                    initialCameraPosition:
                        CameraPosition(target: LatLng(0, 0), zoom: 18),
                    buildingsEnabled: true,
                    onCameraMove: (cameraPosition) {
                      currentZoom = cameraPosition.zoom;
                      _onChange();
                    },
                    polylines: polyLineShown ? _polylinePlaying : _polyline,
                    mapToolbarEnabled: false,
                    gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
                      new Factory<OneSequenceGestureRecognizer>(
                        () => new EagerGestureRecognizer(),
                      ),
                    ].toSet(),
                    markers: Set<Marker>.of(markers.values),
                    mapType: mapTypeEnabled ? MapType.hybrid : MapType.normal,
                    zoomControlsEnabled: false,
                    compassEnabled: false,
                    trafficEnabled: false,
                    myLocationButtonEnabled: false,
                    onTap: (latLng) {
                      previousLatLng = currentLatLng;
                      currentLatLng = latLng;
                      setState(() {
                        show = false;
                      });
                    },
                    onMapCreated: (GoogleMapController controller) {
                      _googleMapController.complete(controller);
                      _controller = controller;
                      if (list!.isNotEmpty) {
                        _controller!.moveCamera(
                            CameraUpdate.newLatLngBounds(getBounds(list!), 40));
                      }
                    })),
            show
                ? Positioned(
                    left: MediaQuery.of(context).size.width / 2 - 100,
                    top: MediaQuery.of(context).size.height / 2.6 - 50,
                    child: _customInfoWindowWidget(),
                  )
                : SizedBox(
                    height: 0,
                    width: 0,
                  ),
            Container(
                margin: EdgeInsets.only(top: 70),
                alignment: Alignment.topRight,
                child: Column(
                  children: [
                    Container(
                      width: 40.0,
                      height: 40.0,
                      margin: EdgeInsets.only(right: 10, top: 10),
                      child: new RawMaterialButton(
                        shape: new CircleBorder(),
                        elevation: 15.0,
                        fillColor: mapTypeEnabled
                            ? Globals.appColor
                            : Color(0xFFF6F6F6),
                        child: Image.asset(
                          'images/mapType.png',
                          height: 15,
                          width: 15,
                          color: mapTypeEnabled
                              ? Color(0xFFF6F6F6)
                              : Globals.appColor,
                        ),
                        onPressed: () {
                          mapTypeEnabled
                              ? Globals.prefs!.setBool('mapHybrid', false)
                              : Globals.prefs!.setBool('mapHybrid', true);
                          setState(() {
                            mapTypeEnabled =
                                Globals.prefs!.getBool('mapHybrid')!;
                            _polyline.clear();
                            _polyline.add(Polyline(
                              polylineId: PolylineId(''),
                              visible: true,
                              points: list!,
                              jointType: JointType.round,
                              endCap: Cap.roundCap,
                              width: 2,
                              startCap: Cap.roundCap,
                              color: mapTypeEnabled
                                  ? Colors.red
                                  : Globals.appColor,
                            ));
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
                        fillColor: isParkingMarkerShowing
                            ? Globals.appColor
                            : Color(0xFFF6F6F6),
                        child: Icon(
                          FontAwesomeIcons.parking,
                          color: isParkingMarkerShowing
                              ? Color(0xFFF6F6F6)
                              : Globals.appColor,
                          size: 20,
                        ),
                        onPressed: () async {
                          if (!isParkingMarkerShowing) {
                            isParkingMarkerShowing = true;
                            for (int i = 0; i < (stopsList?.length ?? 0); i++) {
                              try {
                                var stopItem = stopsList![i];
                                Map<String, String> data = Map<String, String>();
                                data.putIfAbsent("Object", () => widget.name!);
                                data.putIfAbsent("From", () => _formatIsoToTimeStr(stopItem['startTime']));
                                data.putIfAbsent("To", () => _formatIsoToTimeStr(stopItem['endTime']));
                                data.putIfAbsent("Time", () => _formatMsToDuration((stopItem['duration'] ?? 0).toInt()));

                                markerParkingList!.add(MarkerId('$i'));
                                BitmapDescriptor bitmapDescriptor =
                                    await BitmapDescriptor.fromAssetImage(
                                        ImageConfiguration(size: Size(20, 20)),
                                        'images/parking.png');
                                markers[markerParkingList![i]] = Marker(
                                  onTap: () => _onTap(stopsLinkedList![i], data),
                                  position: stopsLinkedList![i],
                                  markerId: markerParkingList![i],
                                  icon: bitmapDescriptor,
                                );
                              } catch (e) {}
                            }
                            setState(() {});
                          } else {
                            isParkingMarkerShowing = false;
                            for (int i = 0;
                                i < markerParkingList!.length;
                                i++) {
                              setState(() {
                                markers.removeWhere((key, value) =>
                                    key == markerParkingList![i]);
                              });
                            }
                            markerParkingList!.clear();
                          }
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
                        fillColor: polyLineShown
                            ? Color(0xFFF6F6F6)
                            : Globals.appColor,
                        child: Image.asset(
                          'images/route.png',
                          height: 15,
                          width: 15,
                          color: polyLineShown
                              ? Globals.appColor
                              : Color(0xFFF6F6F6),
                        ),
                        onPressed: () {
                          setState(() {
                            polyLineShown = !polyLineShown;
                          });
                        },
                      ),
                    ),
                  ],
                )),
            AnimatedSwitcher(
              duration: Duration(milliseconds: 500),
              child: isLoading
                  ? Container(
                      color: Color(0xFFF6F6F6),
                      height: double.infinity,
                      width: double.infinity,
                      child: Center(
                        child: CircularProgressIndicator(
                            valueColor: new AlwaysStoppedAnimation<Color>(
                          Globals.appColor,
                        )),
                      ),
                    )
                  : Align(
                      alignment: Alignment.bottomCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                isShowing = !isShowing;
                              });
                            },
                            child: Container(
                              width: 60,
                              decoration: BoxDecoration(
                                  color: Color(0xFFF6F6F6).withOpacity(0.9),
                                  borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(10),
                                      topLeft: Radius.circular(10))),
                              padding: const EdgeInsets.all(5),
                              child: Icon(
                                FontAwesomeIcons.list,
                                color: Globals.appColor,
                                size: 20,
                              ),
                            ),
                          ),
                          StreamBuilder<HistoryTopDataModel>(
                              stream: historyTopStream,
                              builder: (context, snapshot) {
                                if (snapshot.data != null &&
                                    !snapshot.hasError &&
                                    snapshot.data!.isPlaying) {
                                  return Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: Speedometer(
                                          size: 80,
                                          minValue: 0,
                                          maxValue: 180,
                                          currentValue:
                                              double.parse(snapshot.data!.speed)
                                                  .round(),
                                          warningValue: 120,
                                          backgroundColor: Color(0xFFF6F6F6)
                                              .withOpacity(0.9),
                                          meterColor: Globals.appColor,
                                          warningColor: Colors.red,
                                          kimColor:
                                              double.parse(snapshot.data!.speed)
                                                          .round() >
                                                      120
                                                  ? Colors.red.withOpacity(0.9)
                                                  : Globals.appColor
                                                      .withOpacity(0.9),
                                          displayText: 'km/h',
                                          displayNumericStyle: TextStyle(
                                              fontFamily: 'Digital-Display',
                                              color: double.parse(snapshot
                                                              .data!.speed)
                                                          .round() >
                                                      120
                                                  ? Colors.red
                                                  : Globals.appColor,
                                              fontSize: 24),
                                          displayTextStyle: TextStyle(
                                              fontFamily: 'Montserrat',
                                              fontWeight: FontWeight.bold,
                                              color: double.parse(snapshot
                                                              .data!.speed)
                                                          .round() >
                                                      120
                                                  ? Colors.red
                                                  : Globals.appColor,
                                              fontSize: 8),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Container(
                                          color: Color(0xFFF6F6F6)
                                              .withOpacity(0.9),
                                          height: 80,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                  DateFormat('HH:mm:ss').format(
                                                      DateTime.parse(
                                                          snapshot.data!.time)),
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: Globals.appColor,
                                                    fontSize: 30,
                                                    fontWeight: FontWeight.w700,
                                                    fontFamily:
                                                        'Digital-Display',
                                                  )),
                                              SizedBox(
                                                height: 10,
                                              ),
                                              Text(
                                                  DateFormat('yyyy-MM-dd')
                                                      .format(DateTime.parse(
                                                          snapshot.data!.time)),
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: Globals.appColor,
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w700,
                                                    fontFamily:
                                                        'Digital-Display',
                                                  )),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                } else {
                                  return Container(
                                    height: 0,
                                    width: 0,
                                  );
                                }
                              }),
                          AnimatedSize(
                              duration: Duration(milliseconds: 500),
                              child: Container(
                                height: isShowing
                                    ? MediaQuery.of(context).size.height * 0.20
                                    : 0,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Color(0xFFF6F6F6).withOpacity(0.9),
                                ),
                                child: DefaultTabController(
                                  initialIndex: 1,
                                  length: 2,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      TabBar(
                                        indicatorColor: Globals.appColor,
                                        tabs: [
                                          Tab(
                                            icon: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: <Widget>[
                                                Icon(
                                                  FontAwesomeIcons.solidClock,
                                                  color: Globals.appColor,
                                                  size: 20,
                                                ),
                                                SizedBox(
                                                  width: 10,
                                                ),
                                                Text(
                                                  'time'.tr,
                                                  style: TextStyle(
                                                    color: Globals.appColor,
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily:
                                                        'Baloo_Thambi_2',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Tab(
                                            icon: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: <Widget>[
                                                Icon(
                                                  FontAwesomeIcons.infoCircle,
                                                  color: Globals.appColor,
                                                  size: 20,
                                                ),
                                                SizedBox(
                                                  width: 10,
                                                ),
                                                Text(
                                                  'info'.tr,
                                                  style: TextStyle(
                                                    color: Globals.appColor,
                                                    fontFamily:
                                                        'Baloo_Thambi_2',
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      Expanded(
                                        child: TabBarView(
                                          children: [
                                            ListView.builder(
                                              addAutomaticKeepAlives: false,
                                              itemCount: historyList!.length,
                                              physics: ScrollPhysics(),
                                              padding: EdgeInsets.all(0),
                                              shrinkWrap: true,
                                              scrollDirection: Axis.vertical,
                                              itemBuilder: (context, index) {
                                                Image? icon;
                                                switch (historyList![index]
                                                    .toString()
                                                    .substring(0, 1)) {
                                                  case '1':
                                                    icon = Image.asset(
                                                      'images/route_event.png',
                                                      height: 15,
                                                      width: 15,
                                                    );
                                                    break;
                                                  case '2':
                                                    icon = Image.asset(
                                                      'images/parking.png',
                                                      height: 15,
                                                      width: 15,
                                                    );
                                                    break;
                                                  case '3':
                                                  case '4':
                                                  case '5':
                                                    icon = Image.asset(
                                                      'images/routeLength.png',
                                                      height: 15,
                                                      width: 15,
                                                    );
                                                    break;
                                                  default:
                                                }
                                                return Container(
                                                  padding:
                                                      const EdgeInsets.all(2.5),
                                                  child: Row(
                                                    children: <Widget>[
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                left: 10.0,
                                                                right: 10),
                                                        child: icon!,
                                                      ),
                                                      Expanded(
                                                        flex: 1,
                                                        child: Text(
                                                          historyList![index]
                                                              .toString()
                                                              .substring(1),
                                                          style: TextStyle(
                                                              fontFamily:
                                                                  'Baloo_Thambi_2'),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                            Container(
                                              child: SingleChildScrollView(
                                                child: Column(
                                                  children: <Widget>[
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              5.0),
                                                      child: Row(
                                                        children: <Widget>[
                                                          Expanded(
                                                            flex: 1,
                                                            child: Text(
                                                              'routeLength'.tr,
                                                              style: TextStyle(
                                                                  fontFamily:
                                                                      'Baloo_Thambi_2'),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            flex: 1,
                                                            child: Text(
                                                              ':',
                                                              style: TextStyle(
                                                                  fontFamily:
                                                                      'Baloo_Thambi_2'),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            flex: 1,
                                                            child: Text(
                                                              '${(routeLength as double).toStringAsFixed(2)} Km',
                                                              style: TextStyle(
                                                                  fontFamily:
                                                                      'Baloo_Thambi_2'),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              5.0),
                                                      child: Row(
                                                        children: <Widget>[
                                                          Expanded(
                                                            flex: 1,
                                                            child: Text(
                                                              'movingDuration'
                                                                  .tr,
                                                              style: TextStyle(
                                                                  fontFamily:
                                                                      'Baloo_Thambi_2'),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            flex: 1,
                                                            child: Text(
                                                              ':',
                                                              style: TextStyle(
                                                                  fontFamily:
                                                                      'Baloo_Thambi_2'),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            flex: 1,
                                                            child: Text(
                                                              '$duration',
                                                              style: TextStyle(
                                                                  fontFamily:
                                                                      'Baloo_Thambi_2'),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              5.0),
                                                      child: Row(
                                                        children: <Widget>[
                                                          Expanded(
                                                            flex: 1,
                                                            child: Text(
                                                              'topSpeed'.tr,
                                                              style: TextStyle(
                                                                  fontFamily:
                                                                      'Baloo_Thambi_2'),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            flex: 1,
                                                            child: Text(
                                                              ':',
                                                              style: TextStyle(
                                                                  fontFamily:
                                                                      'Baloo_Thambi_2'),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            flex: 1,
                                                            child: Text(
                                                              '$topSpeed Kmph',
                                                              style: TextStyle(
                                                                  fontFamily:
                                                                      'Baloo_Thambi_2'),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              5.0),
                                                      child: Row(
                                                        children: <Widget>[
                                                          Expanded(
                                                            flex: 1,
                                                            child: Text(
                                                              'averageSpeed'.tr,
                                                              style: TextStyle(
                                                                  fontFamily:
                                                                      'Baloo_Thambi_2'),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            flex: 1,
                                                            child: Text(
                                                              ':',
                                                              style: TextStyle(
                                                                  fontFamily:
                                                                      'Baloo_Thambi_2'),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            flex: 1,
                                                            child: Text(
                                                              '$avgSpeed km/h',
                                                              style: TextStyle(
                                                                  fontFamily:
                                                                      'Baloo_Thambi_2'),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8.0),
                                                      child: Row(
                                                        children: <Widget>[
                                                          Expanded(
                                                            flex: 1,
                                                            child: Text(
                                                              'startAddress'.tr,
                                                              style: TextStyle(
                                                                  fontFamily:
                                                                      'Baloo_Thambi_2'),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            flex: 1,
                                                            child: Text(
                                                              ':',
                                                              style: TextStyle(
                                                                  fontFamily:
                                                                      'Baloo_Thambi_2'),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            flex: 1,
                                                            child: Text(
                                                              startAddress,
                                                              style: TextStyle(
                                                                  fontFamily:
                                                                      'Baloo_Thambi_2'),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              5.0),
                                                      child: Row(
                                                        children: <Widget>[
                                                          Expanded(
                                                            flex: 1,
                                                            child: Text(
                                                              'endAddress'.tr,
                                                              style: TextStyle(
                                                                  fontFamily:
                                                                      'Baloo_Thambi_2'),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            flex: 1,
                                                            child: Text(
                                                              ':',
                                                              style: TextStyle(
                                                                  fontFamily:
                                                                      'Baloo_Thambi_2'),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            flex: 1,
                                                            child: Text(
                                                              endAddress,
                                                              style: TextStyle(
                                                                  fontFamily:
                                                                      'Baloo_Thambi_2'),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )),
                          Container(
                            padding: const EdgeInsets.all(10.0),
                            color: Color(0xFFF6F6F6),
                            height: MediaQuery.of(context).size.height * 0.05,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                InkWell(
                                  onTap: () {
                                    listPlaying!.clear();
                                    setState(() {
                                      isPlaying = !isPlaying;
                                      if (isPlaying) {
                                        changeSpeed(playSpeed);
                                      } else {
                                        if (_timer!.isActive) {
                                          _timer!.cancel();
                                        }
                                      }
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    child: Icon(
                                      isPlaying
                                          ? FontAwesomeIcons.pause
                                          : FontAwesomeIcons.play,
                                      color: Globals.appColor,
                                      size: 25,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    int speed = 500;
                                    setState(() {
                                      if (playSpeed == 500) {
                                        speed = 200;
                                      } else if (playSpeed == 200) {
                                        speed = 100;
                                      } else if (playSpeed == 100) {
                                        speed = 500;
                                      }
                                    });
                                    if (_timer != null) {
                                      if (_timer!.isActive) {
                                        changeSpeed(speed);
                                      }
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(5.0),
                                      child: Container(
                                        height: 25,
                                        width: 25,
                                        child: Image.asset(
                                          (() {
                                            if (playSpeed == 500) {
                                              return 'images/xone.png';
                                            } else if (playSpeed == 200) {
                                              return 'images/xtwo.png';
                                            } else if (playSpeed == 100) {
                                              return 'images/xthree.png';
                                            } else {
                                              return '';
                                            }
                                          }()),
                                          color: Globals.appColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Slider(
                                      value: playPosition.toDouble(),
                                      min: 0,
                                      max: historyMapModelList!.isEmpty
                                          ? 0
                                          : historyMapModelList!.length.toDouble(),
                                      divisions: historyMapModelList!.isEmpty
                                          ? 1
                                          : historyMapModelList!.length,
                                      activeColor: Globals.appColor,
                                      inactiveColor: Color(0xFF7E8188),
                                      label: playPosition < historyMapModelList!.length
                                          ? historyMapModelList![playPosition].time
                                          : (historyMapModelList!.isNotEmpty
                                              ? historyMapModelList![playPosition - 1].time
                                              : ''),
                                      onChanged: (newValue) async {
                                        if (historyMapModelList!.isEmpty) return;
                                        zoomLevel = await _controller!.getZoomLevel();
                                        setState(() {
                                          playPosition = newValue.toInt();
                                          if (playPosition >= historyMapModelList!.length) {
                                            playPosition = historyMapModelList!.length - 1;
                                          }
                                          markers[markerIdMover] = Marker(
                                            position: historyMapModelList![playPosition].latLng,
                                            icon: bitmapDescriptor ?? BitmapDescriptor.defaultMarker,
                                            markerId: markerIdMover,
                                          );
                                          _controller!.animateCamera(
                                              CameraUpdate.newCameraPosition(
                                                  CameraPosition(
                                                      target: historyMapModelList![playPosition].latLng,
                                                      zoom: zoomLevel)));
                                        });
                                      },
                                      semanticFormatterCallback:
                                          (double newValue) {
                                        return '${newValue.round()}';
                                      }),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            )
          ],
        ));
  }

  Widget _customInfoWindowWidget() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 200,
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 1,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                window!.data!["Object"]!,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              SizedBox(height: 5),
              Text(
                'start'.tr + ":" + window!.data!["From"]!,
                style: TextStyle(fontSize: 12),
              ),
              SizedBox(height: 5),
              Text(
                'end'.tr + ":" + window!.data!["To"]!,
                style: TextStyle(fontSize: 12),
              ),
              SizedBox(height: 5),
              Text(
                'duration'.tr + ":" + window!.data!["Time"]!,
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        CustomPaint(
          size: Size(20, 15),
          painter: _PinArrowPainter(),
        ),
      ],
    );
  }

  void changeSpeed(int i) {
    if (_timer != null) {
      if (_timer!.isActive) {
        _timer!.cancel();
      }
    }
    playSpeed = i;
    playMarker();
  }

  void playMarker() {
    _timer = Timer.periodic(Duration(milliseconds: playSpeed), (timer) async {
      playPosition++;
      if (playPosition < historyMapModelList!.length) {
        try {
          String markerText =
              '$name (${historyMapModelList![playPosition].speed}km/h)\n${historyMapModelList![playPosition].time}';
          bitmapDescriptor = await Helper().getMarkerPlayback(
              historyMapModelList![playPosition].speed == '0' ? 's' : 'm',
              markerText,
              '0',
              0,
              'images/pointerAngle.png');

          setState(() {
            markers[markerIdMover] = Marker(
              position: historyMapModelList![playPosition].latLng,
              icon: bitmapDescriptor!,
              markerId: markerIdMover,
            );
          });

          _controller!.animateCamera(
              CameraUpdate.newCameraPosition(
                  CameraPosition(
                      target: historyMapModelList![playPosition].latLng,
                      zoom: zoomLevel)));
          historyTopSink.add(HistoryTopDataModel(
              historyMapModelList![playPosition].speed,
              historyMapModelList![playPosition].time,
              true));
        } catch (e) {}
      } else {
        if (_timer!.isActive) {
          _timer!.cancel();
        }
        setState(() {
          playSpeed = 500;
          isPlaying = false;
          playPosition = 0;
          markers.removeWhere((key, value) => key == markerIdMover);
        });
        historyTopSink.add(HistoryTopDataModel(
            historyMapModelList!.isNotEmpty ? historyMapModelList![playPosition].speed : '0',
            historyMapModelList!.isNotEmpty ? historyMapModelList![playPosition].time : '',
            false));
      }
    });
  }

  void fetchAddress() async {
    if (historyMapModelList == null || historyMapModelList!.isEmpty) return;

    // Check if Traccar route response already contained address strings
    if (routeList != null && routeList!.isNotEmpty) {
      if (routeList!.first['address'] != null && routeList!.first['address'].toString().isNotEmpty) {
        setState(() {
          startAddress = routeList!.first['address'];
        });
      }
      if (routeList!.last['address'] != null && routeList!.last['address'].toString().isNotEmpty) {
        setState(() {
          endAddress = routeList!.last['address'];
        });
      }
    }

    // Fallback to Traccar reverse geocode API if addresses are missing
    if (startAddress == 'fetching'.tr) {
      double startLat = historyMapModelList!.first.latLng.latitude;
      double startLng = historyMapModelList!.first.latLng.longitude;
      var responseStart = await NetworkHelper().requestDataFromNetwork(
          urlFile: '/api/server/geocode?lat=$startLat&lon=$startLng',
          body: {},
          context: context);
      if (responseStart.isNotEmpty) {
        setState(() {
          startAddress = responseStart.replaceAll('\\', '').replaceAll('"', '');
        });
      }
    }

    if (endAddress == 'fetching'.tr) {
      double endLat = historyMapModelList!.last.latLng.latitude;
      double endLng = historyMapModelList!.last.latLng.longitude;
      var responseEnd = await NetworkHelper().requestDataFromNetwork(
          urlFile: '/api/server/geocode?lat=$endLat&lon=$endLng',
          body: {},
          context: context);
      if (responseEnd.isNotEmpty) {
        setState(() {
          endAddress = responseEnd.replaceAll('\\', '').replaceAll('"', '');
        });
      }
    }
  }

  @override
  void dispose() {
    _historyTopDataModelStreamController.close();
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
    }
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Globals.appColor,
      systemNavigationBarColor: Globals.appColor,
    ));
    super.dispose();
  }

  HistoryModel historyModelFromJson(String str) =>
      HistoryModel.fromJson(json.decode(str));
}

class _PinArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = Colors.black12
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
