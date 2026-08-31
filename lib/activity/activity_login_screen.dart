import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:flutter/cupertino.dart';
import 'package:speedotrack/helper/static.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:custom_progress_button/custom_progress_button.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:progress_dialog_null_safe/progress_dialog_null_safe.dart';
import 'package:provider/provider.dart';
import 'package:speedotrack/Animation/animation_fade.dart';
import 'package:speedotrack/Network/network_api_request.dart';
import 'package:speedotrack/activity/activity_splash_screen.dart';
import 'package:speedotrack/globals.dart';
import 'package:speedotrack/model/model_change_password.dart';
import 'package:speedotrack/model/model_credentials.dart';
import 'package:speedotrack/sharedPrefs/login_settings.dart';
import 'package:speedotrack/sharedPrefs/main_prefs.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:video_player/video_player.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenPageState createState() => _LoginScreenPageState();
}

class _LoginScreenPageState extends State<LoginScreen> {
  final TextEditingController forgotEmailController = TextEditingController();
  final TextEditingController usernameEmailController = TextEditingController();
  final TextEditingController passwordEmailController = TextEditingController();

  bool isShowing = false;
  late VideoPlayerController _logoVideoController;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Globals.appColor,
      systemNavigationBarColor: Globals.appColor,
    ));
    _logoVideoController = VideoPlayerController.asset('assets/logo.mp4')
      ..initialize().then((_) {
        _logoVideoController.setLooping(true);
        _logoVideoController.play();
        setState(() {});
      });
  }

  @override
  void dispose() {
    _logoVideoController.dispose();
    forgotEmailController.dispose();
    usernameEmailController.dispose();
    passwordEmailController.dispose();
    super.dispose();
  }

  Future<bool> loginUser({String? username, String? password}) async {
    // Traccar REST API endpoint for login session: POST /api/session
    var response = await NetworkHelper().requestDataFromNetwork(
      urlFile: '/api/session',
      body: {
        'email': username?.trim(),
        'password': password,
      },
    );

    String respStr = response != null ? response.toString() : '';
    
    // Check for successful Traccar user object response (contains user details like "id" or "email")
    if (respStr.contains('"id":') || respStr.contains('"email":') || respStr.contains('email')) {
      Globals.prefs!.setBool(MainPrefs.isLoggedIn, true);
      Globals.prefs!.setString(LoginSettings.email, username!.replaceAll(' ', ''));
      Globals.prefs!.setString(LoginSettings.password, password!);
      Globals.prefs!.setBool(MainPrefs.appFirstTime, true);
      Globals.prefs!.setBool('fetchIcon', true);
      Globals.prefs!.setBool('mapHybrid', false);
      Globals.prefs!.setBool('notification', true);
      Globals.prefs!.setBool('mapCard', true);
      return true;
    } else if (respStr.toLowerCase().contains('unauthorized') || 
               respStr.toLowerCase().contains('account') || 
               respStr.toLowerCase().contains('incorrect')) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('wrongData'.tr)));
      return false;
    } else if (respStr.toLowerCase().contains('too many') || 
               respStr.toLowerCase().contains('locked')) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('tooManyAttemp'.tr)));
      return false;
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('unknownError'.tr)));
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Platform.isAndroid
        ? MultiProvider(
            providers: [
                ChangeNotifierProvider<CredentialsModel>(
                    create: (_) => CredentialsModel())
              ],
            child: Consumer<CredentialsModel>(builder: (context, model, _) {
              if (!isShowing) {
                isShowing = true;
                // model.get(Mediation.Optional);
              }
              return SafeArea(
                child: Scaffold(
                 // backgroundColor: Color(0xFFF6F6F6),
                  body: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Container(
                          decoration: BoxDecoration(
                              //     color: Globals.appColor,
                              borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(100))),
                          height: MediaQuery.of(context).size.height * 0.35,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 50),
                                  child: Container(
                                    height: 250,
                                    child: Hero(
                                      tag: "logo",
                                      child: _logoVideoController.value.isInitialized
                                          ? AspectRatio(
                                              aspectRatio: _logoVideoController.value.aspectRatio,
                                              child: VideoPlayer(_logoVideoController),
                                            )
                                          : Container(),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.0,
                                ),
                                Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 50),
                                    child: Text(
                                      'welcome'.tr + 'ETTS',
                                      maxLines: 2,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontFamily: 'Ubuntu',
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 1),
                                    )),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 60),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.1,
                              ),
                              FadeAnimation(
                                  1,
                                  Container(
                                    height: MediaQuery.of(context).size.height *
                                        0.06,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(50),
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey,
                                            blurRadius: 10,
                                            offset: Offset(0, 5),
                                          )
                                        ]),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 25),
                                      child: Center(
                                        child: TextField(
                                          controller: model.idEdit,
                                          cursorColor: Globals.appColor,
                                          style: TextStyle(
                                              color: Globals.appColor),
                                          decoration: InputDecoration(
                                              icon: Icon(
                                                Icons.mail,
                                                color: Colors.grey,
                                                size: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.025,
                                              ),
                                              border: InputBorder.none,
                                              hintText: "username".tr,
                                              focusColor: Globals.appColor,
                                              hintStyle: TextStyle(
                                                  color: Colors.grey)),
                                        ),
                                      ),
                                    ),
                                  )),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.03,
                              ),
                              FadeAnimation(
                                  1.7,
                                  Container(
                                    height: MediaQuery.of(context).size.height *
                                        0.06,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(50),
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey,
                                            blurRadius: 10,
                                            offset: Offset(0, 5),
                                          )
                                        ]),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 25),
                                      child: Center(
                                        child: TextField(
                                          controller: model.passwordEdit,
                                          cursorColor: Globals.appColor,
                                          style: TextStyle(
                                              color: Globals.appColor),
                                          decoration: InputDecoration(
                                              icon: Icon(
                                                Icons.vpn_key,
                                                color: Colors.grey,
                                                size: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.025,
                                              ),
                                              border: InputBorder.none,
                                              hintText: "password".tr,
                                              focusColor: Globals.appColor,
                                              hintStyle: TextStyle(
                                                  color: Colors.grey)),
                                          obscureText: true,
                                        ),
                                      ),
                                    ),
                                  )),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.03,
                              ),
                              FadeAnimation(
                                  1.8,
                                  InkWell(
                                    onTap: () {
                                      showGeneralDialog(
                                        barrierLabel: 'resetPassword'.tr,
                                        barrierDismissible: true,
                                        barrierColor:
                                            Colors.black.withOpacity(0.5),
                                        context: context,
                                        transitionDuration:
                                            Duration(milliseconds: 100),
                                        pageBuilder: (_, __, ___) {
                                          return Center(
                                            child: Card(
                                                color: Colors.white,
                                                child: Container(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.75,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            10.0),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: <Widget>[
                                                        Text(
                                                          'resetPassword'.tr,
                                                          maxLines: 1,
                                                          textAlign:
                                                              TextAlign.end,
                                                          style: TextStyle(
                                                            color: Colors.black,
                                                            fontSize: 15,
                                                            decoration:
                                                                TextDecoration
                                                                    .none,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            letterSpacing: 1.0,
                                                            fontFamily:
                                                                'Montserrat',
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  vertical: 10,
                                                                  horizontal:
                                                                      20),
                                                          child: TextField(
                                                            controller:
                                                                forgotEmailController,
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                            decoration: InputDecoration(
                                                                prefixIcon: Icon(
                                                                    Icons.email,
                                                                    color: Colors
                                                                        .grey),
                                                                hintText:
                                                                    'enterEmail'
                                                                        .tr,
                                                                hintStyle: TextStyle(
                                                                    color: Colors
                                                                        .grey)),
                                                          ),
                                                        ),
                                                        CustomProgressButton(
                                                          onPressed: () async {
                                                            if (forgotEmailController
                                                                .text
                                                                .isNotEmpty) {
                                                              // Traccar Password Reset endpoint: POST /api/password/reset
                                                              var response = await NetworkHelper()
                                                                  .requestDataFromNetworkWithTimeout(
                                                                      urlFile:
                                                                          '/api/password/reset',
                                                                      body: {
                                                                    'email':
                                                                        forgotEmailController
                                                                            .text
                                                                            .trim(),
                                                                  });
                                                              String respStr = response != null ? response.toString() : '';
                                                              if (!respStr.toLowerCase().contains('error') && !respStr.toLowerCase().contains('not found')) {
                                                                forgotEmailController.clear();
                                                                Navigator.pop(context);
                                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('recoverEmail'.tr)));
                                                              } else if (respStr.toLowerCase().contains('not found')) {
                                                                forgotEmailController.clear();
                                                                Navigator.pop(context);
                                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('noUser'.tr)));
                                                              } else {
                                                                forgotEmailController.clear();
                                                                Navigator.pop(context);
                                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('oopsSomethingWentWrong'.tr)));
                                                              }
                                                            } else {
                                                              ScaffoldMessenger
                                                                      .of(
                                                                          context)
                                                                  .showSnackBar(
                                                                      SnackBar(
                                                                          content:
                                                                              Text('pleaseFillYourCorrectEmail'.tr)));
                                                            }
                                                          },
                                                          height: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .height *
                                                              0.06,
                                                          maxWidth: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              0.50,
                                                          progressWidget: CircularProgressIndicator(
                                                              backgroundColor:
                                                                  Globals
                                                                      .appColor,
                                                              valueColor:
                                                                  AlwaysStoppedAnimation<
                                                                          Color>(
                                                                      Colors
                                                                          .white)),
                                                          stateWidgets: {
                                                            ButtonState.success:
                                                                Text(
                                                              'success'.tr,
                                                              style: TextStyle(
                                                                  fontSize: 20),
                                                            ),
                                                            ButtonState.fail:
                                                                Text(
                                                              'failure'.tr,
                                                              style: TextStyle(
                                                                  fontSize: 20),
                                                            ),
                                                            ButtonState.loading:
                                                                Text(
                                                              'recoverPassword'
                                                                  .tr,
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 14),
                                                            ),
                                                            ButtonState.idle:
                                                                Text(
                                                              'login'.tr,
                                                              style: TextStyle(
                                                                  fontSize: 20,
                                                                  color: Colors
                                                                      .white),
                                                            ),
                                                          },
                                                          stateColors: {
                                                            ButtonState.success:
                                                                Colors.green,
                                                            ButtonState.fail:
                                                                Colors
                                                                    .redAccent,
                                                            ButtonState.loading:
                                                                Colors.red,
                                                            ButtonState.idle:
                                                                Globals
                                                                    .appColor,
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                )),
                                          );
                                        },
                                      );
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      child: Text(
                                        "resetPassword".tr,
                                        textAlign: TextAlign.end,
                                        style: TextStyle(
                                            fontFamily: 'Ubuntu',
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.8,
                                            fontSize: 14),
                                      ),
                                    ),
                                  )),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.03,
                              ),
                              FadeAnimation(
                                  1.9,
                                  CustomProgressButton(
                                    onPressed: () async {
                                      if (model.idEdit.text.isNotEmpty &&
                                          model.passwordEdit.text.isNotEmpty) {
                                        bool result = await loginUser(
                                            username: model.idEdit.text,
                                            password: model.passwordEdit.text);
                                        if (result) {
                                          try {
                                            // await model.store(Mediation.Optional);
                                          } catch (e) {}
                                          changeTimeZone();
                                        }
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text(
                                                    'enterYourCredentials'
                                                        .tr)));
                                      }
                                    },
                                    height: MediaQuery.of(context).size.height *
                                        0.06,
                                    progressWidget: CircularProgressIndicator(
                                        backgroundColor: Globals.appColor,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white)),
                                    stateWidgets: {
                                      ButtonState.success: Text(
                                        'success'.tr,
                                        style: TextStyle(fontSize: 20),
                                      ),
                                      ButtonState.fail: Text(
                                        'failure'.tr,
                                        style: TextStyle(fontSize: 20),
                                      ),
                                      ButtonState.loading: Text(
                                        "login".tr,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontFamily: 'Ubuntu',
                                        ),
                                      ),
                                      ButtonState.idle: Text(
                                        'login'.tr,
                                        style: TextStyle(
                                            fontSize: 20, color: Colors.white),
                                      ),
                                    },
                                    stateColors: {
                                      ButtonState.success: Colors.green,
                                      ButtonState.fail: Colors.redAccent,
                                      ButtonState.loading: Colors.red,
                                      ButtonState.idle: Globals.appColor,
                                    },
                                  )),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.05,
                              ),
                            ],
                          ),
                        ),
                        FadeAnimation(
                            2,
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 25),
                              child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: <Widget>[
                                    Expanded(
                                      flex: 1,
                                      child: InkWell(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Icon(
                                              FontAwesomeIcons.whatsapp,
                                              color: Colors.grey,
                                              size: 30,
                                            ),
                                            SizedBox(
                                              height: 5,
                                            ),
                                            Container(
                                              alignment: Alignment.center,
                                              child: Text(
                                                'whatsapp'.tr,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                        onTap: () async {
                                          var whatsappUrl =
                                              "whatsapp://send?phone=${Globals.mobileNumber}";
                                          await canLaunch(whatsappUrl)
                                              ? launch(whatsappUrl)
                                              : print('cantOpenWhatsapp'.tr);
                                        },
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: InkWell(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Icon(
                                              FontAwesomeIcons.phone,
                                              color: Colors.grey,
                                              size: 30,
                                            ),
                                            SizedBox(
                                              height: 5,
                                            ),
                                            Container(
                                              alignment: Alignment.center,
                                              child: Text(
                                                'support'.tr,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                        onTap: () async {
                                          var emailUrl =
                                              'tel:${Globals.hotLineNumberWithCode}';
                                          launchUrlString(emailUrl);
                                        },
                                      ),
                                    ),
                                  ]),
                            )),
                      ],
                    ),
                  ),
                ),
              );
            }))
        : SafeArea(
            child: Scaffold(
            backgroundColor: Color(0xFFF6F6F6),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Container(
                    decoration: BoxDecoration(
                        color: Globals.appColor,
                        borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(100))),
                    height: MediaQuery.of(context).size.height * 0.35,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 50),
                            child: Container(
                              child: Hero(
                                tag: "logo",
                                child: _logoVideoController.value.isInitialized
                                    ? AspectRatio(
                                        aspectRatio: _logoVideoController.value.aspectRatio,
                                        child: VideoPlayer(_logoVideoController),
                                      )
                                    : Container(),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.04,
                          ),
                          Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 50),
                              child: Text(
                                'welcome'.tr + 'Track & Tell Communications Smc-Pvt Ltd',
                                maxLines: 1,
                                style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.white,
                                    fontFamily: 'Ubuntu',
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 1),
                              )),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 60),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.1,
                        ),
                        FadeAnimation(
                            1,
                            Container(
                              height: MediaQuery.of(context).size.height * 0.06,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50),
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey,
                                      blurRadius: 10,
                                      offset: Offset(0, 5),
                                    )
                                  ]),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 25),
                                child: Center(
                                  child: TextField(
                                    controller: usernameEmailController,
                                    cursorColor: Globals.appColor,
                                    style: TextStyle(color: Globals.appColor),
                                    decoration: InputDecoration(
                                        icon: Icon(
                                          Icons.mail,
                                          color: Colors.grey,
                                          size: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.025,
                                        ),
                                        border: InputBorder.none,
                                        hintText: "username".tr,
                                        focusColor: Globals.appColor,
                                        hintStyle:
                                            TextStyle(color: Colors.grey)),
                                  ),
                                ),
                              ),
                            )),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.03,
                        ),
                        FadeAnimation(
                            1.7,
                            Container(
                              height: MediaQuery.of(context).size.height * 0.06,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50),
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey,
                                      blurRadius: 10,
                                      offset: Offset(0, 5),
                                    )
                                  ]),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 25),
                                child: Center(
                                  child: TextField(
                                    controller: passwordEmailController,
                                    cursorColor: Globals.appColor,
                                    style: TextStyle(color: Globals.appColor),
                                    decoration: InputDecoration(
                                        icon: Icon(
                                          Icons.vpn_key,
                                          color: Colors.grey,
                                          size: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.025,
                                        ),
                                        border: InputBorder.none,
                                        hintText: "password".tr,
                                        focusColor: Globals.appColor,
                                        hintStyle:
                                            TextStyle(color: Colors.grey)),
                                    obscureText: true,
                                  ),
                                ),
                              ),
                            )),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.03,
                        ),
                        FadeAnimation(
                            1.8,
                            InkWell(
                              onTap: () {
                                showGeneralDialog(
                                  barrierLabel: 'resetPassword'.tr,
                                  barrierDismissible: true,
                                  barrierColor: Colors.black.withOpacity(0.5),
                                  context: context,
                                  transitionDuration:
                                      Duration(milliseconds: 100),
                                  pageBuilder: (_, __, ___) {
                                    return Center(
                                      child: Card(
                                          color: Colors.white,
                                          child: Container(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.75,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(10.0),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: <Widget>[
                                                  Text(
                                                    'resetPassword'.tr,
                                                    maxLines: 1,
                                                    textAlign: TextAlign.end,
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 15,
                                                      decoration:
                                                          TextDecoration.none,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      letterSpacing: 1.0,
                                                      fontFamily: 'Montserrat',
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 10,
                                                        horizontal: 20),
                                                    child: TextField(
                                                      controller:
                                                          forgotEmailController,
                                                      style: TextStyle(
                                                        color: Colors.grey,
                                                      ),
                                                      decoration: InputDecoration(
                                                          prefixIcon: Icon(
                                                              Icons.email,
                                                              color:
                                                                  Colors.grey),
                                                          hintText:
                                                              'enterEmail'.tr,
                                                          hintStyle: TextStyle(
                                                              color:
                                                                  Colors.grey)),
                                                    ),
                                                  ),
                                                  CustomProgressButton(
                                                    onPressed: () async {
                                                      if (forgotEmailController
                                                          .text.isNotEmpty) {
                                                        // Traccar Password Reset endpoint: POST /api/password/reset
                                                        var response =
                                                            await NetworkHelper()
                                                                .requestDataFromNetworkWithTimeout(
                                                                    urlFile:
                                                                        '/api/password/reset',
                                                                    body: {
                                                              'email':
                                                                  forgotEmailController
                                                                      .text
                                                                      .trim(),
                                                            });
                                                        String respStr = response != null ? response.toString() : '';
                                                        if (!respStr.toLowerCase().contains('error') && !respStr.toLowerCase().contains('not found')) {
                                                          forgotEmailController.clear();
                                                          Navigator.pop(context);
                                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('recoverEmail'.tr)));
                                                        } else if (respStr.toLowerCase().contains('not found')) {
                                                          forgotEmailController.clear();
                                                          Navigator.pop(context);
                                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('noUser'.tr)));
                                                        } else {
                                                          forgotEmailController.clear();
                                                          Navigator.pop(context);
                                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('oopsSomethingWentWrong'.tr)));
                                                        }
                                                      } else {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(SnackBar(
                                                                content: Text(
                                                                    'pleaseFillYourCorrectEmail'
                                                                        .tr)));
                                                      }
                                                    },
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height *
                                                            0.06,
                                                    maxWidth:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.50,
                                                    progressWidget:
                                                        CircularProgressIndicator(
                                                            backgroundColor:
                                                                Globals
                                                                    .appColor,
                                                            valueColor:
                                                                AlwaysStoppedAnimation<
                                                                        Color>(
                                                                    Colors
                                                                        .white)),
                                                    stateWidgets: {
                                                      ButtonState.success: Text(
                                                        'success'.tr,
                                                        style: TextStyle(
                                                            fontSize: 20),
                                                      ),
                                                      ButtonState.fail: Text(
                                                        'failure'.tr,
                                                        style: TextStyle(
                                                            fontSize: 20),
                                                      ),
                                                      ButtonState.loading: Text(
                                                        'recoverPassword'.tr,
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 14),
                                                      ),
                                                      ButtonState.idle: Text(
                                                        'login'.tr,
                                                        style: TextStyle(
                                                            fontSize: 20,
                                                            color:
                                                                Colors.white),
                                                      ),
                                                    },
                                                    stateColors: {
                                                      ButtonState.success:
                                                          Colors.green,
                                                      ButtonState.fail:
                                                          Colors.redAccent,
                                                      ButtonState.loading:
                                                          Colors.red,
                                                      ButtonState.idle:
                                                          Globals.appColor,
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )),
                                    );
                                  },
                                );
                              },
                              child: Container(
                                width: double.infinity,
                                child: Text(
                                  "resetPassword".tr,
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                      fontFamily: 'Ubuntu',
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.8,
                                      fontSize: 14),
                                ),
                              ),
                            )),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.03,
                        ),
                        FadeAnimation(
                            1.9,
                            CustomProgressButton(
                              onPressed: () async {
                                if (usernameEmailController.text.isNotEmpty &&
                                    passwordEmailController.text.isNotEmpty) {
                                  bool result = await loginUser(
                                      username: usernameEmailController.text,
                                      password: passwordEmailController.text);
                                  if (result) {
                                    changeTimeZone();
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text('enterYourCredentials'.tr)));
                                }
                              },
                              height: MediaQuery.of(context).size.height * 0.06,
                              progressWidget: CircularProgressIndicator(
                                  backgroundColor: Globals.appColor,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white)),
                              stateWidgets: {
                                ButtonState.success: Text(
                                  'success'.tr,
                                  style: TextStyle(fontSize: 20),
                                ),
                                ButtonState.fail: Text(
                                  'failure'.tr,
                                  style: TextStyle(fontSize: 20),
                                ),
                                ButtonState.loading: Text(
                                  "login".tr,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontFamily: 'Ubuntu',
                                  ),
                                ),
                                ButtonState.idle: Text(
                                  'login'.tr,
                                  style: TextStyle(
                                      fontSize: 20, color: Colors.white),
                                ),
                              },
                              stateColors: {
                                ButtonState.success: Colors.green,
                                ButtonState.fail: Colors.redAccent,
                                ButtonState.loading: Colors.red,
                                ButtonState.idle: Globals.appColor,
                              },
                            )),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.05,
                        ),
                      ],
                    ),
                  ),
                  FadeAnimation(
                      2,
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              Expanded(
                                flex: 1,
                                child: InkWell(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Icon(
                                        FontAwesomeIcons.robot,
                                        color: Colors.grey,
                                        size: 30,
                                      ),
                                      SizedBox(
                                        height: 5,
                                      ),
                                      Container(
                                        alignment: Alignment.center,
                                        child: Text(
                                          'demoLogin'.tr,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                  onTap: () async {
                                    ProgressDialog pr;
                                    pr = ProgressDialog(context,
                                        type: ProgressDialogType.normal,
                                        isDismissible: false,
                                        showLogs: false);
                                    pr.show();
                                    bool result = await loginUser(
                                        username: Globals.demoUsername,
                                        password: Globals.demoPassword);
                                    if (result) {
                                      pr.hide();
                                      changeTimeZone();
                                    }
                                  },
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: InkWell(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Icon(
                                        FontAwesomeIcons.whatsapp,
                                        color: Colors.grey,
                                        size: 30,
                                      ),
                                      SizedBox(
                                        height: 5,
                                      ),
                                      Container(
                                        alignment: Alignment.center,
                                        child: Text(
                                          'whatsapp'.tr,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                  onTap: () async {
                                    var whatsappUrl =
                                        "whatsapp://send?phone=${Globals.mobileNumber}";
                                    await canLaunch(whatsappUrl)
                                        ? launch(whatsappUrl)
                                        : print('cantOpenWhatsapp'.tr);
                                  },
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: InkWell(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Icon(
                                        FontAwesomeIcons.phone,
                                        color: Colors.grey,
                                        size: 30,
                                      ),
                                      SizedBox(
                                        height: 5,
                                      ),
                                      Container(
                                        alignment: Alignment.center,
                                        child: Text(
                                          'support'.tr,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                  onTap: () async {
                                    var emailUrl =
                                        'tel:${Globals.hotLineNumberWithCode}';
                                    await canLaunch(emailUrl)
                                        ? launch(emailUrl)
                                        : print('Can\'t call at the moment.');
                                  },
                                ),
                              ),
                            ]),
                      )),
                ],
              ),
            ),
          ));
  }

  ChangePassword changePasswordFromJson(String str) =>
      ChangePassword.fromJson(json.decode(str));

  void changeTimeZone() async {
    ProgressDialog pr;
    pr = ProgressDialog(context,
        type: ProgressDialogType.normal, isDismissible: false, showLogs: false);
    pr.show();

    // Verify Traccar Session
    await NetworkHelper().requestDataFromNetworkWithTimeout(
        urlFile: '/api/session',
        body: {});

    pr.hide();
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      Navigator.of(context)
        ..pop()
        ..push(CupertinoPageRoute(
            builder: (context) =>
                SplashScreen(isFromLogin: true, isAppRestarted: false)));
    }
  }
}
