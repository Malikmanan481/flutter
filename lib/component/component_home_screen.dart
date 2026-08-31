import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:requests/requests.dart';
import 'package:shimmer/shimmer.dart';
import 'package:speedotrack/Network/network_api_request.dart';
import 'package:speedotrack/activity/activity_notification_map.dart';
import 'package:speedotrack/activity/activity_webview.dart';
import 'package:speedotrack/bloc/home_bloc.dart';
import 'package:speedotrack/bloc/notification_bloc.dart';
import 'package:speedotrack/component/component_curved_navigation_bar.dart';
import 'package:speedotrack/component/share_location_dialog.dart';
import 'package:speedotrack/controller/controller_menu_home_screen.dart';
import 'package:speedotrack/fragments/fragment_fleet.dart';
import 'package:speedotrack/fragments/fragment_home.dart';
import 'package:speedotrack/fragments/fragment_map.dart';
import 'package:speedotrack/fragments/fragment_notification.dart';
import 'package:speedotrack/fragments/fragment_settings.dart';
import 'package:speedotrack/globals.dart';
import 'package:speedotrack/helper/helper.dart';
import 'package:speedotrack/helper/static.dart';
import 'package:speedotrack/model/User.dart';
import 'package:speedotrack/model/model_object_fn.dart';
import 'package:speedotrack/model/model_settings_fn.dart';
import 'package:speedotrack/sharedPrefs/login_settings.dart';
import 'package:speedotrack/sharedPrefs/main_prefs.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart' as dateTime;

class ProviderType extends ChangeNotifier {
  bool value = false, searchStatus = false;
  String search = '';

  changeValue() {
    value = true;
    notifyListeners();
  }

  searchValue(String searchValue) {
    search = searchValue;
    searchStatus = true;
    notifyListeners();
  }

  searchComplete() {
    searchStatus = false;
    notifyListeners();
  }
}

class HomeScreenContainer extends StatefulWidget {
  final Widget? menuScreen;

  HomeScreenContainer({
    this.menuScreen,
  });

  @override
  _HomeScreenContainerState createState() => _HomeScreenContainerState();
}

bool isLoading = true;

