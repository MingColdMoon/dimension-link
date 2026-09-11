import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/app_config.dart';
import '../theme/app_colors.dart';
import 'network_log.dart';

/// 非生产环境的悬浮网络调试入口。
class NetworkInspectorOverlay extends StatelessWidget {
  const NetworkInspectorOverlay({
    super.key,
    required this.child,
    required this.store,
    required this.navigatorKey,
    this.leadingTool,
  });

  final Widget child;
  final NetworkLogStore store;
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget? leadingTool;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          left: 12,
          bottom: 96,
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (leadingTool != null) ...[
                  leadingTool!,
                  const SizedBox(height: 8),
                ],
                ListenableBuilder(
                  listenable: store,
                  builder: (context, _) {
                    return _InspectorFab(
                      count: store.entries.length,
                      onPressed: () {
                        navigatorKey.currentState?.push(
                          MaterialPageRoute<void>(
                            builder: (_) => NetworkLogPage(store: store),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InspectorFab extends StatelessWidget {
  const _InspectorFab({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.starPurple,
      elevation: 6,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        key: const Key('network-inspector-fab'),
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_tethering, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              const Text(
                '网络',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 请求列表页。
class NetworkLogPage extends StatelessWidget {
  const NetworkLogPage({super.key, required this.store});

  final NetworkLogStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('网络调试 · ${AppConfig.current.env.label}'),
        actions: [
          IconButton(
            tooltip: '清空',
            onPressed: store.clear,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final entries = store.entries;
          if (entries.isEmpty) {
            return const Center(
              child: Text('还没有请求。去点一次注册或登录吧。'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: entries.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => NetworkLogDetailPage(entry: entry),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        _StatusChip(entry: entry),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${entry.method} ${entry.pathAndQuery}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${entry.duration.inMilliseconds}ms · ${DateFormat('HH:mm:ss').format(entry.startedAt)}',
                                style: const TextStyle(
                                  color: AppColors.inkMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.inkMuted),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.entry});

  final NetworkLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = entry.isSuccess ? AppColors.mint : AppColors.sakura;
    final label = entry.statusCode?.toString() ?? 'ERR';
    return Container(
      width: 48,
      padding: const EdgeInsets.symmetric(vertical: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

/// 单条请求详情。
class NetworkLogDetailPage extends StatelessWidget {
  const NetworkLogDetailPage({super.key, required this.entry});

  final NetworkLogEntry entry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${entry.method} ${entry.statusCode ?? 'ERR'}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _block('URL', entry.uri.toString()),
          _block('耗时', '${entry.duration.inMilliseconds} ms'),
          if (entry.error != null) _block('错误', entry.error!),
          _block('请求体', _pretty(redactSensitiveJson(entry.requestBody))),
          _block('响应体', _pretty(redactSensitiveJson(entry.responseBody))),
        ],
      ),
    );
  }

  Widget _block(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.inkMuted, fontSize: 12)),
          const SizedBox(height: 6),
          SelectableText(
            body.isEmpty ? '（空）' : body,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  String _pretty(String raw) {
    if (raw.isEmpty) {
      return '';
    }
    try {
      return const JsonEncoder.withIndent('  ').convert(jsonDecode(raw));
    } catch (_) {
      return raw;
    }
  }
}
