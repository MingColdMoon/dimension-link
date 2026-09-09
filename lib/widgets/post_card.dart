import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../screens/post/post_detail_screen.dart';
import '../screens/profile/user_profile_screen.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import 'cute_kit.dart';

class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post, this.showBanner = true});

  final Post post;
  final bool showBanner;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final author = post.author;
    final circle = post.circle;
    final time = DateFormat('M月d日 HH:mm').format(post.createdAt);

    return MochiCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PostDetailScreen(postId: post.id)),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CuteAvatar(
                emoji: author.emoji,
                accentIndex: author.accentIndex,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => UserProfileScreen(userId: author.id),
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(author.nickname, style: const TextStyle(fontSize: 16)),
                    Text(
                      '${author.handle} · $time',
                      style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              MoodPill(mood: post.mood),
            ],
          ),
          const SizedBox(height: 12),
          Text(post.content, style: const TextStyle(fontSize: 15, height: 1.5)),
          if (showBanner) ...[
            const SizedBox(height: 12),
            IllustratedBanner(hue: post.imageHue, title: post.imageTitle),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              _SoftChip(label: '${circle.emoji} ${circle.name}'),
              const Spacer(),
              _Action(
                icon: state.liked(post) ? Icons.favorite : Icons.favorite_border,
                color: state.liked(post) ? AppColors.sakura : AppColors.inkMuted,
                count: post.likeCount,
                onTap: () => context.read<AppState>().toggleLike(post.id),
              ),
              _Action(
                icon: Icons.mode_comment_outlined,
                color: AppColors.inkMuted,
                count: post.commentCount,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PostDetailScreen(postId: post.id),
                    ),
                  );
                },
              ),
              _Action(
                icon: state.starred(post) ? Icons.star : Icons.star_border,
                color: state.starred(post) ? AppColors.peach : AppColors.inkMuted,
                count: post.starCount,
                onTap: () => context.read<AppState>().toggleStar(post.id),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SoftChip extends StatelessWidget {
  const _SoftChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.lilacMist,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.starPurple)),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.color,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text('$count', style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
