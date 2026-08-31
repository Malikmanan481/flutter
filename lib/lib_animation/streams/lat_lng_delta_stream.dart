import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:speedotrack/lib_animation/models/lat_lng_delta.dart';

class LatLngDeltaStream {
  final _controller = StreamController<LatLngDelta>.broadcast();

  LatLng? _lastLatLng;

  Stream<LatLngDelta> get stream => _controller.stream;

  void addLatLng(LatLngDelta delta) {
    if (delta.to != null) {
      _lastLatLng = delta.to;
    }
    _controller.sink.add(delta);
  }

  // ==========================================
  // TRACCAR LIVE WEBSOCKET & POSITIONS INTEGRATION
  // ==========================================

  /// Pushes raw Traccar position JSON from `/api/socket` or `/api/positions` into animation stream
  void addTraccarPosition(Map<String, dynamic> positionJson) {
    final delta = LatLngDelta.fromTraccarPosition(
      previousLatLng: _lastLatLng,
      newPositionJson: positionJson,
    );

    if (delta.to != null) {
      _lastLatLng = delta.to;
      _controller.sink.add(delta);
    }
  }

  /// Manually resets or initializes the last known tracking coordinate
  void resetLastPosition([LatLng? position]) {
    _lastLatLng = position;
  }

  dispose() {
    _controller.close();
  }
}
