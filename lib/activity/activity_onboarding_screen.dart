import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speedotrack/activity/activity_onboarding.dart';
import 'package:speedotrack/network/network_api_request.dart';
import 'package:speedotrack/providers/provider_color.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  @override
  void initState() {
    super.initState();
    _checkTraccarServer();
  }

  /// Traccar server connectivity verification
  Future<void> _checkTraccarServer() async {
    try {
      await NetworkHelper().requestDataFromNetworkWithTimeoutGET(
        urlFile: '/api/server',
        body: {},
        context: context,
      );
    } catch (e) {
      debugPrint('Traccar server initialization error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: ChangeNotifierProvider(
          create: (context) => ColorProvider(),
          child: Onboarding(),
        ),
      ),
    );
  }
}
