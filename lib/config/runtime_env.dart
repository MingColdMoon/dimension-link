import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_endpoints.dart';
import 'api_host.dart';
import 'app_config.dart';
import 'app_env.dart';

/// 运行时接口环境。仅非生产构建允许切换。
class RuntimeEnv extends ChangeNotifier {
  RuntimeEnv({AppConfig? compiled}) : compiled = compiled ?? AppConfig.current {
    env = this.compiled.env;
    apiBaseUrl = resolveApiBaseUrl(this.compiled.apiBaseUrl);
  }

  static const prefsKey = 'dimension_link_runtime_env';

  final AppConfig compiled;

  late AppEnv env;
  late String apiBaseUrl;

  /// 生产包不允许切换接口环境。
  bool get canSwitch => !compiled.isProduction;

  ApiEndpoint get currentEndpoint => ApiEndpoints.of(env);

  Future<void> restore() async {
    if (!canSwitch) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(prefsKey);
    if (saved == null || saved.isEmpty) {
      return;
    }
    try {
      await select(AppEnv.parse(saved), persist: false);
    } catch (_) {
      // 忽略损坏的本地覆盖。
    }
  }

  Future<void> select(AppEnv next, {bool persist = true}) async {
    if (!canSwitch) {
      return;
    }
    env = next;
    apiBaseUrl = resolveApiBaseUrl(ApiEndpoints.baseUrlOf(next));
    if (persist) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKey, next.name);
    }
    notifyListeners();
  }
}
