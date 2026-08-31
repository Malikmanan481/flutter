import 'package:flutter/material.dart';

class SizeConfig {
  static double? _screenWidth;
  static double? _screenHeight;
  static double? _blockWidth = 0;
  static double? _blockHeight = 0;
  static double? textMultiplier;
  static double? imageSizeMultiplier;
  static double? heightMultiplier;
  static double? widthMultiplier;

  void init(BoxConstraints constraints, Orientation orientation) {
    if (orientation == Orientation.portrait) {
      _screenWidth = constraints.maxWidth;
      _screenHeight = constraints.maxHeight;
    } else {
      _screenWidth = constraints.maxHeight;
      _screenHeight = constraints.maxWidth;
    }
    _blockWidth = _screenWidth! / 250;
    _blockHeight = _screenHeight! / 250;
    textMultiplier = _blockHeight;
    imageSizeMultiplier = _blockWidth;
    heightMultiplier = _blockHeight;
    widthMultiplier = _blockWidth;
    print("Block Width: $_blockWidth");
    print("Block Height: $_blockHeight");
    print("screen Width: $_screenWidth");
    print("screen Height: $_screenHeight");
  }

  // ==========================================
  // TRACCAR API BACKEND UI HELPERS
  // ==========================================

  /// Get calculated resolution parameters for Traccar device images (`/api/devices/{id}/image`)
  static Map<String, int> getTraccarImageQueryParams({
    double baseWidthMultiplier = 20,
    double baseHeightMultiplier = 20,
  }) {
    final int width = (((widthMultiplier ?? 1.0) * baseWidthMultiplier)).round();
    final int height = (((heightMultiplier ?? 1.0) * baseHeightMultiplier)).round();

    return {
      'width': width > 0 ? width : 120,
      'height': height > 0 ? height : 120,
    };
  }

  /// Calculates responsive card/popup height for vehicle details loaded from `/api/positions`
  static double getTraccarMapCardHeight() {
    if (_screenHeight == null || _screenHeight == 0) return 220.0;
    return (_screenHeight! * 0.28).clamp(180.0, 350.0);
  }

  /// Calculates responsive player height for Traccar camera stream (`/api/stream/{deviceId}/{channel}/live.m3u8`)
  static double getTraccarStreamPlayerHeight() {
    if (_screenWidth == null || _screenWidth == 0) return 200.0;
    // Maintains 16:9 aspect ratio responsive to device screen width
    return (_screenWidth! * 9 / 16).clamp(150.0, 400.0);
  }
}
