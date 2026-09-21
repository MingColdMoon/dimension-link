import 'package:dimension_link/chat/chat_media.dart';
import 'package:dimension_link/chat/group_rules.dart';
import 'package:dimension_link/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

Conversation _group({
  String ownerId = 'u_me',
  List<String> adminIds = const ['u_sakurai'],
  bool groupMuted = false,
  List<String> mutedUserIds = const [],
}) {
  return Conversation(
    id: 'cv_group',
    kind: ConversationKind.group,
    title: '漫展小队',
    ownerId: ownerId,
    adminIds: adminIds,
    groupMuted: groupMuted,
    mutedUserIds: mutedUserIds,
    members: const [],
    peer: AppUser.placeholder('cv_group'),
  );
}

void main() {
  test('全员禁言时管理层仍可发言，管理员被单独禁言后不能发言', () {
    final cv = _group(groupMuted: true, mutedUserIds: ['u_tsukimi']);
    expect(cv.canSpeak('u_me'), isTrue);
    expect(cv.canSpeak('u_sakurai'), isTrue);
    expect(cv.canSpeak('u_tsukimi'), isFalse);
    expect(_group(mutedUserIds: ['u_sakurai']).canSpeak('u_sakurai'), isFalse);
    expect(canToggleGroupMute(GroupRole.admin), isTrue);
    expect(canSetGroupAdmin(GroupRole.admin), isFalse);
    expect(canMuteGroupMember(GroupRole.admin, GroupRole.member), isTrue);
    expect(canMuteGroupMember(GroupRole.admin, GroupRole.owner), isFalse);
  });

  test('群主退群会把位置交给管理员', () {
    expect(
      nextGroupOwner(
        ownerId: 'u_me',
        adminIds: const ['u_sakurai'],
        memberIds: const ['u_me', 'u_sakurai', 'u_tsukimi'],
      ),
      'u_sakurai',
    );
    expect(
      nextGroupOwner(
        ownerId: 'u_me',
        adminIds: const [],
        memberIds: const ['u_me', 'u_tsukimi'],
      ),
      'u_tsukimi',
    );
    expect(
      nextGroupOwner(ownerId: 'u_me', adminIds: const [], memberIds: const ['u_me']),
      isNull,
    );
  });

  test('插画卡地址能解析出色相', () {
    expect(parseIllustrationHue('illustration:330'), 330);
    expect(isIllustrationUrl('illustration:40'), isTrue);
    expect(resolveChatMediaUrl('/uploads/a.jpg', apiBaseUrl: 'http://127.0.0.1:8080/v1'), 'http://127.0.0.1:8080/uploads/a.jpg');
  });
}
