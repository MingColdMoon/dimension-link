import 'api_host.dart';
import 'app_env.dart';

/// 可切换的接口环境。URL 与 `env/*.env` 保持一致。
class ApiEndpoint {
  const ApiEndpoint({
    required this.env,
    required this.baseUrl,
    required this.label,
  });

  final AppEnv env;
  final String baseUrl;
  final String label;
}

class ApiEndpoints {
  ApiEndpoints._();

  static const development = ApiEndpoint(
    env: AppEnv.dev,
    baseUrl: 'http://127.0.0.1:8080/v1',
    label: '开发环境',
  );

  static const staging = ApiEndpoint(
    env: AppEnv.staging,
    baseUrl: 'http://123.56.169.7/v1',
    label: '测试环境',
  );

  static const production = ApiEndpoint(
    env: AppEnv.prod,
    baseUrl: 'https://api.dimension-link.dev/v1',
    label: '生产环境',
  );

  static const List<ApiEndpoint> all = [development, staging, production];

  static ApiEndpoint of(AppEnv env) {
    return switch (env) {
      AppEnv.dev => development,
      AppEnv.staging => staging,
      AppEnv.prod => production,
    };
  }

  static String baseUrlOf(AppEnv env) => of(env).baseUrl;

  /// 当前平台实际请求的地址（Android 模拟器会把回环改成 10.0.2.2）。
  static String resolvedBaseUrlOf(AppEnv env) => resolveApiBaseUrl(baseUrlOf(env));
}
