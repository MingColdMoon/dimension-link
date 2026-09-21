import '../models/models.dart';

/// 群内角色，与后端 `group.rules` 对齐。
enum GroupRole { owner, admin, member }

GroupRole resolveGroupRole(Conversation conversation, String userId) {
  if (conversation.isOwner(userId)) {
    return GroupRole.owner;
  }
  if (conversation.isAdmin(userId)) {
    return GroupRole.admin;
  }
  return GroupRole.member;
}

bool canSetGroupAdmin(GroupRole actor) => actor == GroupRole.owner;

bool canMuteGroupMember(GroupRole actor, GroupRole target) {
  if (actor == GroupRole.owner) {
    return target != GroupRole.owner;
  }
  if (actor == GroupRole.admin) {
    return target == GroupRole.member;
  }
  return false;
}

bool canKickGroupMember(GroupRole actor, GroupRole target) {
  return canMuteGroupMember(actor, target);
}

bool canToggleGroupMute(GroupRole actor) {
  return actor == GroupRole.owner || actor == GroupRole.admin;
}

/// 群主退群时交给首位管理员，否则下一位成员。
String? nextGroupOwner({
  required String ownerId,
  required List<String> adminIds,
  required List<String> memberIds,
}) {
  final rest = memberIds.where((id) => id != ownerId).toList();
  for (final id in adminIds) {
    if (rest.contains(id)) {
      return id;
    }
  }
  return rest.isEmpty ? null : rest.first;
}
