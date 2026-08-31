import 'package:flutter/material.dart';

class CircularImage extends StatelessWidget {
  final double _width, _height;
  final ImageProvider image;

  CircularImage(this.image, {double width = 40, double height = 40})
      : _width = width,
        _height = height;

  // ==========================================
  // TRACCAR API DEVICE IMAGE BACKEND HELPER
  // ==========================================
  /// Traccar Device Image endpoint (`/api/devices/{id}/image`) se image load karne ke liye factory constructor
  factory CircularImage.fromTraccarDevice({
    required String baseUrl,
    required int deviceId,
    String? sessionCookie,
    double width = 40,
    double height = 40,
  }) {
    final cleanUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final imageUrl = '$cleanUrl/api/devices/$deviceId/image';

    final Map<String, String> headers = {};
    if (sessionCookie != null && sessionCookie.isNotEmpty) {
      headers['Cookie'] = sessionCookie;
    }

    return CircularImage(
      NetworkImage(imageUrl, headers: headers),
      width: width,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _width,
      height: _height,
      decoration:
          BoxDecoration(shape: BoxShape.circle, image: DecorationImage(image: image, fit: BoxFit.cover), boxShadow: [
        BoxShadow(
          blurRadius: 10,
          color: Colors.black45,
        )
      ]),
    );
  }
}
