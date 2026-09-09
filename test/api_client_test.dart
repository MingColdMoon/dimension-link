import 'dart:convert';
import 'dart:typed_data';

import 'package:dimension_link/config/app_config.dart';
import 'package:dimension_link/network/api_client.dart';
import 'package:dimension_link/network/network_inspector.dart';
import 'package:dimension_link/network/network_log.dart';
import 'package:dimension_link/state/app_state.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this._handler);

  final ResponseBody Function(RequestOptions options) _handler;

  RequestOptions? lastOptions;
  String? lastBody;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    if (requestStream != null) {
      final chunks = await requestStream.toList();
      lastBody = utf8.decode(chunks.expand((c) => c).toList());
    }
    return _handler(options);
  }
}

ResponseBody jsonBody(int status, Map<String, dynamic> data) {
  return ResponseBody.fromString(
    jsonEncode(data),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('敏感字段会在调试面板中打码', () {
    const raw =
        '{"nickname":"铃","password":"123456","accessToken":"aaa","refreshToken":"bbb"}';
    final redacted = redactSensitiveJson(raw);
    expect(redacted, contains('"password":"***"'));
    expect(redacted, contains('"accessToken":"***"'));
    expect(redacted, isNot(contains('123456')));
  });

  test('注册会 POST /auth/register 并写入会话', () async {
    final adapter = _ScriptedAdapter((options) {
      if (options.method == 'GET') {
        return jsonBody(200, {
          'code': 0,
          'message': 'ok',
          'data': {'items': []},
        });
      }
      expect(options.method, 'POST');
      expect(options.path, '/auth/register');
      return jsonBody(200, {
        'code': 0,
        'message': 'ok',
        'data': {
          'accessToken': 'tok_a',
          'refreshToken': 'tok_r',
          'expiresIn': 7200,
          'user': {
            'id': 'u_new',
            'nickname': '测试酱',
            'handle': 'testchan',
            'bio': '新住民',
            'signature': '你好',
            'emoji': '✨',
            'accentIndex': 1,
            'followers': 0,
            'following': 0,
            'level': 1,
            'badges': ['初入次元'],
          },
        },
      });
    });
    final logs = NetworkLogStore();
    final dio = Dio(
      BaseOptions(baseUrl: AppConfig.current.apiBaseUrl),
    )..httpClientAdapter = adapter;
    final api = ApiClient(dio: dio, logStore: logs);
    final state = AppState(api: api);

    final err = await state.register(
      nickname: '测试酱',
      handle: 'testchan',
      password: '123456',
    );

    expect(err, isNull);
    expect(state.isLoggedIn, isTrue);
    expect(state.me.nickname, '测试酱');
    expect(state.me.handle, '@testchan');
    expect(adapter.lastBody, contains('"nickname":"测试酱"'));
    expect(
      logs.entries.any((e) => e.uri.path.endsWith('/auth/register') && e.isSuccess),
      isTrue,
    );
  });

  test('注册失败时展示后端中文 message，并留下日志', () async {
    final adapter = _ScriptedAdapter((options) {
      return jsonBody(409, {
        'code': 1005,
        'message': '这个 @ 已经被占用啦',
        'data': null,
      });
    });
    final logs = NetworkLogStore();
    final dio = Dio(
      BaseOptions(baseUrl: AppConfig.current.apiBaseUrl),
    )..httpClientAdapter = adapter;
    final api = ApiClient(dio: dio, logStore: logs);
    final state = AppState(api: api);

    final err = await state.register(
      nickname: '测试酱',
      handle: 'taken',
      password: '123456',
    );

    expect(err, '这个 @ 已经被占用啦');
    expect(state.isLoggedIn, isFalse);
    expect(logs.entries, isNotEmpty);
  });

  testWidgets('非生产环境展示网络调试入口并可打开面板', (tester) async {
    if (AppConfig.current.isProduction) {
      return;
    }
    final logs = NetworkLogStore();
    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navKey,
        home: NetworkInspectorOverlay(
          store: logs,
          navigatorKey: navKey,
          child: const Scaffold(body: Text('首页')),
        ),
      ),
    );
    expect(find.byKey(const Key('network-inspector-fab')), findsOneWidget);

    await tester.tap(find.byKey(const Key('network-inspector-fab')));
    await tester.pumpAndSettle();

    expect(find.byType(NetworkLogPage), findsOneWidget);
    expect(find.textContaining('网络调试'), findsOneWidget);
    expect(find.textContaining('还没有请求'), findsOneWidget);
  });
}
