import 'dart:io';

/// 把开发环境的回环地址换成当前平台真正能打到电脑的主机名。
///
/// Android 模拟器里 `127.0.0.1` 指向模拟器自己，需要改成 `10.0.2.2` 才能访问宿主机。
String resolveApiBaseUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.host.isEmpty) {
    return url;
  }
  final loopback = uri.host == '127.0.0.1' || uri.host == 'localhost' || uri.host == '::1';
  if (!loopback) {
    return url;
  }
  if (Platform.isAndroid) {
    return uri.replace(host: '10.0.2.2').toString();
  }
  return url;
}
