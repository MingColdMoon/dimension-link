import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/cute_kit.dart';
import '../../widgets/post_card.dart';
import '../community/circle_detail_screen.dart';
import '../profile/user_profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().runSearch('');
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final posts = state.searchResultPosts;
    final users = state.searchResultUsers;
    final circles = state.searchResultCircles;

    return Scaffold(
      appBar: AppBar(title: const Text('搜寻次元')),
      body: StarryBackdrop(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              onChanged: (v) {
                setState(() => _query = v);
                context.read<AppState>().runSearch(v);
              },
              decoration: const InputDecoration(
                hintText: '搜动态、住民、圈子',
                prefixIcon: Icon(Icons.search, color: AppColors.sakura),
              ),
            ),
            const SizedBox(height: 16),
            const Text('住民', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            ...users.take(6).map(
                  (u) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: MochiCard(
                      padding: const EdgeInsets.all(12),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => UserProfileScreen(userId: u.id)),
                        );
                      },
                      child: Row(
                        children: [
                          CuteAvatar(emoji: u.emoji, accentIndex: u.accentIndex, size: 40),
                          const SizedBox(width: 10),
                          Expanded(child: Text('${u.nickname}  ${u.handle}')),
                        ],
                      ),
                    ),
                  ),
                ),
            const SizedBox(height: 8),
            const Text('圈子', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: circles
                  .map(
                    (c) => ActionChip(
                      label: Text('${c.emoji} ${c.name}'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => CircleDetailScreen(circleId: c.id)),
                        );
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            const Text('动态', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            if (posts.isEmpty)
              EmptyHint(text: _query.isEmpty ? '输入关键词，或看看最新动态。' : '没有找到匹配的动态。')
            else
              ...posts.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PostCard(post: p, showBanner: false),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
