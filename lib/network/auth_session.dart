import '../models/models.dart';

/// 登录/注册成功后的会话。
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final AppUser user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final userRaw = json['user'];
    if (userRaw is! Map) {
      throw const FormatException('登录响应缺少 user');
    }
    return AuthSession(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      user: AppUser.fromJson(Map<String, dynamic>.from(userRaw)),
    );
  }
}
