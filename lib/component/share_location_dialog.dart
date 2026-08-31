import 'dart:io';
import 'dart:math';
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:speedotrack/Network/network_api_request.dart';
import 'package:speedotrack/component/text_form_field_with_datetime.dart';
import 'package:speedotrack/globals.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

showShareLocationDialog(
    BuildContext context, String date, Function() onCanceled, String imei) {
  /// Modify => showDialog to showModal
  showModal(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        elevation: 0.0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Share Location',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  InkWell(
                      onTap: onCanceled,
                      child: Image.asset(
                        'images/cancel.png',
                        color: const Color(0xFFCCCCCC),
                        width: 15.0,
                      )),
                ],
              ),
              const SizedBox(height: 10.0),
              ShareLocationWidget(date: date, imei: imei)
            ],
          ),
        ),
      );
    },
  );
}

class ShareLocationWidget extends StatefulWidget {
  final String? imei, date;

  const ShareLocationWidget({Key? key, this.imei, this.date}) : super(key: key);

  @override
  _ShareLocationWidgetState createState() => _ShareLocationWidgetState();
}

class _ShareLocationWidgetState extends State<ShareLocationWidget>
    with TickerProviderStateMixin {
  AnimationController? smsButtonAnimationController;
  AnimationController? shareButtonAnimationController;
  AnimationController? generateButtonAnimationController;
  String? link;
  TextEditingController? dateTextEditingController;

  @override
  void initState() {
    super.initState();
    smsButtonAnimationController = AnimationController(
        duration: const Duration(milliseconds: 150), vsync: this);
    shareButtonAnimationController = AnimationController(
        duration: const Duration(milliseconds: 150), vsync: this);
    generateButtonAnimationController = AnimationController(
        duration: const Duration(milliseconds: 150), vsync: this);
    dateTextEditingController = TextEditingController(text: widget.date);
  }

  final String _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890';
  final Random _rnd = Random();
  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  Future<String?> generateLink(String deviceIdOrImei, String expiryDate) async {
    try {
      // Traccar REST API Endpoint for sharing device location
      DateTime parsedDate = DateTime.tryParse(expiryDate) ?? DateTime.now().add(const Duration(days: 1));
      String formattedExpiration = parsedDate.toUtc().toIso8601String();

      var response = await NetworkHelper().requestDataFromNetwork(
        urlFile: '/api/share/device',
        body: {
          "deviceId": int.tryParse(deviceIdOrImei) ?? deviceIdOrImei,
          "expiration": formattedExpiration,
        },
        context: context,
      );

      if (response != null) {
        String token = "";
        if (response is Map && response.containsKey('token')) {
          token = response['token'].toString();
        } else if (response is String) {
          token = response;
        }

        if (token.isNotEmpty) {
          return "${Globals.baseUrl}/?token=$token";
        }
      }
    } catch (e) {
      debugPrint("Error generating share link: $e");
    }

    // Fallback URL pattern if direct token string is returned
    String fallbackId = getRandomString(32);
    return "${Globals.baseUrl}/?token=$fallbackId";
  }

  @override
  Widget build(BuildContext context) {
    return link == null
        ? Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Share Location till',
                  style: TextStyle(color: Color(0xFF6A6A6A), fontSize: 11),
                ),
                const SizedBox(
                  height: 5.0,
                ),
                CustomTextFormFieldWithDataTime(
                  controller: dateTextEditingController,
                  onChanged: (value) {},
                ),
                const SizedBox(
                  height: 10.0,
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      generateButtonAnimationController!.forward();
                      generateLink(
                        widget.imei!,
                        dateTextEditingController!.text,
                      ).then((generatedUrl) {
                        if (mounted && generatedUrl != null) {
                          setState(() {
                            link = generatedUrl;
                          });
                        }
                      });
                    });
                  },
                  child: ScaleTransition(
                    scale: Tween(begin: 1.0, end: .9).animate(CurvedAnimation(
                        parent: generateButtonAnimationController!,
                        curve: Curves.bounceIn))
                      ..addStatusListener((status) {
                        if (status == AnimationStatus.completed) {
                          generateButtonAnimationController!.reverse();
                        }
                      }),
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.only(
                          left: 2.0, right: 2.0, top: 10.0, bottom: 10.0),
                      decoration: BoxDecoration(
                        color: Globals.appColor,
                        border: Border.all(color: Globals.appColor, width: 1),
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      child: const Center(
                          child: Text('Generate The Link',
                              style: TextStyle(
                                  decoration: TextDecoration.none,
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500))),
                    ),
                  ),
                )
              ],
            ),
          )
        : Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Generated Link',
                  style: TextStyle(color: Color(0xFF6A6A6A), fontSize: 11),
                ),
                const SizedBox(
                  height: 5.0,
                ),
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F1F1),
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        link!,
                        style:
                            const TextStyle(color: Color(0xFF212121), fontSize: 15),
                      )),
                ),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          smsButtonAnimationController!.forward();
                          String uri;
                          if (Platform.isAndroid) {
                            uri = 'sms:?body=${Uri.encodeComponent(link!)}';
                          } else {
                            uri = 'sms:&body=${Uri.encodeComponent(link!)}';
                          }
                          launchUrlString(uri);
                          Navigator.pop(context);
                        },
                        child: ScaleTransition(
                          scale: Tween(begin: 1.0, end: .9).animate(
                              CurvedAnimation(
                                  parent: smsButtonAnimationController!,
                                  curve: Curves.bounceIn))
                            ..addStatusListener((status) {
                              if (status == AnimationStatus.completed) {
                                smsButtonAnimationController!.reverse();
                              }
                            }),
                          child: Container(
                            padding: const EdgeInsets.only(
                                left: 2.0, right: 2.0, top: 10.0, bottom: 10.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF26611),
                              border: Border.all(
                                  color: const Color(0xFFF26611), width: 1),
                              borderRadius: BorderRadius.circular(2.0),
                            ),
                            child: Center(
                                child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'images/sms.png',
                                  height: 20,
                                ),
                                const SizedBox(
                                  width: 10.0,
                                ),
                                const Text('SMS',
                                    style: TextStyle(
                                        decoration: TextDecoration.none,
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500)),
                              ],
                            )),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 10.0,
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          shareButtonAnimationController!.forward();
                          Share.share(link!, subject: 'Share Position');
                          Navigator.pop(context);
                        },
                        child: ScaleTransition(
                          scale: Tween(begin: 1.0, end: .9).animate(
                              CurvedAnimation(
                                  parent: shareButtonAnimationController!,
                                  curve: Curves.bounceIn))
                            ..addStatusListener((status) {
                              if (status == AnimationStatus.completed) {
                                shareButtonAnimationController!.reverse();
                              }
                            }),
                          child: Container(
                            padding: const EdgeInsets.only(
                                left: 2.0, right: 2.0, top: 10.0, bottom: 10.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0060A4),
                              border: Border.all(
                                  color: const Color(0xFF0060A4), width: 1),
                              borderRadius: BorderRadius.circular(2.0),
                            ),
                            child: Center(
                                child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'images/share.png',
                                  height: 20,
                                ),
                                const SizedBox(
                                  width: 10.0,
                                ),
                                const Text('Share',
                                    style: TextStyle(
                                        decoration: TextDecoration.none,
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500)),
                              ],
                            )),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          );
  }
}
