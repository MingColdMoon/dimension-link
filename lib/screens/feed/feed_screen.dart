import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/cute_kit.dart';
import '../../widgets/post_card.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final me = state.me;

    return StarryBackdrop(
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    CuteAvatar(emoji: me.emoji, accentIndex: me.accentIndex, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('嗨，${me.nickname}', style: const TextStyle(fontSize: 20)),
                          Text(me.signature, style: const TextStyle(color: AppColors.inkMuted)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text('Lv.${me.level}'),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 108),
              sliver: state.posts.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 48),
                        child: EmptyHint(
                          text: state.feedError ?? '广场还没有动态，去发布第一条吧。',
                        ),
                      ),
                    )
                  : SliverList.separated(
                      itemCount: state.posts.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => PostCard(post: state.posts[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
