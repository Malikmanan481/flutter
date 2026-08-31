import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:get/get_common/get_reset.dart';
import 'package:provider/provider.dart';
import 'package:speedotrack/helper/static.dart';
import 'package:speedotrack/network/network_api_request.dart';
import 'package:speedotrack/providers/provider_color.dart';

import '../component/component_onboard_page.dart';
import '../component/component_page_view_indicator.dart';
import '../data/data_onboard_page.dart';

class Onboarding extends StatefulWidget {
  @override
  _OnboardingState createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  final PageController pageController = PageController();

  @override
  void initState() {
    super.initState();
    _fetchServerConfig();
  }

  /// Traccar /api/server endpoint se server configuration verify karne ka logic
  Future<void> _fetchServerConfig() async {
    try {
      var response = await NetworkHelper().requestDataFromNetworkWithTimeoutGET(
        urlFile: '/api/server',
        body: {},
        context: context,
      );

      if (response != null && response.isNotEmpty) {
        var serverData = json.decode(response);
        debugPrint('Traccar Server Connected: ${serverData['version'] ?? ''}');
      }
    } catch (e) {
      debugPrint('Error connecting to Traccar server: $e');
    }
  }

  /// Skip handle karne ke liye Traccar /api/session check
  Future<void> _handleSkip() async {
    try {
      var sessionResp = await NetworkHelper().requestDataFromNetworkWithTimeoutGET(
        urlFile: '/api/session',
        body: {},
        context: context,
      );

      if (sessionResp != null && sessionResp.isNotEmpty) {
        // Active session exists -> Navigate to Home
        Get.offAllNamed('/home');
      } else {
        // No session -> Navigate to Login
        Get.offAllNamed('/login');
      }
    } catch (e) {
      Get.offAllNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    ColorProvider colorProvider = Provider.of<ColorProvider>(context);
    return Stack(
      children: <Widget>[
        PageView.builder(
          controller: pageController,
          physics: NeverScrollableScrollPhysics(),
          itemCount: onboardData.length,
          itemBuilder: (context, index) {
            return OnboardPage(
              pageController: pageController,
              pageModel: onboardData[index],
              lastPage: index + 1 == onboardData.length ? true : false,
            );
          },
        ),
        Container(
          width: double.infinity,
          height: 70,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(left: 32.0),
                  child: Hero(
                    tag: "logo",
                    child: Image.asset(
                      StaticVarMethod.listimageurl,
                      color: colorProvider.color,
                      height: 30,
                      width: 100,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 32.0),
                  child: GestureDetector(
                    onTap: _handleSkip,
                    child: Text(
                      'skip'.tr,
                      style: TextStyle(
                        color: colorProvider.color,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 80.0, left: 40),
            child: PageViewIndicator(
              controller: pageController,
              itemCount: onboardData.length,
              color: colorProvider.color,
            ),
          ),
        )
      ],
    );
  }
}
