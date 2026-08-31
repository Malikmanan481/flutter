import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:speedotrack/activity/activity_about_us.dart';
import 'package:speedotrack/activity/activity_image.dart';
import 'package:speedotrack/activity/activity_live_support.dart';
import 'package:speedotrack/activity/activity_splash_screen.dart';
import 'package:speedotrack/activity/activity_webview.dart';
import 'package:speedotrack/controller/controller_menu_home_screen.dart';
import 'package:speedotrack/globals.dart';
import 'package:speedotrack/sharedPrefs/login_settings.dart';
import 'component_circular_image.dart';

class MenuScreen extends StatelessWidget {
  final List<MenuItem> options = Platform.isAndroid
      ? [
          MenuItem(Icons.home, 'Home', 1),
          MenuItem(Icons.live_help, 'Live Support', 6),
          MenuItem(Icons.info, 'About Us', 8),
        ]
      : [
          MenuItem(Icons.home, 'Home', 1),
          MenuItem(Icons.live_help, 'Live Support', 6),
          MenuItem(Icons.info, 'About Us', 8),
        ];

  void menuOptionItemClicked(int position, BuildContext context) {
    if (position == 1) {
      Provider.of<MenuControllerHome>(context, listen: false).toggle();
    }
    if (position == 6) {
      Provider.of<MenuControllerHome>(context, listen: false).toggle();
      Navigator.of(context)
          .push(CupertinoPageRoute(builder: (context) => LiveSupport()));
    }
    if (position == 2) {
      Provider.of<MenuControllerHome>(context, listen: false).toggle();
      Navigator.push(
          context,
          CupertinoPageRoute(
              builder: (context) => ActivityWebView(
                    url: Globals.payNow,
                    title: 'PAY NOW',
                  )));
    }
    if (position == 7) {
      Provider.of<MenuControllerHome>(context, listen: false).toggle();
      Navigator.push(
          context,
          CupertinoPageRoute(
              builder: (context) => ActivityWebView(
                    url: Globals.pricing,
                    title: 'Pricing',
                  )));
    }
    if (position == 8) {
      Provider.of<MenuControllerHome>(context, listen: false).toggle();
      Navigator.of(context)
          .push(CupertinoPageRoute(builder: (context) => AboutActivity()));
    }
    if (position == 3) {
      Provider.of<MenuControllerHome>(context, listen: false).toggle();
      Navigator.of(context)
          .push(CupertinoPageRoute(builder: (context) => ImageActivity()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        if (details.delta.dx < -6) {
          Provider.of<MenuControllerHome>(context, listen: true).toggle();
        }
      },
      child: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          padding: EdgeInsets.only(top: 40, left: 10, bottom: 50, right: 10),
          color: Globals.appColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircularImage(
                AssetImage('images/appIcon.png'),
              ),
              Spacer(),
              Column(
                children: options.map((item) {
                  return ListTile(
                    onTap: () {
                      menuOptionItemClicked(item.position, context);
                    },
                    leading: Icon(
                      item.icon,
                      color: Colors.white,
                      size: 25,
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontFamily: 'Baloo_Thambi_2'),
                    ),
                  );
                }).toList(),
              ),
              Spacer(),
              ListTile(
                onTap: () async {
                  /// Refactored: Call Traccar DELETE session endpoint `/api/session` to handle clean logout
                  try {
                    await NetworkHelper().requestDataFromNetwork(
                      urlFile: 'api/session',
                      body: {},
                      context: context,
                    );
                  } catch (e) {
                    print("Traccar session logout error: $e");
                  }

                  String? email = Globals.prefs!.getString(LoginSettings.email);
                  if (email != null) {
                    FirebaseMessaging.instance.unsubscribeFromTopic(
                        email.replaceAll('@', '_at_'));
                  }
                  FirebaseMessaging.instance.deleteToken();
                  Globals.prefs!.clear();
                  Get.to(
                      transition: Transition.rightToLeft,
                      SplashScreen(isFromLogin: false, isAppRestarted: true));
                },
                title: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.exit_to_app,
                      color: Colors.white,
                      size: 30,
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    Expanded(
                      child: Text(
                          'Logout - ${Globals.prefs!.getString(LoginSettings.email) ?? ''}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontFamily: 'Baloo_Thambi_2',
                            letterSpacing: 1,
                            fontWeight: FontWeight.w500,
                          )),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MenuItem {
  String title;
  IconData icon;
  int position;

  MenuItem(this.icon, this.title, this.position);
}
