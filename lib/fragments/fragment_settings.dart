import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart' as intl;
import 'package:progress_dialog_null_safe/progress_dialog_null_safe.dart';
import 'package:restart_app/restart_app.dart';
import 'package:speedotrack/activity/activity_change_icon.dart';
import 'package:speedotrack/activity/activity_command_history.dart';
import 'package:speedotrack/activity/activity_eventlist.dart';
import 'package:speedotrack/activity/activity_geofencelist.dart';
import 'package:speedotrack/activity/activity_historyMap.dart';
import 'package:speedotrack/activity/activity_splash_screen.dart';
import 'package:speedotrack/activity/fragment_change_icon.dart';
import 'package:speedotrack/globals.dart';
import 'package:speedotrack/model/User.dart';
import 'package:speedotrack/network/network_api_request.dart';
import 'package:speedotrack/sharedPrefs/login_settings.dart';

class SettingsFragment extends StatefulWidget {
  @override
  _SettingsFragmentState createState() => _SettingsFragmentState();
}

class _SettingsFragmentState extends State<SettingsFragment> {
  bool notificationSwitch = Globals.prefs!.getBool('notification') ?? false;
  bool mapCardSwitch = Globals.prefs!.getBool('mapCard') ?? false;

  TextEditingController oldPasswordTextController = TextEditingController();
  TextEditingController newPasswordTextController = TextEditingController();
  TextEditingController confirmPasswordTextController = TextEditingController();
  String email = '';
  var formatter = intl.DateFormat('yyyy-MM-dd');
  BuildContext? context2;

