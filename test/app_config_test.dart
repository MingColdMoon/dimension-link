import 'dart:io';

import 'package:dimension_link/config/api_endpoints.dart';
import 'package:dimension_link/config/api_host.dart';
import 'package:dimension_link/config/app_config.dart';
import 'package:dimension_link/config/app_env.dart';
import 'package:dimension_link/config/runtime_env.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 解析 `KEY=VALUE` 环境文件（忽略空行与 `#` 注释）。
Map<String, String> loadEnvFile(String path) {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: '缺少环境配置文件: $path');
  final map = <String, String>{};
  for (final raw in file.readAsLinesSync()) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) {
      continue;
    }
    final index = line.indexOf('=');
    expect(index, greaterThan(0), reason: '$path 含有非法行: $raw');
    final key = line.substring(0, index).trim();
    final value = line.substring(index + 1).trim();
    map[key] = value;
  }
  return map;
}

void expectRequiredKeys(Map<String, String> env, String path) {
  const keys = ['APP_ENV', 'API_BASE_URL', 'ENABLE_LOGGING'];
  for (final key in keys) {
    expect(env.containsKey(key), isTrue, reason: '$path 缺少 $key');
    expect(env[key], isNotEmpty, reason: '$path 的 $key 不能为空');
  }
  expect(
    env['ENABLE_LOGGING'] == 'true' || env['ENABLE_LOGGING'] == 'false',
    isTrue,
    reason: '$path 的 ENABLE_LOGGING 必须是 true 或 false',
  );
}

void main() {
  late Map<String, String> development;
  late Map<String, String> staging;
  late Map<String, String> production;

  setUpAll(() {
    development = loadEnvFile('env/development.env');
    staging = loadEnvFile('env/staging.env');
    production = loadEnvFile('env/production.env');
  });

  test('三套环境文件都包含必需变量', () {
    expectRequiredKeys(development, 'env/development.env');
    expectRequiredKeys(staging, 'env/staging.env');
    expectRequiredKeys(production, 'env/production.env');
  });

  test('开发 / 测试 / 生产环境互相隔离', () {
    expect(AppEnv.parse(development['APP_ENV']!), AppEnv.dev);
    expect(AppEnv.parse(staging['APP_ENV']!), AppEnv.staging);
    expect(AppEnv.parse(production['APP_ENV']!), AppEnv.prod);
    expect(development['APP_ENV'], isNot(staging['APP_ENV']));
    expect(production['API_BASE_URL'], isNot(development['API_BASE_URL']));

    expect(development['ENABLE_LOGGING'], 'true');
    expect(staging['ENABLE_LOGGING'], 'true');
    expect(production['ENABLE_LOGGING'], 'false');
  });

  test('AppConfig 与当前编译注入的环境文件一致', () {
    const envName = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
    final expected = switch (AppEnv.parse(envName)) {
      AppEnv.dev => development,
      AppEnv.staging => staging,
      AppEnv.prod => production,
    };

    expect(AppConfig.current.env, AppEnv.parse(envName));
    expect(AppConfig.current.apiBaseUrl, expected['API_BASE_URL']);
    expect(
      AppConfig.current.enableLogging,
      expected['ENABLE_LOGGING'] == 'true',
    );
    expect(AppConfig.current.isProduction, AppConfig.current.env.isProd);
  });

  test('可切换接口地址与 env 文件一致', () {
    expect(ApiEndpoints.development.baseUrl, development['API_BASE_URL']);
    expect(ApiEndpoints.staging.baseUrl, staging['API_BASE_URL']);
    expect(ApiEndpoints.production.baseUrl, production['API_BASE_URL']);
    expect(resolveApiBaseUrl(development['API_BASE_URL']!), development['API_BASE_URL']);
    expect(resolveApiBaseUrl(staging['API_BASE_URL']!), staging['API_BASE_URL']);
  });

  test('运行时环境仅非生产可切换，并写入本地覆盖', () async {
    SharedPreferences.setMockInitialValues({});
    final runtime = RuntimeEnv(
      compiled: AppConfig(
        env: AppEnv.dev,
        apiBaseUrl: development['API_BASE_URL']!,
        enableLogging: true,
      ),
    );
    expect(runtime.canSwitch, isTrue);
    await runtime.select(AppEnv.prod);
    expect(runtime.env, AppEnv.prod);
    expect(runtime.apiBaseUrl, production['API_BASE_URL']);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(RuntimeEnv.prefsKey), 'prod');

    final restored = RuntimeEnv(
      compiled: AppConfig(
        env: AppEnv.dev,
        apiBaseUrl: development['API_BASE_URL']!,
        enableLogging: true,
      ),
    );
    await restored.restore();
    expect(restored.env, AppEnv.prod);
    expect(restored.apiBaseUrl, production['API_BASE_URL']);

    final locked = RuntimeEnv(
      compiled: AppConfig(
        env: AppEnv.prod,
        apiBaseUrl: production['API_BASE_URL']!,
        enableLogging: false,
      ),
    );
    expect(locked.canSwitch, isFalse);
    await locked.select(AppEnv.dev);
    expect(locked.env, AppEnv.prod);
  });

  test('APP_ENV 别名可以正确解析', () {
    expect(AppEnv.parse('development'), AppEnv.dev);
    expect(AppEnv.parse('DEV'), AppEnv.dev);
    expect(AppEnv.parse('test'), AppEnv.staging);
    expect(AppEnv.parse('qa'), AppEnv.staging);
    expect(AppEnv.parse('production'), AppEnv.prod);
    expect(AppEnv.parse('PROD'), AppEnv.prod);
  });

  test('未知 APP_ENV 会抛出错误', () {
    expect(() => AppEnv.parse('local'), throwsArgumentError);
    expect(() => AppEnv.parse(''), throwsArgumentError);
  });

  test('打包脚本为三套环境注入 dart-define-from-file', () {
    final script = File('scripts/package.ps1').readAsStringSync();
    expect(script, contains('--dart-define-from-file='));
    expect(script, contains('env/development.env'));
    expect(script, contains('env/staging.env'));
    expect(script, contains('env/production.env'));
    expect(script, contains(r'dimension-link-$version-$($appEnv.Key).apk'));
    for (final target in ['apk', 'appbundle', 'windows', 'web']) {
      expect(script, contains("'$target'"));
    }
  });

  test('VS Code 打包任务覆盖三套 APK 环境', () {
    final tasks = File('.vscode/tasks.json').readAsStringSync();
    expect(tasks, contains('scripts/package.ps1'));
    expect(tasks, contains('-Env dev -Target apk'));
    expect(tasks, contains('-Env staging -Target apk'));
    expect(tasks, contains('-Env prod -Target apk'));
  });
}
