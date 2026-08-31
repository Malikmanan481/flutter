// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:speedotrack/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App initialization and UI smoke test', (WidgetTester tester) async {
    // Build our app and trigger initial frame
    await tester.pumpWidget(MyApp());
    
    // Verify that MyApp widget tree renders successfully
    expect(find.byType(MyApp), findsOneWidget);
  });

  // ==========================================
  // TRACCAR API BACKEND INTEGRATION TEST
  // ==========================================
  test('Traccar API Server Endpoint Verification Test', () async {
    // Traccar Backend base server URL sanity check
    final serverUrl = TraccarBackendInit.getServerUrl();
    expect(serverUrl, isNotEmpty);
    expect(serverUrl.startsWith('http'), isTrue);
  });
}
