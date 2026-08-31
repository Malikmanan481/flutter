import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:speedotrack/bloc/bloc_home_item.dart';
import 'package:speedotrack/globals.dart';

class TraccarMapService {
  final String baseUrl;
  final String basicAuth; // Base64 encoded "username:password"

  TraccarMapService({
    required this.baseUrl,
    required this.basicAuth,
  });

  Map<String, String> get _headers => {
        'Authorization': 'Basic $basicAuth',
        'Accept': 'application/json',
      };

  /// Fetch devices & positions from Traccar API and map for MapFragment
  Future<List<HomeItem>> fetchMapData() async {
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('$baseUrl/api/devices'), headers: _headers),
        http.get(Uri.parse('$baseUrl/api/positions'), headers: _headers),
      ]);

      if (responses[0].statusCode == 200 && responses[1].statusCode == 200) {
        List<dynamic> devicesJson = jsonDecode(responses[0].body);
        List<dynamic> positionsJson = jsonDecode(responses[1].body);

        // Map latest position by deviceId
        Map<int, Map<String, dynamic>> positionMap = {};
        for (var pos in positionsJson) {
          if (pos['deviceId'] != null) {
            positionMap[pos['deviceId']] = pos as Map<String, dynamic>;
          }
        }

        List<HomeItem> homeItems = [];

        for (var dev in devicesJson) {
          int deviceId = dev['id'];
          Map<String, dynamic>? pos = positionMap[deviceId];

          if (pos != null) {
            homeItems.add(_createHomeItemForMap(dev, pos));
          }
        }

        return homeItems;
      }
    } catch (e) {
      print("Error fetching Traccar map data: $e");
    }
    return [];
  }

  HomeItem _createHomeItemForMap(Map<String, dynamic> device, Map<String, dynamic> position) {
    // Speed conversion: Knots to KM/H
    double speedKnots = (position['speed'] as num?)?.toDouble() ?? 0.0;
    double speedKmh = speedKnots * 1.852;

    // Vehicle Angle / Heading (0 - 360 degrees)
    double angle = (position['course'] as num?)?.toDouble() ?? 0.0;

    // Ignition & Device Status
    Map<String, dynamic> attributes = position['attributes'] ?? {};
    bool? ignition = attributes['ignition'] as bool?;
    String devStatus = (device['status'] ?? 'offline').toString().toLowerCase();

    // Map to App Status: 'm' (Moving), 's' (Stopped), 'i' (Idle), 'off' (Offline)
    String status = 'off';
    String statusMsg = 'Offline';

    if (devStatus == 'offline' || devStatus == 'unknown') {
      status = 'off';
      statusMsg = 'Device Offline';
    } else if (speedKmh > 2.0) {
      status = 'm';
      statusMsg = 'Moving (${speedKmh.toStringAsFixed(1)} km/h)';
    } else if (ignition == true) {
      status = 'i';
      statusMsg = 'Engine Idle';
    } else {
      status = 's';
      statusMsg = 'Stopped';
    }

    return HomeItem(
      id: device['id'].toString(),
      name: device['name'] ?? 'Device ${device['id']}',
      imei: device['uniqueId']?.toString() ?? '',
      lat: (position['latitude'] as num?)?.toString() ?? '0.0',
      lng: (position['longitude'] as num?)?.toString() ?? '0.0',
      speed: speedKmh,
      angle: angle,
      status: status,
      statusMessage: statusMsg,
      imageName: device['category'] ?? 'car',
      lastUpdate: device['lastUpdate'] ?? position['fixTime'] ?? '',
    );
  }

  /// Sync continuously with Stream controller
  void startLiveMapSync({int intervalSeconds = 5}) {
    Timer.periodic(Duration(seconds: intervalSeconds), (timer) async {
      List<HomeItem> items = await fetchMapData();
      if (items.isNotEmpty && Globals.homeBloc != null) {
        Globals.homeBloc!.updateHomeList(items);
      }
    });
  }
}
