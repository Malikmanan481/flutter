import 'package:get/get.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:speedotrack/activity/activity_about_us.dart';

import '../globals.dart';

class ImageZoomActivity extends StatefulWidget {
  final String? url;

  const ImageZoomActivity({Key? key, this.url}) : super(key: key);

  @override
  _ImageZoomActivityState createState() => _ImageZoomActivityState();
}

class _ImageZoomActivityState extends State<ImageZoomActivity> {
  String _getFormattedUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return '';
    // Agar relative Traccar path ho toh Globals.baseUrl append kar do
    if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      return rawUrl;
    }
    String baseUrl = Globals.baseUrl.endsWith('/')
        ? Globals.baseUrl.substring(0, Globals.baseUrl.length - 1)
        : Globals.baseUrl;
    String path = rawUrl.startsWith('/') ? rawUrl : '/$rawUrl';
    return '$baseUrl$path';
  }

  @override
  Widget build(BuildContext context) {
    final String fullImageUrl = _getFormattedUrl(widget.url);

    return Scaffold(
      backgroundColor: Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Globals.appColor,
        elevation: 0.0,
        title: Text(
          'viewImage'.tr,
          style:
              TextStyle(color: Color(0xFFF6F6F6), fontFamily: 'Baloo_Thambi_2'),
        ),
        iconTheme: IconThemeData(
          color: Color(0xFFF6F6F6), //change your color here
        ),
      ),
      body: Container(
        child: fullImageUrl.isNotEmpty
            ? ExtendedImage.network(
                fullImageUrl,
                height: double.infinity,
                width: double.infinity,
                mode: ExtendedImageMode.gesture,
                initGestureConfigHandler: (state) {
                  return GestureConfig(
                    minScale: 0.9,
                    animationMinScale: 0.7,
                    maxScale: 3.0,
                    animationMaxScale: 3.5,
                    speed: 1.0,
                    inertialSpeed: 100.0,
                    initialScale: 1.0,
                    inPageView: false,
                    initialAlignment: InitialAlignment.center,
                  );
                },
                loadStateChanged: (ExtendedImageState state) {
                  switch (state.extendedImageLoadState) {
                    case LoadState.loading:
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Globals.appColor,
                          ),
                        ),
                      );
                    case LoadState.failed:
                      return Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 60,
                          color: Colors.grey,
                        ),
                      );
                    case LoadState.completed:
                      return null;
                  }
                },
              )
            : Center(
                child: Icon(
                  Icons.image_not_supported,
                  size: 60,
                  color: Colors.grey,
                ),
              ),
      ),
    );
  }
}
