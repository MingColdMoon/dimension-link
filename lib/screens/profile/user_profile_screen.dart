import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/cute_kit.dart';
import '../../widgets/post_card.dart';
import '../messages/chat_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadUserProfile(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.userById(widget.userId);
    final posts = state.postsOfUser(widget.userId);
    final isMe = state.currentUserId == widget.userId;
    final following = user.isFollowing;

    return Scaffold(
      appBar: AppBar(title: Text(user.nickname)),
      body: StarryBackdrop(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            MochiCard(
              child: Column(
                children: [
                  CuteAvatar(emoji: user.emoji, accentIndex: user.accentIndex, size: 80),
                  const SizedBox(height: 8),
                  Text(user.handle, style: const TextStyle(color: AppColors.inkMuted)),
                  Text(user.bio, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text('粉丝 ${user.followers} · 关注 ${user.following} · Lv.${user.level}'),
                  if (!isMe) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GradientButton(
                            label: following ? '已关注' : '关注',
                            onPressed: () => context.read<AppState>().toggleFollow(widget.userId),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final cv = await context.read<AppState>().ensureConversation(widget.userId);
                              if (!context.mounted) {
                                return;
                              }
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(conversationId: cv.id),
                                ),
                              );
                            },
                            child: const Text('发私信'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...posts.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PostCard(post: p),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
