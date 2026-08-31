import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_speedometer_new/flutter_speedometer_new.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:html/parser.dart';
import 'package:intl/intl.dart' as intl;
import 'package:location/location.dart';
import 'package:location/location.dart' as Location;
import 'package:progress_indicators/progress_indicators.dart';
import 'package:rxdart/subjects.dart';
import 'package:speedotrack/globals.dart';
import 'package:speedotrack/helper/helper.dart';
import 'package:speedotrack/main.dart';
import 'package:speedotrack/model/model_object_fn.dart';
import 'package:speedotrack/model/model_sensor_home.dart';
import 'package:speedotrack/model/model_settings_fn.dart';

import 'package:speedotrack/network/network_api_request.dart';
import 'package:speedotrack/sharedPrefs/main_prefs.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:speedotrack/lib_animation/lat_lng_interpolation.dart';
import 'package:speedotrack/lib_animation/models/lat_lng_delta.dart';

class TrackingModel {
  String? _lat;
  String? _lng;
  int? _speed;
  String? _angle;
  String? _status;
  String? _statusMessage;

  TrackingModel(this._lat, this._lng, this._speed, this._angle, this._status,
      this._statusMessage);
}

class TrackingActivity extends StatefulWidget {
  final String? lat;
  final String? lng;
  final int? speed;
  final String? angle;
  final String? name;
  final String? imei;
  final String? status;
  final String? statusMessage;
  static bool ignitionAvailable = false;
  const TrackingActivity(
      {@required this.lat,
      @required this.lng,
      @required this.speed,
      @required this.angle,
      @required this.name,
      @required this.imei,
      @required this.status,
      @required this.statusMessage});

  @override
  _TrackingActivityState createState() => _TrackingActivityState(
      finalLat: lat!,
      finalLng: lng!,
      finalSpeed: speed!,
      finalAngle: angle!,
      finalName: name!,
      finalImei: imei!,
      finalStatus: status!,
      finalStatusMessage: statusMessage!);
}

