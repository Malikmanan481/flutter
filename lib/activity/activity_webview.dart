import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speedotrack/globals.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ActivityWebView extends StatefulWidget {
  final String? url;
  final String? title;

  const ActivityWebView({Key? key, this.url, this.title}) : super(key: key);

  @override
  _ActivityWebViewState createState() => _ActivityWebViewState(url, title);
}

class _ActivityWebViewState extends State<ActivityWebView> {
  final String? url;
  final String? title;
  late final WebViewController _webViewController;
  bool isLoading = true;

  _ActivityWebViewState(this.url, this.title);

  @override
  void initState() {
    super.initState();
    _initTraccarWebView();
  }

  // ==================== TRACCAR API & WEBVIEW INTEGRATION ====================
  void _initTraccarWebView() {
    String targetUrl = url ?? '';

    // Automatically resolve relative Traccar API endpoints
    if (targetUrl.isNotEmpty && !targetUrl.startsWith('http')) {
      String baseUrl = Globals.baseUrl ?? '';
      if (baseUrl.isNotEmpty) {
        if (!baseUrl.endsWith('/') && !targetUrl.startsWith('/')) {
          baseUrl += '/';
        }
        targetUrl = '$baseUrl$targetUrl';
      }
    }

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String pageUrl) {
            if (mounted) {
              setState(() {
                isLoading = true;
              });
            }
          },
          onPageFinished: (String pageUrl) {
            if (mounted) {
              setState(() {
                isLoading = false;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    if (targetUrl.isNotEmpty) {
      _webViewController.loadRequest(Uri.parse(targetUrl));
    } else {
      setState(() {
        isLoading = false;
      });
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
            (title ?? '').toUpperCase(),
            style: TextStyle(
                color: Color(0xFFF6F6F6), fontFamily: 'Baloo_Thambi_2'),
          ),
          iconTheme: IconThemeData(
            color: Color(0xFFF6F6F6), //change your color here
          ),
        ),
        body: Stack(
          children: <Widget>[
            if (url != null && url!.isNotEmpty)
              WebViewWidget(controller: _webViewController),
            Visibility(
              visible: isLoading,
              child: Center(
                child: CircularProgressIndicator(
                    backgroundColor: Color(0xFFF6F6F6),
                    valueColor: new AlwaysStoppedAnimation<Color>(
                      Globals.appColor,
                    )),
              ),
            ),
          ],
        ));
  }
}
