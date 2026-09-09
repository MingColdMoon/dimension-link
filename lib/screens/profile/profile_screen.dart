import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/cute_kit.dart';
import '../../widgets/post_card.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final me = state.me;
    final myPosts = state.postsOfUser(me.id);

    return StarryBackdrop(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 108),
          children: [
            MochiCard(
              child: Column(
                children: [
                  CuteAvatar(emoji: me.emoji, accentIndex: me.accentIndex, size: 86),
                  const SizedBox(height: 10),
                  Text(me.nickname, style: const TextStyle(fontSize: 24)),
                  Text(me.handle, style: const TextStyle(color: AppColors.inkMuted)),
                  const SizedBox(height: 8),
                  Text(me.bio, textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text('「${me.signature}」', style: const TextStyle(color: AppColors.starPurple)),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _Stat(label: '动态', value: '${myPosts.length}'),
                      _Stat(label: '关注', value: '${me.following}'),
                      _Stat(label: '粉丝', value: '${me.followers}'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: me.badges.map((b) => Chip(label: Text(b))).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                            );
                          },
                          child: const Text('编辑资料'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            await context.read<AppState>().logout();
                            if (!context.mounted) return;
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                              (route) => false,
                            );
                          },
                          child: const Text('退出登录'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('我的动态', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            if (myPosts.isEmpty)
              const EmptyHint(text: '还没有动态，去广场发布第一条吧。')
            else
              ...myPosts.map(
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

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, color: AppColors.sakura)),
        Text(label, style: const TextStyle(color: AppColors.inkMuted, fontSize: 12)),
      ],
    );
  }
}
