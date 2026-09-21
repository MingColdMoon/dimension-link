import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../chat/group_rules.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/cute_kit.dart';

class GroupSettingsScreen extends StatelessWidget {
  const GroupSettingsScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cv = state.findConversation(conversationId);
    if (cv == null || !cv.isGroup) {
      return Scaffold(
        appBar: AppBar(title: const Text('群资料')),
        body: const StarryBackdrop(
          child: Center(child: EmptyHint(text: '这个群已经不在了')),
        ),
      );
    }
    final meId = state.currentUserId ?? '';
    final actor = resolveGroupRole(cv, meId);

    return Scaffold(
      appBar: AppBar(title: const Text('群资料')),
      body: StarryBackdrop(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            MochiCard(
              child: Column(
                children: [
                  CuteAvatar(emoji: cv.displayEmoji, accentIndex: cv.displayAccent, size: 72),
                  const SizedBox(height: 10),
                  Text(cv.displayName, style: const TextStyle(fontSize: 22)),
                  Text(
                    '${cv.members.length} 位成员 · ${cv.isOwner(meId) ? '你是群主' : cv.isAdmin(meId) ? '你是管理员' : '普通成员'}',
                    style: const TextStyle(color: AppColors.inkMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (canToggleGroupMute(actor)) ...[
              const SizedBox(height: 12),
              MochiCard(
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('全员禁言'),
                          Text('群主和管理员仍可发言', style: TextStyle(color: AppColors.inkMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                    Switch(
                      key: const Key('group-mute-all'),
                      value: cv.groupMuted,
                      activeThumbColor: AppColors.sakura,
                      onChanged: (value) async {
                        final err = await context.read<AppState>().setGroupMute(
                          conversationId,
                          muted: value,
                        );
                        if (!context.mounted || err == null) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                      },
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text('成员', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            ...cv.members.map((user) {
              final role = resolveGroupRole(cv, user.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: MochiCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      CuteAvatar(emoji: user.emoji, accentIndex: user.accentIndex, size: 44),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.nickname, style: const TextStyle(fontSize: 16)),
                            Text(user.handle, style: const TextStyle(color: AppColors.inkMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                      _RoleChip(role: role, muted: cv.isMemberMuted(user.id)),
                      if (user.id != meId && _hasMemberActions(actor, role))
                        PopupMenuButton<String>(
                          key: Key('group-member-menu-${user.id}'),
                          onSelected: (action) => _onMemberAction(context, cv, user, action),
                          itemBuilder: (context) => [
                            if (canSetGroupAdmin(actor) && role == GroupRole.member)
                              const PopupMenuItem(value: 'admin', child: Text('设为管理员')),
                            if (canSetGroupAdmin(actor) && role == GroupRole.admin)
                              const PopupMenuItem(value: 'unadmin', child: Text('取消管理员')),
                            if (canMuteGroupMember(actor, role) && !cv.isMemberMuted(user.id))
                              const PopupMenuItem(value: 'mute', child: Text('禁言')),
                            if (canMuteGroupMember(actor, role) && cv.isMemberMuted(user.id))
                              const PopupMenuItem(value: 'unmute', child: Text('解除禁言')),
                            if (canKickGroupMember(actor, role))
                              const PopupMenuItem(value: 'kick', child: Text('移出群聊')),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('leave-group'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.sakura,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => _leave(context, cv),
              child: Text(cv.isOwner(meId) ? '转让群主并退出' : '退出群聊'),
            ),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasMemberActions(GroupRole actor, GroupRole target) {
    return canSetGroupAdmin(actor) ||
        canMuteGroupMember(actor, target) ||
        canKickGroupMember(actor, target);
  }

  Future<void> _onMemberAction(
    BuildContext context,
    Conversation conversation,
    AppUser user,
    String action,
  ) async {
    final state = context.read<AppState>();
    String? err;
    switch (action) {
      case 'admin':
        err = await state.setGroupAdmin(conversation.id, user.id, admin: true);
      case 'unadmin':
        err = await state.setGroupAdmin(conversation.id, user.id, admin: false);
      case 'mute':
        err = await state.setGroupMute(conversation.id, userId: user.id, muted: true);
      case 'unmute':
        err = await state.setGroupMute(conversation.id, userId: user.id, muted: false);
      case 'kick':
        final ok = await _confirm(context, '把 ${user.nickname} 移出群聊？');
        if (!ok) {
          return;
        }
        err = await state.kickGroupMember(conversation.id, user.id);
    }
    if (!context.mounted || err == null) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
  }

  Future<void> _leave(BuildContext context, Conversation conversation) async {
    final ok = await _confirm(
      context,
      conversation.isOwner(context.read<AppState>().currentUserId)
          ? '退出后群主会交给管理员或下一位成员，确定离开？'
          : '确定退出这个群聊？',
    );
    if (!ok || !context.mounted) {
      return;
    }
    final err = await context.read<AppState>().leaveGroup(conversation.id);
    if (!context.mounted) {
      return;
    }
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    Navigator.of(context).pop(true);
  }

  Future<bool> _confirm(BuildContext context, String text) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('再确认一下'),
        content: Text(text),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('再想想')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('确定')),
        ],
      ),
    );
    return result ?? false;
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role, required this.muted});

  final GroupRole role;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final label = switch (role) {
      GroupRole.owner => '群主',
      GroupRole.admin => '管理',
      GroupRole.member => muted ? '禁言' : '成员',
    };
    final color = switch (role) {
      GroupRole.owner => AppColors.sakura,
      GroupRole.admin => AppColors.starPurple,
      GroupRole.member => muted ? AppColors.peach : AppColors.inkMuted,
    };
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11)),
    );
  }
}
