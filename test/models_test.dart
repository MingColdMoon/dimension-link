import 'package:dimension_link/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PostCard JSON 按接口文档解析', () {
    final post = Post.fromJson({
      'id': 'p1',
      'author': {
        'id': 'u_sakurai',
        'nickname': '桜井澪',
        'handle': '@mio_cos',
        'bio': 'COSER',
        'signature': '假发',
        'emoji': '🌸',
        'accentIndex': 5,
        'followers': 22100,
        'following': 340,
        'level': 41,
        'badges': ['漫展常驻'],
        'isFollowing': true,
      },
      'content': '漫展返图来啦～',
      'createdAt': '2026-09-08T10:00:00Z',
      'mood': 'excited',
      'circle': {'id': 'c_cos', 'name': 'COSPLAY', 'emoji': '👗'},
      'imageHue': 330,
      'imageTitle': '樱色舞台',
      'likeCount': 3,
      'starCount': 1,
      'commentCount': 2,
      'liked': true,
      'starred': false,
    });

    expect(post.author.nickname, '桜井澪');
    expect(post.author.isFollowing, isTrue);
    expect(post.circle.id, 'c_cos');
    expect(post.mood, MoodTag.excited);
    expect(post.liked, isTrue);
    expect(post.likeCount, 3);
    expect(post.starred, isFalse);
    expect(post.authorId, 'u_sakurai');
    expect(post.circleId, 'c_cos');
  });

  test('extractItems 兼容 data 直接为数组', () {
    final items = extractItems([
      {'id': 'p1', 'content': 'hello'},
    ]);
    expect(items, hasLength(1));
    expect(items.first['id'], 'p1');
    expect(extractItems({'items': [{'id': 'p2'}]}).first['id'], 'p2');
    expect(extractItems({'list': [{'id': 'p3'}]}).first['id'], 'p3');
  });

  test('PostCard 兼容数字字符串、snake_case 与缺少嵌套对象', () {
    final post = Post.fromJson({
      'id': 12,
      'authorId': 'u_sakurai',
      'content': '有返回值就该看见我',
      'created_at': '2026-09-08T10:00:00Z',
      'mood': 'excited',
      'circle_id': 'c_cos',
      'like_count': '3',
      'starCount': 1.0,
      'liked': 1,
      'starred': 'false',
    });
    expect(post.id, '12');
    expect(post.author.id, 'u_sakurai');
    expect(post.circle.id, 'c_cos');
    expect(post.likeCount, 3);
    expect(post.starCount, 1);
    expect(post.liked, isTrue);
    expect(post.starred, isFalse);
    expect(post.content, '有返回值就该看见我');
  });

  test('PostCard 兼容 _id 与 badges 字符串', () {
    final post = Post.fromJson({
      '_id': 'mongo_1',
      'content': '根级字段也能看见',
      'author': {
        'id': 'u1',
        'nickname': '铃',
        'handle': 'suzu',
        'badges': '绘圈新人王,樱花祭签到',
      },
    });
    expect(post.id, 'mongo_1');
    expect(post.author.badges, ['绘圈新人王', '樱花祭签到']);
  });

  test('CommentItem / ConversationItem / CircleItem 按接口文档解析', () {
    final comment = Comment.fromJson({
      'id': 'c1',
      'user': {
        'id': 'u_tsukimi',
        'nickname': '月见黑',
        'handle': '@tsukimi',
        'emoji': '🐈‍⬛',
        'accentIndex': 1,
        'followers': 1,
        'following': 1,
        'level': 1,
        'badges': [],
      },
      'content': '裙撑绝了',
      'createdAt': '2026-09-08T10:20:00Z',
    });
    expect(comment.user.nickname, '月见黑');
    expect(comment.userId, 'u_tsukimi');

    final conversation = Conversation.fromJson({
      'id': 'cv1',
      'peer': {
        'id': 'u_sakurai',
        'nickname': '桜井澪',
        'handle': '@mio_cos',
        'emoji': '🌸',
        'accentIndex': 5,
        'followers': 1,
        'following': 1,
        'level': 1,
        'badges': [],
      },
      'unread': 1,
      'lastMessage': {
        'id': 'm3',
        'senderId': 'u_sakurai',
        'text': '太好了，我在西区 Cos 舞台附近等你。',
        'createdAt': '2026-09-08T13:20:00Z',
      },
    });
    expect(conversation.peerId, 'u_sakurai');
    expect(conversation.lastMessage?.text, contains('西区'));
    expect(conversation.unread, 1);

    final group = Conversation.fromJson({
      'id': 'cvg',
      'kind': 'group',
      'title': '漫展小队',
      'ownerId': 'u_me',
      'members': [
        {'id': 'u_me', 'nickname': '星野铃', 'handle': '@hoshi_suzu', 'emoji': '🎀'},
        {'id': 'u_sakurai', 'nickname': '桜井澪', 'handle': '@mio_cos', 'emoji': '🌸'},
      ],
      'unread': 0,
    });
    expect(group.isGroup, isTrue);
    expect(group.displayName, '漫展小队');
    expect(group.members, hasLength(2));
    expect(group.isOwner('u_me'), isTrue);
    expect(group.canSpeak('u_me'), isTrue);

    final muted = Conversation.fromJson({
      'id': 'cvg2',
      'kind': 'group',
      'title': '禁言测试',
      'ownerId': 'u_me',
      'adminIds': ['u_sakurai'],
      'mutedUserIds': ['u_tsukimi'],
      'groupMuted': true,
      'members': [
        {'id': 'u_me', 'nickname': '星野铃', 'handle': '@hoshi_suzu', 'emoji': '🎀'},
        {'id': 'u_tsukimi', 'nickname': '月见黑', 'handle': '@kuro', 'emoji': '🌙'},
      ],
    });
    expect(muted.canSpeak('u_tsukimi'), isFalse);
    expect(muted.canSpeak('u_sakurai'), isTrue);

    final mutedAdmin = Conversation.fromJson({
      'id': 'cvg3',
      'kind': 'group',
      'title': '禁言管理员',
      'ownerId': 'u_me',
      'adminIds': ['u_sakurai'],
      'mutedUserIds': ['u_sakurai'],
      'groupMuted': false,
      'members': [
        {'id': 'u_me', 'nickname': '星野铃', 'handle': '@hoshi_suzu', 'emoji': '🎀'},
        {'id': 'u_sakurai', 'nickname': '桜井澪', 'handle': '@mio_cos', 'emoji': '🌸'},
      ],
    });
    expect(mutedAdmin.canSpeak('u_sakurai'), isFalse);
    expect(mutedAdmin.canSpeak('u_me'), isTrue);

    final image = ChatMessage.fromJson({
      'id': 'mi',
      'senderId': 'u_me',
      'text': '樱色舞台',
      'kind': 'image',
      'imageUrl': 'illustration:330',
      'createdAt': '2026-09-08T13:20:00Z',
    });
    expect(image.isImage, isTrue);
    expect(image.preview, contains('[图片]'));

    final system = ChatMessage.fromJson({
      'id': 'ms',
      'senderId': 'system',
      'text': '开启了全员禁言',
      'kind': 'system',
      'createdAt': '2026-09-08T13:20:00Z',
    });
    expect(system.isSystem, isTrue);
    expect(system.preview, '开启了全员禁言');

    final circle = Circle.fromJson({
      'id': 'c_doujin',
      'name': '同人创作',
      'emoji': '✒️',
      'desc': '短篇',
      'memberCount': 12840,
      'accentIndex': 1,
      'tags': ['乙女'],
      'joined': true,
    });
    expect(circle.joined, isTrue);
    expect(circle.tags, ['乙女']);
  });

  test('MatchCandidate 按接口文档解析', () {
    final candidate = MatchCandidate.fromJson({
      'user': {
        'id': 'u_yukimi',
        'nickname': '雪见白',
        'handle': '@yukimi_shiro',
        'bio': '水彩插画练习生',
        'signature': '纸面上的雪不会化。',
        'emoji': '❄️',
        'accentIndex': 4,
        'followers': 2100,
        'following': 180,
        'level': 16,
        'badges': ['绘圈同好'],
        'city': '上海',
        'hobbies': ['插画', '同人'],
      },
      'mode': 'nearby',
      'score': 92,
      'distanceKm': '0.5',
      'city': '上海',
      'district': '徐汇',
      'hobbies': ['插画', '水彩', '同人'],
      'sharedHobbies': ['插画', '同人'],
      'reason': '信号几乎叠在一起',
      'online': true,
    });
    expect(candidate.userId, 'u_yukimi');
    expect(candidate.mode, MatchMode.nearby);
    expect(candidate.score, 92);
    expect(candidate.distanceKm, 0.5);
    expect(candidate.sharedHobbies, ['插画', '同人']);
    expect(candidate.online, isTrue);
    expect(candidate.isResonance, isTrue);
    expect(candidate.borderTier, MatchBorderTier.red);
    expect(candidate.distanceLabel, contains('500m'));
    expect(candidate.shortDistanceLabel, '500m');
    expect(MatchBorderTier.fromScore(49), MatchBorderTier.white);
    expect(MatchBorderTier.fromScore(50), MatchBorderTier.purple);
    expect(MatchBorderTier.fromScore(70), MatchBorderTier.gold);
    expect(MatchBorderTier.fromScore(85), MatchBorderTier.red);
  });
}
