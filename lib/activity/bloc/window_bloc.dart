import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speedotrack/activity/bloc/window_event.dart';
import 'package:speedotrack/activity/bloc/window_state.dart';

class WindowBloc extends Bloc<WindowEvent, WindowState> {
  WindowBloc() : super(NoEventState());

  WindowState get initialState => NoEventState();
  double offsetY = 0.0;
  double offsetX = 0.0;
  double height = 0;
  double width = 0;

  // Cached Traccar position & attributes payload
  Map<String, dynamic>? _lastTraccarPosition;
  Map<String, dynamic>? get lastTraccarPosition => _lastTraccarPosition;

  @override
  Stream<WindowState> mapEventToState(WindowEvent? event) async* {
    if (event is ChangePositionEvent) {
      var devicePixelRatio = Platform.isAndroid
          ? MediaQuery.of(event.context!).devicePixelRatio
          : 1.0;
      if (height == 0 && width == 0) {
        offsetY =
            (event.screenCoordinate?.y.toDouble() ?? 0) / devicePixelRatio;
        offsetX =
            (event.screenCoordinate?.x.toDouble() ?? 0) / devicePixelRatio;
      } else {
        offsetY =
            (event.screenCoordinate?.y.toDouble() ?? 0) / devicePixelRatio -
                (height + 50);
        offsetX =
            (event.screenCoordinate?.x.toDouble() ?? 0) / devicePixelRatio -
                ((width / 2));
      }

      yield PositionChangedState(offsetX: offsetX, offsetY: offsetY);
      yield NoEventState();
    } else if (event is WindowLoadedEvent) {
      height = event.height!;
      width = event.width!;
      offsetY = offsetY - (height + 90);
      offsetX = offsetX - ((width / 2));
      yield PositionChangedState(offsetX: offsetX, offsetY: offsetY);
      yield NoEventState();
    }
  }

  /// Helper to parse Traccar API `/api/positions` payload into Map data for Window popup UI
  Map<String, String> formatTraccarData(
      Map<String, dynamic> positionJson, String deviceName) {
    _lastTraccarPosition = positionJson;
    Map<String, String> data = {};

    if (deviceName.isNotEmpty) {
      data['Name'] = deviceName;
    }

    // Speed conversion: Traccar knots to Km/h (1 knot = 1.852 km/h)
    double speedKnots = ((positionJson['speed'] ?? 0) as num).toDouble();
    int speedKmH = (speedKnots * 1.852).round();
    data['Speed'] = '$speedKmH km/h';

    // Extract attributes (Ignition, Distance, Battery)
    Map<String, dynamic> attributes =
        (positionJson['attributes'] as Map<String, dynamic>?) ?? {};

    if (attributes.containsKey('ignition')) {
      bool ignition = attributes['ignition'] == true;
      data['Ignition'] = ignition ? 'ON' : 'OFF';
    }

    if (attributes.containsKey('totalDistance')) {
      double totalDist = ((attributes['totalDistance'] ?? 0) as num).toDouble();
      data['Odometer'] = '${(totalDist / 1000.0).toStringAsFixed(1)} km';
    }

    if (attributes.containsKey('batteryLevel')) {
      data['Battery'] = '${attributes['batteryLevel']}%';
    }

    if (positionJson['address'] != null &&
        positionJson['address'].toString().isNotEmpty) {
      data['Address'] = positionJson['address'].toString();
    }

    return data;
  }
}
