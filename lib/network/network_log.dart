import 'package:flutter/foundation.dart';

/// 单条 HTTP 记录，供非生产环境调试面板展示。
class NetworkLogEntry {
  const NetworkLogEntry({
    required this.method,
    required this.uri,
    required this.startedAt,
    required this.duration,
    this.statusCode,
    this.requestBody,
    this.responseBody,
    this.error,
  });

  final String method;
  final Uri uri;
  final DateTime startedAt;
  final Duration duration;
  final int? statusCode;
  final String? requestBody;
  final String? responseBody;
  final String? error;

  bool get isSuccess =>
      error == null && statusCode != null && statusCode! >= 200 && statusCode! < 400;

  String get pathAndQuery {
    final query = uri.hasQuery ? '?${uri.query}' : '';
    return '${uri.path}$query';
  }
}

/// 内存中的请求日志。生产环境不会挂到 UI。
class NetworkLogStore extends ChangeNotifier {
  NetworkLogStore({this.capacity = 100});

  final int capacity;
  final List<NetworkLogEntry> _entries = [];

  List<NetworkLogEntry> get entries => List.unmodifiable(_entries);

  void add(NetworkLogEntry entry) {
    _entries.insert(0, entry);
    if (_entries.length > capacity) {
      _entries.removeLast();
    }
    notifyListeners();
  }

  void clear() {
    if (_entries.isEmpty) {
      return;
    }
    _entries.clear();
    notifyListeners();
  }
}

/// 调试面板里隐藏口令等敏感字段。
String redactSensitiveJson(String? body) {
  if (body == null || body.isEmpty) {
    return '';
  }
  return body.replaceAllMapped(
    RegExp(r'"(password|accessToken|refreshToken)"\s*:\s*"[^"]*"', caseSensitive: false),
    (match) => '"${match.group(1)}":"***"',
  );
}
