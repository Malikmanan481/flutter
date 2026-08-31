import 'dart:collection';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:custom_progress_button/custom_progress_button.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';
import 'package:location/location.dart';
import 'package:speedotrack/activity/activity_about_us.dart';
import 'package:speedotrack/activity/activity_geofencelist.dart';
import 'package:speedotrack/globals.dart';
import 'package:speedotrack/network/network_api_request.dart';

class GeoFenceMapActivity extends StatefulWidget {
  final List<String>? nameList;
  GeoFenceMapActivity({this.nameList});

  @override
  _GeoFenceMapActivityState createState() => _GeoFenceMapActivityState();
}

class _GeoFenceMapActivityState extends State<GeoFenceMapActivity> {
  // Location
  LocationData? _locationData;
  // Maps
  bool mapTypeEnabled = Globals.prefs!.getBool('mapHybrid')!;
  Set<Polygon> _polygons = HashSet<Polygon>();
  Set<Circle> _circles = HashSet<Circle>();
  List<LatLng> polygonLatLngs = [];
  double radius = 50;
  //ids
  int _polygonIdCounter = 1;
  int _circleIdCounter = 1;
  // Type controllers
  bool _isPolygon = false; //Default
  bool _isCircle = true;
  bool zoneIn = true;
  bool zoneOut = true;
  LatLng? position;

  TextEditingController textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  // Draw Polygon to the map
  void _setPolygon() {
    final String polygonIdVal = 'polygon_id_$_polygonIdCounter';
    _polygons.add(Polygon(
      polygonId: PolygonId(polygonIdVal),
      points: polygonLatLngs,
      strokeWidth: 2,
      strokeColor: Colors.red,
      fillColor: Colors.red.withOpacity(0.5),
    ));
  }

  // Set circles as points to the map
  void _setCircles(LatLng point) {
    final String circleIdVal = 'circle_id_$_circleIdCounter';
    _circleIdCounter++;
    _circles.add(Circle(
        circleId: CircleId(circleIdVal),
        center: point,
        radius: radius,
        fillColor: Colors.red.withOpacity(0.5),
        strokeWidth: 2,
        strokeColor: Colors.red));
  }

