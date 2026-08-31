import 'package:get/get.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:speedotrack/Animation/animation_fade.dart';
import 'package:speedotrack/activity/activity_about_us.dart';
import 'package:speedotrack/activity/activity_webview.dart';
import 'package:speedotrack/network/network_api_request.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../globals.dart';

class LiveSupport extends StatefulWidget {
  @override
  _LiveSupportState createState() => _LiveSupportState();
}

Future<void> whatsappActvity() async {
  var whatsappUrl = "https://wa.me/${Globals.mobileNumber}";
  launchUrlString(whatsappUrl);
}

Future<void> emailActivity() async {
  var emailUrl = 'mailto:${Globals.email}';
  launchUrlString(emailUrl);
}

Future<void> hotLineActivity() async {
  var emailUrl = 'tel:${Globals.hotLineNumberWithCode}';
  launchUrlString(emailUrl);
}

Items item2 = new Items(
    title: "whatsapp".tr,
    subtitle: "",
    task: whatsappActvity,
    img: "images/whatsapp.png",
    time: 1.0);
Items item3 = new Items(
    title: "email".tr,
    task: emailActivity,
    subtitle: "",
    img: "images/ic_email_colored.png",
    time: 1.5);
Items item4 = new Items(
    title: "hotline".tr,
    task: hotLineActivity,
    subtitle: "",
    img: "images/hotline_support.png",
    time: 2.0);

class _LiveSupportState extends State<LiveSupport> {
  @override
  void initState() {
    super.initState();
    _fetchTraccarServerInfo();
  }

  /// Traccar REST API (/api/server) se support aur server context fetch karne ke liye
  Future<void> _fetchTraccarServerInfo() async {
    try {
      var response = await NetworkHelper().requestDataFromNetworkWithTimeout(
        urlFile: '/api/server',
        context: context,
      );

      if (response != null && response is Map<String, dynamic>) {
        if (response.containsKey('attributes')) {
          var attributes = response['attributes'];
          if (attributes != null && attributes is Map<String, dynamic>) {
            if (attributes.containsKey('supportPhone')) {
              Globals.hotLineNumberWithCode = attributes['supportPhone'].toString();
            }
            if (attributes.containsKey('supportEmail')) {
              Globals.email = attributes['supportEmail'].toString();
            }
            if (attributes.containsKey('whatsapp')) {
              Globals.mobileNumber = attributes['whatsapp'].toString();
            }
          }
        }
      }
    } catch (e) {
      // Backend error handling silently to keep UI stable
    }
  }

  void websiteChatBot() {
    Navigator.push(
        context,
        CupertinoPageRoute(
            builder: (context) => ActivityWebView(
                  url: Globals.websiteChatBot,
                  title: 'liveChat'.tr,
                )));
  }

  @override
  Widget build(BuildContext context) {
    List<Items> myList = [
      item2,
      item3,
      item4
    ];
    return Scaffold(
      backgroundColor: Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Globals.appColor,
        elevation: 0.0,
        title: Text(
          'liveSupport'.tr,
          style:
              TextStyle(color: Color(0xFFF6F6F6), fontFamily: 'Baloo_Thambi_2'),
        ),
        iconTheme: IconThemeData(
          color: Color(0xFFF6F6F6),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Flexible(
              child: GridView.count(
                  childAspectRatio: 1.25,
                  padding: EdgeInsets.only(left: 16, right: 16, bottom: 10),
                  crossAxisCount: 2,
                  crossAxisSpacing: 18,
                  controller: new ScrollController(keepScrollOffset: false),
                  shrinkWrap: true,
                  mainAxisSpacing: 10,
                  children: myList.map((data) {
                    return FadeAnimation(
                        data.time!,
                        InkWell(
                          onTap: data.task,
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            elevation: 5,
                            child: Container(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Image.asset(
                                    data.img!,
                                    width: 42,
                                  ),
                                  SizedBox(
                                    height: 15,
                                  ),
                                  Text(
                                    data.title!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Montserrat'),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Text(
                                      data.subtitle!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Color(0xFF7E8188),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Montserrat'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ));
                  }).toList()),
            ),
          ],
        ),
      ),
    );
  }
}

class Items {
  String? title;
  String? subtitle;
  String? event;
  String? img;
  double? time;
  Function()? task;

  Items(
      {this.title, this.subtitle, this.event, this.img, this.time, this.task});
}
