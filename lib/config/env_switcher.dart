import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_env.dart';
import '../config/api_endpoints.dart';
import '../config/runtime_env.dart';
import '../network/api_client.dart';
import '../screens/auth/login_screen.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';

/// 开发 / 测试环境切换接口 Base URL。
class EnvSwitcherFab extends StatelessWidget {
  const EnvSwitcherFab({super.key, required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    final runtime = context.watch<RuntimeEnv>();
    if (!runtime.canSwitch) {
      return const SizedBox.shrink();
    }
    return Material(
      color: runtime.env.bannerColor,
      elevation: 6,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        key: const Key('env-switcher-fab'),
        onTap: () => _openSheet(context),
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.swap_horiz, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                runtime.env.label,
                key: ValueKey('env-fab-label-${runtime.env.name}'),
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSheet(BuildContext context) async {
    final runtime = context.read<RuntimeEnv>();
    final selected = await showModalBottomSheet<AppEnv>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _EnvSwitcherSheet(current: runtime.env, currentUrl: runtime.apiBaseUrl),
    );
    if (selected == null || selected == runtime.env || !context.mounted) {
      return;
    }
    await runtime.select(selected);
    if (!context.mounted) {
      return;
    }
    context.read<ApiClient>().applyBaseUrl(runtime.apiBaseUrl);
    await context.read<AppState>().logout(notifyRemote: false);
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
    final messengerContext = navigatorKey.currentContext;
    if (messengerContext != null && messengerContext.mounted) {
      ScaffoldMessenger.of(messengerContext).showSnackBar(
        SnackBar(content: Text('已切换到${selected.label}环境')),
      );
    }
  }
}

/// 底部面板里的选中态立刻更新，确认后再真正切换。
class _EnvSwitcherSheet extends StatefulWidget {
  const _EnvSwitcherSheet({required this.current, required this.currentUrl});

  final AppEnv current;
  final String currentUrl;

  @override
  State<_EnvSwitcherSheet> createState() => _EnvSwitcherSheetState();
}

class _EnvSwitcherSheetState extends State<_EnvSwitcherSheet> {
  late AppEnv _picked = widget.current;

  String _subtitleFor(ApiEndpoint endpoint) {
    final resolved = ApiEndpoints.resolvedBaseUrlOf(endpoint.env);
    if (resolved != endpoint.baseUrl) {
      return resolved;
    }
    if (endpoint.baseUrl == widget.currentUrl && endpoint.env != widget.current) {
      return '${endpoint.baseUrl}（地址相同，状态仍会切换）';
    }
    return endpoint.baseUrl;
  }

  @override
  Widget build(BuildContext context) {
    final pickedEndpoint = ApiEndpoints.of(_picked);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('切换接口环境', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              '当前 ${widget.current.label} · ${widget.currentUrl}',
              style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            for (final endpoint in ApiEndpoints.all)
              ListTile(
                key: Key('env-option-${endpoint.env.name}'),
                selected: endpoint.env == _picked,
                selectedTileColor: endpoint.env.bannerColor.withValues(alpha: 0.12),
                leading: Icon(
                  endpoint.env == _picked
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: endpoint.env.bannerColor,
                ),
                title: Text(endpoint.label),
                subtitle: Text(_subtitleFor(endpoint)),
                onTap: () => setState(() => _picked = endpoint.env),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('env-switch-confirm'),
                onPressed: () => Navigator.pop(context, _picked),
                style: FilledButton.styleFrom(backgroundColor: pickedEndpoint.env.bannerColor),
                child: Text(_picked == widget.current ? '保持${_picked.label}环境' : '切换到${_picked.label}环境'),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '切换后会退出登录，因为不同环境的通行证不能混用。',
              style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