  Widget _fabPolygon() {
    return FloatingActionButton.extended(
      onPressed: () {
        //Remove the last point setted at the polygon
        setState(() {
          if (polygonLatLngs.isNotEmpty) {
            polygonLatLngs.removeLast();
          }
        });
      },
      icon: Icon(Icons.undo),
      label: Text('undoPoint'.tr),
      backgroundColor: Globals.appColor,
    );
  }

  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};

  int earthRadius = 6371000;

  LatLng getPoint(LatLng center, int radius, double angle) {
    // Get the coordinates of a circle point at the given angle
    double east = radius * cos(angle);
    double north = radius * sin(angle);

    double cLat = center.latitude;
    double cLng = center.longitude;
    double latRadius = earthRadius * cos(cLat / 180 * pi);

    double newLat = cLat + (north / earthRadius / pi * 180);
    double newLng = cLng + (east / latRadius / pi * 180);
    return new LatLng(newLat, newLng);
  }

  Location location = new Location();
  bool? _serviceEnabled;
  PermissionStatus? _permissionGranted;

  Future<LocationData> _checkLocationPermission() async {
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled!) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled!) {
        Fluttertoast.showToast(
            msg: 'unableToFetchLocation'.tr,
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Globals.appColor,
            textColor: Colors.white,
            fontSize: 16.0);
      }
    }
    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        Fluttertoast.showToast(
            msg: 'unableToFetchLocation'.tr,
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Globals.appColor,
            textColor: Colors.white,
            fontSize: 16.0);
      }
    }
    return _locationData = await location.getLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Globals.appColor,
          elevation: 0.0,
          title: Text(
            'geoFenceMap'.tr,
            style: TextStyle(
                color: Color(0xFFF6F6F6), fontFamily: 'Baloo_Thambi_2'),
          ),
          iconTheme: IconThemeData(
            color: Color(0xFFF6F6F6), //change your color here
          ),
        ),
        floatingActionButton: polygonLatLngs.length > 0 && _isPolygon
            ? Padding(
                child: _fabPolygon(),
                padding: EdgeInsets.only(top: 60),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
        body: SafeArea(
          child: FutureBuilder<Object>(
              future: _checkLocationPermission(),
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
                          valueColor: new AlwaysStoppedAnimation<Color>(
                              Globals.appColor),
                        ),
                      ),
                    ],
                  ));
                }
                return Column(
                  children: <Widget>[
                    Expanded(
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(_locationData!.latitude!,
                              _locationData!.longitude!),
                          zoom: 16,
                        ),
                        mapType:
                            mapTypeEnabled ? MapType.hybrid : MapType.normal,
                        markers: Set<Marker>.of(markers.values),
                        circles: _circles,
                        polygons: _polygons,
                        zoomControlsEnabled: false,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        onMapCreated: (value) async {
                          await Future.delayed(Duration(milliseconds: 500));
                          position = LatLng(_locationData!.latitude!,
                              _locationData!.longitude!);
                          setState(() {
                            _setCircles(LatLng(_locationData!.latitude!,
                                _locationData!.longitude!));
                          });
                        },
                        onTap: (point) {
                          if (_isPolygon) {
                            setState(() {
                              _circles.clear();
                              polygonLatLngs.add(point);
                              _setPolygon();
                            });
                          } else if (_isCircle) {
                            position = point;
                            setState(() {
                              polygonLatLngs.clear();
                              _polygons.clear();
                              _circles.clear();
                              _setCircles(point);
                            });
                          }
                        },
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        padding: EdgeInsets.all(10),
                        child: Column(
                          children: [
                            Visibility(
                              visible: _isCircle,
                              child: Slider(
                                  value: radius,
                                  min: 0,
                                  max: 500,
                                  divisions: 50,
                                  activeColor: Globals.appColor,
                                  inactiveColor: Color(0xFF7E8188),
                                  label: '$radius',
                                  onChanged: (newValue) {
                                    setState(() {
                                      radius = newValue;
                                      polygonLatLngs.clear();
                                      _polygons.clear();
                                      _circles.clear();
                                      _setCircles(position!);
                                    });
                                  },
                                  semanticFormatterCallback: (double newValue) {
                                    return '${newValue.round()}';
                                  }),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                      padding: EdgeInsets.only(
                                          left: 10.0, right: 10.0, top: 2.0),
                                      child: TextField(
                                          keyboardType: TextInputType.name,
                                          controller: textEditingController,
                                          textCapitalization:
                                              TextCapitalization.words,
                                          decoration: InputDecoration(
                                            hintText: 'enterZone'.tr,
                                          ))),
                                  flex: 3,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: <Widget>[
                                    ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          _isPolygon = true;
                                          _isCircle = false;
                                        });
                                      },
                                      child: Text(
                                        'custom'.tr,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _isPolygon
                                                ? Globals.appColor
                                                : Colors.grey),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          radius = 50;
                                          _isPolygon = false;
                                          _isCircle = true;
                                        });
                                      },
                                      child: Text(
                                        'circle'.tr,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _isCircle
                                                ? Globals.appColor
                                                : Colors.grey),
                                      ),
                                    )
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Expanded(
                                  child: CheckboxListTile(
                                    title: Text(
                                      'zoneIn'.tr,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Globals.appColor,
                                          fontSize: 14,
                                          fontFamily: 'Montserrat'),
                                    ),
                                    value: zoneIn,
                                    activeColor: Globals.appColor,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        zoneIn = value!;
                                      });
                                    },
                                  ),
                                  flex: 3,
                                ),
                                Expanded(
                                  child: CheckboxListTile(
                                    title: Text(
                                      'zoneOut'.tr,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Globals.appColor,
                                          fontSize: 14,
                                          fontFamily: 'Montserrat'),
                                    ),
                                    value: zoneOut,
                                    activeColor: Globals.appColor,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        zoneOut = value!;
                                      });
                                    },
                                  ),
                                  flex: 3,
                                ),
                                Expanded(
                                  child: CustomProgressButton(
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
                                        'save'.tr,
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 16),
                                      ),
                                      ButtonState.idle: Text(
                                        'save'.tr,
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: Colors.white,
                                        ),
                                      ),
                                    },
                                    onPressed: () async {
                                      String zoneName = textEditingController.text.trim();

                                      if (zoneName.isEmpty) {
                                        Fluttertoast.showToast(
                                            msg: 'fillDetails'.tr,
                                            toastLength: Toast.LENGTH_SHORT,
                                            gravity: ToastGravity.CENTER,
                                            timeInSecForIosWeb: 1,
                                            backgroundColor: Globals.appColor,
                                            textColor: Colors.white,
                                            fontSize: 16.0);
                                        return;
                                      }

                                      if (widget.nameList != null &&
                                          widget.nameList!.contains(zoneName.toLowerCase())) {
                                        Fluttertoast.showToast(
                                            msg: 'enterName'.tr,
                                            toastLength: Toast.LENGTH_SHORT,
                                            gravity: ToastGravity.CENTER,
                                            timeInSecForIosWeb: 1,
                                            backgroundColor: Globals.appColor,
                                            textColor: Colors.white,
                                            fontSize: 16.0);
                                        return;
                                      }

                                      // Prepare WKT (Well-Known Text) string for Traccar API
                                      String wktArea = "";
                                      if (_isCircle && position != null) {
                                        wktArea = "CIRCLE (${position!.latitude} ${position!.longitude}, $radius)";
                                      } else if (_isPolygon && polygonLatLngs.isNotEmpty) {
                                        List<String> pts = polygonLatLngs
                                            .map((p) => "${p.latitude} ${p.longitude}")
                                            .toList();
                                        // Close the polygon loop if required by standard WKT
                                        if (pts.first != pts.last) {
                                          pts.add(pts.first);
                                        }
                                        wktArea = "POLYGON ((${pts.join(', ')}))";
                                      }

                                      if (wktArea.isEmpty || (!zoneIn && !zoneOut)) {
                                        Fluttertoast.showToast(
                                            msg: 'fillDetails'.tr,
                                            toastLength: Toast.LENGTH_SHORT,
                                            gravity: ToastGravity.CENTER,
                                            timeInSecForIosWeb: 1,
                                            backgroundColor: Globals.appColor,
                                            textColor: Colors.white,
                                            fontSize: 16.0);
                                        return;
                                      }

                                      try {
                                        // 1. Create Geofence in Traccar via POST /api/geofences
                                        var response = await NetworkHelper().requestDataFromNetwork(
                                            urlFile: '/api/geofences',
                                            httpMethod: 'POST',
                                            body: {
                                              'name': zoneName,
                                              'description': '',
                                              'area': wktArea,
                                            },
                                            context: context);

                                        if (response != null && response.isNotEmpty) {
                                          var decoded = jsonDecode(response);
                                          int? geofenceId = decoded['id'];

                                          // 2. Link Geofence to Devices via POST /api/permissions if available
                                          if (geofenceId != null && Globals.imeiArray.isNotEmpty) {
                                            for (var devId in Globals.imeiArray) {
                                              try {
                                                await NetworkHelper().requestDataFromNetwork(
                                                    urlFile: '/api/permissions',
                                                    httpMethod: 'POST',
                                                    body: {
                                                      'deviceId': int.tryParse(devId) ?? devId,
                                                      'geofenceId': geofenceId
                                                    },
                                                    context: context);
                                              } catch (_) {}
                                            }
                                          }

                                          Fluttertoast.showToast(
                                              msg: 'zoneSuccessful'.tr,
                                              toastLength: Toast.LENGTH_SHORT,
                                              gravity: ToastGravity.CENTER,
                                              timeInSecForIosWeb: 1,
                                              backgroundColor: Globals.appColor,
                                              textColor: Colors.white,
                                              fontSize: 16.0);

                                          polygonLatLngs.clear();
                                          textEditingController.clear();

                                          Navigator.of(context)
                                            ..pop()
                                            ..pop()
                                            ..push(CupertinoPageRoute(
                                                builder: (context) =>
                                                    GeoFenceListActivity()));
                                        } else {
                                          Fluttertoast.showToast(
                                              msg: 'fillDetails'.tr,
                                              toastLength: Toast.LENGTH_SHORT,
                                              gravity: ToastGravity.CENTER,
                                              timeInSecForIosWeb: 1,
                                              backgroundColor: Globals.appColor,
                                              textColor: Colors.white,
                                              fontSize: 16.0);
                                        }
                                      } catch (e) {
                                        Fluttertoast.showToast(
                                            msg: 'fillDetails'.tr,
                                            toastLength: Toast.LENGTH_SHORT,
                                            gravity: ToastGravity.CENTER,
                                            timeInSecForIosWeb: 1,
                                            backgroundColor: Globals.appColor,
                                            textColor: Colors.white,
                                            fontSize: 16.0);
                                      }
                                    },
                                    progressWidget: CircularProgressIndicator(
                                        backgroundColor: Globals.appColor,
                                        valueColor:
                                            new AlwaysStoppedAnimation<Color>(
                                                Colors.white)),
                                  ),
                                  flex: 2,
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                );
              }),
        ));
  }
}
