import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:speedotrack/bloc/bloc_home_item.dart';
import 'package:speedotrack/globals.dart';

class TraccarApiService {
  final String baseUrl; // e.g. "https://demo.traccar.org" or "http://your-server-ip:8082"
  final String userOrToken; // Username / Email
  final String password; // Password

  Timer? _syncTimer;

  TraccarApiService({
    required this.baseUrl,
    required this.userOrToken,
    required this.password,
  });

  /// Base64 Basic Auth Header
  Map<String, String> get _headers {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$userOrToken:$password'));
    return {
      'Authorization': basicAuth,
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  /// Start Automatic Polling for UI Update
  void startAutoSync({int intervalSeconds = 5}) {
    _syncTimer?.cancel();
    fetchAndUpdateBloc();
    _syncTimer = Timer.periodic(Duration(seconds: intervalSeconds), (_) {
      fetchAndUpdateBloc();
    });
  }

  void stopAutoSync() {
    _syncTimer?.cancel();
  }

  /// Traccar API Call (/api/devices + /api/positions)
  Future<List<HomeItem>> fetchDevicesAndPositions() async {
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('$baseUrl/api/devices'), headers: _headers),
        http.get(Uri.parse('$baseUrl/api/positions'), headers: _headers),
      ]);

      if (responses[0].statusCode == 200 && responses[1].statusCode == 200) {
        List<dynamic> devicesJson = jsonDecode(responses[0].body);
        List<dynamic> positionsJson = jsonDecode(responses[1].body);

        // Map positions by deviceId for quick lookup
        Map<int, Map<String, dynamic>> positionMap = {};
        for (var pos in positionsJson) {
          if (pos['deviceId'] != null) {
            positionMap[pos['deviceId']] = pos as Map<String, dynamic>;
          }
        }

        List<HomeItem> homeItemsList = [];

        for (var dev in devicesJson) {
          int deviceId = dev['id'];
          Map<String, dynamic>? pos = positionMap[deviceId];
          
          HomeItem item = _mapToHomeItem(dev, pos);
          homeItemsList.add(item);
        }

        return homeItemsList;
      } else {
        throw Exception('Traccar API Error: ${responses[0].statusCode}');
      }
    } catch (e) {
      print("Error fetching Traccar data: $e");
      return [];
    }
  }

  /// Map Traccar Data -> HomeItem Compatible with HomeFragment UI
  HomeItem _mapToHomeItem(Map<String, dynamic> device, Map<String, dynamic>? position) {
    String deviceStatus = (device['status'] ?? 'offline').toString().toLowerCase();
    
    // Traccar speed is in Knots. Convert to KM/H (1 knot = 1.852 km/h)
    double speedKnots = (position != null && position['speed'] != null)
        ? (position['speed'] as num).toDouble()
        : 0.0;
    double speedKmh = speedKnots * 1.852;

    Map<String, dynamic> attributes = position?['attributes'] ?? {};
    bool? ignition = attributes['ignition'] as bool?;

    // Status logic: 'm' = Moving, 's' = Stopped, 'i' = Idle, 'off' = Offline
    String mappedStatus = 'off';
    
    if (deviceStatus == 'offline' || deviceStatus == 'unknown') {
      mappedStatus = 'off';
    } else if (speedKmh > 2.0) {
      mappedStatus = 'm'; // Moving
    } else if (ignition == true) {
      mappedStatus = 'i'; // Idle (Engine ON, Speed 0)
    } else {
      mappedStatus = 's'; // Stopped (Engine OFF, Speed 0)
    }

    return HomeItem(
      id: device['id'].toString(),
      name: device['name'] ?? 'Device ${device['id']}',
      status: mappedStatus,
      speed: speedKmh,
      latitude: (position?['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (position?['longitude'] as num?)?.toDouble() ?? 0.0,
      lastUpdate: device['lastUpdate'] ?? position?['fixTime'] ?? '',
      uniqueId: device['uniqueId']?.toString() ?? '',
    );
  }

  /// Sync fetched data directly into BLoC stream used by HomeFragment
  Future<void> fetchAndUpdateBloc() async {
    List<HomeItem> items = await fetchDevicesAndPositions();
    if (items.isNotEmpty && Globals.homeBloc != null) {
      Globals.homeBloc!.updateHomeList(items);
    }
  }
}
