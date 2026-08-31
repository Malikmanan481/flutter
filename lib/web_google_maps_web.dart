import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

class GoogleMapsInAppWebView extends StatefulWidget {
  final double lat;
  final double lng;
  final int? deviceId;
  final String? serverUrl;
  final String? userCookie;

  GoogleMapsInAppWebView({
    required this.lat,
    required this.lng,
    this.deviceId,
    this.serverUrl,
    this.userCookie,
  });

  @override
  _GoogleMapsInAppWebViewState createState() => _GoogleMapsInAppWebViewState();
}

class _GoogleMapsInAppWebViewState extends State<GoogleMapsInAppWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..loadHtmlString(_generateHtml(widget.lat, widget.lng));

    // Optional: Traccar Device ID provided hone par latest position fetch karna
    if (widget.deviceId != null && widget.serverUrl != null) {
      fetchTraccarPosition();
    }
  }

  // ==========================================
  // TRACCAR API BACKEND INTEGRATION METHODS
  // ==========================================

  /// Traccar REST API `/api/positions?deviceId={id}` se position data fetch karke map set karna
  Future<void> fetchTraccarPosition() async {
    if (widget.deviceId == null || widget.serverUrl == null) return;

    try {
      final baseUrl = widget.serverUrl!.endsWith('/')
          ? widget.serverUrl!.substring(0, widget.serverUrl!.length - 1)
          : widget.serverUrl!;
      final url = Uri.parse('$baseUrl/api/positions?deviceId=${widget.deviceId}');

      final headers = <String, String>{
        'Accept': 'application/json',
      };
      if (widget.userCookie != null && widget.userCookie!.isNotEmpty) {
        headers['Cookie'] = widget.userCookie!;
      }

      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final pos = data.last;
          final double latitude = (pos['latitude'] as num).toDouble();
          final double longitude = (pos['longitude'] as num).toDouble();
          updateMapPosition(latitude, longitude);
        }
      }
    } catch (_) {
      // Graceful error handle - page retains initial lat/lng
    }
  }

  /// WebView ko reload kiye bagair dynamically new Traccar position coordinates push karna
  void updateMapPosition(double lat, double lng) {
    _controller.runJavaScript('if (typeof updateLocation === "function") { updateLocation($lat, $lng); }');
  }

  /// Generate HTML with dynamic latitude and longitude
  String _generateHtml(double lat, double lng) {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Google Map Fullscreen</title>
    <style>
        html, body {
            margin: 0;
            padding: 0;
            height: 100%;
        }
        #googleMap {
            width: 100%;
            height: 100%;
        }
    </style>
</head>
<body>
    <div id="googleMap"></div>
    <script>
        var map;
        var marker;

        function myMap() {
            var latLng = new google.maps.LatLng($lat, $lng);
            var mapProp = {
                center: latLng,
                zoom: 15,
                disableDefaultUI: true
            };
            map = new google.maps.Map(document.getElementById("googleMap"), mapProp);
            marker = new google.maps.Marker({
                position: latLng,
                map: map
            });
        }

        // Traccar API Dynamic Location Update Bridge
        function updateLocation(newLat, newLng) {
            if (map && marker) {
                var newLatLng = new google.maps.LatLng(newLat, newLng);
                marker.setPosition(newLatLng);
                map.panTo(newLatLng);
            }
        }
    </script>
    <script src="https://maps.googleapis.com/maps/api/js?key=AIzaSyA9rAmaPqla68na5oQFPR-LBZ_1Gt_mGIM&callback=myMap" async defer></script>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebViewWidget(controller: _controller),
    );
  }
}
