import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:speedotrack/model/model_onboard_page.dart';

List<OnboardPageModel> onboardData = [
  OnboardPageModel(
    Color(0xFFE6E6E6),
    Color(0xFF005699),
    Color(0xFFFFE074),
    2,
    'images/flutter_onboarding_1.png',
    'REAL TIME',
    'TRACKING',
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
  ),
  OnboardPageModel(
    Color(0xFF005699),
    Color(0xFFFFE074),
    Color(0xFF39393A),
    2,
    'images/flutter_onboarding_2.png',
    'FUEL',
    'REPORTS',
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
  ),
  OnboardPageModel(
    Color(0xFFFFE074),
    Color(0xFF39393A),
    Color(0xFFE6E6E6),
    0,
    'images/flutter_onboarding_3.png',
    'MONITOR MULTIPLE',
    'VEHICLE',
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
  ),
  OnboardPageModel(
    Color(0xFF39393A),
    Color(0xFFE6E6E6),
    Color(0xFF005699),
    1,
    'images/flutter_onboarding_4.png',
    'REMOTELY CONTROL',
    'YOUR VEHICLE',
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
  ),
];

// ==========================================
// TRACCAR API BACKEND INTEGRATION
// ==========================================

/// Helper to fetch and map Traccar server information (`/api/server`)
class TraccarServerConfig {
  /// Fetches Traccar server metadata (announcements, registration status, attributes)
  static Future<Map<String, dynamic>?> fetchServerMetadata(String baseUrl) async {
    try {
      final String cleanUrl =
          baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

      final response = await http.get(
        Uri.parse('$cleanUrl/api/server'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {
      // Prevents network error exceptions from breaking UI flow
    }
    return null;
  }

  /// Returns existing `onboardData` or appends server dynamic announcements if configured on Traccar
  static List<OnboardPageModel> getOnboardDataWithServerNotice(
      Map<String, dynamic>? serverConfig) {
    if (serverConfig != null && serverConfig['announcement'] != null) {
      final String announcement = serverConfig['announcement'].toString();
      if (announcement.isNotEmpty) {
        final List<OnboardPageModel> dynamicData = List.from(onboardData);
        dynamicData.add(
          OnboardPageModel(
            const Color(0xFF005699),
            const Color(0xFFE6E6E6),
            const Color(0xFFFFE074),
            0,
            'images/flutter_onboarding_1.png',
            'SERVER ANNOUNCEMENT',
            serverConfig['title']?.toString().toUpperCase() ?? 'NOTICE',
            announcement,
          ),
        );
        return dynamicData;
      }
    }
    return onboardData;
  }
}
