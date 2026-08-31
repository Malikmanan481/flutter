import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rxdart/subjects.dart';
import 'package:speedotrack/bloc/bloc_home_item.dart';
import 'package:speedotrack/globals.dart';
import 'package:speedotrack/helper/helper.dart';
import 'package:speedotrack/sharedPrefs/main_prefs.dart';

class HomeBloc {
  final StreamController<List<HomeItem>> _homeListStreamController =
      BehaviorSubject<List<HomeItem>>();

  Stream<List<HomeItem>> get homeListStream =>
      _homeListStreamController.stream;

  StreamSink<List<HomeItem>> get homeListSink =>
      _homeListStreamController.sink;

  HomeBloc() {
    final List<String>? imeis =
        Globals.prefs?.getStringList(MainPrefs.keyIMEI);
    if (imeis != null && imeis.isNotEmpty) {
      homeListSink.add(Helper().homeScreenSetup(imeis));
    }
  }

  // ==========================================
  // TRACCAR API BACKEND INTEGRATION
  // ==========================================

  /// Fetch devices (/api/devices) & positions (/api/positions) directly from Traccar REST API
  Future<void> fetchTraccarData({
    required String baseUrl,
    Map<String, String>? headers,
  }) async {
    try {
      final String cleanUrl =
          baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

      final Map<String, String> requestHeaders = headers ??
          {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          };

      // 1. Fetch devices list from Traccar API (/api/devices)
      final devicesResponse = await http.get(
        Uri.parse('$cleanUrl/api/devices'),
        headers: requestHeaders,
      );

      if (devicesResponse.statusCode != 200) return;

      final List<dynamic> devicesJson =
          jsonDecode(devicesResponse.body) as List<dynamic>;

      // 2. Fetch live positions from Traccar API (/api/positions)
      final positionsResponse = await http.get(
        Uri.parse('$cleanUrl/api/positions'),
        headers: requestHeaders,
      );

      List<dynamic> positionsJson = [];
      if (positionsResponse.statusCode == 200) {
        positionsJson =
            jsonDecode(positionsResponse.body) as List<dynamic>;
      }

      // Map position payloads by deviceId for rapid lookup
      final Map<int, Map<String, dynamic>> positionMap = {};
      for (var pos in positionsJson) {
        if (pos is Map<String, dynamic> && pos.containsKey('deviceId')) {
          positionMap[pos['deviceId'] as int] = pos;
        }
      }

      // 3. Map Traccar API JSON items to HomeItem list
      final List<HomeItem> items = devicesJson.map((dev) {
        final Map<String, dynamic> deviceMap = dev as Map<String, dynamic>;
        final int deviceId = deviceMap['id'] as int? ?? 0;
        final Map<String, dynamic>? posMap = positionMap[deviceId];

        return HomeItem.fromTraccar(
          deviceJson: deviceMap,
          positionJson: posMap,
        );
      }).toList();

      if (!_homeListStreamController.isClosed) {
        homeListSink.add(items);
      }
    } catch (_) {
      // Fallback prevents stream interruption
    }
  }

  /// Update stream directly using raw JSON payloads received from Traccar WebSocket or REST calls
  void updateFromTraccarRaw({
    required List<Map<String, dynamic>> devices,
    List<Map<String, dynamic>>? positions,
  }) {
    final Map<int, Map<String, dynamic>> positionMap = {};
    if (positions != null) {
      for (var pos in positions) {
        if (pos.containsKey('deviceId')) {
          positionMap[pos['deviceId'] as int] = pos;
        }
      }
    }

    final List<HomeItem> items = devices.map((dev) {
      final int deviceId = dev['id'] as int? ?? 0;
      return HomeItem.fromTraccar(
        deviceJson: dev,
        positionJson: positionMap[deviceId],
      );
    }).toList();

    if (!_homeListStreamController.isClosed) {
      homeListSink.add(items);
    }
  }

  bool isClosed() {
    return _homeListStreamController.isClosed;
  }

  void dispose() {
    _homeListStreamController.close();
  }
}
