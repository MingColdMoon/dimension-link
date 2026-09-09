import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'network/api_client.dart';
import 'network/network_inspector.dart';
import 'network/network_log.dart';
import 'screens/splash_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.current;
  if (config.apiBaseUrl.isEmpty) {
    throw StateError('API_BASE_URL 不能为空');
  }
  config.logSummary();
  final logs = NetworkLogStore();
  final api = ApiClient(logStore: logs);
  runApp(DimensionLinkApp(api: api, logs: logs));
}

class DimensionLinkApp extends StatelessWidget {
  const DimensionLinkApp({super.key, this.api, this.logs});

  final ApiClient? api;
  final NetworkLogStore? logs;

  @override
  Widget build(BuildContext context) {
    final config = AppConfig.current;
    return ChangeNotifierProvider(
      create: (_) => AppState(api: api),
      child: MaterialApp(
        title: '次元链接',
        navigatorKey: appNavigatorKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        builder: (context, child) {
          var content = child ?? const SizedBox.shrink();
          if (config.showNetworkInspector && logs != null) {
            content = NetworkInspectorOverlay(
              store: logs!,
              navigatorKey: appNavigatorKey,
              child: content,
            );
          }
          if (config.isProduction) {
            return content;
          }
          return Banner(
            message: config.env.bannerLabel,
            location: BannerLocation.topEnd,
            color: config.env.bannerColor,
            child: content,
          );
        },
        home: const SplashScreen(),
      ),
    );
  }
}
