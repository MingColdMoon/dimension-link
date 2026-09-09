import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/cute_kit.dart';
import 'circle_detail_screen.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return StarryBackdrop(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 108),
          children: [
            const Text('圈子', style: TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            const Text('按兴趣结成小小星球，同好都在这里。', style: TextStyle(color: AppColors.inkMuted)),
            const SizedBox(height: 16),
            ...state.circles.map((circle) {
              final joined = circle.joined;
              final color = AppColors.avatarPalette[circle.accentIndex];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MochiCard(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CircleDetailScreen(circleId: circle.id),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(circle.emoji, style: const TextStyle(fontSize: 28)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(circle.name, style: const TextStyle(fontSize: 18)),
                            Text(
                              '${circle.memberCount} 位住民 · ${circle.desc}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.read<AppState>().toggleJoinCircle(circle.id),
                        child: Text(joined ? '已加入' : '加入'),
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
