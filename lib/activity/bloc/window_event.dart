import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract class WindowEvent extends Equatable {
  const WindowEvent();

  @override
  List<Object?> get props => [];
}

class ChangePositionEvent extends WindowEvent {
  final BuildContext? context;
  final ScreenCoordinate? screenCoordinate;

  ChangePositionEvent({this.context, this.screenCoordinate});

  @override
  List<Object?> get props => [context, screenCoordinate];
}

class WindowLoadedEvent extends WindowEvent {
  final double? height, width;

  WindowLoadedEvent({this.height, this.width});

  @override
  List<Object?> get props => [height, width];
}

// ==========================================
// TRACCAR API INTEGRATION EVENTS
// ==========================================

/// Event to pass raw Traccar API `/api/positions` JSON or WebSocket data payload
class UpdateTraccarPositionEvent extends WindowEvent {
  final Map<String, dynamic> positionJson;
  final String? deviceName;

  const UpdateTraccarPositionEvent({
    required this.positionJson,
    this.deviceName,
  });

  @override
  List<Object?> get props => [positionJson, deviceName];
}

/// Event to trigger fetching live device data from `/api/devices/{id}` or `/api/positions`
class FetchTraccarDeviceDataEvent extends WindowEvent {
  final int deviceId;

  const FetchTraccarDeviceDataEvent({required this.deviceId});

  @override
  List<Object?> get props => [deviceId];
}
