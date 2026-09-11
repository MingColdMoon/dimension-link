import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/models.dart';
import 'api_exception.dart';
import 'auth_session.dart';
import 'network_log.dart';

/// HTTP 客户端：统一 baseUrl、鉴权与（非生产）请求日志。
class ApiClient {
  ApiClient({
    Dio? dio,
    this.logStore,
    AppConfig? config,
    String? baseUrl,
  }) : dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? (config ?? AppConfig.current).apiBaseUrl,
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 12),
                headers: const {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    this.dio.interceptors.add(_AuthInterceptor(this));
    this.dio.interceptors.add(NetworkLogInterceptor(logStore));
  }

  static const accessTokenKey = 'dimension_link_access_token';
  static const refreshTokenKey = 'dimension_link_refresh_token';

  static const _anonymousPaths = {'/auth/login', '/auth/register', '/auth/refresh'};

  final Dio dio;
  final NetworkLogStore? logStore;
  String? accessToken;
  String? refreshToken;
  Future<void>? _refreshing;

  String get baseUrl => dio.options.baseUrl;

  /// 运行时切换接口地址（开发/测试环境切换工具使用）。
  void applyBaseUrl(String url) {
    dio.options.baseUrl = url;
    accessToken = null;
    refreshToken = null;
  }

  Future<void> restoreTokens() async {
    final prefs = await SharedPreferences.getInstance();
    accessToken = prefs.getString(accessTokenKey);
    refreshToken = prefs.getString(refreshTokenKey);
  }

  Future<void> persistSession(AuthSession session) async {
    accessToken = session.accessToken;
    refreshToken = session.refreshToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(accessTokenKey, session.accessToken);
    await prefs.setString(refreshTokenKey, session.refreshToken);
  }

  Future<void> clearTokens() async {
    accessToken = null;
    refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(accessTokenKey);
    await prefs.remove(refreshTokenKey);
  }

  Future<AuthSession> register({
    required String nickname,
    required String handle,
    required String password,
  }) {
    return _sendAuth(
      '/auth/register',
      {
        'nickname': nickname,
        'handle': handle,
        'password': password,
      },
    );
  }

  Future<AuthSession> login({
    required String identifier,
    required String password,
  }) {
    return _sendAuth(
      '/auth/login',
      {
        'identifier': identifier,
        'password': password,
      },
    );
  }

  Future<AuthSession> _sendAuth(String path, Map<String, dynamic> body) async {
    return AuthSession.fromJson(await _request('POST', path, data: body));
  }

  Future<void> logoutRemote() async {
    await _request(
      'POST',
      '/auth/logout',
      data: {
        if (refreshToken != null && refreshToken!.isNotEmpty) 'refreshToken': refreshToken,
      },
    );
  }

  /// 用 refreshToken 换新的 token 对。对应 `POST /v1/auth/refresh`。
  Future<AuthSession> refreshSession() async {
    var token = refreshToken;
    if (token == null || token.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString(refreshTokenKey);
      refreshToken = token;
    }
    if (token == null || token.isEmpty) {
      throw const ApiException(code: 1006, message: '请先登录');
    }
    final session = AuthSession.fromJson(
      await _request(
        'POST',
        '/auth/refresh',
        data: {'refreshToken': token},
        allowRefresh: false,
      ),
    );
    await persistSession(session);
    return session;
  }

  Future<MeProfile> getMe() async {
    return MeProfile.fromJson(await _request('GET', '/me'));
  }

  Future<AppUser> updateMe({
    required String nickname,
    required String bio,
    required String signature,
  }) async {
    final data = await _request(
      'PATCH',
      '/me',
      data: {
        'nickname': nickname,
        'bio': bio,
        'signature': signature,
      },
    );
    return AppUser.fromJson(data);
  }

  Future<AppUser> getUser(String userId) async {
    return AppUser.fromJson(await _request('GET', '/users/$userId'));
  }

  Future<({bool isFollowing, int followers})> toggleFollow(String userId) async {
    final data = await _request('POST', '/users/$userId/follow');
    return (
      isFollowing: asBool(pick(data, ['isFollowing', 'is_following'])),
      followers: asInt(data['followers']),
    );
  }

  Future<List<Post>> listPosts({String? authorId, String? circleId}) {
    return _getItems(
      '/posts',
      Post.fromJson,
      query: {
        'limit': 50,
        'authorId': ?authorId,
        'circleId': ?circleId,
      },
    );
  }

  Future<Post> getPost(String postId) async {
    return Post.fromJson(await _request('GET', '/posts/$postId'));
  }

  Future<Post> createPost({
    required String content,
    required String circleId,
    required String mood,
    required String imageTitle,
  }) async {
    return Post.fromJson(
      await _request(
        'POST',
        '/posts',
        data: {
          'content': content,
          'circleId': circleId,
          'mood': mood,
          'imageTitle': imageTitle,
        },
      ),
    );
  }

  Future<({bool liked, int likeCount})> toggleLike(String postId) async {
    final data = await _request('POST', '/posts/$postId/like');
    return (
      liked: asBool(data['liked']),
      likeCount: asInt(pick(data, ['likeCount', 'like_count'])),
    );
  }

  Future<({bool starred, int starCount})> toggleStar(String postId) async {
    final data = await _request('POST', '/posts/$postId/star');
    return (
      starred: asBool(data['starred']),
      starCount: asInt(pick(data, ['starCount', 'star_count'])),
    );
  }

  Future<List<Comment>> listComments(String postId) {
    return _getItems('/posts/$postId/comments', Comment.fromJson, query: {'limit': 50});
  }

  Future<Comment> createComment(String postId, String content) async {
    return Comment.fromJson(
      await _request('POST', '/posts/$postId/comments', data: {'content': content}),
    );
  }

  Future<List<Circle>> listCircles() {
    return _getItems('/circles', Circle.fromJson);
  }

  Future<Circle> getCircle(String circleId) async {
    return Circle.fromJson(await _request('GET', '/circles/$circleId'));
  }

  Future<({bool joined, int memberCount})> toggleJoinCircle(String circleId) async {
    final data = await _request('POST', '/circles/$circleId/join');
    return (
      joined: asBool(data['joined']),
      memberCount: asInt(pick(data, ['memberCount', 'member_count'])),
    );
  }

  Future<List<Conversation>> listConversations() {
    return _getItems('/conversations', Conversation.fromJson);
  }

  Future<Conversation> createConversation(String peerId) async {
    return Conversation.fromJson(
      await _request('POST', '/conversations', data: {'peerId': peerId}),
    );
  }

  Future<Conversation> createGroup({
    required List<String> memberIds,
    String title = '',
  }) async {
    return Conversation.fromJson(
      await _request(
        'POST',
        '/conversations',
        data: {
          'memberIds': memberIds,
          if (title.trim().isNotEmpty) 'title': title.trim(),
        },
      ),
    );
  }

  Future<List<ChatMessage>> listMessages(String conversationId) {
    return _getItems(
      '/conversations/$conversationId/messages',
      ChatMessage.fromJson,
      query: {'limit': 50},
    );
  }

  Future<ChatMessage> sendMessage(String conversationId, String text) async {
    return ChatMessage.fromJson(
      await _request(
        'POST',
        '/conversations/$conversationId/messages',
        data: {'text': text},
      ),
    );
  }

  Future<int> markConversationRead(String conversationId) async {
    final data = await _request('POST', '/conversations/$conversationId/read');
    return asInt(data['unread']);
  }

  Future<List<Notice>> listNotices() {
    return _getItems('/notices', Notice.fromJson, query: {'limit': 50});
  }

  Future<SearchResult> search(String query) async {
    return SearchResult.fromJson(
      await _request('GET', '/search', query: {'q': query, 'limit': 50}),
    );
  }

  Future<List<T>> _getItems<T>(
    String path,
    T Function(Map<String, dynamic> json) parse, {
    Map<String, dynamic>? query,
  }) async {
    final data = await _request('GET', path, query: query);
    final items = <T>[];
    for (final item in extractItems(data)) {
      try {
        items.add(parse(item));
      } catch (error, stack) {
        debugPrint('解析 $path 条目失败: $error\n$stack');
      }
    }
    return items;
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    bool allowRefresh = true,
  }) async {
    try {
      final response = await dio.request<dynamic>(
        path,
        data: data,
        queryParameters: query,
        options: Options(method: method),
      );
      return _unwrap(response.data);
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      if (allowRefresh && _shouldRefresh(path, error)) {
        try {
          await _refreshOnce();
          return await _request(
            method,
            path,
            data: data,
            query: query,
            allowRefresh: false,
          );
        } catch (refreshError) {
          debugPrint('刷新通行证失败: $refreshError');
        }
      }
      throw _fromDio(error);
    } catch (error, stack) {
      debugPrint('接口解析失败 $method $path: $error\n$stack');
      throw const ApiException(message: '次元暂时断开了');
    }
  }

  bool _shouldRefresh(String path, DioException error) {
    if (_anonymousPaths.contains(path) || path == '/auth/logout') {
      return false;
    }
    if (error.response?.statusCode != 401) {
      return false;
    }
    return (refreshToken != null && refreshToken!.isNotEmpty);
  }

  Future<void> _refreshOnce() {
    return _refreshing ??= () async {
      try {
        await refreshSession();
      } finally {
        _refreshing = null;
      }
    }();
  }

  Map<String, dynamic> _unwrap(dynamic data) {
    final decoded = _decodeBody(data);
    if (decoded is List) {
      return {'items': decoded};
    }
    if (decoded is! Map) {
      throw const ApiException(message: '次元暂时断开了');
    }
    final map = Map<String, dynamic>.from(decoded);
    final hasCode = map.containsKey('code') || map.containsKey('status');
    final code = asInt(pick(map, ['code', 'status']));
    final message = asString(pick(map, ['message', 'msg'])).trim();
    if (hasCode && !_isSuccessCode(code)) {
      throw ApiException(
        code: code,
        message: message.isEmpty ? '次元暂时断开了' : message,
      );
    }
    var inner = map['data'] ?? map['result'] ?? map['payload'];
    if (inner is String) {
      inner = _decodeBody(inner);
    }
    if (inner is List) {
      return {'items': inner};
    }
    if (inner is Map) {
      return Map<String, dynamic>.from(inner);
    }
    // 兼容 items 直接挂在根上：{ code: 0, items: [...] }
    if (extractItems(map).isNotEmpty || map.containsKey('items')) {
      return map;
    }
    return <String, dynamic>{};
  }

  /// 兼容 `text/plain` JSON、以及已经是 Map/List 的响应。
  dynamic _decodeBody(dynamic data) {
    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isEmpty) {
        return null;
      }
      try {
        return jsonDecode(trimmed);
      } catch (_) {
        return data;
      }
    }
    return data;
  }

  /// 文档约定 0；部分后端用 200 / 1 表示成功。
  bool _isSuccessCode(int code) => code == 0 || code == 1 || code == 200;

  ApiException _fromDio(DioException error) {
    final data = _decodeBody(error.response?.data);
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final message = asString(pick(map, ['message', 'msg'])).trim();
      if (message.isNotEmpty) {
        return ApiException(
          code: asInt(pick(map, ['code']), 5000),
          message: message,
          httpStatus: error.response?.statusCode,
        );
      }
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        final target = error.requestOptions.uri.toString();
        final detail = '${error.message ?? ''} ${error.error ?? ''}';
        final refused = detail.contains('Connection refused') ||
            detail.contains('Failed host lookup') ||
            detail.contains('SocketException');
        if (error.type != DioExceptionType.unknown || refused) {
          return ApiException(
            message: refused
                ? '连不上 $target。Android 模拟器请使用 10.0.2.2；真机请用电脑局域网 IP，或执行 adb reverse tcp:8080 tcp:8080。并确认后端已启动。'
                : '连不上次元服务器（$target），请检查网络或 API 地址',
          );
        }
        return const ApiException(message: '次元暂时断开了');
      default:
        return const ApiException(message: '次元暂时断开了');
    }
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._client);

  final ApiClient _client;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final path = options.path;
    if (!ApiClient._anonymousPaths.contains(path)) {
      final token = _client.accessToken;
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }
}

