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
}
