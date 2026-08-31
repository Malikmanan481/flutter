import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../globals.dart';

class ReportViewActivity extends StatefulWidget {
  final String? htmlDocument;
  final String? apiUrl; // Traccar API Endpoint URL (e.g., https://demo.traccar.org/api/reports/route)
  final Map<String, String>? headers; // Traccar Auth Headers / Cookie

  const ReportViewActivity({
    Key? key,
    this.htmlDocument,
    this.apiUrl,
    this.headers,
  }) : super(key: key);

  @override
  State<ReportViewActivity> createState() => _ReportViewActivityState();
}

class _ReportViewActivityState extends State<ReportViewActivity> {
  bool isLoading = true;
  InAppWebViewController? webViewController;
  final GlobalKey webViewKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Globals.appColor,
        elevation: 0.0,
        title: Text(
          'reports'.tr,
          style: const TextStyle(
            color: Color(0xFFF6F6F6),
            fontFamily: 'Baloo_Thambi_2',
          ),
        ),
        iconTheme: const IconThemeData(
          color: Color(0xFFF6F6F6),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: Stack(
          children: <Widget>[
            InAppWebView(
              key: webViewKey,
              initialSettings: InAppWebViewSettings(
                transparentBackground: true,
                safeBrowsingEnabled: true,
                supportZoom: true,
                isFraudulentWebsiteWarningEnabled: true,
              ),
              onWebViewCreated: (controller) async {
                webViewController = controller;
                
                // If API URL is provided, load directly from Traccar Backend
                if (widget.apiUrl != null && widget.apiUrl!.isNotEmpty) {
                  final headers = widget.headers ?? {};
                  headers.putIfAbsent('Accept', () => 'text/html');

                  await webViewController!.loadUrl(
                    urlRequest: URLRequest(
                      url: WebUri(widget.apiUrl!),
                      headers: headers,
                    ),
                  );
                } 
                // Otherwise load provided raw HTML String
                else if (widget.htmlDocument != null && widget.htmlDocument!.isNotEmpty) {
                  await webViewController!.loadData(
                    data: widget.htmlDocument!,
                    mimeType: "text/html",
                    encoding: "utf-8",
                  );
                }
              },
              onLoadStart: (controller, url) {
                setState(() {
                  isLoading = true;
                });
              },
              onLoadStop: (controller, url) async {
                setState(() {
                  isLoading = false;
                });
              },
              onProgressChanged: (controller, progress) {
                if (progress == 100) {
                  setState(() {
                    isLoading = false;
                  });
                }
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                final url = navigationAction.request.url;
                if (navigationAction.isForMainFrame &&
                    url != null &&
                    ![
                      'http',
                      'https',
                      'file',
                      'chrome',
                      'data',
                      'javascript',
                      'about'
                    ].contains(url.scheme)) {
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                    return NavigationActionPolicy.CANCEL;
                  }
                }
                return NavigationActionPolicy.ALLOW;
              },
            ),
            
            // Loading Overlay
            if (isLoading)
              Center(
                child: CircularProgressIndicator(
                  backgroundColor: const Color(0xFFF6F6F6),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Globals.appColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
