import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/cute_kit.dart';
import 'chat_screen.dart';

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
            const Text('消息', style: TextStyle(fontSize: 28)),
            const SizedBox(height: 12),
            ...state.notices.map(
              (n) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: MochiCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Text('🔔', style: TextStyle(fontSize: 22)),
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
            const Text('私信', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            ...state.conversations.map((cv) {
              final peer = cv.peer;
              final last = cv.lastMessage;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: MochiCard(
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
                      CuteAvatar(emoji: peer.emoji, accentIndex: peer.accentIndex),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(peer.nickname, style: const TextStyle(fontSize: 16)),
                            Text(
                              last?.text ?? '还没有对话',
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
