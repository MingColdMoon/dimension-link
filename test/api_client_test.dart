import 'dart:convert';
import 'dart:typed_data';

import 'package:dimension_link/config/api_endpoints.dart';
import 'package:dimension_link/config/app_config.dart';
import 'package:dimension_link/config/app_env.dart';
import 'package:dimension_link/config/env_switcher.dart';
import 'package:dimension_link/config/runtime_env.dart';
import 'package:dimension_link/network/api_client.dart';
import 'package:dimension_link/network/auth_session.dart';
import 'package:dimension_link/network/network_inspector.dart';
import 'package:dimension_link/network/network_log.dart';
import 'package:dimension_link/state/app_state.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
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

ResponseBody jsonBody(int status, Object data, {String contentType = Headers.jsonContentType}) {
  return ResponseBody.fromString(
    data is String ? data : jsonEncode(data),
    status,
    headers: {
      Headers.contentTypeHeader: [contentType],
    },
  );
}

Map<String, dynamic> sampleUser({String id = 'u_new', String nickname = '测试酱'}) {
  return {
    'id': id,
    'nickname': nickname,
    'handle': 'testchan',
    'bio': '新住民',
    'signature': '你好',
    'emoji': '✨',
    'accentIndex': 1,
    'followers': 0,
    'following': 0,
    'level': 1,
    'badges': ['初入次元'],
  };
}

Map<String, dynamic> samplePost({
  String id = 'p_live',
  String content = '有返回值就该看见我',
}) {
  return {
    'id': id,
    'content': content,
    'author': sampleUser(id: 'u_sakurai', nickname: '桜井澪'),
    'circle': {'id': 'c_cos', 'name': 'COSPLAY', 'emoji': '👗'},
    'createdAt': '2026-09-08T10:00:00Z',
    'mood': 'happy',
    'likeCount': '3',
    'starCount': 1.0,
    'liked': 1,
  };
}

