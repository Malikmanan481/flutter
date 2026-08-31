import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MenuController extends ChangeNotifier {
  late AnimationController _controller;
  TickerProvider? vsync;

  // Traccar Session & User State
  Map<String, dynamic>? traccarUser;
  bool isLoadingTraccarData = false;

  MenuController({required this.vsync});

  void initialize({required TickerProvider vsync}) {
    this.vsync = vsync;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: vsync,
    )..addListener(notifyListeners);
  }

  AnimationController get controller => _controller;

  void open() {
    _controller.forward();
  }

  void close() {
    _controller.reverse();
  }

  AnimationStatus get state => _controller.status;

  // ==========================================
  // TRACCAR API BACKEND INTEGRATION
  // ==========================================

  /// Fetch active session user info directly from Traccar (`GET /api/session`)
  Future<Map<String, dynamic>?> fetchTraccarSession({
    required String baseUrl,
    Map<String, String>? headers,
  }) async {
    try {
      isLoadingTraccarData = true;
      notifyListeners();

      final String cleanUrl =
          baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

      final response = await http.get(
        Uri.parse('$cleanUrl/api/session'),
        headers: headers ?? {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        traccarUser = jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        traccarUser = null;
      }
    } catch (_) {
      traccarUser = null;
    } finally {
      isLoadingTraccarData = false;
      notifyListeners();
    }
    return traccarUser;
  }

  /// Revoke and close current session on Traccar backend (`DELETE /api/session`)
  Future<bool> logoutTraccarSession({
    required String baseUrl,
    Map<String, String>? headers,
  }) async {
    try {
      final String cleanUrl =
          baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

      final response = await http.delete(
        Uri.parse('$cleanUrl/api/session'),
        headers: headers ?? {'Accept': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        traccarUser = null;
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Check backend server availability (`GET /api/health`)
  Future<bool> checkTraccarServerHealth(String baseUrl) async {
    try {
      final String cleanUrl =
          baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

      final response = await http.get(
        Uri.parse('$cleanUrl/api/health'),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
