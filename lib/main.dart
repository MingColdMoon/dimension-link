import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'config/env_switcher.dart';
import 'config/runtime_env.dart';
import 'network/api_client.dart';
import 'network/network_inspector.dart';
import 'network/network_log.dart';
import 'screens/splash_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.current;
  if (config.apiBaseUrl.isEmpty) {
    throw StateError('API_BASE_URL 不能为空');
  }
  final runtime = RuntimeEnv();
  await runtime.restore();
  config.logSummary();
  debugPrint('[DimensionLink] 运行时环境=${runtime.env.label} api=${runtime.apiBaseUrl}');
  final logs = NetworkLogStore();
  final api = ApiClient(logStore: logs, baseUrl: runtime.apiBaseUrl);
  runApp(DimensionLinkApp(api: api, logs: logs, runtimeEnv: runtime));
}

class DimensionLinkApp extends StatelessWidget {
  const DimensionLinkApp({super.key, this.api, this.logs, this.runtimeEnv});

  final ApiClient? api;
  final NetworkLogStore? logs;
  final RuntimeEnv? runtimeEnv;

  @override
  Widget build(BuildContext context) {
    final config = AppConfig.current;
    return MultiProvider(
      providers: [
        if (runtimeEnv != null) ChangeNotifierProvider<RuntimeEnv>.value(value: runtimeEnv!),
        if (api != null) Provider<ApiClient>.value(value: api!),
        ChangeNotifierProvider(create: (_) => AppState(api: api)),
      ],
      child: MaterialApp(
        title: '次元链接',
        navigatorKey: appNavigatorKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        builder: (context, child) {
          final page = child ?? const SizedBox.shrink();
          if (runtimeEnv == null) {
            if (config.isProduction) {
              return page;
            }
            return Banner(
              message: config.env.bannerLabel,
              location: BannerLocation.topEnd,
              color: config.env.bannerColor,
              child: page,
            );
          }
          return _RuntimeChrome(
            logs: logs,
            child: page,
          );
        },
        home: const SplashScreen(),
      ),
    );
  }
}

/// 监听运行时环境，刷新角标、环境按钮与网络面板。
class _RuntimeChrome extends StatelessWidget {
  const _RuntimeChrome({required this.child, this.logs});

  final Widget child;
  final NetworkLogStore? logs;

  @override
  Widget build(BuildContext context) {
    final config = AppConfig.current;
    final runtime = context.watch<RuntimeEnv>();
    var content = child;
    if (config.showNetworkInspector && logs != null) {
      content = NetworkInspectorOverlay(
        store: logs!,
        navigatorKey: appNavigatorKey,
        leadingTool: runtime.canSwitch
            ? EnvSwitcherFab(navigatorKey: appNavigatorKey)
            : null,
        child: content,
      );
    }
    if (config.isProduction) {
      return content;
    }
    return Banner(
      key: ValueKey('env-banner-${runtime.env.name}'),
      message: runtime.env.bannerLabel,
      location: BannerLocation.topEnd,
      color: runtime.env.bannerColor,
      child: content,
    );
  }
}
