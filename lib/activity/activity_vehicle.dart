import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:html/parser.dart';
import 'package:intl/intl.dart' as intl;
import 'package:speedotrack/globals.dart';
import 'package:speedotrack/network/network_api_request.dart';

class VehicleInfoModel {
  final String? name;
  final String? status;
  final String? image;

  VehicleInfoModel(this.name, this.status, this.image);
}

class VehicleActivity extends StatefulWidget {
  final String? name;
  final String? imei;

  const VehicleActivity({Key? key, @required this.name, @required this.imei})
      : super(key: key);

  @override
  _VehicleActivityState createState() =>
      _VehicleActivityState(name: name, imei: imei);
}

class _VehicleActivityState extends State<VehicleActivity> {
  final String? name;
  final String? imei;
  bool loading = false;

  _VehicleActivityState({this.name, this.imei});

  List<VehicleInfoModel> vehicleInfoModelArray = [];

  @override
  void initState() {
    super.initState();
    fetchTraccarData();
  }

  // ==================== TRACCAR API INTEGRATION ====================
  void fetchTraccarData() async {
    vehicleInfoModelArray.clear();

    String simNumber = 'N/A';
    String odometerStr = '0 Km';
    String expiry = 'No Data';
    String deviceModel = 'N/A';
    String connection = 'no';
    String gps = 'no';
    String engineHoursStr = '0 hrs';

    int? deviceId;

    try {
      // 1. Fetch Device Info from Traccar REST API
      var devRes = await NetworkHelper().requestDataFromNetworkWithTimeoutGET(
        urlFile: 'api/devices?uniqueId=$imei',
        context: context,
      );

      Map<String, dynamic>? deviceData;
      if (devRes != null && devRes.isNotEmpty) {
        var parsed = devRes is String ? jsonDecode(devRes) : devRes;
        if (parsed is List && parsed.isNotEmpty) {
          deviceData = parsed[0];
        }
      }

      if (deviceData != null) {
        deviceId = deviceData['id'];
        simNumber = deviceData['phone'] ??
            deviceData['attributes']?['phone'] ??
            deviceData['attributes']?['simNumber'] ??
            'N/A';
        deviceModel = deviceData['model'] ??
            deviceData['category'] ??
            deviceData['name'] ??
            'Traccar Device';

        String statusStr = deviceData['status'] ?? 'offline';
        connection =
            (statusStr == 'online' || statusStr == 'unknown') ? 'yes' : 'no';

        if (deviceData['expirationTime'] != null) {
          try {
            DateTime expDate =
                DateTime.parse(deviceData['expirationTime']).toLocal();
            expiry = intl.DateFormat('yyyy-MM-dd').format(expDate);
          } catch (_) {
            expiry = deviceData['expirationTime'].toString().split('T')[0];
          }
        }

        Map<String, dynamic> devAttr =
            deviceData['attributes'] is Map ? deviceData['attributes'] : {};
        if (devAttr.containsKey('decoder.odometer') ||
            devAttr.containsKey('odometer')) {
          var odo = devAttr['odometer'] ?? devAttr['decoder.odometer'] ?? 0;
          double odoKm = (odo is num) ? odo / 1000 : 0.0;
          odometerStr = '${odoKm.toStringAsFixed(1)} Km';
        }
      }

      // 2. Fetch Position Telemetry for Live Status
      if (deviceId != null) {
        var posRes = await NetworkHelper().requestDataFromNetworkWithTimeoutGET(
          urlFile: 'api/positions?deviceId=$deviceId',
          context: context,
        );

        if (posRes != null && posRes.isNotEmpty) {
          var parsedPos = posRes is String ? jsonDecode(posRes) : posRes;
          if (parsedPos is List && parsedPos.isNotEmpty) {
            var pos = parsedPos[0];
            bool isValid = pos['valid'] ?? false;
            gps = isValid ? 'yes' : 'no';

            Map<String, dynamic> posAttr =
                pos['attributes'] is Map ? pos['attributes'] : {};

            if (posAttr.containsKey('totalDistance') ||
                posAttr.containsKey('odometer')) {
              var odo = posAttr['totalDistance'] ?? posAttr['odometer'] ?? 0;
              double odoKm = (odo is num) ? odo / 1000 : 0.0;
              odometerStr = '${odoKm.toStringAsFixed(1)} Km';
            }

            if (posAttr.containsKey('hours')) {
              var hrsMs = posAttr['hours'] ?? 0;
              double hrs = (hrsMs is num) ? hrsMs / 3600000 : 0.0;
              engineHoursStr = '${hrs.toStringAsFixed(1)} hrs';
            }
          }
        }
      }

      // Build primary vehicle information cards
      vehicleInfoModelArray.add(
          VehicleInfoModel('IMEI', imei, 'images/vehicleInfoImeiIcon.png'));
      vehicleInfoModelArray.add(VehicleInfoModel(
          'Sim Number', simNumber, 'images/vehicleInfoSimNoIcon.png'));
      vehicleInfoModelArray.add(VehicleInfoModel('odometer'.tr, odometerStr,
          'images/vehicleInfoOdometerIcon.png'));
      vehicleInfoModelArray.add(VehicleInfoModel(
          'expiryDate'.tr, expiry, 'images/vehicleInfoExpiryDateIcon.png'));
      vehicleInfoModelArray.add(VehicleInfoModel(
          'device'.tr, deviceModel, 'images/vehicleInfoDeviceIcon.png'));
      vehicleInfoModelArray.add(VehicleInfoModel(
          'internet'.tr, connection, 'images/vehicleInfoInternetIcon.png'));
      vehicleInfoModelArray
          .add(VehicleInfoModel('GPS', gps, 'images/vehicleInfoGpsIcon.png'));
      vehicleInfoModelArray.add(VehicleInfoModel(
          'Engine Hours', engineHoursStr, 'images/vehicleInfoEngineHoursIcon.png'));

      // 3. Fetch Maintenance Services from Traccar API
      if (deviceId != null) {
        var maintRes =
            await NetworkHelper().requestDataFromNetworkWithTimeoutGET(
          urlFile: 'api/maintenance?deviceId=$deviceId',
          context: context,
        );

        if (maintRes != null && maintRes.isNotEmpty) {
          var parsedMaint =
              maintRes is String ? jsonDecode(maintRes) : maintRes;
          if (parsedMaint is List) {
            for (var maint in parsedMaint) {
              String name = maint['name'] ?? 'Service';
              double period = (maint['period'] ?? 0).toDouble();

              String statusText = 'OK';
              if (period > 0) {
                statusText = 'Interval: ${period.toInt()}';
              }

              String image = getImageForService(name);
              vehicleInfoModelArray
                  .add(VehicleInfoModel(name, statusText, image));
            }
          }
        }
      }
    } catch (e) {
      // Fallback gracefully without breaking UI state
    }

    if (mounted) {
      setState(() {
        loading = true;
      });
    }
  }

