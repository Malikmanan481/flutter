import 'dart:collection';

import 'package:flutter/material.dart';

class DeviceStore extends ChangeNotifier {
  // ==========================================
  // TRACCAR API STATE STORAGE
  // ==========================================
  final Map<int, dynamic> _devices = {};
  final Map<int, dynamic> _positions = {};
  int? _selectedDeviceId;
  bool _isLoading = false;
  String? _errorMessage;

  // ==========================================
  // GETTERS (UI & CONTROLLERS KE LIYE)
  // ==========================================

  /// Complete devices map (Key: Device ID, Value: Device Object)
  UnmodifiableMapView<int, dynamic> get devices => UnmodifiableMapView(_devices);

  /// Complete positions map (Key: Device ID, Value: Position Object)
  UnmodifiableMapView<int, dynamic> get positions => UnmodifiableMapView(_positions);

  /// Devices list format me (`/api/devices` direct rendering ke liye)
  List<dynamic> get deviceList => _devices.values.toList();

  /// Active selected device ID
  int? get selectedDeviceId => _selectedDeviceId;

  /// Active selected device object
  dynamic get selectedDevice => _selectedDeviceId != null ? _devices[_selectedDeviceId] : null;

  /// Active selected device position object (`/api/positions`)
  dynamic get selectedPosition => _selectedDeviceId != null ? _positions[_selectedDeviceId] : null;

  /// Loading state indicator
  bool get isLoading => _isLoading;

  /// Error message state
  String? get errorMessage => _errorMessage;

  // ==========================================
  // TRACCAR REST API UPDATERS
  // ==========================================

  /// `/api/devices` response se complete device list store me sync karna
  void setDevices(List<dynamic> deviceList) {
    _devices.clear();
    for (var device in deviceList) {
      if (device is Map<String, dynamic> && device.containsKey('id')) {
        _devices[device['id'] as int] = device;
      }
    }
    _errorMessage = null;
    notifyListeners();
  }

  /// `/api/positions` response se positions sync karna
  void setPositions(List<dynamic> positionList) {
    for (var pos in positionList) {
      if (pos is Map<String, dynamic> && pos.containsKey('deviceId')) {
        _positions[pos['deviceId'] as int] = pos;
      }
    }
    notifyListeners();
  }

  /// Real-time WebSocket `/api/socket` updates se single device status change update karna
  void updateDevice(Map<String, dynamic> device) {
    final int? id = device['id'] as int?;
    if (id != null) {
      _devices[id] = device;
      notifyListeners();
    }
  }

  /// Real-time WebSocket `/api/socket` se target position/location payload merge update karna
  void updatePosition(Map<String, dynamic> position) {
    final int? deviceId = position['deviceId'] as int?;
    if (deviceId != null) {
      _positions[deviceId] = position;
      notifyListeners();
    }
  }

  // ==========================================
  // HELPER METHODS
  // ==========================================

  /// Selected device set karna (`/api/devices/{id}` ya map selection ke liye)
  void selectDevice(int? deviceId) {
    _selectedDeviceId = deviceId;
    notifyListeners();
  }

  /// Fetching state control
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// API error set karna
  void setError(String? error) {
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }

  /// Logout ya session revoke (`/api/session/token/revoke`) par state reset karna
  void clearStore() {
    _devices.clear();
    _positions.clear();
    _selectedDeviceId = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