  showPasswordDialog() {
    TextField oldPasswordField = TextField(
      controller: oldPasswordTextController,
      style: TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      keyboardType: TextInputType.visiblePassword,
      obscureText: true,
      decoration: InputDecoration(
        hintText: 'oldPassword'.tr,
        hintStyle: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 14,
          color: Color(0xFF7E8188),
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    TextField passwordField = TextField(
      controller: newPasswordTextController,
      style: TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      keyboardType: TextInputType.visiblePassword,
      obscureText: true,
      decoration: InputDecoration(
        hintText: 'newPassword'.tr,
        hintStyle: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 14,
          color: Color(0xFF7E8188),
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    TextField confirmPasswordField = TextField(
      controller: confirmPasswordTextController,
      style: TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      keyboardType: TextInputType.visiblePassword,
      obscureText: true,
      decoration: InputDecoration(
        hintText: 'confirmPassword'.tr,
        hintStyle: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 14,
          color: Color(0xFF7E8188),
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'changePassword'.tr,
            style: TextStyle(
              fontFamily: 'Montserrat',
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              oldPasswordField,
              passwordField,
              confirmPasswordField,
            ],
          ),
          actions: [
            TextButton(
              child: Text(
                'cancel'.tr,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7E8188),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('passwordChangeCancel'.tr)),
                );
              },
            ),
            TextButton(
              child: Text(
                'proceed'.tr,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              onPressed: () async {
                if (oldPasswordTextController.text.isNotEmpty &&
                    newPasswordTextController.text.isNotEmpty &&
                    confirmPasswordTextController.text.isNotEmpty) {
                  if (newPasswordTextController.text ==
                      confirmPasswordTextController.text) {
                    // Fetch current user details from Traccar session
                    var response = await NetworkHelper().requestDataFromNetworkWithTimeout(
                      urlFile: '/api/session',
                      context: context,
                    );

                    if (response.isNotEmpty) {
                      Map<String, dynamic> userMap = json.decode(response);
                      userMap['password'] = newPasswordTextController.text;
                      int userId = userMap['id'];

                      // Update password via Traccar API /api/users/{id}
                      dynamic result = await NetworkHelper().requestDataFromNetworkWithTimeout(
                        urlFile: '/api/users/$userId',
                        body: userMap,
                        context: context,
                      );

                      if (result.isNotEmpty) {
                        oldPasswordTextController.clear();
                        newPasswordTextController.clear();
                        confirmPasswordTextController.clear();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('passwordChangedSuccess'.tr)),
                        );
                        Globals.prefs!.clear();
                        Get.to(
                          transition: Transition.rightToLeft,
                          SplashScreen(isFromLogin: false, isAppRestarted: true),
                        );
                      } else {
                        oldPasswordTextController.clear();
                        newPasswordTextController.clear();
                        confirmPasswordTextController.clear();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context2 ?? context).showSnackBar(
                          SnackBar(content: Text('oopsSomethingWentWrong'.tr)),
                        );
                      }
                    }
                  } else {
                    ScaffoldMessenger.of(context2 ?? context).showSnackBar(
                      SnackBar(content: Text('newPasswordDoNotMatch'.tr)),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context2 ?? context).showSnackBar(
                    SnackBar(content: Text('passwordCantBlank'.tr)),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      email = Globals.prefs!.getString(LoginSettings.email) ?? '';
    });
  }

  void showLanguageDialog() {
    showGeneralDialog(
      barrierLabel: 'changeLanguage'.tr,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      context: context,
      transitionDuration: Duration(milliseconds: 100),
      pageBuilder: (_, __, ___) {
        return Center(
          child: Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text(
                      'changeLanguage'.tr,
                      maxLines: 1,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        decoration: TextDecoration.none,
                        letterSpacing: 1.0,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                  androidSensorDropDown(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  DropdownButton<String> androidSensorDropDown() {
    List<String> languageList = ['English', 'French'];
    String deviceSelected = languageList[0].toLowerCase();
    List<DropdownMenuItem<String>> dropdownItems = [];
    for (int i = 0; i < languageList.length; i++) {
      var newItem = DropdownMenuItem(
        child: Text(languageList[i]),
        value: languageList[i].toLowerCase(),
      );
      dropdownItems.add(newItem);
    }
    return DropdownButton<String>(
      value: deviceSelected,
      items: dropdownItems,
      dropdownColor: Colors.white,
      onChanged: (lang) async {
        ProgressDialog pr = ProgressDialog(
          context,
          type: ProgressDialogType.normal,
          isDismissible: false,
          showLogs: false,
        );
        pr.show();

        // Fetch Traccar current user session
        var sessionRes = await NetworkHelper().requestDataFromNetworkWithTimeout(
          urlFile: '/api/session',
          context: context,
        );

        if (sessionRes.isNotEmpty) {
          Map<String, dynamic> userMap = json.decode(sessionRes);
          int userId = userMap['id'];
          userMap['attributes'] = userMap['attributes'] ?? {};
          userMap['attributes']['language'] = lang;

          // Save language preference to Traccar user attributes
          await NetworkHelper().requestDataFromNetworkWithTimeout(
            urlFile: '/api/users/$userId',
            body: userMap,
            context: context,
          );

          pr.hide();
          Navigator.pop(context);

          if (lang == "English" || lang == "en") {
            Globals.prefs!.setString("language", "en");
            Get.updateLocale(const Locale('en', 'US'));
          } else {
            Globals.prefs!.setString("language", "fr");
            Get.updateLocale(const Locale('fr', 'FR'));
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('languageChangedSuccessfully'.tr)),
          );
          Timer(Duration(seconds: 2), () {
            Get.to(
              transition: Transition.rightToLeft,
              SplashScreen(isFromLogin: false, isAppRestarted: true),
            );
          });
        } else {
          pr.hide();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double fontSize = 13;
    double divHeight = 5;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primaryColor: Globals.appColor, useMaterial3: false),
      home: Container(
        color: Color(0xFFF6F6F6),
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Wrap(
            children: <Widget>[
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                ),
                elevation: 5,
                child: Column(
                  children: <Widget>[
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: <Widget>[
                          Container(
                            width: 40.0,
                            height: 40.0,
                            decoration: BoxDecoration(
                              color: Color(0xFFF6F6F6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.notifications_active,
                              color: Globals.appColor,
                            ),
                          ),
                          Text(
                            "  " + 'notification'.tr,
                            style: TextStyle(
                              color: Colors.grey,
                              fontFamily: 'baloo_Thambi_2',
                              fontSize: fontSize,
                            ),
                          ),
                          Spacer(),
                          Switch(
                            activeColor: Color(0xFFF6F6F6),
                            activeTrackColor: Colors.green,
                            inactiveThumbColor: Color(0xFFF6F6F6),
                            inactiveTrackColor: Colors.red,
                            value: notificationSwitch,
                            onChanged: (value) async {
                              Globals.prefs!.setBool('notification', value);
                              if (value) {
                                setState(() {
                                  notificationSwitch = Globals.prefs!.getBool('notification')!;
                                });
                                String? token = await FirebaseMessaging.instance.getToken();

                                // Update FCM token in Traccar User Attributes
                                var response = await NetworkHelper().requestDataFromNetwork(
                                  urlFile: "/api/session",
                                  context: context,
                                );
                                if (response.isNotEmpty) {
                                  Map<String, dynamic> userMap = json.decode(response);
                                  int userId = userMap['id'];
                                  userMap['attributes'] = userMap['attributes'] ?? {};
                                  userMap['attributes']['fcmToken'] = token;

                                  await NetworkHelper().requestDataFromNetwork(
                                    urlFile: "/api/users/$userId",
                                    body: userMap,
                                    context: context,
                                  );

                                  FirebaseMessaging.instance.subscribeToTopic(
                                    Globals.prefs!
                                        .getString(LoginSettings.email)!
                                        .replaceAll('@', '_at_'),
                                  );
                                }
                              } else {
                                FirebaseMessaging.instance.deleteToken();
                                FirebaseMessaging.instance.unsubscribeFromTopic(
                                  Globals.prefs!
                                      .getString(LoginSettings.email)!
                                      .replaceAll('@', '_at_'),
                                );
                              }
                              setState(() {
                                notificationSwitch = Globals.prefs!.getBool('notification')!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: divHeight),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: InkWell(
                        onTap: () => Get.to(
                          transition: Transition.rightToLeft,
                          FragmentChangeIconScreen(),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: <Widget>[
                            Container(
                              width: 40.0,
                              height: 40.0,
                              decoration: BoxDecoration(
                                color: Color(0xFFF6F6F6),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.directions_car,
                                color: Globals.appColor,
                              ),
                            ),
                            Text(
                              "  " + 'changeDeviceSettings'.tr,
                              style: TextStyle(
                                color: Colors.grey,
                                fontFamily: 'baloo_Thambi_2',
                                fontSize: fontSize,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: divHeight),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (context) => CommandHistoryActivity(),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: <Widget>[
                            Container(
                              width: 40.0,
                              height: 40.0,
                              decoration: BoxDecoration(
                                color: Color(0xFFF6F6F6),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.code,
                                color: Globals.appColor,
                              ),
                            ),
                            Text(
                              "  " + 'commandHistory'.tr,
                              style: TextStyle(
                                color: Colors.grey,
                                fontFamily: 'baloo_Thambi_2',
                                fontSize: fontSize,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: divHeight),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (context) => GeoFenceListActivity(),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: <Widget>[
                            Container(
                              width: 40.0,
                              height: 40.0,
                              decoration: BoxDecoration(
                                color: Color(0xFFF6F6F6),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.report_problem,
                                color: Globals.appColor,
                              ),
                            ),
                            Text(
                              "  " + 'geoFenceSettings'.tr,
                              style: TextStyle(
                                color: Colors.grey,
                                fontFamily: 'baloo_Thambi_2',
                                fontSize: fontSize,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: divHeight),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (context) => EventListActivity(),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: <Widget>[
                            Container(
                              width: 40.0,
                              height: 40.0,
                              decoration: BoxDecoration(
                                color: Color(0xFFF6F6F6),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.notification_important,
                                color: Globals.appColor,
                              ),
                            ),
                            Text(
                              "  " + 'notificationSettings'.tr,
                              style: TextStyle(
                                color: Colors.grey,
                                fontFamily: 'baloo_Thambi_2',
                                fontSize: fontSize,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: divHeight),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: InkWell(
                        onTap: () => Globals.prefs!
                                    .getString(LoginSettings.email)
                                    .toString()
                                    .toLowerCase() !=
                                'demo'
                            ? showPasswordDialog()
                            : Fluttertoast.showToast(
                                msg: 'Password of this account cannot be changed.',
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.CENTER,
                                timeInSecForIosWeb: 1,
                                backgroundColor: Globals.appColor,
                                textColor: Colors.white,
                                fontSize: fontSize,
                              ),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: <Widget>[
                            Container(
                              width: 40.0,
                              height: 40.0,
                              decoration: BoxDecoration(
                                color: Color(0xFFF6F6F6),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.lock_open,
                                color: Globals.appColor,
                              ),
                            ),
                            Text(
                              'changePassword'.tr,
                              style: TextStyle(
                                color: Colors.grey,
                                fontFamily: 'baloo_Thambi_2',
                                fontSize: fontSize,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: divHeight),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: InkWell(
                        onTap: () async {
                          ProgressDialog pr = ProgressDialog(
                            context,
                            type: ProgressDialogType.normal,
                            isDismissible: false,
                            showLogs: false,
                          );
                          pr.show();

                          String timeZone = '';
                          Duration localDatetime = DateTime.now().timeZoneOffset;
                          if (!localDatetime.isNegative) {
                            if ((localDatetime.inMinutes % 60) > 0) {
                              timeZone =
                                  '+ ${localDatetime.inHours.abs()} hours + ${localDatetime.inMinutes % 60} minutes';
                            } else {
                              timeZone = '+ ${localDatetime.inHours.abs()} hours';
                            }
                          } else {
                            if ((localDatetime.inMinutes % 60) > 0) {
                              timeZone =
                                  '- ${localDatetime.inHours.abs()} hours - ${localDatetime.inMinutes % 60} minutes';
                            } else {
                              timeZone = '- ${localDatetime.inHours.abs()} hours';
                            }
                          }

                          // Get user session from Traccar API
                          var response = await NetworkHelper().requestDataFromNetworkWithTimeout(
                            urlFile: '/api/session',
                            context: context,
                          );

                          if (response.isNotEmpty) {
                            Map<String, dynamic> userMap = json.decode(response);
                            int userId = userMap['id'];
                            userMap['attributes'] = userMap['attributes'] ?? {};
                            userMap['attributes']['timezone'] = timeZone;

                            dynamic result = await NetworkHelper().requestDataFromNetworkWithTimeout(
                              urlFile: '/api/users/$userId',
                              body: userMap,
                              context: context,
                            );

                            if (result.isNotEmpty) {
                              pr.hide();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Timezone changed successfully. App will restart automatically!!',
                                  ),
                                ),
                              );

                              Future.delayed(Duration(seconds: 1)).then((val) {
                                Restart.restartApp(
                                  notificationTitle: 'Restarting App',
                                  notificationBody: 'Please tap here to open the app again.',
                                );
                              });
                            } else {
                              pr.hide();
                            }
                          } else {
                            pr.hide();
                          }
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: <Widget>[
                            Container(
                              width: 40.0,
                              height: 40.0,
                              decoration: BoxDecoration(
                                color: Color(0xFFF6F6F6),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.language,
                                color: Globals.appColor,
                              ),
                            ),
                            Text(
                              'syncTimeZone'.tr,
                              style: TextStyle(
                                color: Colors.grey,
                                fontFamily: 'baloo_Thambi_2',
                                fontSize: fontSize,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: divHeight),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: InkWell(
                        onTap: () async {
                          showLanguageDialog();
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: <Widget>[
                            Container(
                              width: 40.0,
                              height: 40.0,
                              decoration: BoxDecoration(
                                color: Color(0xFFF6F6F6),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.compare_arrows,
                                color: Globals.appColor,
                              ),
                            ),
                            Text(
                              'chooseLanguage'.tr,
                              style: TextStyle(
                                color: Colors.grey,
                                fontFamily: 'baloo_Thambi_2',
                                fontSize: fontSize,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
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