  String getImageForService(String name) {
    switch (name) {
      case 'AC Filter':
        return 'images/acFilterChangeIcon.png';
      case 'Fitness':
        return 'images/carFitnessIcon.png';
      case 'Engine Oil':
        return 'images/engineOilChangeIcon.png';
      case 'Insurance':
        return 'images/insuranceIcon.png';
      case 'Oil Filter':
        return 'images/oilFilterChangeIcon.png';
      case 'Route Permit':
        return 'images/routePermitIcon.png';
      case 'Tax Token':
        return 'images/taxTokenIcon.png';
      case 'Tyre Change':
        return 'images/tyreChangeIcon.png';
      default:
        return 'images/simVehicle.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    double _crossAxisSpacing = 0, _mainAxisSpacing = 0, _aspectRatio = 2.4;
    int _crossAxisCount = 2;
    return Scaffold(
      backgroundColor: Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Globals.appColor,
        elevation: 0.0,
        title: Text(
          '${name!}',
          style:
              TextStyle(color: Color(0xFFF6F6F6), fontFamily: 'Baloo_Thambi_2'),
        ),
        iconTheme: IconThemeData(
          color: Color(0xFFF6F6F6), //change your color here
        ),
      ),
      body: loading
          ? GridView.builder(
              itemCount: vehicleInfoModelArray.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _crossAxisCount,
                crossAxisSpacing: _crossAxisSpacing,
                mainAxisSpacing: _mainAxisSpacing,
                childAspectRatio: _aspectRatio,
              ),
              itemBuilder: (BuildContext context, int index) {
                return Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(5))),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Expanded(
                            flex: 3,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 5.0),
                                    child: Text(
                                      '${vehicleInfoModelArray[index].name}',
                                      maxLines: 1,
                                      textAlign: TextAlign.start,
                                      style: TextStyle(
                                          color: Globals.appColor,
                                          fontSize: 12,
                                          letterSpacing: 1.3,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Montserrat'),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 5,
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 5.0),
                                    child: Text(
                                      '${vehicleInfoModelArray[index].status!}',
                                      maxLines: 1,
                                      textAlign: TextAlign.start,
                                      style: TextStyle(
                                          color: vehicleInfoModelArray[index]
                                                  .status!
                                                  .contains('EXPIRED')
                                              ? Colors.red
                                              : Color(0xFF7E8188),
                                          fontSize: 10,
                                          letterSpacing: 1.3,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Montserrat'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: SizedBox(
                              height: 40,
                              width: 40,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Image.asset(
                                  vehicleInfoModelArray[index].image!,
                                  color: Globals.appColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            )
          : Center(
              child: CircularProgressIndicator(
                  backgroundColor: Color(0xFFF6F6F6),
                  valueColor: new AlwaysStoppedAnimation<Color>(
                    Globals.appColor,
                  )),
            ),
    );
  }
}
