import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../community/community_screen.dart';
import '../feed/compose_screen.dart';
import '../feed/feed_screen.dart';
import '../messages/messages_screen.dart';
import '../messages/start_chat_screen.dart';
import '../profile/profile_screen.dart';
import '../search/search_screen.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final pages = const [
      FeedScreen(),
      CommunityScreen(),
      MessagesScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: state.tabIndex, children: pages),
      floatingActionButton: state.tabIndex == 0
          ? FloatingActionButton(
              backgroundColor: AppColors.sakura,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ComposeScreen()),
                );
              },
              child: const Icon(Icons.auto_awesome, color: Colors.white),
            )
          : state.tabIndex == 2
              ? FloatingActionButton(
                  backgroundColor: AppColors.starPurple,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const StartChatScreen(groupMode: true)),
                    );
                  },
                  child: const Icon(Icons.groups_rounded, color: Colors.white),
                )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _CuteNav(
        index: state.tabIndex,
        unread: state.unreadChatCount,
        onTap: state.setTab,
        onSearch: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SearchScreen()),
          );
        },
      ),
    );
  }
}

class _CuteNav extends StatelessWidget {
  const _CuteNav({
    required this.index,
    required this.unread,
    required this.onTap,
    required this.onSearch,
  });

  final int index;
  final int unread;
  final ValueChanged<int> onTap;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.starPurple.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Row(
              children: [
                _NavItem(icon: Icons.home_rounded, label: '广场', selected: index == 0, onTap: () => onTap(0)),
                _NavItem(icon: Icons.diversity_1, label: '圈子', selected: index == 1, onTap: () => onTap(1)),
                _NavItem(
                  icon: Icons.chat_bubble_rounded,
                  label: '消息',
                  selected: index == 2,
                  badge: unread,
                  onTap: () => onTap(2),
                ),
                _NavItem(icon: Icons.person_rounded, label: '我的', selected: index == 3, onTap: () => onTap(3)),
                IconButton(
                  onPressed: onSearch,
                  icon: const Icon(Icons.search_rounded, color: AppColors.starPurple),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.sakuraSoft.withValues(alpha: 0.7) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: selected ? AppColors.sakura : AppColors.inkMuted),
                  if (badge > 0)
                    Positioned(
                      right: -8,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.sakura,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$badge',
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: selected ? AppColors.sakura : AppColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
