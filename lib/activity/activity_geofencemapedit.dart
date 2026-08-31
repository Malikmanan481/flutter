import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:get/get.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:custom_progress_button/custom_progress_button.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:speedotrack/activity/activity_geofencelist.dart';
import 'package:speedotrack/globals.dart';
import 'package:speedotrack/network/network_api_request.dart';

class GeoFenceMapEditActivity extends StatefulWidget {
  final String? name;
  final String? id;
  final String? vertices;
  GeoFenceMapEditActivity({this.name, this.id, this.vertices});

  @override
  _GeoFenceMapEditActivityState createState() =>
      _GeoFenceMapEditActivityState();
}

class _GeoFenceMapEditActivityState extends State<GeoFenceMapEditActivity> {
  // Maps
  bool mapTypeEnabled = Globals.prefs!.getBool('mapHybrid')!;
  Set<Marker> _markers = HashSet<Marker>();
  Set<Polygon> _polygons = HashSet<Polygon>();
  Set<Circle> _circles = HashSet<Circle>();
  List<LatLng> polygonLatLngs = [];
  double radius = 50;
  //ids
  int _polygonIdCounter = 1;
  int _circleIdCounter = 1;
  // Type controllers
  bool _isPolygon = true; //Default
  bool _isCircle = false;
  bool zoneIn = true;
  bool zoneOut = true;
  LatLng? position;

  TextEditingController textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    setState(() {
      textEditingController.text = widget.name != null
          ? widget.name!.split(' created')[0]
          : '';
    });

    if (widget.vertices != null && widget.vertices!.isNotEmpty) {
      try {
        String a = '[' + widget.vertices! + ']';
        var ab = json.decode(a);
        for (int i = 0; i < ab.length; i = i + 2) {
          polygonLatLngs.add(LatLng(
              (ab[i] as num).toDouble(), (ab[i + 1] as num).toDouble()));
        }
      } catch (e) {
        // Fallback for unexpected formats
      }
    }
  }

  LatLngBounds getBounds(List<LatLng> latLngList) {
    if (latLngList.isEmpty) {
      return LatLngBounds(
        northeast: LatLng(20.5937, 78.9629),
        southwest: LatLng(20.5937, 78.9629),
      );
    }
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
          child: Column(
            children: <Widget>[
              Expanded(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(20.5937, 78.9629),
                  ),
                  mapType: mapTypeEnabled ? MapType.hybrid : MapType.normal,
                  markers: _markers,
                  circles: _circles,
                  polygons: _polygons,
                  zoomControlsEnabled: false,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  onMapCreated: (value) async {
                    setState(() {
                      if (polygonLatLngs.isNotEmpty) {
                        _setPolygon();
                      }
                    });
                    await Future.delayed(Duration(milliseconds: 500));
                    if (polygonLatLngs.isNotEmpty) {
                      value.animateCamera(CameraUpdate.newLatLngBounds(
                          getBounds(polygonLatLngs), 40));
                    }
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
                                if (position != null) {
                                  _setCircles(position!);
                                }
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
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.max,
                        children: [
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
                                  'deleteZone'.tr,
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16),
                                ),
                                ButtonState.idle: Text(
                                  'deleteZone'.tr,
                                  style: TextStyle(
                                      fontSize: 20, color: Colors.white),
                                ),
                              },
                              onPressed: () async {
                                if (widget.id == null || widget.id!.isEmpty) return;

                                try {
                                  // Traccar REST API Delete Geofence
                                  var response = await NetworkHelper()
                                      .requestDataFromNetwork(
                                          urlFile: '/api/geofences/${widget.id}',
                                          httpMethod: 'DELETE',
                                          context: context);

                                  Fluttertoast.showToast(
                                      msg: 'zoneDelete'.tr,
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
                                } catch (e) {
                                  Fluttertoast.showToast(
                                      msg: 'failure'.tr,
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
                                  valueColor: new AlwaysStoppedAnimation<Color>(
                                      Colors.white)),
                            ),
                            flex: 2,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child: CustomProgressButton(
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

                                // Construct WKT string for Traccar
                                String wktArea = "";
                                if (_isCircle && position != null) {
                                  wktArea = "CIRCLE (${position!.latitude} ${position!.longitude}, ${radius.round()})";
                                } else if (_isPolygon && polygonLatLngs.isNotEmpty) {
                                  List<String> pts = polygonLatLngs
                                      .map((p) => "${p.latitude} ${p.longitude}")
                                      .toList();
                                  if (pts.first != pts.last) {
                                    pts.add(pts.first);
                                  }
                                  wktArea = "POLYGON ((${pts.join(', ')}))";
                                }

                                if (wktArea.isEmpty) {
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
                                  // Traccar REST API Update Geofence
                                  var response = await NetworkHelper()
                                      .requestDataFromNetwork(
                                          urlFile: '/api/geofences/${widget.id}',
                                          httpMethod: 'PUT',
                                          body: {
                                            'id': int.tryParse(widget.id ?? '') ?? widget.id,
                                            'name': zoneName,
                                            'description': '',
                                            'area': wktArea,
                                          },
                                          context: context);

                                  Fluttertoast.showToast(
                                      msg: 'zoneEdit'.tr,
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
                                  valueColor: new AlwaysStoppedAnimation<Color>(
                                      Colors.white)),
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
                                  'saveEdit'.tr,
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16),
                                ),
                                ButtonState.idle: Text(
                                  'saveEdit'.tr,
                                  style: TextStyle(
                                      fontSize: 20, color: Colors.white),
                                ),
                              },
                              stateColors: {
                                ButtonState.success: Colors.green,
                                ButtonState.fail: Colors.redAccent,
                                ButtonState.loading: Colors.red,
                                ButtonState.idle: Globals.appColor,
                              },
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
          ),
        ));
  }
}
