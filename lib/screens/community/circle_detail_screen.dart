import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/cute_kit.dart';
import '../../widgets/post_card.dart';
import '../feed/compose_screen.dart';

class CircleDetailScreen extends StatefulWidget {
  const CircleDetailScreen({super.key, required this.circleId});

  final String circleId;

  @override
  State<CircleDetailScreen> createState() => _CircleDetailScreenState();
}

class _CircleDetailScreenState extends State<CircleDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadCircleDetail(widget.circleId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final circle = state.circleById(widget.circleId);
    final posts = state.postsOfCircle(widget.circleId);
    final joined = circle.joined;

    return Scaffold(
      appBar: AppBar(title: Text(circle.name)),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.sakura,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ComposeScreen(presetCircleId: circle.id),
            ),
          );
        },
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      body: StarryBackdrop(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            MochiCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${circle.emoji} ${circle.name}', style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 6),
                  Text(circle.desc),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: circle.tags.map((t) => Chip(label: Text(t))).toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('${circle.memberCount} 人在逛'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GradientButton(
                          label: joined ? '已加入圈子' : '加入圈子',
                          onPressed: () =>
                              context.read<AppState>().toggleJoinCircle(circle.id),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (posts.isEmpty)
              const EmptyHint(text: '这个圈子还很安静，去发第一条动态吧。')
            else
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