class _TrackingActivityState extends State<TrackingActivity>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  _TrackingActivityState(
      {this.finalLat,
      this.finalLng,
      this.finalSpeed,
      this.finalAngle,
      this.finalName,
      this.finalImei,
      this.finalStatus,
      this.finalStatusMessage});

  BitmapDescriptor? bitmapDescriptor;
  final String? finalStatusMessage;
  final String? finalLat;
  final String? finalLng;
  final int? finalSpeed;
  final String? finalAngle;
  final String? finalName;
  final String? finalImei;
  final String? finalStatus;
  GoogleMapController? _controller;
  String serverTime = '';
  String deviceTime = '';
  String engineHoursString = '';
  String address = 'View Address';
  String ignition = '';
  String? gpsCn;
  String weather = '',
      weatherImageURL = '${Globals.baseUrl}/img/logo_small.png';
  bool viewHider = true;
  bool myLocation = false;
  bool ruler = false;
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  bool trafficStatus = false,
      mapTypeEnabled = Globals.prefs!.getBool('mapHybrid') ?? false;
  Timer? _timer;
  int i = 0;
  final Set<Polyline> _polyline = {};
  final Set<Polyline> _distancePolyLine = {};
  bool first = false;
  MarkerId? markerId;
  String mileage = 'Fetching';
  String engineHour = 'Fetching';
  List<LatLng> latLngList = [];
  LatLngInterpolationStream? _latLngStream;
  StreamSubscription<LatLngDelta>? subscription;
  GoogleMap? googleMap;
  bool isStarted = true;
  var now = new DateTime.now();
  var nowAdd = new DateTime.now().add(Duration(days: 1));
  var formatter = new intl.DateFormat('yyyy-MM-dd');
  TrackingModel? trackingModel;
  PublishSubject<double> eventObservable = PublishSubject();
  List<SensorModelHome> sensorModelAboveLocal = [
    SensorModelHome('images/ignitionIcon.png', 'Fetching', Colors.grey),
    SensorModelHome('images/gpsIcon.png', 'Fetching', Colors.grey),
    SensorModelHome('images/speedIcon.png', 'Fetching', Globals.appColor),
    SensorModelHome('images/odometerIcon.png', 'Fetching', Globals.appColor),
    SensorModelHome('images/engineHourIcon.png', 'Fetching', Globals.appColor)
  ];
  List<SensorModelHome> sensorModelBelowLocal = [];
  StreamController<TrackingModel> _trackingModelStreamController =
      BehaviorSubject();

  Stream<TrackingModel> get trackingModelStream =>
      _trackingModelStreamController.stream;

  StreamSink<TrackingModel> get trackingModelSink =>
      _trackingModelStreamController.sink;

  StreamController<List<SensorModelHome>> _sensorAboveListStreamController =
      BehaviorSubject();

  Stream<List<SensorModelHome>> get sensorAboveListStream =>
      _sensorAboveListStreamController.stream;

  StreamSink<List<SensorModelHome>> get sensorAboveListSink =>
      _sensorAboveListStreamController.sink;

  StreamController<List<SensorModelHome>> _sensorBelowListStreamController =
      BehaviorSubject();

  Stream<List<SensorModelHome>> get sensorBelowListStream =>
      _sensorBelowListStreamController.stream;

  StreamSink<List<SensorModelHome>> get sensorBelowListSink =>
      _sensorBelowListStreamController.sink;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        fetchFnObjects();
        break;
      case AppLifecycleState.paused:
        _polyline.clear();
        latLngList.clear();
        if (_timer != null) _timer!.cancel();
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Globals.appColor,
    ));
    trackingModelSink.add(TrackingModel(finalLat, finalLng, finalSpeed,
        finalAngle, finalStatus, finalStatusMessage));
    markerId = MarkerId(finalImei!);
    _latLngStream = LatLngInterpolationStream(
      movementDuration: Duration(milliseconds: 9900),
    );
    _latLngStream!
        .addLatLng(LatLng(double.parse(finalLat!), double.parse(finalLng!)));
    setDataWithTimer();
    setSubscription();
  }

  void setSubscription() {
    subscription = _latLngStream!
        .getLatLngInterpolation()
        .listen((LatLngDelta delta) async {
      if (!ruler) {
        latLngList.add(delta.to!);
        if (latLngList.length % 30 == 0 && !myLocation && _controller != null) {
          double zoomLevel = await _controller!.getZoomLevel();
          _controller!.animateCamera(CameraUpdate.newCameraPosition(
              CameraPosition(target: delta.to!, zoom: zoomLevel)));
        }
        if (mounted) {
          setState(() {
            markers[markerId!] = Marker(
              position: delta.to!,
              icon: bitmapDescriptor!,
              anchor: Offset(0.5, 0.675),
              markerId: markerId!,
            );
          });
          _polyline.add(Polyline(
            polylineId: PolylineId(latLngList.first.toString()),
            visible: !ruler ? true : false,
            points: latLngList,
            jointType: JointType.bevel,
            endCap: Cap.roundCap,
            width: 3,
            startCap: Cap.roundCap,
            color: Colors.red,
          ));
        }
      }
    });
  }

  bool whiteContainer = true;

  void setDataWithTimer() {
    if (mounted) {
      updateUI();
      fetchFnObjects();
      fetchMileage();
      fetchEngineHour();
      fetchWeather();
      setState(() {});
    }
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      fetchFnObjects();
    });
  }

  // ==================== TRACCAR API INTEGRATION ====================

  void fetchFnObjects() async {
    try {
      // 1. Fetch Device ID and online status from Traccar API
      var devRes = await NetworkHelper().requestDataFromNetworkWithTimeoutGET(
        urlFile: 'api/devices?uniqueId=$finalImei',
        context: context,
      );

      int? deviceId;
      String devStatus = 'offline';
      String statusMsg = 'Offline';

      if (devRes != null && devRes.isNotEmpty) {
        var parsedDev = devRes is String ? jsonDecode(devRes) : devRes;
        if (parsedDev is List && parsedDev.isNotEmpty) {
          deviceId = parsedDev[0]['id'];
          devStatus = parsedDev[0]['status'] ?? 'offline';
          statusMsg = (devStatus == 'online' || devStatus == 'unknown')
              ? 'Moving / Online'
              : 'Stopped / Offline';
        }
      }

      if (deviceId != null) {
        // 2. Fetch Position Telemetry from Traccar API
        var posRes =
            await NetworkHelper().requestDataFromNetworkWithTimeoutGET(
          urlFile: 'api/positions?deviceId=$deviceId',
          context: context,
        );

        if (posRes != null && posRes.isNotEmpty) {
          var parsedPos = posRes is String ? jsonDecode(posRes) : posRes;
          if (parsedPos is List && parsedPos.isNotEmpty) {
            var pos = parsedPos[0];

            String latStr = pos['latitude'].toString();
            String lngStr = pos['longitude'].toString();

            // Traccar speed is provided in knots (1 knot = 1.852 km/h)
            double rawSpeed = (pos['speed'] ?? 0).toDouble();
            int speedKmH = (rawSpeed * 1.852).round();
            String angleStr = (pos['course'] ?? 0).toString();

            serverTime = pos['serverTime'] ?? pos['fixTime'] ?? '';
            deviceTime = pos['deviceTime'] ?? pos['fixTime'] ?? '';

            Map<String, dynamic> attributes =
                pos['attributes'] is Map ? pos['attributes'] : {};

            bool isIgnitionOn = attributes['ignition'] == true ||
                attributes['acc'] == true ||
                attributes['ignition'] == 'true';
            ignition = isIgnitionOn ? 'On' : 'Off';

            bool isValidGps = pos['valid'] ?? false;
            gpsCn = isValidGps ? '2' : '0';

            var odoMeters =
                attributes['totalDistance'] ?? attributes['odometer'] ?? 0;
            double odoKm = (odoMeters is num) ? odoMeters / 1000 : 0.0;

            String statusKey =
                (devStatus == 'online' || devStatus == 'unknown') ? 'm' : 's';

            trackingModelSink.add(TrackingModel(
              latStr,
              lngStr,
              speedKmH,
              angleStr,
              statusKey,
              statusMsg,
            ));

            String iconPrefix = Globals.prefs != null
                ? (Globals.prefs!.getString('${finalImei}_icons') ?? '')
                : '';

            BitmapDescriptor value = await Helper().getMarker(
              context,
              statusKey,
              finalName!,
              angleStr,
              speedKmH,
              'images/${Helper().getMarkerName(statusKey, iconPrefix)}',
            );
            bitmapDescriptor = value;

            if (_latLngStream != null) {
              _latLngStream!.addLatLng(
                LatLng(double.parse(latStr), double.parse(lngStr)),
              );
            }

            // Sensors UI
            sensorModelAboveLocal[0] = SensorModelHome(
              'images/ignitionIcon.png',
              isIgnitionOn ? 'Ignition:\nOn' : 'Ignition:\nOff',
              isIgnitionOn ? Globals.appColor : Colors.grey,
            );
            TrackingActivity.ignitionAvailable = true;

            sensorModelAboveLocal[1] = SensorModelHome(
              'images/gpsIcon.png',
              isValidGps ? 'GPS:\nOn' : 'GPS:\nOff',
              isValidGps ? Globals.appColor : Colors.grey,
            );

            sensorModelAboveLocal[2] = SensorModelHome(
              'images/speedIcon.png',
              'Odometer:\n${odoKm.toStringAsFixed(1)}km',
              Globals.appColor,
            );

            sensorModelBelowLocal.clear();

            if (serverTime.isNotEmpty) {
              try {
                DateTime sTime = DateTime.parse(serverTime).toLocal();
                String formattedSDate =
                    intl.DateFormat('dd-MM-yy HH:mm').format(sTime);
                sensorModelBelowLocal.add(SensorModelHome(
                  'images/serverIcon.png',
                  'Time (Server): $formattedSDate',
                  Globals.appColor,
                ));
              } catch (_) {}
            }

            if (deviceTime.isNotEmpty) {
              try {
                DateTime dTime = DateTime.parse(deviceTime).toLocal();
                String formattedDDate =
                    intl.DateFormat('dd-MM-yy HH:mm').format(dTime);
                sensorModelBelowLocal.add(SensorModelHome(
                  'images/deviceTime.png',
                  'Time (Device): $formattedDDate',
                  Globals.appColor,
                ));
              } catch (_) {}
            }

            updateList();
          }
        }
      }
    } catch (e) {
      // Graceful fallback
    }
  }

  void fetchMileage() async {
    try {
      var devRes = await NetworkHelper().requestDataFromNetworkWithTimeoutGET(
        urlFile: 'api/devices?uniqueId=$finalImei',
        context: context,
      );
      if (devRes != null && devRes.isNotEmpty) {
        var parsedDev = devRes is String ? jsonDecode(devRes) : devRes;
        if (parsedDev is List && parsedDev.isNotEmpty) {
          int deviceId = parsedDev[0]['id'];
          DateTime startOfDay = DateTime(now.year, now.month, now.day);
          DateTime endOfDay = startOfDay.add(Duration(days: 1));

          String fromIso = startOfDay.toUtc().toIso8601String();
          String toIso = endOfDay.toUtc().toIso8601String();

          var reportRes =
              await NetworkHelper().requestDataFromNetworkWithTimeoutGET(
            urlFile:
                'api/reports/summary?deviceId=$deviceId&from=$fromIso&to=$toIso',
            context: context,
          );

          if (reportRes != null && reportRes.isNotEmpty) {
            var parsedReport =
                reportRes is String ? jsonDecode(reportRes) : reportRes;
            if (parsedReport is List && parsedReport.isNotEmpty) {
              double distMeters =
                  (parsedReport[0]['distance'] ?? 0).toDouble();
              double distKm = distMeters / 1000;
              mileage = '${distKm.toStringAsFixed(1)} km';
            }
          }
        }
      }
    } catch (e) {
      mileage = 'No Data';
    }
    sensorModelAboveLocal[3] = SensorModelHome(
        'images/odometerIcon.png', 'Mileage:\n$mileage', Globals.appColor);
    updateList();
  }

  void fetchEngineHour() async {
    try {
      var devRes = await NetworkHelper().requestDataFromNetworkWithTimeoutGET(
        urlFile: 'api/devices?uniqueId=$finalImei',
        context: context,
      );
      if (devRes != null && devRes.isNotEmpty) {
        var parsedDev = devRes is String ? jsonDecode(devRes) : devRes;
        if (parsedDev is List && parsedDev.isNotEmpty) {
          int deviceId = parsedDev[0]['id'];
          DateTime startOfDay = DateTime(now.year, now.month, now.day);
          DateTime endOfDay = startOfDay.add(Duration(days: 1));

          String fromIso = startOfDay.toUtc().toIso8601String();
          String toIso = endOfDay.toUtc().toIso8601String();

          var reportRes =
              await NetworkHelper().requestDataFromNetworkWithTimeoutGET(
            urlFile:
                'api/reports/summary?deviceId=$deviceId&from=$fromIso&to=$toIso',
            context: context,
          );

          if (reportRes != null && reportRes.isNotEmpty) {
            var parsedReport =
                reportRes is String ? jsonDecode(reportRes) : reportRes;
            if (parsedReport is List && parsedReport.isNotEmpty) {
              var engMs = parsedReport[0]['engineHours'] ?? 0;
              double engHours = (engMs is num) ? engMs / 3600000 : 0.0;
              engineHour = '${engHours.toStringAsFixed(1)} h';
            }
          }
        }
      }
    } catch (e) {
      engineHour = 'No Data';
    }
    sensorModelAboveLocal[4] = SensorModelHome('images/engineHourIcon.png',
        'Engine Hour:\n$engineHour', Globals.appColor);
    updateList();
  }

  void fetchAddress(String lat, String lng) async {
    setState(() {
      address = 'Fetching';
    });
    try {
      var response =
          await NetworkHelper().requestDataFromNetworkWithTimeoutGET(
        urlFile: 'api/server/geocode?latitude=$lat&longitude=$lng',
        context: context,
      );
      if (response != null && response.toString().isNotEmpty) {
        String result = response is String ? response : response.toString();
        if (mounted) {
          setState(() {
            address = result.replaceAll('\\', '').replaceAll('"', '');
          });
        }
        Timer(Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              address = 'View Address';
            });
          }
        });
      } else {
        if (mounted) {
          setState(() {
            address = 'No Data';
          });
        }
        Timer(Duration(seconds: 1, milliseconds: 500), () {
          if (mounted) {
            setState(() {
              address = 'View Address';
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          address = 'No Data';
        });
      }
    }
  }

  void fetchWeather() {
    NetworkHelper()
        .requestWeatherFromNetworkGET(
            lat: finalLat, lng: finalLng, context: context)
        .then((value) {
      if (value != null && value.isNotEmpty) {
        dynamic result = jsonDecode(value);
        if (mounted) {
          setState(() {
            weather = '${result['main']['temp']}°C';
            weatherImageURL =
                'http://openweathermap.org/img/w/${result['weather'][0]['icon']}.png';
          });
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    if (_latLngStream != null) _latLngStream!.cancel();
    if (subscription != null) subscription!.cancel();
    _latLngStream = null;
    WidgetsBinding.instance.removeObserver(this);
    if (_controller != null) _controller!.dispose();
    _trackingModelStreamController.close();
    _sensorAboveListStreamController.close();
    _sensorBelowListStreamController.close();
    if (_timer != null) _timer!.cancel();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Globals.appColor,
      systemNavigationBarColor: Globals.appColor,
    ));
  }

  void updateUI() {
    updateList();
  }

  int distance = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        iconTheme: IconThemeData(
          color: mapTypeEnabled ? Color(0xFFF6F6F6) : Globals.appColor,
        ),
      ),
      body: StreamBuilder<TrackingModel>(
          stream: trackingModelStream,
          builder: (context, snapshot) {
            if (snapshot.data == null || snapshot.hasError) {
              return Center(
                  child: Text(
                'Fetching data...',
                maxLines: 2,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Globals.appColor,
                    fontSize: 14,
                    decoration: TextDecoration.none,
                    letterSpacing: 1,
                    fontFamily: 'Montserrat'),
              ));
            }
            return Stack(
              alignment: Alignment.topCenter,
              children: <Widget>[
                GoogleMap(
                    onTap: (value) {
                      setState(() {
                        viewHider = !viewHider;
                      });
                    },
                    compassEnabled: false,
                    initialCameraPosition: CameraPosition(
                      zoom: 18,
                      target: LatLng(
                          double.parse(finalLat!), double.parse(finalLng!)),
                    ),
                    polylines: ruler ? _distancePolyLine : _polyline,
                    mapToolbarEnabled: false,
                    gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
                      new Factory<OneSequenceGestureRecognizer>(
                        () => new EagerGestureRecognizer(),
                      ),
                    ].toSet(),
                    markers: Set<Marker>.of(markers.values),
                    mapType: mapTypeEnabled ? MapType.hybrid : MapType.normal,
                    zoomControlsEnabled: false,
                    trafficEnabled: trafficStatus,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    onMapCreated: (GoogleMapController controller) async {
                      _controller = controller;
                      String iconPrefix = Globals.prefs != null
                          ? (Globals.prefs!.getString('${finalImei}_icons') ??
                              '')
                          : '';
                      bitmapDescriptor = await Helper().getMarker(
                        context,
                        snapshot.data!._status!,
                        finalName!,
                        snapshot.data!._angle!,
                        snapshot.data!._speed!,
                        'images/${Helper().getMarkerName(snapshot.data!._status!, iconPrefix)}',
                      );
                      if (mounted) {
                        setState(() {
                          markers[markerId!] = Marker(
                            position: LatLng(double.parse(finalLat!),
                                double.parse(finalLng!)),
                            icon: bitmapDescriptor!,
                            anchor: Offset(0.5, 0.675),
                            markerId: markerId!,
                          );
                          whiteContainer = false;
                        });
                      }
                    }),
                AnimatedSize(
                    duration: Duration(seconds: 1),
                    curve: Curves.bounceIn,
                    child: Container(
                      height: whiteContainer
                          ? MediaQuery.of(context).size.height
                          : 0,
                      width: whiteContainer
                          ? MediaQuery.of(context).size.width
                          : 0,
                      color: Color(0xFFF6F6F6),
                    )),
                Container(
                  alignment: Alignment.topCenter,
                  padding: const EdgeInsets.all(10.0),
                  margin: EdgeInsets.only(top: 30),
                  height: 80,
                  width: ruler ? 150 : 80,
                  child: Visibility(
                    visible: snapshot.data!._status == 'm' ? true : (ruler),
                    child: ruler
                        ? Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: GlowingProgressIndicator(
                              child: Text(
                                '$distance km',
                                style: TextStyle(
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF4500),
                                ),
                              ),
                              duration: Duration(milliseconds: 500),
                            ),
                          )
                        : Speedometer(
                            size: 80,
                            minValue: 0,
                            maxValue: 180,
                            currentValue: snapshot.data!._speed!,
                            warningValue: 120,
                            backgroundColor: Colors.transparent,
                            meterColor: Globals.appColor,
                            warningColor: Colors.red,
                            kimColor: Colors.white.withOpacity(0.9),
                            displayText: 'km/h',
                            displayNumericStyle: TextStyle(
                                fontFamily: 'Digital-Display',
                                color: snapshot.data!._speed! > 120
                                    ? Colors.red
                                    : (mapTypeEnabled
                                        ? Colors.red
                                        : Globals.appColor),
                                fontSize: 24),
                            displayTextStyle: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.bold,
                                color: snapshot.data!._speed! > 120
                                    ? Colors.red
                                    : (mapTypeEnabled
                                        ? Colors.red
                                        : Globals.appColor),
                                fontSize: 8),
                          ),
                  ),
                ),
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
                            bool nextVal = !(Globals.prefs!
                                    .getBool('mapHybrid') ??
                                false);
                            Globals.prefs!.setBool('mapHybrid', nextVal);
                            setState(() {
                              mapTypeEnabled = nextVal;
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
                          fillColor: trafficStatus
                              ? Globals.appColor
                              : Color(0xFFF6F6F6),
                          child: Icon(Icons.traffic,
                              size: 15,
                              color: trafficStatus
                                  ? Color(0xFFF6F6F6)
                                  : Globals.appColor),
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
                          child: Icon(FontAwesomeIcons.directions,
                              size: 15, color: Globals.appColor),
                          onPressed: () => openMap(
                              double.parse(snapshot.data!._lat!),
                              double.parse(snapshot.data!._lng!)),
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
                            size: 15,
                            color: Globals.appColor,
                          ),
                          onPressed: () => openMapStreet(
                              double.parse(snapshot.data!._lat!),
                              double.parse(snapshot.data!._lng!)),
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
                          child: Image.asset(
                            'images/switchIcon.png',
                            height: 15,
                            width: 15,
                            color: Globals.appColor,
                          ),
                          onPressed: () {
                            fetchChangeDeviceData();
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
                              myLocation ? Globals.appColor : Color(0xFFF6F6F6),
                          child: Image.asset(
                            'images/gpsIcon.png',
                            height: 15,
                            width: 15,
                            color: myLocation
                                ? Color(0xFFF6F6F6)
                                : Globals.appColor,
                          ),
                          onPressed: () {
                            setState(() {
                              myLocation = !myLocation;
                              if (!myLocation) {
                                _controller!.animateCamera(
                                    CameraUpdate.newCameraPosition(
                                        CameraPosition(
                                            zoom: 18,
                                            target:
                                                markers.values.last.position,
                                            bearing: double.parse(
                                                snapshot.data!._angle!))));
                              } else {
                                getToMyLocation();
                              }
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
                              ruler ? Globals.appColor : Color(0xFFF6F6F6),
                          child: Icon(
                            FontAwesomeIcons.ruler,
                            size: 15,
                            color: ruler ? Color(0xFFF6F6F6) : Globals.appColor,
                          ),
                          onPressed: () async {
                            setState(() {
                              ruler = !ruler;
                            });
                            if (ruler) {
                              LatLng latLngLast = markers.values.last.position;
                              List<LatLng> latLngDistance = [];
                              var location = new Location.Location();
                              try {
                                LocationData currentLocation =
                                    await location.getLocation();
                                latLngDistance.add(LatLng(
                                    currentLocation.latitude!,
                                    currentLocation.longitude!));
                                latLngDistance.add(latLngLast);
                              } on Exception {}
                              List<double> latitude = [];
                              List<double> longitude = [];
                              for (int i = 0; i < latLngDistance.length; i++) {
                                latitude.add(latLngDistance[i].latitude);
                                longitude.add(latLngDistance[i].longitude);
                              }
                              int distanceTemp = calculateDistance(
                                      latLngDistance.first.latitude,
                                      latLngDistance.first.longitude,
                                      latLngDistance.last.latitude,
                                      latLngDistance.last.longitude)
                                  .toInt();
                              setState(() {
                                _distancePolyLine.clear();
                                _distancePolyLine.add(Polyline(
                                  polylineId: PolylineId(
                                      latLngDistance.last.toString()),
                                  visible: ruler,
                                  points: latLngDistance,
                                  jointType: JointType.round,
                                  endCap: Cap.roundCap,
                                  width: 2,
                                  startCap: Cap.roundCap,
                                  color: Colors.red,
                                ));
                                _controller!.animateCamera(
                                    CameraUpdate.newCameraPosition(
                                        CameraPosition(
                                            target: latLngDistance.last,
                                            bearing: 0)));
                                _controller!.animateCamera(
                                    CameraUpdate.newLatLngBounds(
                                        getBounds(latitude, longitude), 100));
                                distance = distanceTemp;
                              });
                            } else {
                              _controller!.animateCamera(
                                  CameraUpdate.newCameraPosition(CameraPosition(
                                zoom: 18,
                                target: markers.values.last.position,
                                bearing: double.parse(snapshot.data!._angle!),
                              )));
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedOpacity(
                  opacity: viewHider ? 1.0 : 0.0,
                  duration: Duration(seconds: 1),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Wrap(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                              color: Color(0xFFF6F6F6),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              SizedBox(
                                height: 10,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 10.0, right: 10),
                                child: Container(
                                  width: MediaQuery.of(context).size.width,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Expanded(
                                        flex: 4,
                                        child: InkWell(
                                          onTap: () => fetchAddress(
                                              snapshot.data!._lat!,
                                              snapshot.data!._lng!),
                                          child: Row(
                                            children: [
                                              Image.asset(
                                                'images/address.png',
                                                height: 25,
                                                width: 25,
                                                color: Color(0xFF7E8188),
                                              ),
                                              SizedBox(
                                                width: 5,
                                              ),
                                              Expanded(
                                                child: AutoSizeText(
                                                  '$address',
                                                  softWrap: true,
                                                  wrapWords: true,
                                                  minFontSize: 6,
                                                  textAlign: TextAlign.start,
                                                  style: TextStyle(
                                                    color: Color(0xFF7E8188),
                                                    fontSize: 14,
                                                    letterSpacing: 1,
                                                    fontFamily: 'Montserrat',
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 3,
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Image.network(
                                              weatherImageURL,
                                              height: 25,
                                              width: 25,
                                            ),
                                            SizedBox(
                                              width: 5,
                                            ),
                                            AutoSizeText(
                                              weather,
                                              minFontSize: 10,
                                              textAlign: TextAlign.end,
                                              style: TextStyle(
                                                color: Color(0xFF7E8188),
                                                fontSize: 14,
                                                letterSpacing: 1,
                                                fontFamily: 'Montserrat',
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 3,
                                            )
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                              StreamBuilder<List<SensorModelHome>>(
                                  stream: sensorAboveListStream,
                                  builder: (context, snapshot) {
                                    if (snapshot.data == null ||
                                        snapshot.hasError ||
                                        snapshot.data!.length == 0) {
                                      return Container(
                                        height: 0,
                                        width: 0,
                                      );
                                    }
                                    return TrackingListWidget(
                                        sensorModel: snapshot.data!);
                                  }),
                              StreamBuilder<List<SensorModelHome>>(
                                  stream: sensorBelowListStream,
                                  builder: (context, snapshot) {
                                    if (snapshot.data == null ||
                                        snapshot.hasError ||
                                        snapshot.data!.length == 0) {
                                      return Container(
                                        height: 0,
                                        width: 0,
                                      );
                                    }
                                    return TrackingListWidget(
                                        sensorModel: snapshot.data!);
                                  }),
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 10.0, right: 10, top: 5, bottom: 5),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: <Widget>[
                                    Expanded(
                                      child: Image.asset(
                                        'images/googleLogo.png',
                                        height: 20,
                                      ),
                                      flex: 1,
                                    ),
                                    Expanded(
                                      child: AutoSizeText(
                                        '$finalName',
                                        minFontSize: 8,
                                        maxLines: 1,
                                        textAlign: TextAlign.end,
                                        style: TextStyle(
                                          color: Color(0xFF7E8188),
                                          fontSize: 15,
                                          letterSpacing: 1.0,
                                          fontFamily: 'Montserrat',
                                        ),
                                      ),
                                      flex: 3,
                                    ),
                                    Expanded(
                                      child: AutoSizeText(
                                        '${snapshot.data!._statusMessage}',
                                        minFontSize: 8,
                                        maxLines: 1,
                                        textAlign: TextAlign.end,
                                        style: TextStyle(
                                          color: Color(0xFF7E8188),
                                          fontSize: 15,
                                          letterSpacing: 1.0,
                                          fontFamily: 'Montserrat',
                                        ),
                                      ),
                                      flex: 5,
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            );
          }),
    );
  }

  void changeDeviceDialog(
      List<String> imeiArray, List<String> namesJsonArray) {
    showGeneralDialog(
      barrierLabel: 'Change Device',
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      context: context,
      transitionDuration: Duration(milliseconds: 100),
      pageBuilder: (_, __, ___) {
        return Center(
          child: Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: AutoSizeText(
                        'Change Device',
                        minFontSize: 8,
                        maxLines: 1,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          decoration: TextDecoration.none,
                          letterSpacing: 1.0,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ),
                    changeDeviceDropDown(imeiArray, namesJsonArray),
                  ],
                ),
              )),
        );
      },
    );
  }

  DropdownButton<String> changeDeviceDropDown(
      List<String> iMEIArray, List<String> namesJsonArray) {
    String deviceSelected = iMEIArray[0];
    List<DropdownMenuItem<String>> dropdownItems = [];
    for (int i = 0; i < iMEIArray.length; i++) {
      var newItem = DropdownMenuItem(
        child: Text(namesJsonArray[i]),
        value: iMEIArray[i],
      );
      dropdownItems.add(newItem);
    }

    return DropdownButton<String>(
        value: deviceSelected,
        items: dropdownItems,
        onChanged: (iMEI) async {
          try {
            var devRes =
                await NetworkHelper().requestDataFromNetworkWithTimeoutGET(
              urlFile: 'api/devices?uniqueId=$iMEI',
              context: context,
            );
            if (devRes != null && devRes.isNotEmpty) {
              var parsedDev = devRes is String ? jsonDecode(devRes) : devRes;
              if (parsedDev is List && parsedDev.isNotEmpty) {
                int deviceId = parsedDev[0]['id'];
                var posRes =
                    await NetworkHelper().requestDataFromNetworkWithTimeoutGET(
                  urlFile: 'api/positions?deviceId=$deviceId',
                  context: context,
                );
                if (posRes != null && posRes.isNotEmpty) {
                  var parsedPos =
                      posRes is String ? jsonDecode(posRes) : posRes;
                  if (parsedPos is List && parsedPos.isNotEmpty) {
                    var pos = parsedPos[0];
                    double rawSpeed = (pos['speed'] ?? 0).toDouble();
                    int speedKmH = (rawSpeed * 1.852).round();
                    Navigator.of(context)
                      ..pop()
                      ..pushReplacement(MaterialPageRoute(
                          builder: (context) => TrackingActivity(
                              lat: pos['latitude'].toString(),
                              lng: pos['longitude'].toString(),
                              speed: speedKmH,
                              angle: (pos['course'] ?? 0).toString(),
                              name: (parsedDev[0]['name'] ?? 'DEVICE')
                                  .toString()
                                  .toUpperCase(),
                              imei: iMEI,
                              status: parsedDev[0]['status'] == 'online'
                                  ? 'm'
                                  : 's',
                              statusMessage: parsedDev[0]['status'] == 'online'
                                  ? 'Moving / Online'
                                  : 'Stopped / Offline')));
                  }
                }
              }
            }
          } catch (e) {
            Fluttertoast.showToast(
                msg: 'Some error occurred while switching device.');
          }
        });
  }

  LatLngBounds getBounds(List<double> latitude, List<double> longitude) {
    var lngs = longitude;
    var lats = latitude;

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

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  void fetchChangeDeviceData() {
    List<String> imeiArray = [];
    List<String> namesJsonArray = [];
    try {
      if (Globals.prefs != null) {
        imeiArray.addAll(Globals.prefs!.getStringList(MainPrefs.keyIMEI) ?? []);
        for (int i = 0; i < imeiArray.length; i++) {
          String? settingsStr =
              Globals.prefs!.getString('${imeiArray[i]}_settings');
          if (settingsStr != null) {
            namesJsonArray.add(VehicleSettingsModel.fromJson(
                    jsonDecode(settingsStr))
                .name!
                .toUpperCase());
          } else {
            namesJsonArray.add(imeiArray[i]);
          }
        }
        if (imeiArray.isNotEmpty) {
          changeDeviceDialog(imeiArray, namesJsonArray);
        }
      }
    } catch (e) {}
  }

  void getToMyLocation() async {
    var location = new Location.Location();
    try {
      LocationData currentLocation = await location.getLocation();
      _controller!.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
          zoom: 18,
          target:
              LatLng(currentLocation.latitude!, currentLocation.longitude!))));
    } on Exception {}
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

  void updateList() {
    if (!_sensorBelowListStreamController.isClosed) {
      List<SensorModelHome> sensorModelAbove = [];
      for (var sensor in sensorModelAboveLocal) {
        if (sensor.text.contains('Fetching') ||
            sensor.text.contains('No Data')) {
          continue;
        }
        sensorModelAbove.add(sensor);
      }
      List<SensorModelHome> sensorModelBelow = [];
      for (var sensor in sensorModelBelowLocal) {
        if (sensor.text.contains('Fetching') ||
            sensor.text.contains('No Data')) {
          continue;
        }
        sensorModelBelow.add(sensor);
      }
      if ((sensorModelAbove.length + sensorModelBelow.length) > 8) {
        sensorAboveListSink.add(sensorModelAbove);
        sensorBelowListSink.add(sensorModelBelow);
      } else {
        List<SensorModelHome> sensorModelCombined = [];
        sensorModelCombined.addAll(sensorModelAbove);
        sensorModelCombined.addAll(sensorModelBelow);
        sensorAboveListSink.add(sensorModelCombined);
        sensorBelowListSink.add([]);
      }
    }
  }
}

class TrackingListWidget extends StatelessWidget {
  final List<SensorModelHome>? sensorModel;

  const TrackingListWidget({Key? key, this.sensorModel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      child: ListView.builder(
        shrinkWrap: true,
        addAutomaticKeepAlives: false,
        scrollDirection: Axis.horizontal,
        itemCount: sensorModel!.length,
        itemBuilder: (BuildContext context, int index) => Padding(
          padding: const EdgeInsets.only(top: 5, bottom: 5),
          child: Card(
            elevation: 2,
            shadowColor: Color(0xFFF6F6F6),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(5))),
            child: Container(
              width: 80,
              child: Center(
                  child: Column(
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Container(
                    child: Center(
                        child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Image.asset(sensorModel![index].image,
                                color: sensorModel![index].color))),
                    width: 35,
                    height: 30,
                  ),
                  Padding(
                      padding:
                          const EdgeInsets.only(bottom: 2, left: 2, right: 2),
                      child: AutoSizeText(
                        sensorModel![index].text,
                        maxLines: 2,
                        minFontSize: 6,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 10.0,
                            color: sensorModel![index].color,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat'),
                      )),
                ],
              )),
            ),
          ),
        ),
      ),
    );
  }
}
