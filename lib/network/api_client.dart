import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
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
  })  : _config = config ?? AppConfig.current,
        dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: (config ?? AppConfig.current).apiBaseUrl,
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

  final Dio dio;
  final NetworkLogStore? logStore;
  final AppConfig _config;
  String? accessToken;

  String get baseUrl => _config.apiBaseUrl;

  Future<void> restoreTokens() async {
    final prefs = await SharedPreferences.getInstance();
    accessToken = prefs.getString(accessTokenKey);
  }

  Future<void> persistSession(AuthSession session) async {
    accessToken = session.accessToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(accessTokenKey, session.accessToken);
    await prefs.setString(refreshTokenKey, session.refreshToken);
  }

  Future<void> clearTokens() async {
    accessToken = null;
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
    await _request('POST', '/auth/logout');
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
      isFollowing: data['isFollowing'] as bool? ?? false,
      followers: data['followers'] as int? ?? 0,
    );
  }

  Future<List<Post>> listPosts({String? authorId, String? circleId}) {
    return _getItems(
      '/posts',
      Post.fromJson,
      query: {
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
      liked: data['liked'] as bool? ?? false,
      likeCount: data['likeCount'] as int? ?? 0,
    );
  }

  Future<({bool starred, int starCount})> toggleStar(String postId) async {
    final data = await _request('POST', '/posts/$postId/star');
    return (
      starred: data['starred'] as bool? ?? false,
      starCount: data['starCount'] as int? ?? 0,
    );
  }

  Future<List<Comment>> listComments(String postId) {
    return _getItems('/posts/$postId/comments', Comment.fromJson);
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
      joined: data['joined'] as bool? ?? false,
      memberCount: data['memberCount'] as int? ?? 0,
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

  Future<List<ChatMessage>> listMessages(String conversationId) {
    return _getItems('/conversations/$conversationId/messages', ChatMessage.fromJson);
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
    return data['unread'] as int? ?? 0;
  }

  Future<List<Notice>> listNotices() {
    return _getItems('/notices', Notice.fromJson);
  }

  Future<SearchResult> search(String query) async {
    return SearchResult.fromJson(
      await _request('GET', '/search', query: {'q': query}),
    );
  }

  Future<List<T>> _getItems<T>(
    String path,
    T Function(Map<String, dynamic> json) parse, {
    Map<String, dynamic>? query,
  }) async {
    final data = await _request('GET', path, query: query);
    return [for (final item in asJsonMapList(data['items'])) parse(item)];
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Object? data,
    Map<String, dynamic>? query,
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
      throw _fromDio(error);
    } catch (_) {
      throw const ApiException(message: '次元暂时断开了');
    }
  }

  Map<String, dynamic> _unwrap(dynamic data) {
    if (data is! Map) {
      throw const ApiException(message: '次元暂时断开了');
    }
    final map = Map<String, dynamic>.from(data);
    final code = map['code'] as int? ?? 0;
    final message = (map['message'] as String?)?.trim();
    if (code != 0) {
      throw ApiException(
        code: code,
        message: (message == null || message.isEmpty) ? '次元暂时断开了' : message,
      );
    }
    final inner = map['data'];
    if (inner == null) {
      return <String, dynamic>{};
    }
    if (inner is Map) {
      return Map<String, dynamic>.from(inner);
    }
    throw const ApiException(message: '次元暂时断开了');
  }

  ApiException _fromDio(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final message = (data['message'] as String?)?.trim();
      if (message != null && message.isNotEmpty) {
        return ApiException(
          code: data['code'] as int? ?? 5000,
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
        return const ApiException(message: '连不上次元服务器，请检查网络或 API 地址');
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
    final token = _client.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
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