class _HomeScreenContainerState extends State<HomeScreenContainer>
    with SingleTickerProviderStateMixin {
  Curve scaleDownCurve = Interval(0.0, 0.3, curve: Curves.easeOut);
  Curve scaleUpCurve = Interval(0.0, 1.0, curve: Curves.easeOut);
  Curve slideOutCurve = Interval(0.0, 1.0, curve: Curves.easeOut);
  Curve slideInCurve = Interval(0.0, 1.0, curve: Curves.easeOut);
  int? bottomSelectedIndex = 2;
  bool isExpired = false;
  String message = '';
  Timer? _timer;
  FocusNode? focusNode;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  AppUpdateInfo? _updateInfo;

  PageController pageController = PageController(
    initialPage: 2,
    viewportFraction: 0.999,
    keepPage: true,
  );

  List<Widget> pages = [
    FleetFragment(),
    HomeFragment(),
    MapFragment(),
    NotificationFragment(),
    SettingsFragment()
  ];

  Widget buildPageView() {
    return LiquidPullToRefresh(
      key: _refreshIndicatorKey,
      onRefresh: fetchFnObjects,
      showChildOpacityTransition: false,
      color: Globals.appColor,
      child: PageView.builder(
        controller: pageController,
        allowImplicitScrolling: false,
        pageSnapping: true,
        itemCount: pages.length,
        onPageChanged: (index) async {
          setState(() {
            bottomSelectedIndex = index;
          });
          if (index != 1 && mounted && !FleetFragment.showingCircular) {
            FleetFragment.showingCircular = true;
            Globals.homeBloc!.homeListSink
                .add(Helper().homeScreenSetup(sortedImeiArray));
            await Future.microtask(
                () => Helper().homeScreenSetup(sortedImeiArray));
          }
        },
        itemBuilder: (context, position) {
          return pages[position];
        },
      ),
    );
  }

  void notificationSetup() {
    bool notification = Globals.prefs!.getBool('notification') ?? false;
    if (notification) {
      String? userEmail = Globals.prefs!.getString(LoginSettings.email);
      if (userEmail != null) {
        _firebaseMessaging.subscribeToTopic(userEmail.replaceAll('@', '_at_'));
      }
    }
  }

  /// Refactored: Traccar API User & FCM token update
  void activateFCM() async {
    try {
      var sessionResponse = await NetworkHelper().requestDataFromNetwork(
        urlFile: "/api/session",
        context: context,
      );

      if (sessionResponse.isNotEmpty) {
        Map<String, dynamic> userJson = json.decode(sessionResponse);
        int userId = userJson['id'];
        String? fcmToken = Globals.prefs!.getString(LoginSettings.notificationToken);

        if (fcmToken != null && fcmToken.isNotEmpty) {
          // Send notification token attribute to Traccar User model
          Map<String, dynamic> attributes = Map.from(userJson['attributes'] ?? {});
          attributes['notificationToken'] = fcmToken;
          userJson['attributes'] = attributes;

          await NetworkHelper().requestDataFromNetwork(
            urlFile: "/api/users/$userId",
            body: json.encode(userJson),
            context: context,
          );
        }
      }
    } catch (e) {
      print("Error activating FCM on Traccar: $e");
    }
  }

  static Future<dynamic> myBackgroundMessageHandler(
      Map<String, dynamic> message) {
    _showNotification(message);
    return Future<void>.value();
  }

  static Future<String>? downloadAndSaveFile(String? url) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/bigPicture';
    final http.Response response = await http.get(Uri.parse(url!));
    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }

  static Future _showNotification(Map<String, dynamic> message) async {
    var pushTitle;
    var pushText;
    Map<String, dynamic> data = message;
    data['isAppStarted'] = true;
    if (Platform.isAndroid) {
      var nodeData = message['data'];
      pushTitle = nodeData['title'];
      pushText = nodeData['body'];
    } else {
      pushTitle = message['title'];
      pushText = message['body'];
    }
    var vibrationPattern = Int64List(2);
    vibrationPattern[0] = 0;
    vibrationPattern[1] = 500;
    final String? bigPicturePath =
        message['data']['click_action'] == 'FLUTTER_NOTIFICATION_CLICK'
            ? ''
            : await downloadAndSaveFile(message['data']['imageURL']);
    final String? largeIconPath =
        message['data']['click_action'] == 'FLUTTER_NOTIFICATION_CLICK'
            ? ''
            : await downloadAndSaveFile(message['data']['imageURL']);
    final BigPictureStyleInformation? bigPictureStyleInformation =
        message['data']['click_action'] == 'FLUTTER_NOTIFICATION_CLICK'
            ? null
            : BigPictureStyleInformation(FilePathAndroidBitmap(bigPicturePath!),
                largeIcon: FilePathAndroidBitmap(largeIconPath!),
                contentTitle: pushTitle,
                htmlFormatContentTitle: true,
                summaryText: pushText,
                htmlFormatSummaryText: true);
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      '111',
      'speedotrack_notification_channel',
      icon: 'ic_launcher',
      sound: RawResourceAndroidNotificationSound('user'),
      vibrationPattern: vibrationPattern,
      enableLights: true,
      color: Globals.appColor,
      ledColor: Globals.appColor,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      styleInformation:
          message['data']['click_action'] == 'FLUTTER_NOTIFICATION_CLICK'
              ? BigTextStyleInformation('')
              : bigPictureStyleInformation,
      ledOnMs: 1000,
      ledOffMs: 500,
    );
  }

  static FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  void afterSetup() async {
    fetchData();
    await fetchFnSettings();
    await fetchFnObjects();
    if (mounted) {
      setState(() {
        appBarTitle = Image.asset(
          StaticVarMethod.listimageurl,
          height: 40,
          width: 120,
        );
      });
    }
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      fetchFnObjects();
    });
    
    try {
      if (Platform.isAndroid) {
        InAppUpdate.checkForUpdate().then((info) {
          setState(() {
            _updateInfo = info;
          });
        }).catchError((e) {
          showSnack(e.toString());
        });
      }
    } catch (e) {}
  }

  void showSnack(String text) {}

  /// Refactored: Fetch Device Positions via Traccar REST API `/api/positions`
  Future<void> fetchFnObjects() async {
    try {
      var response = await NetworkHelper().requestDataFromNetworkWithTimeout(
        urlFile: 'api/positions',
      );

      if (response.isNotEmpty) {
        List<dynamic> positions = json.decode(response);
        if (positions.isNotEmpty) {
          for (var pos in positions) {
            String deviceId = pos['deviceId'].toString();
            // Store mapped position data locally
            Globals.prefs!.setString('${deviceId}_objects', jsonEncode(pos));
          }
        }
        if (!Globals.homeBloc!.isClosed()) {
          Globals.dataLoaded = true;
          Globals.homeBloc!.homeListSink
              .add(Helper().homeScreenSetup(sortedImeiArray));
        }
      }
    } catch (e) {
      print("Error fetching Traccar positions: $e");
    }
    return;
  }

  void fetchData() {
    Globals.imeiArray.clear();
    sortedImeiArray.clear();
    namesJsonArray.clear();
    try {
      List<String>? cachedImeis = Globals.prefs!.getStringList(MainPrefs.keyIMEI);
      if (cachedImeis != null) {
        Globals.imeiArray.addAll(cachedImeis);
        sortedImeiArray.addAll(Globals.imeiArray);
        for (int i = 0; i < Globals.imeiArray.length; i++) {
          String? settingStr = Globals.prefs!.getString('${Globals.imeiArray[i]}_settings');
          if (settingStr != null) {
            Map<String, dynamic> deviceMap = jsonDecode(settingStr);
            namesJsonArray.add((deviceMap['name'] ?? '').toString().toLowerCase());
          }
        }
      }
    } catch (e) {
      print("Error reading stored device data: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    Globals.fetchedLogin = true;
    afterSetup();
    initLocalNotifications();
    
    if (Globals.prefs!.getBool('notification') ?? true) {
      activateFCM();
    }
    
    Globals.homeBloc = HomeBloc();
    Globals.notificationBloc = NotificationBloc();
    focusNode = FocusNode();
    _searchQuery.addListener(onChange);
    _textFocus.addListener(onChange);
  }

  TabController getTabController(int initialIndex) {
    return TabController(initialIndex: initialIndex, length: 5, vsync: this);
  }

  void initLocalNotifications() {}

  Future onSelectNotification(String payload) async {
    bool isAppOpened = false;
    Map<String, dynamic> message = jsonDecode(payload);
    isAppOpened = message['isAppStarted'] ?? false;
    List<dynamic> rows = [];
    if (isAppOpened) {
      if (message['data']['click_action'] == 'FLUTTER_NOTIFICATION_CLICK') {
        var response =
            await NetworkHelper().requestDataFromNetworkWithTimeoutGET(
                urlFile: 'api/reports/events',
                body: {
                  'from': dateTime.DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(DateTime.now().subtract(Duration(days: 1))),
                  'to': dateTime.DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(DateTime.now()),
                },
                context: context);
        if (response.isNotEmpty) {
          dynamic result = jsonDecode(response);
          if (result != null && result is List && result.isNotEmpty) {
            rows.clear();
            rows.addAll(result);
            for (int index = 0; index < rows.length; index++) {
              String id = rows[index]['id'].toString();
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => NotificationMapActivity(
                    id: id,
                  ),
                ),
              );
            }
          }
        }
      } else if (message['data']['click_action'] == 'CHROME_CLICK') {
        if (await canLaunch(message['data']['url'])) {
          await launch(message['data']['url']);
        }
      } else if (message['data']['click_action'] == 'WEBVIEW_CLICK') {
        Navigator.push(
            context,
            MaterialPageRoute<void>(
                builder: (context) => ActivityWebView(
                      url: message['data']['url'],
                      title: message['data']['title'],
                    )));
      }
    }
  }

  @override
  void dispose() {
    if (_timer != null) {
      _timer!.cancel();
    }
    super.dispose();
  }

  final GlobalKey<LiquidPullToRefreshState> _refreshIndicatorKey =
      GlobalKey<LiquidPullToRefreshState>();

  /// Refactored: Fetch Devices via Traccar REST API `/api/devices`
  Future<void> fetchFnSettings() async {
    try {
      var response = await NetworkHelper().requestDataFromNetworkWithTimeout(
        urlFile: 'api/devices',
        context: context,
      );
      if (response.isNotEmpty) {
        List<dynamic> devices = json.decode(response);
        if (devices.isNotEmpty) {
          List<String> imeiArray = [];
          Map<String, bool> parkingMode = {};

          for (var dev in devices) {
            String deviceKey = dev['uniqueId'] ?? dev['id'].toString();
            Globals.prefs!.setString('${deviceKey}_settings', jsonEncode(dev));
            parkingMode[deviceKey] = false;
            imeiArray.add(deviceKey);
          }

          Globals.prefs!.setStringList(MainPrefs.keyIMEI, imeiArray);
          Globals.prefs!.setString('parkingMode', jsonEncode(parkingMode));
          fetchData();
        }
        await fetchFnObjects();
        Globals.fetchedSettings = true;
      }
    } catch (e) {
      print("Error fetching Traccar devices: $e");
    }
  }

  /// Refactored: Check Expiration directly from Traccar Device object (`disabled` or `expirationTime`)
  Future<void> checkExpiryDevice() async {
    int expiredDevicesLength = 0;
    String expiredDevicesName = '';
    for (int i = 0; i < Globals.imeiArray.length; i++) {
      String? settingsRaw = Globals.prefs!.getString('${Globals.imeiArray[i]}_settings');
      if (settingsRaw != null) {
        Map<String, dynamic> dev = jsonDecode(settingsRaw);
        if (dev['expirationTime'] != null) {
          DateTime expireDate = DateTime.parse(dev['expirationTime']);
          int expired = expireDate.difference(DateTime.now()).inDays;
          if (expired <= 7 && expired > -1) {
            expiredDevicesLength++;
            expiredDevicesName = '$expiredDevicesName ${dev['name']},';
          }
        }
      }
    }
    if (expiredDevicesLength > 0) {
      expiredDevicesName =
          expiredDevicesName.substring(0, expiredDevicesName.length - 1);
      message =
          'Your ${expiredDevicesLength > 1 ? 'devices' : 'device'} ($expiredDevicesName) will '
          'expire very soon. For Auto Renewal '
          'please pay monthly charges to avoid disconnection.';
      setState(() {
        isExpired = true;
      });
    }
  }

  final TextEditingController _searchQuery = TextEditingController();
  FocusNode _textFocus = FocusNode();

  void onChange() {
    Provider.of<ProviderType>(context, listen: false)
        .searchValue(_searchQuery.text);
  }

  List<String> sortedImeiArray = [];
  Widget appBarTitle = Shimmer.fromColors(
    baseColor: Globals.appColor,
    highlightColor: Colors.white,
    enabled: true,
    child: Image.asset(
      StaticVarMethod.listimageurl,
      height: 40,
      width: 120,
    ),
  );
  Icon actionIcon = Icon(
    Icons.search,
    color: Colors.white,
  );

  createContentDisplay() {
    return zoomAndSlideContent(Container(
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Color(0xFFF6F6F6),
        appBar: AppBar(
            backgroundColor: Globals.appColor,
            elevation: 0.0,
            leading: IconButton(
                icon: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child:
                      Image.asset('images/menu.png', color: Color(0xFFF6F6F6)),
                ),
                onPressed: () {
                  Provider.of<MenuControllerHome>(context, listen: false)
                      .toggle();
                }),
            title: Hero(tag: 'logo', child: appBarTitle),
            centerTitle: true,
            actions: <Widget>[
              IconButton(
                icon: actionIcon,
                onPressed: () {
                  setState(() {
                    if (actionIcon.icon == Icons.search) {
                      actionIcon = Icon(
                        Icons.close,
                        color: Colors.white,
                      );
                      appBarTitle = TextField(
                        controller: _searchQuery,
                        focusNode: focusNode,
                        onChanged: (value) {
                          if (value.isNotEmpty && value != '') {
                            sortedImeiArray.clear();
                            for (int i = 0; i < Globals.imeiArray.length; i++) {
                              if (Globals.imeiArray[i]
                                      .contains(value.toLowerCase()) ||
                                  (namesJsonArray.length > i &&
                                      namesJsonArray[i]
                                          .contains(value.toLowerCase()))) {
                                sortedImeiArray.add(Globals.imeiArray[i]);
                              }
                            }
                            Globals.homeBloc!.homeListSink
                                .add(Helper().homeScreenSetup(sortedImeiArray));
                          } else {
                            sortedImeiArray.clear();
                            sortedImeiArray.addAll(Globals.imeiArray);
                            Globals.homeBloc!.homeListSink
                                .add(Helper().homeScreenSetup(sortedImeiArray));
                          }
                        },
                        style: TextStyle(
                          color: Colors.white,
                        ),
                        cursorColor: Colors.white,
                        decoration: InputDecoration(
                            filled: true,
                            fillColor: Globals.appColor,
                            prefixIcon: Icon(Icons.search, color: Colors.white),
                            hintText: "Search device",
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            hintStyle: TextStyle(color: Color(0xFFF6F6F6))),
                      );
                      focusNode!.requestFocus();
                    } else {
                      sortedImeiArray.clear();
                      sortedImeiArray.addAll(Globals.imeiArray);
                      Globals.homeBloc!.homeListSink
                          .add(Helper().homeScreenSetup(sortedImeiArray));
                      Provider.of<ProviderType>(context, listen: false)
                          .searchComplete();
                      setState(() {
                        actionIcon = Icon(
                          Icons.search,
                          color: Colors.white,
                        );
                        appBarTitle = Image.asset(
                          StaticVarMethod.listimageurl,
                          height: 40,
                          width: 120,
                        );
                        _searchQuery.clear();
                      });
                    }
                  });
                },
              ),
              IconButton(
                  onPressed: () {
                    if (Globals.imeiArray.isNotEmpty && namesJsonArray.isNotEmpty) {
                      changeDeviceDialog(Globals.imeiArray, namesJsonArray);
                    }
                  },
                  icon: Icon(
                    Icons.share,
                    color: Colors.white,
                  ))
            ]),
        body: Stack(
          children: <Widget>[
            buildPageView(),
            Align(
              alignment: FractionalOffset.bottomCenter,
              child: CurvedNavigationBar(
                height: 45,
                animationDuration: Duration(milliseconds: 250),
                buttonBackgroundColor: Globals.appColor,
                color: Globals.appColor,
                backgroundColor: Colors.transparent,
                items: <Widget>[
                  Icon(
                    Icons.directions_car,
                    size: 30,
                    color: Color(0xFFF6F6F6),
                  ),
                  Icon(
                    Icons.list_alt,
                    size: 30,
                    color: Color(0xFFF6F6F6),
                  ),
                  Icon(
                    Icons.map,
                    size: 30,
                    color: Color(0xFFF6F6F6),
                  ),
                  Icon(
                    Icons.notifications_none,
                    size: 30,
                    color: Color(0xFFF6F6F6),
                  ),
                  Icon(
                    Icons.settings,
                    size: 30,
                    color: Color(0xFFF6F6F6),
                  ),
                ],
                onTap: (index) {
                  bottomSelectedIndex = index;
                  pageController.animateToPage(index,
                      duration: Duration(milliseconds: 250),
                      curve: Curves.fastOutSlowIn);
                },
                index: bottomSelectedIndex,
              ),
            ),
            Visibility(
              visible: isExpired,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 50,
                        child: Scaffold(
                          backgroundColor: Colors.transparent,
                          bottomNavigationBar: BottomAppBar(
                            color: Colors.transparent,
                            clipBehavior: Clip.antiAliasWithSaveLayer,
                            shape: CircularNotchedRectangle(),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(5),
                                    topRight: Radius.circular(5)),
                                color: Colors.white,
                              ),
                              height: 40.0,
                            ),
                          ),
                          floatingActionButtonLocation:
                              FloatingActionButtonLocation.centerDocked,
                          floatingActionButton: FloatingActionButton(
                            backgroundColor: Colors.white,
                            onPressed: () {},
                            child: Container(
                                clipBehavior: Clip.antiAliasWithSaveLayer,
                                decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(50))),
                                child: Image.asset('images/appIcon.png')),
                          ),
                        ),
                      ),
                      Material(
                        elevation: 5,
                        color: Colors.white,
                        child: Container(
                          padding: const EdgeInsets.only(
                              left: 20, right: 20, bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                          ),
                          child: Text(
                            message,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                letterSpacing: 1,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Montserrat'),
                          ),
                        ),
                      ),
                      Material(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(5),
                                bottomLeft: Radius.circular(5))),
                        child: Container(
                          padding: const EdgeInsets.only(left: 20, right: 20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(5),
                                bottomLeft: Radius.circular(5)),
                            color: Globals.appColor,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      isExpired = false;
                                    });
                                  },
                                  child: Container(
                                    alignment: Alignment.center,
                                    height: 40,
                                    child: Text(
                                      'CANCEL',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          letterSpacing: 1,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Montserrat'),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 50,
                                color: Colors.white,
                              ),
                              Expanded(
                                flex: 1,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      isExpired = false;
                                    });
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute<void>(
                                            builder: (context) =>
                                                ActivityWebView(
                                                  url: Globals.payNow,
                                                  title: 'PAY NOW',
                                                )));
                                  },
                                  child: Container(
                                    height: 40,
                                    alignment: Alignment.center,
                                    child: Text(
                                      'PAY NOW',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          letterSpacing: 1,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Montserrat'),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }

  void changeDeviceDialog(List<String> imeiArray, List<String> namesJsonArray) {
    showGeneralDialog(
      barrierLabel: 'Share Device',
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
                      child: AutoSizeText(
                        'Share Device',
                        minFontSize: 8,
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
                    changeDeviceDropDown(imeiArray, namesJsonArray),
                  ],
                ),
              )),
        );
      },
    );
  }

  DropdownButton<String> changeDeviceDropDown(
      List<String> iMEIArray, List<String> namesJsonArray) {
    String deviceSelected = iMEIArray[0];
    List<DropdownMenuItem<String>> dropdownItems = [];
    for (int i = 0; i < iMEIArray.length; i++) {
      var newItem = DropdownMenuItem(
        child: Text(namesJsonArray.length > i ? namesJsonArray[i] : iMEIArray[i]),
        value: iMEIArray[i],
      );
      dropdownItems.add(newItem);
    }

    return DropdownButton<String>(
        value: deviceSelected,
        items: dropdownItems,
        onChanged: (iMEI) {
          try {
            String todayDate = dateTime.DateFormat('yyyy-MM-dd')
                .format(DateTime.now().add(Duration(days: 1)));
            showShareLocationDialog(context, todayDate, () {
              Navigator.of(context, rootNavigator: true).pop(context);
            }, iMEI!);
          } catch (e) {}
        });
  }

  zoomAndSlideContent(Widget content) {
    var slidePercent, scalePercent;
    try {
      switch (Provider.of<MenuControllerHome>(context, listen: true).state) {
        case MenuState.closed:
          slidePercent = 0.0;
          scalePercent = 0.0;
          break;
        case MenuState.open:
          slidePercent = 1.0;
          scalePercent = 1.0;
          break;
        case MenuState.opening:
          slidePercent = slideOutCurve.transform(
              Provider.of<MenuControllerHome>(context, listen: true)
                  .percentOpen);
          scalePercent = scaleDownCurve.transform(
              Provider.of<MenuControllerHome>(context, listen: true)
                  .percentOpen);
          break;
        case MenuState.closing:
          slidePercent = slideInCurve.transform(
              Provider.of<MenuControllerHome>(context, listen: true)
                  .percentOpen);
          scalePercent = scaleUpCurve.transform(
              Provider.of<MenuControllerHome>(context, listen: true)
                  .percentOpen);
          break;
      }
    } catch (e) {}

    final slideAmount = 275.0 * slidePercent;
    final contentScale = 1.0 - (0.2 * scalePercent);
    final cornerRadius = 16.0 *
        Provider.of<MenuControllerHome>(context, listen: false).percentOpen;

    return Transform(
      transform: Matrix4.translationValues(slideAmount, 0.0, 0.0)
        ..scale(contentScale, contentScale),
      alignment: Alignment.centerLeft,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              offset: const Offset(0.0, 5.0),
              blurRadius: 15.0,
              spreadRadius: 10.0,
            ),
          ],
        ),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(cornerRadius), child: content),
      ),
    );
  }

  Future<bool> _onBackPressed() async {
    if (Provider.of<MenuControllerHome>(context, listen: false).isOpened() ==
        MenuState.open) {
      Provider.of<MenuControllerHome>(context, listen: false).toggle();
      return false;
    } else {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (bool val, val2) {},
      child: Stack(
        children: [
          Container(
            child: Scaffold(
              body: widget.menuScreen,
            ),
          ),
          createContentDisplay()
        ],
      ),
    );
  }
}