/// 把 Dio 请求写入 [NetworkLogStore]。
class NetworkLogInterceptor extends Interceptor {
  NetworkLogInterceptor(this.store);

  final NetworkLogStore? store;

  static const _startedAtExtra = 'networkLogStartedAt';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startedAtExtra] = DateTime.now();
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _record(
      options: response.requestOptions,
      statusCode: response.statusCode,
      responseBody: _encode(response.data),
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _record(
      options: err.requestOptions,
      statusCode: err.response?.statusCode,
      responseBody: _encode(err.response?.data),
      error: err.message ?? err.type.name,
    );
    handler.next(err);
  }

  void _record({
    required RequestOptions options,
    int? statusCode,
    String? responseBody,
    String? error,
  }) {
    final logs = store;
    if (logs == null) {
      return;
    }
    final startedAt = options.extra[_startedAtExtra] as DateTime? ?? DateTime.now();
    logs.add(
      NetworkLogEntry(
        method: options.method,
        uri: options.uri,
        startedAt: startedAt,
        duration: DateTime.now().difference(startedAt),
        statusCode: statusCode,
        requestBody: _encode(options.data),
        responseBody: responseBody,
        error: error,
      ),
    );
  }

  String? _encode(dynamic data) {
    if (data == null) {
      return null;
    }
    if (data is String) {
      return data;
    }
    if (data is Map || data is List) {
      try {
        return jsonEncode(data);
      } catch (_) {
        return data.toString();
      }
    }
    if (data is Uint8List) {
      return '<binary ${data.length} bytes>';
    }
    return data.toString();
  }
}
