import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:speedotrack/activity/bloc/window_event.dart';
import 'package:speedotrack/activity/bloc/window_state.dart';
import 'package:speedotrack/activity/bloc/window_bloc.dart';

class Window extends StatefulWidget {
  final Map<String, String>? data;

  Window({
    Key? key,
    this.data,
  }) : super(key: key);

  /// Helper factory to populate window directly from Traccar API `/api/positions` payload
  factory Window.fromTraccarPosition({
    Key? key,
    required Map<String, dynamic> positionJson,
    String? deviceName,
  }) {
    Map<String, String> formattedData = {};

    if (deviceName != null && deviceName.isNotEmpty) {
      formattedData['Name'] = deviceName;
    }

    // Speed conversion: Traccar returns knots -> Convert to Km/h (1 knot = 1.852 km/h)
    double rawSpeed = (positionJson['speed'] ?? 0.0) as double;
    int speedKmH = (rawSpeed * 1.852).round();
    formattedData['Speed'] = '$speedKmH km/h';

    // Ignition state from Traccar attributes map
    Map<String, dynamic> attributes =
        (positionJson['attributes'] as Map<String, dynamic>?) ?? {};
    if (attributes.containsKey('ignition')) {
      bool ignition = attributes['ignition'] == true;
      formattedData['Ignition'] = ignition ? 'ON' : 'OFF';
    }

    // Odometer/Distance from Traccar attributes (meters -> km)
    if (attributes.containsKey('totalDistance')) {
      double totalDist = ((attributes['totalDistance'] ?? 0) as num).toDouble();
      formattedData['Odometer'] =
          '${(totalDist / 1000.0).toStringAsFixed(1)} km';
    }

    // Battery status
    if (attributes.containsKey('batteryLevel')) {
      formattedData['Battery'] = '${attributes['batteryLevel']}%';
    }

    // Fix time formatting
    String fixTimeRaw = positionJson['fixTime'] ?? positionJson['deviceTime'] ?? '';
    if (fixTimeRaw.isNotEmpty) {
      try {
        DateTime parsedDate = DateTime.parse(fixTimeRaw).toLocal();
        formattedData['Time'] = DateFormat('dd/MM HH:mm').format(parsedDate);
      } catch (_) {
        formattedData['Time'] = fixTimeRaw;
      }
    }

    // Address if reverse-geocoded by Traccar
    if (positionJson['address'] != null &&
        positionJson['address'].toString().isNotEmpty) {
      formattedData['Address'] = positionJson['address'].toString();
    }

    return Window(
      key: key,
      data: formattedData,
    );
  }

  @override
  _WindowState createState() => _WindowState();
}

class _WindowState extends State<Window> {
  double offsetY = 0, offsetX = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        BlocProvider.of<WindowBloc>(context).add(WindowLoadedEvent(
            height: context.size!.height, width: context.size!.width)));
  }

  @override
  Widget build(BuildContext context) {
    final displayData = widget.data ?? {};

    return BlocListener<WindowBloc, WindowState>(
        listener: (context, state) {
          if (state is PositionChangedState) {
            setState(() {
              offsetY = state.offsetY!;
              offsetX = state.offsetX!;
            });
          }
        },
        child: Padding(
            padding: EdgeInsets.only(top: 270, left: 90),
            child: Transform(
              transform: Matrix4.translationValues(offsetX, offsetY, 0.0),
              child: ClipPath(
                clipper: MyCustomClipper(),
                child: Container(
                  padding:
                      EdgeInsets.only(top: 15, left: 15, right: 15, bottom: 30),
                  margin: EdgeInsets.only(top: 15, left: 15, right: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Wrap(
                    children: <Widget>[
                      Column(
                        children: [
                          for (int i = 0; i < displayData.length; i++)
                            RowsWidget(
                              title: displayData.keys.elementAt(i),
                              value: displayData.values.elementAt(i),
                            )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )));
  }
}

class RowsWidget extends StatelessWidget {
  final String? title, value;

  RowsWidget({this.title, this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 170,
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Flexible(
                  fit: FlexFit.tight,
                  flex: 2,
                  child: Text(
                    title ?? '',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
                Flexible(
                  flex: 4,
                  child: Text(
                    value ?? '',
                    style: TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 5,
            )
          ],
        ));
  }
}

class MyCustomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    double width = size.width;
    double height = size.height;
    final path = Path();
    path.lineTo(0.0, size.height - 30);
    path.quadraticBezierTo(0.0, size.height - 25, 5.0, size.height - 25);
    path.lineTo(size.width - 5.0, size.height - 25);
    path.lineTo((width / 2) - 15, height - 25);
    path.lineTo((width / 2), height);
    path.lineTo((width / 2) + 15, height - 25);
    path.lineTo(width - 5, height - 25);
    path.quadraticBezierTo(
        size.width, size.height - 25, size.width, size.height - 30);
    path.lineTo(size.width, 5.0);
    path.quadraticBezierTo(size.width, 0.0, size.width - 5.0, 0.0);
    path.lineTo(5.0, 0.0);
    path.quadraticBezierTo(0.0, 0.0, 0.0, 5.0);
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