Map<String, dynamic> loginEnvelope() {
  return {
    'code': 0,
    'message': 'ok',
    'data': {
      'accessToken': 'tok_a',
      'refreshToken': 'tok_r',
      'expiresIn': 7200,
      'user': sampleUser(),
    },
  };
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

  test('GET /posts 的 data 为数组时能解析出动态', () async {
    final adapter = _ScriptedAdapter((options) {
      if (options.path == '/posts') {
        return jsonBody(200, {
          'code': 0,
          'message': 'ok',
          'data': [samplePost()],
        });
      }
      return jsonBody(200, {'code': 0, 'message': 'ok', 'data': {'items': []}});
    });
    final dio = Dio(BaseOptions(baseUrl: AppConfig.current.apiBaseUrl))
      ..httpClientAdapter = adapter;
    final posts = await ApiClient(dio: dio).listPosts();
    expect(posts, hasLength(1));
    expect(posts.first.content, '有返回值就该看见我');
    expect(posts.first.likeCount, 3);
    expect(posts.first.liked, isTrue);
  });

  test('GET /posts 根级 items、code=200、text/plain JSON 也能解析', () async {
    final adapter = _ScriptedAdapter((options) {
      return jsonBody(
        200,
        jsonEncode({
          'code': 200,
          'message': 'ok',
          'items': [samplePost(id: 'p_root')],
        }),
        contentType: 'text/plain',
      );
    });
    final dio = Dio(BaseOptions(baseUrl: AppConfig.current.apiBaseUrl))
      ..httpClientAdapter = adapter;
    final posts = await ApiClient(dio: dio).listPosts();
    expect(posts.single.id, 'p_root');
  });

  test('圈子接口失败时广场仍能写入 /posts', () async {
    final adapter = _ScriptedAdapter((options) {
      if (options.path == '/auth/login' || options.path == '/auth/register') {
        return jsonBody(200, loginEnvelope());
      }
      if (options.path == '/posts') {
        return jsonBody(200, {
          'code': 0,
          'message': 'ok',
          'data': [samplePost()],
        });
      }
      if (options.path == '/circles') {
        return jsonBody(500, {'code': 5000, 'message': '圈子挂了', 'data': null});
      }
      return jsonBody(200, {'code': 0, 'message': 'ok', 'data': {'items': []}});
    });
    final dio = Dio(BaseOptions(baseUrl: AppConfig.current.apiBaseUrl))
      ..httpClientAdapter = adapter;
    final state = AppState(api: ApiClient(dio: dio));
    final err = await state.login('测试酱', '123456');
    expect(err, isNull);
    expect(state.posts, hasLength(1));
    expect(state.posts.first.content, '有返回值就该看见我');
    expect(state.feedError, isNull);
    expect(state.circles.any((circle) => circle.id == 'c_cos'), isTrue);
  });

  test('点赞响应兼容数字布尔值', () async {
    final adapter = _ScriptedAdapter((options) {
      expect(options.path, '/posts/p_live/like');
      return jsonBody(200, {
        'code': 0,
        'message': 'ok',
        'data': {'liked': 1, 'likeCount': '4'},
      });
    });
    final dio = Dio(BaseOptions(baseUrl: AppConfig.current.apiBaseUrl))
      ..httpClientAdapter = adapter;
    final result = await ApiClient(dio: dio).toggleLike('p_live');
    expect(result.liked, isTrue);
    expect(result.likeCount, 4);
  });

  test('accessToken 过期时会 POST /auth/refresh 并重试原请求', () async {
    var postsHits = 0;
    final adapter = _ScriptedAdapter((options) {
      if (options.path == '/auth/refresh') {
        expect(options.headers['Authorization'], isNull);
        expect(options.data.toString(), contains('tok_r'));
        return jsonBody(200, {
          'code': 0,
          'message': 'ok',
          'data': {
            'accessToken': 'tok_new',
            'refreshToken': 'tok_r2',
            'expiresIn': 7200,
            'user': sampleUser(),
          },
        });
      }
      if (options.path == '/posts') {
        postsHits += 1;
        final auth = options.headers['Authorization'] as String?;
        if (auth != 'Bearer tok_new') {
          return jsonBody(401, {'code': 1006, 'message': '请先登录', 'data': null});
        }
        return jsonBody(200, {
          'code': 0,
          'message': 'ok',
          'data': {'items': [samplePost()]},
        });
      }
      return jsonBody(200, {'code': 0, 'message': 'ok', 'data': {'items': []}});
    });
    final dio = Dio(BaseOptions(baseUrl: AppConfig.current.apiBaseUrl))
      ..httpClientAdapter = adapter;
    final api = ApiClient(dio: dio);
    await api.persistSession(
      AuthSession.fromJson({
        'accessToken': 'tok_old',
        'refreshToken': 'tok_r',
        'user': sampleUser(),
      }),
    );
    final posts = await api.listPosts();
    expect(postsHits, 2);
    expect(posts.single.content, '有返回值就该看见我');
    expect(api.accessToken, 'tok_new');
  });

  testWidgets('开发 / 测试包显示环境切换入口，生产配置不显示', (tester) async {
    final navKey = GlobalKey<NavigatorState>();
    final runtime = RuntimeEnv();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<RuntimeEnv>.value(value: runtime),
          Provider<ApiClient>.value(value: ApiClient(baseUrl: runtime.apiBaseUrl)),
          ChangeNotifierProvider(create: (_) => AppState()),
        ],
        child: MaterialApp(
          navigatorKey: navKey,
          home: Scaffold(body: EnvSwitcherFab(navigatorKey: navKey)),
        ),
      ),
    );
    if (AppConfig.current.isProduction) {
      expect(find.byKey(const Key('env-switcher-fab')), findsNothing);
      return;
    }
    expect(runtime.canSwitch, isTrue);
    expect(find.byKey(const Key('env-switcher-fab')), findsOneWidget);

    await tester.tap(find.byKey(const Key('env-switcher-fab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('切换接口环境'), findsOneWidget);
    expect(find.byKey(const Key('env-option-dev')), findsOneWidget);
    expect(find.byKey(const Key('env-option-staging')), findsOneWidget);
    expect(find.byKey(const Key('env-option-prod')), findsOneWidget);

    await tester.tap(find.byKey(const Key('env-option-staging')));
    await tester.pump();
    expect(find.text('切换到测试环境'), findsOneWidget);
    if (ApiEndpoints.staging.baseUrl == ApiEndpoints.development.baseUrl) {
      expect(find.textContaining('地址相同，状态仍会切换'), findsOneWidget);
    }

    await tester.tap(find.byKey(const Key('env-switch-confirm')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(runtime.env, AppEnv.staging);
    expect(find.text('已切换到测试环境'), findsOneWidget);
  });

  testWidgets('生产编译配置下环境切换按钮不出现', (tester) async {
    final runtime = RuntimeEnv(
      compiled: const AppConfig(
        env: AppEnv.prod,
        apiBaseUrl: 'https://api.dimension-link.dev/v1',
        enableLogging: false,
      ),
    );
    expect(runtime.canSwitch, isFalse);
    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ChangeNotifierProvider<RuntimeEnv>.value(
        value: runtime,
        child: MaterialApp(home: EnvSwitcherFab(navigatorKey: navKey)),
      ),
    );
    expect(find.byKey(const Key('env-switcher-fab')), findsNothing);
  });

  testWidgets('开发包叠加层同时出现环境和网络按钮', (tester) async {
    if (AppConfig.current.isProduction) {
      return;
    }
    final runtime = RuntimeEnv();
    final logs = NetworkLogStore();
    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ChangeNotifierProvider<RuntimeEnv>.value(
        value: runtime,
        child: MaterialApp(
          navigatorKey: navKey,
          home: NetworkInspectorOverlay(
            store: logs,
            navigatorKey: navKey,
            leadingTool: EnvSwitcherFab(navigatorKey: navKey),
            child: const Scaffold(body: Text('首页')),
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('env-switcher-fab')), findsOneWidget);
    expect(find.byKey(const Key('network-inspector-fab')), findsOneWidget);
  });

  test('拉群会 POST /conversations，并带上 memberIds', () async {
    final adapter = _ScriptedAdapter((options) {
      expect(options.method, 'POST');
      expect(options.path, '/conversations');
      return jsonBody(200, {
        'code': 0,
        'message': 'ok',
        'data': {
          'id': 'cv_g1',
          'kind': 'group',
          'title': '漫展小队',
          'ownerId': 'u_me',
          'members': [
            sampleUser(id: 'u_me', nickname: '星野铃'),
            sampleUser(id: 'u_sakurai', nickname: '桜井澪'),
            sampleUser(id: 'u_tsukimi', nickname: '月见黑'),
          ],
          'unread': 0,
        },
      });
    });
    final dio = Dio(BaseOptions(baseUrl: AppConfig.current.apiBaseUrl))
      ..httpClientAdapter = adapter;
    final api = ApiClient(dio: dio, logStore: NetworkLogStore());
    final group = await api.createGroup(
      memberIds: ['u_sakurai', 'u_tsukimi'],
      title: '漫展小队',
    );
    expect(jsonDecode(adapter.lastBody!), {
      'memberIds': ['u_sakurai', 'u_tsukimi'],
      'title': '漫展小队',
    });
    expect(group.isGroup, isTrue);
    expect(group.displayName, '漫展小队');
    expect(group.members, hasLength(3));
  });
}
