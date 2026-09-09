/// 后端统一错误。
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.code = 5000,
    this.httpStatus,
  });

  final String message;
  final int code;
  final int? httpStatus;

  @override
  String toString() => 'ApiException($code): $message';
}
