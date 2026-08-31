import 'dart:async';
import 'dart:convert';
import 'dart:developer' as d;
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:requests/requests.dart';
import 'package:video_player/video_player.dart';

import '../globals.dart';
import 'package:speedotrack/activity/activity_home_screen.dart';
import 'package:speedotrack/activity/activity_login_screen.dart';
import 'package:speedotrack/model/ObjectDataModel.dart';
import 'package:speedotrack/model/VehicleSettingsModel.dart';
import 'package:speedotrack/sharedPrefs/login_settings.dart';
import 'package:speedotrack/sharedPrefs/main_prefs.dart';

class SplashScreen extends StatefulWidget {
  final bool? isFromLogin;
  final bool? isAppRestarted;

  const SplashScreen({this.isFromLogin, this.isAppRestarted, Key? key})
      : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool isLoggedIn = false;
  String loadingMessage = '${'welcome'.tr} ${Globals.name}';
  int settingsCount = 0, objectCount = 0, userCount = 0;
  bool notRunning = true;

  VideoPlayerController? _logoVideoPlayer;
  bool _logoVideoCompleted = false;
  bool _setupReady = false;
  bool internet = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Globals.appColor,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Globals.appColor,
    ));

    _logoVideoPlayer = VideoPlayerController.asset('assets/logo.mp4');
    _logoVideoPlayer!.setVolume(0);
    _logoVideoPlayer!.initialize().then((_) {
      if (mounted) {
        _logoVideoPlayer!.setLooping(false);
        _logoVideoPlayer!.play();
        setState(() {});

        // Listen for video completion
        _logoVideoPlayer!.addListener(() {
          if (_logoVideoPlayer!.value.position >=
                  _logoVideoPlayer!.value.duration &&
              _logoVideoPlayer!.value.duration > Duration.zero &&
              !_logoVideoCompleted) {
            _logoVideoCompleted = true;
            _navigateAfterVideo();
          }
        });
      }
    });

    isInternetConnected().then((val) {
      if (val) {
        setState(() {
          internet = true;
          Future.microtask(() => setUp());
        });
      } else {
        setState(() {
          internet = false;
        });
      }
    });

    _timer = Timer.periodic(Duration(seconds: 5), (time) {
      isInternetConnected().then((val) {
        if (val) {
          internet = true;
          Future.microtask(() => setUp());
        } else {
          setState(() {
            internet = false;
          });
        }
      });
    });
  }

  Future<bool> getStarted(BuildContext context) async {
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return internet
        ? Scaffold(
            body: Container(
            child: Stack(
              children: <Widget>[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: SizedBox(
                      height: 250,
                      child: _logoVideoPlayer != null &&
                              _logoVideoPlayer!.value.isInitialized
                          ? AspectRatio(
                              aspectRatio: _logoVideoPlayer!.value.aspectRatio,
                              child: VideoPlayer(_logoVideoPlayer!),
                            )
                          : Container(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 80.0),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$loadingMessage',
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Globals.appColor,
                              fontSize: 14,
                              decoration: TextDecoration.none,
                              letterSpacing: 1,
                              fontFamily: 'Montserrat'),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 10, left: 40, right: 40),
                          child: CircularProgressIndicator(
                            backgroundColor: Colors.transparent,
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Globals.appColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ))
        : Scaffold(
            body: Stack(
            children: <Widget>[
              Container(color: Globals.appColor),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: SizedBox(
                    height: 250,
                    child: _logoVideoPlayer != null &&
                            _logoVideoPlayer!.value.isInitialized
                        ? AspectRatio(
                            aspectRatio: _logoVideoPlayer!.value.aspectRatio,
                            child: VideoPlayer(_logoVideoPlayer!),
                          )
                        : Container(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 80.0),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'internetNotConnected'.tr,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            decoration: TextDecoration.none,
                            letterSpacing: 1,
                            fontFamily: 'Montserrat'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ));
  }

  void setUp() async {
    await [Permission.location, Permission.notification, Permission.sms]
        .request();
    _setupReady = true;
    if (_logoVideoCompleted) {
      _navigateAfterVideo();
    }
  }

  void _navigateAfterVideo() {
    if (!mounted) return;
    if (!_setupReady) return;
    if (!(widget.isAppRestarted ?? false) && !(widget.isFromLogin ?? false)) {
      loginCheck();
    } else if (!(widget.isAppRestarted ?? false) && (widget.isFromLogin ?? false)) {
      getLoginStatus();
    } else if ((widget.isAppRestarted ?? false) && !(widget.isFromLogin ?? false)) {
      loginCheck();
    }
  }

  Future<bool> isInternetConnected() async {
    try {
      var result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
      return false;
    } on SocketException catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _logoVideoPlayer?.dispose();
    super.dispose();
  }

  void loginCheck() async {
    if (mounted) {
      setState(() {
        loadingMessage = "${'welcome'.tr} ${Globals.name}";
      });
    }

    isLoggedIn = Globals.prefs?.getBool(MainPrefs.isLoggedIn) ?? false;

    await Future.delayed(Duration(milliseconds: 100));

    if (mounted) {
      if (isLoggedIn) {
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(builder: (context) => LoginScreen()),
        );
      }
    }
  }

  void getLoginStatus() async {
    isLoggedIn = Globals.prefs?.getBool(MainPrefs.isLoggedIn) ?? false;
    if (isLoggedIn) {
      if (mounted) {
        setState(() {
          loadingMessage = "checkUserCredentials".tr;
        });
      }
      fetchLogin();
    } else {
      Navigator.pushReplacement(
          context, CupertinoPageRoute(builder: (context) => LoginScreen()));
    }
  }

  /// Traccar API Authentication & Session Checking
  void fetchLogin() async {
    try {
      String sessionUrl = '${Globals.baseUrl}/api/session';
      
      // 1. Check if existing session cookie is still valid on Traccar
      var sessionResponse = await Requests.get(sessionUrl);
      
      if (sessionResponse.statusCode == 200) {
        if (mounted) {
          setState(() {
            loadingMessage = 'gettingDevices'.tr;
          });
        }
        fetchTraccarDevices();
      } else {
        // 2. Perform fresh login against Traccar API (/api/session)
        String username = Globals.prefs?.getString(LoginSettings.email) ?? '';
        String password = Globals.prefs?.getString(LoginSettings.password) ?? '';

        var loginResponse = await Requests.post(
          sessionUrl,
          body: {
            'email': username,
            'password': password,
          },
          bodyEncoding: RequestBodyEncoding.FormURLEncoded,
        );

        if (loginResponse.statusCode == 200) {
          if (mounted) {
            setState(() {
              loadingMessage = 'gettingDevices'.tr;
            });
          }
          fetchTraccarDevices();
        } else {
          // Auth failed / Session expired
          String? email = Globals.prefs?.getString(LoginSettings.email);
          if (email != null && email.isNotEmpty) {
            FirebaseMessaging.instance.unsubscribeFromTopic(
                email.replaceAll('@', '_at_'));
          }
          Globals.prefs?.clear();
          if (mounted) {
            Navigator.pushReplacement(
                context,
                CupertinoPageRoute(
                    builder: (context) =>
                        SplashScreen(isFromLogin: false, isAppRestarted: true)));
          }
        }
      }
    } catch (e) {
      d.log('Traccar Login Error: $e');
      if (mounted) {
        Navigator.pushReplacement(
            context, CupertinoPageRoute(builder: (context) => LoginScreen()));
      }
    }
  }

  /// Fetch devices list directly from Traccar REST API (/api/devices)
  void fetchTraccarDevices() async {
    try {
      var response = await Requests.get('${Globals.baseUrl}/api/devices');
      if (response.statusCode == 200 && response.content().isNotEmpty) {
        List<dynamic> devicesList = response.json();
        List<String> imeiArray = [];
        Map<String, bool> parkingMode = {};

        for (var device in devicesList) {
          // Use Traccar uniqueId (IMEI) or fallback to ID string
          String uniqueId = device['uniqueId']?.toString() ?? device['id'].toString();

          Globals.prefs?.setString('${uniqueId}_settings', jsonEncode(device));
          parkingMode[uniqueId] = false;

          String iconName = 'm_2_';
          if (device['category'] != null) {
            iconName = 'm_${device['category']}_';
          }

          if (Globals.prefs?.getString('${uniqueId}_icons') == null) {
            Globals.prefs?.setString('${uniqueId}_icons', iconName);
          }

          imeiArray.add(uniqueId);
        }

        Globals.prefs?.setStringList(MainPrefs.keyIMEI, imeiArray);
        Globals.prefs?.setString('parkingMode', jsonEncode(parkingMode));
        Globals.fetchedSettings = true;

        if (mounted) {
          setState(() {
            loadingMessage = 'Ready. Let\'s go...';
          });
        }

        Get.off(() => HomeScreen(), transition: Transition.rightToLeft);
      } else {
        d.log("Failed to load devices: ${response.statusCode}");
      }
    } catch (e) {
      d.log('Traccar Devices Fetch Error: $e');
    }
  }

  // Backwards compatibility functions to avoid breaking references elsewhere
  void fetchFnSettings() => fetchTraccarDevices();
  void fetchFnObjects() => Get.off(() => HomeScreen(), transition: Transition.rightToLeft);
}
