import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:speedotrack/activity/activity_historyMap.dart';
import 'package:speedotrack/globals.dart';
import 'package:speedotrack/helper/static.dart';
import 'package:speedotrack/network/network_api_request.dart';
import 'package:speedotrack/sharedPrefs/login_settings.dart';

class AboutActivity extends StatefulWidget {
  @override
  _AboutActivityState createState() => _AboutActivityState();
}

class _AboutActivityState extends State<AboutActivity> {
  String? version, email;

  @override
  void initState() {
    super.initState();
    initSharedPrefs();
  }

  // ==================== TRACCAR API INTEGRATION ====================
  void initSharedPrefs() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String? localEmail = Globals.prefs!.getString(LoginSettings.email);

    if (mounted) {
      setState(() {
        version = packageInfo.version;
        email = localEmail;
      });
    }

    try {
      // Fetch active user session from Traccar REST API
      var response = await NetworkHelper().requestDataFromNetworkWithTimeoutGET(
        urlFile: 'api/session',
        context: context,
      );

      if (response != null && response.isNotEmpty) {
        var parsed = response is String ? jsonDecode(response) : response;
        if (parsed is Map && parsed.containsKey('email')) {
          String? fetchedEmail = parsed['email'];
          if (fetchedEmail != null && fetchedEmail.isNotEmpty) {
            email = fetchedEmail;
          }
        }
      }
    } catch (e) {
      // Fallback to local email if API is unreachable
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Globals.appColor,
        elevation: 0.0,
        title: Text(
          'aboutUs'.tr,
          style:
              TextStyle(color: Color(0xFFF6F6F6), fontFamily: 'Baloo_Thambi_2'),
        ),
        iconTheme: IconThemeData(
          color: Color(0xFFF6F6F6), //change your color here
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              child: Image.asset(
                StaticVarMethod.listimageurl,
                color: Globals.appColor,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Text(
                "${Globals.name}" + "providesRealTimeVehicleTracking".tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.3,
                    fontFamily: 'Montserrat'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Container(
                color: Color(0xFFBDEBF9),
                padding: EdgeInsets.only(left: 10, right: 10),
                child: Text(
                  'inFocusOurValuedCustomers'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1.3,
                      fontFamily: 'Montserrat'),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Text(
                '${Globals.name}' + "companyInfo".tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.3,
                    fontFamily: 'Montserrat'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Container(
                color: Color(0xFFBDEBF9),
                padding: EdgeInsets.only(left: 10, right: 10),
                child: Text(
                  'serviceRoundCheck'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1.3,
                      fontFamily: 'Montserrat'),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Text(
                'Our operations and a dedicated service team is available online 24 hours to '
                'support all our customers. For any query anytime of the day, you will get response to your queries over Phone, E-mail, Online Chat Bot facility and also receive quick solutions to issues that require attention from ${Globals.name}.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.3,
                    fontFamily: 'Montserrat'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Text(
                'User: $email - App version: $version',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1.3,
                    fontFamily: 'Montserrat'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
