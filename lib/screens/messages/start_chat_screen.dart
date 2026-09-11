import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../network/api_exception.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/cute_kit.dart';
import 'chat_screen.dart';

/// 选人发起私聊，或选多人拉群。
class StartChatScreen extends StatefulWidget {
  const StartChatScreen({super.key, this.groupMode = false});

  final bool groupMode;

  @override
  State<StartChatScreen> createState() => _StartChatScreenState();
}

class _StartChatScreenState extends State<StartChatScreen> {
  final _title = TextEditingController();
  final _picked = <String>{};

  bool get _isGroupSubmit => widget.groupMode || _picked.length >= 2;

  bool get _canSubmit => widget.groupMode ? _picked.length >= 2 : _picked.isNotEmpty;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final meId = state.currentUserId;
    final candidates = state.users.where((user) => user.id != meId).toList();
    final groupMode = widget.groupMode || _picked.length >= 2;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupMode ? '拉个群' : '找人聊天'),
        actions: [
          if (_canSubmit)
            TextButton(
              key: const Key('start-chat-submit'),
              onPressed: () => _submit(context),
              child: Text(_isGroupSubmit ? '拉群（${_picked.length}）' : '发私信'),
            ),
        ],
      ),
      body: StarryBackdrop(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            if (groupMode) ...[
              TextField(
                controller: _title,
                decoration: const InputDecoration(hintText: '群名（可空，默认用成员昵称）'),
              ),
              const SizedBox(height: 12),
              Text(
                widget.groupMode ? '至少邀请两位住民' : '再选一位就能拉群',
                style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
              ),
              const SizedBox(height: 8),
            ],
            if (candidates.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: EmptyHint(text: '还没有其他住民，去广场或搜寻看看。'),
              ),
            ...candidates.map((user) {
              final selected = _picked.contains(user.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: MochiCard(
                  padding: const EdgeInsets.all(12),
                  onTap: () => setState(() {
                    if (selected) {
                      _picked.remove(user.id);
                    } else {
                      _picked.add(user.id);
                    }
                  }),
                  child: Row(
                    children: [
                      CuteAvatar(emoji: user.emoji, accentIndex: user.accentIndex, size: 44),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.nickname, style: const TextStyle(fontSize: 16)),
                            Text(user.handle, style: const TextStyle(color: AppColors.inkMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                      Icon(
                        selected ? Icons.check_circle : Icons.circle_outlined,
                        color: selected ? AppColors.sakura : AppColors.inkMuted,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    final state = context.read<AppState>();
    if (_isGroupSubmit) {
      final err = await state.createGroupChat(
        memberIds: _picked.toList(),
        title: _title.text,
      );
      if (!context.mounted) {
        return;
      }
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        return;
      }
      final created = state.lastCreatedConversation();
      if (created == null) {
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ChatScreen(conversationId: created.id)),
      );
      return;
    }
    try {
      final conversation = await state.ensureConversation(_picked.first);
      if (!context.mounted) {
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ChatScreen(conversationId: conversation.id)),
      );
    } on ApiException catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }
}
