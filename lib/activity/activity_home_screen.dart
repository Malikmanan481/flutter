import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:speedotrack/component/component_home_screen.dart';
import 'package:speedotrack/component/component_menu_page.dart';
import 'package:speedotrack/controller/controller_menu_home_screen.dart';
import 'package:speedotrack/network/network_api_request.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  MenuControllerHome? menuController;
  TickerProvider? vsync;

  @override
  void initState() {
    menuController = new MenuControllerHome(
      vsync: this,
    )..addListener(() => setState(() {}));
    super.initState();
    setState(() {});
    
    // Traccar Backend Initialization
    _initTraccarBackend();
  }

  /// Initializing Traccar session and fetching device list on Home Screen load
  Future<void> _initTraccarBackend() async {
    try {
      // 1. Verify Active Session with Traccar
      var sessionResponse = await NetworkHelper().requestDataFromNetworkWithTimeout(
        urlFile: '/api/session',
        context: context,
      );

      // 2. Fetch Devices List from Traccar API
      if (sessionResponse != null) {
        await NetworkHelper().requestDataFromNetworkWithTimeout(
          urlFile: '/api/devices',
          context: context,
        );
      }
    } catch (e) {
      // Backend errors handled silently to prevent UI disruption
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProviderType>(
      create: (context) => ProviderType(),
      child: ChangeNotifierProvider.value(
        value: menuController!,
        child: HomeScreenContainer(
          menuScreen: MenuScreen(),
        ),
      ),
    );
  }
}
