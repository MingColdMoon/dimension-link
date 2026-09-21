import 'dart:convert';
import 'dart:typed_data';

import '../config/app_config.dart';

/// 内置插画卡：色相 + 标题，不依赖相册也能发图。
class ChatIllustration {
  const ChatIllustration({required this.hue, required this.title});

  final int hue;
  final String title;

  String get url => 'illustration:$hue';
}

const chatIllustrations = [
  ChatIllustration(hue: 330, title: '樱色舞台'),
  ChatIllustration(hue: 200, title: '雨巷霓虹'),
  ChatIllustration(hue: 40, title: '晨间电车'),
  ChatIllustration(hue: 280, title: '行星发卡'),
  ChatIllustration(hue: 170, title: '夜场排队'),
  ChatIllustration(hue: 220, title: '耳机里的雨'),
];

int? parseIllustrationHue(String imageUrl) {
  final match = RegExp(r'^illustration:(\d+)$').firstMatch(imageUrl.trim());
  if (match == null) {
    return null;
  }
  return int.tryParse(match.group(1)!);
}

bool isIllustrationUrl(String imageUrl) => parseIllustrationHue(imageUrl) != null;

/// 把接口返回的图片地址拼成可加载 URL。
String resolveChatMediaUrl(String imageUrl, {String? apiBaseUrl}) {
  final raw = imageUrl.trim();
  if (raw.startsWith('http://') || raw.startsWith('https://') || raw.startsWith('data:')) {
    return raw;
  }
  if (isIllustrationUrl(raw) || raw.isEmpty) {
    return raw;
  }
  final base = (apiBaseUrl ?? AppConfig.current.apiBaseUrl).replaceFirst(RegExp(r'/v1/?$'), '');
  if (raw.startsWith('/')) {
    return '$base$raw';
  }
  return '$base/$raw';
}

Uint8List? decodeDataImage(String imageUrl) {
  final match = RegExp(r'^data:image/[^;]+;base64,(.+)$').firstMatch(imageUrl);
  if (match == null) {
    return null;
  }
  try {
    return base64Decode(match.group(1)!);
  } catch (_) {
    return null;
  }
}

String dataImageUrl(Uint8List bytes, {String mimeType = 'image/jpeg'}) {
  return 'data:$mimeType;base64,${base64Encode(bytes)}';
}
