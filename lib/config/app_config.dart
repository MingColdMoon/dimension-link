import 'package:flutter/foundation.dart';

import 'app_env.dart';

/// 编译期注入的应用配置，对应 `--dart-define` / `--dart-define-from-file`。
///
/// 未传任何 define 时，默认与 `env/development.env` 保持一致（开发环境）。
class AppConfig {
  const AppConfig({
    required this.env,
    required this.apiBaseUrl,
    required this.enableLogging,
  });

  /// 当前运行环境。
  final AppEnv env;

  /// API 基地地址（Base URL），例如 `http://127.0.0.1:8080/v1`。
  final String apiBaseUrl;

  /// 是否输出调试日志。生产环境应为 false。
  final bool enableLogging;

  static const String _envName = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );
  static const String _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8080/v1',
  );
  static const bool _enableLogging = bool.fromEnvironment(
    'ENABLE_LOGGING',
    defaultValue: true,
  );

  /// 当前构建注入的配置。
  static final AppConfig current = AppConfig(
    env: AppEnv.parse(_envName),
    apiBaseUrl: _apiBaseUrl,
    enableLogging: _enableLogging,
  );

  bool get isProduction => env.isProd;

  /// 非生产环境打包也可打开应用内网络调试面板。
  bool get showNetworkInspector => !isProduction;

  /// 打印当前环境摘要；[enableLogging] 为 false 时不输出。
  void logSummary() {
    if (!enableLogging) {
      return;
    }
    debugPrint(
      '[DimensionLink] 环境=${env.label}(${env.name}) apiBaseUrl=$apiBaseUrl',
    );
  }
}
