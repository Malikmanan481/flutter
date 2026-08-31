import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class HomeScreenMenuController extends StatefulWidget {
  final ZoomScaffoldBuilder? builder;

  HomeScreenMenuController({
    this.builder,
  });

  @override
  HomeScreenMenuControllerState createState() {
    return new HomeScreenMenuControllerState();
  }
}

class HomeScreenMenuControllerState extends State<HomeScreenMenuController> {
  @override
  Widget build(BuildContext context) {
    return widget.builder!(
        context, Provider.of<MenuControllerHome>(context, listen: true));
  }
}

typedef Widget ZoomScaffoldBuilder(
    BuildContext context, MenuControllerHome menuController);

class Layout {
  final WidgetBuilder? contentBuilder;

  Layout({
    this.contentBuilder,
  });
}

class MenuControllerHome extends ChangeNotifier {
  final TickerProvider? vsync;
  final AnimationController? _animationController;
  MenuState state = MenuState.closed;

  // Traccar Session & User Profile State
  Map<String, dynamic>? traccarUser;
  bool isLoadingSession = false;

  MenuControllerHome({
    this.vsync,
  }) : _animationController = new AnimationController(vsync: vsync!) {
    _animationController!
      ..duration = const Duration(milliseconds: 250)
      ..addListener(() {
        notifyListeners();
      })
      ..addStatusListener((AnimationStatus status) {
        switch (status) {
          case AnimationStatus.forward:
            state = MenuState.opening;
            break;
          case AnimationStatus.reverse:
            state = MenuState.closing;
            break;
          case AnimationStatus.completed:
            state = MenuState.open;
            break;
          case AnimationStatus.dismissed:
            state = MenuState.closed;
            break;
        }
        notifyListeners();
      });
  }

  @override
  dispose() {
    _animationController!.dispose();
    super.dispose();
  }

  get percentOpen {
    return _animationController!.value;
  }

  open() {
    _animationController!.forward();
  }

  close() {
    _animationController!.reverse();
  }

  MenuState isOpened() {
    return state;
  }

  toggle() {
    if (state == MenuState.open) {
      close();
    } else if (state == MenuState.closed) {
      open();
    }
  }

  // ==========================================
  // TRACCAR API BACKEND SESSION INTEGRATION
  // ==========================================

  /// Fetch active session user info directly from Traccar (`/api/session`)
  Future<Map<String, dynamic>?> fetchTraccarUserSession({
    required String baseUrl,
    Map<String, String>? headers,
  }) async {
    try {
      isLoadingSession = true;
      notifyListeners();

      final String cleanUrl =
          baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

      final response = await http.get(
        Uri.parse('$cleanUrl/api/session'),
        headers: headers ?? {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        traccarUser = jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        traccarUser = null;
      }
    } catch (_) {
      traccarUser = null;
    } finally {
      isLoadingSession = false;
      notifyListeners();
    }
    return traccarUser;
  }

  /// Revoke current session on Traccar backend (`DELETE /api/session`)
  Future<bool> logoutTraccarSession({
    required String baseUrl,
    Map<String, String>? headers,
  }) async {
    try {
      final String cleanUrl =
          baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

      final response = await http.delete(
        Uri.parse('$cleanUrl/api/session'),
        headers: headers ?? {'Accept': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        traccarUser = null;
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }
}

enum MenuState {
  closed,
  opening,
  open,
  closing,
}
