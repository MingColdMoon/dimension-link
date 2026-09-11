import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/cute_kit.dart';
import 'chat_screen.dart';
import 'start_chat_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return StarryBackdrop(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 108),
          children: [
            Row(
              children: [
                const Expanded(child: Text('消息', style: TextStyle(fontSize: 28))),
                TextButton.icon(
                  key: const Key('start-direct-chat'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const StartChatScreen()),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('私聊'),
                ),
                TextButton.icon(
                  key: const Key('start-group-chat'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const StartChatScreen(groupMode: true)),
                    );
                  },
                  icon: const Icon(Icons.groups_outlined, size: 18),
                  label: const Text('拉群'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...state.notices.map(
              (n) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: MochiCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Text(n.kind == 'group' ? '🪐' : '🔔', style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n.title, style: const TextStyle(fontSize: 15)),
                            Text(n.body, style: const TextStyle(color: AppColors.inkMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text('会话', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            if (state.conversations.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: EmptyHint(text: '还没有私信或群聊，点右上角找人吧。'),
              ),
            ...state.conversations.map((cv) {
              final last = cv.lastMessage;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child:                 MochiCard(
                  key: Key('conversation-${cv.id}'),
                  onTap: () async {
                    await context.read<AppState>().markConversationRead(cv.id);
                    if (!context.mounted) {
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ChatScreen(conversationId: cv.id)),
                    );
                  },
                  child: Row(
                    children: [
                      CuteAvatar(emoji: cv.displayEmoji, accentIndex: cv.displayAccent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cv.isGroup ? '${cv.displayName} · ${cv.members.length}人' : cv.displayName,
                              style: const TextStyle(fontSize: 16),
                            ),
                            Text(
                              last?.text ?? (cv.isGroup ? '群已经建好，打个招呼吧' : '还没有对话'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.inkMuted),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (last != null)
                            Text(
                              DateFormat('HH:mm').format(last.createdAt),
                              style: const TextStyle(fontSize: 11, color: AppColors.inkMuted),
                            ),
                          if (cv.unread > 0) ...[
                            const SizedBox(height: 6),
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: AppColors.sakura,
                              child: Text(
                                '${cv.unread}',
                                style: const TextStyle(color: Colors.white, fontSize: 11),
                              ),
                            ),
                          ],
                        ],
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
}
