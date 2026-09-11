import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/cute_kit.dart';
import '../../widgets/post_card.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _comment = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadPostDetail(widget.postId);
    });
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final post = state.findPost(widget.postId);
    if (post == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('动态')),
        body: const StarryBackdrop(
          child: Center(child: EmptyHint(text: '正在把这条动态从次元里捞出来…')),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('动态详情')),
      body: StarryBackdrop(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  PostCard(post: post),
                  const SizedBox(height: 16),
                  const Text('留言板', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  if (post.comments.isEmpty)
                    const EmptyHint(text: '还没有人留言，做第一个敲黑板的人吧。')
                  else
                    ...post.comments.map((c) {
                      final user = c.user;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: MochiCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CuteAvatar(
                                emoji: user.emoji,
                                accentIndex: user.accentIndex,
                                size: 36,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(user.nickname, style: const TextStyle(fontSize: 13)),
                                    Text(c.content),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _comment,
                        decoration: const InputDecoration(hintText: '轻轻说一句...'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      style: IconButton.styleFrom(backgroundColor: AppColors.sakura),
                      onPressed: () async {
                        final err = await context.read<AppState>().addComment(
                              post.id,
                              _comment.text,
                            );
                        if (!context.mounted) {
                          return;
                        }
                        if (err != null) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                          return;
                        }
                        _comment.clear();
                      },
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
