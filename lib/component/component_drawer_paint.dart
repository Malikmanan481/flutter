import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DrawerPaint extends CustomPainter {
  final Color curveColor;
  final Paint curvePaint;

  DrawerPaint({
    this.curveColor = Colors.pink,
  }) : curvePaint = Paint()
          ..color = curveColor
          ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    var path = Path();
    var diameter = size.height / 3;

    path.moveTo(35, 0);
    path.relativeCubicTo(25, diameter * 0.4, -15, diameter / 2, 0, diameter);
    path.relativeCubicTo(30, diameter * 0.6, -15, diameter / 2, 0, diameter);
    path.relativeCubicTo(35, diameter * 0.7, -80, diameter * 0.7, 0, diameter);

    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, curvePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

// ==========================================
// TRACCAR DRAWER BACKEND SERVICE
// ==========================================

class TraccarDrawerApi {
  /// Navigation Drawer header me User Profile / Account details fetch karne ke liye (`/api/session`)
  static Future<Map<String, dynamic>?> fetchSessionUser({
    required String baseUrl,
    required String sessionCookie,
  }) async {
    final cleanUrl =
        baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

    try {
      final response = await http.get(
        Uri.parse('$cleanUrl/api/session'),
        headers: {
          'Accept': 'application/json',
          'Cookie': sessionCookie,
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// Drawer se User Session Logout karne ke liye (`DELETE /api/session`)
  static Future<bool> logoutSession({
    required String baseUrl,
    required String sessionCookie,
  }) async {
    final cleanUrl =
        baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

    try {
      final response = await http.delete(
        Uri.parse('$cleanUrl/api/session'),
        headers: {
          'Cookie': sessionCookie,
        },
      );

      return response.statusCode == 204 || response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Drawer menu me Server Settings ya App Info display karne ke liye (`/api/server`)
  static Future<Map<String, dynamic>?> fetchServerInfo({
    required String baseUrl,
    required String sessionCookie,
  }) async {
    final cleanUrl =
        baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

    try {
      final response = await http.get(
        Uri.parse('$cleanUrl/api/server'),
        headers: {
          'Accept': 'application/json',
          'Cookie': sessionCookie,
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }
}
