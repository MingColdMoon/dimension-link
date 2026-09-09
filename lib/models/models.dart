/// 解析接口 ISO-8601 时间。
DateTime parseApiTime(dynamic raw) {
  if (raw is DateTime) {
    return raw.toLocal();
  }
  if (raw is String && raw.isNotEmpty) {
    return DateTime.parse(raw).toLocal();
  }
  return DateTime.now();
}

Map<String, dynamic> asJsonMap(dynamic raw) {
  if (raw is Map<String, dynamic>) {
    return raw;
  }
  if (raw is Map) {
    return Map<String, dynamic>.from(raw);
  }
  return <String, dynamic>{};
}

List<Map<String, dynamic>> asJsonMapList(dynamic raw) {
  if (raw is! List) {
    return const [];
  }
  return [
    for (final item in raw)
      if (item is Map) Map<String, dynamic>.from(item),
  ];
}

enum MoodTag {
  happy('开心', '✿'),
  excited('高能', '✦'),
  sleepy('摸鱼', '☾'),
  love('心动', '♡'),
  sad('破防', '☁'),
  fire('安利', '★');

  const MoodTag(this.label, this.symbol);
  final String label;
  final String symbol;

  /// 接口只传英文 key。
  static MoodTag fromKey(String? key) {
    return MoodTag.values.firstWhere(
      (item) => item.name == key,
      orElse: () => MoodTag.happy,
    );
  }
}

class AppUser {
  const AppUser({
    required this.id,
    required this.nickname,
    required this.handle,
    required this.bio,
    required this.signature,
    required this.emoji,
    required this.accentIndex,
    required this.followers,
    required this.following,
    required this.level,
    required this.badges,
    this.password,
    this.isFollowing = false,
  });

  final String id;
  final String nickname;
  final String handle;
  final String bio;
  final String signature;
  final String emoji;
  final int accentIndex;
  final int followers;
  final int following;
  final int level;
  final List<String> badges;
  final String? password;
  final bool isFollowing;

  /// 从后端 `UserPublic` JSON 构造。
  factory AppUser.fromJson(Map<String, dynamic> json) {
    final handleRaw = (json['handle'] as String? ?? '').trim();
    final handle = handleRaw.startsWith('@') || handleRaw.isEmpty
        ? handleRaw
        : '@$handleRaw';
    return AppUser(
      id: json['id'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      handle: handle,
      bio: json['bio'] as String? ?? '',
      signature: json['signature'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '✨',
      accentIndex: json['accentIndex'] as int? ?? 0,
      followers: json['followers'] as int? ?? 0,
      following: json['following'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      badges: [
        for (final item in json['badges'] as List? ?? const []) item.toString(),
      ],
      isFollowing: json['isFollowing'] as bool? ?? false,
    );
  }

  AppUser copyWith({
    String? nickname,
    String? bio,
    String? signature,
    String? emoji,
    int? followers,
    int? following,
    int? level,
    bool? isFollowing,
  }) {
    return AppUser(
      id: id,
      nickname: nickname ?? this.nickname,
      handle: handle,
      bio: bio ?? this.bio,
      signature: signature ?? this.signature,
      emoji: emoji ?? this.emoji,
      accentIndex: accentIndex,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      level: level ?? this.level,
      badges: badges,
      password: password,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
}

class Comment {
  const Comment({
    required this.id,
    required this.user,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final AppUser user;
  final String content;
  final DateTime createdAt;

  String get userId => user.id;

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String? ?? '',
      user: AppUser.fromJson(asJsonMap(json['user'])),
      content: json['content'] as String? ?? '',
      createdAt: parseApiTime(json['createdAt']),
    );
  }
}

class Circle {
  const Circle({
    required this.id,
    required this.name,
    required this.emoji,
    required this.desc,
    required this.memberCount,
    required this.accentIndex,
    required this.tags,
    this.joined = false,
  });

  final String id;
  final String name;
  final String emoji;
  final String desc;
  final int memberCount;
  final int accentIndex;
  final List<String> tags;
  final bool joined;

  factory Circle.fromJson(Map<String, dynamic> json) {
    return Circle(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '',
      desc: json['desc'] as String? ?? '',
      memberCount: json['memberCount'] as int? ?? 0,
      accentIndex: json['accentIndex'] as int? ?? 0,
      tags: [
        for (final item in json['tags'] as List? ?? const []) item.toString(),
      ],
      joined: json['joined'] as bool? ?? false,
    );
  }

  factory Circle.preview(Map<String, dynamic> json) {
    return Circle(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '',
      desc: '',
      memberCount: 0,
      accentIndex: 0,
      tags: const [],
    );
  }

  Circle copyWith({
    int? memberCount,
    bool? joined,
  }) {
    return Circle(
      id: id,
      name: name,
      emoji: emoji,
      desc: desc,
      memberCount: memberCount ?? this.memberCount,
      accentIndex: accentIndex,
      tags: tags,
      joined: joined ?? this.joined,
    );
  }
}

class Post {
  const Post({
    required this.id,
    required this.author,
    required this.content,
    required this.createdAt,
    required this.mood,
    required this.circle,
    required this.imageHue,
    required this.imageTitle,
    required this.liked,
    required this.starred,
    required this.likeCount,
    required this.starCount,
    required this.commentCount,
    this.comments = const [],
  });

  final String id;
  final AppUser author;
  final String content;
  final DateTime createdAt;
  final MoodTag mood;
  final Circle circle;
  final int imageHue;
  final String imageTitle;
  final bool liked;
  final bool starred;
  final int likeCount;
  final int starCount;
  final int commentCount;
  final List<Comment> comments;

  String get authorId => author.id;
  String get circleId => circle.id;

  factory Post.fromJson(Map<String, dynamic> json) {
    final comments = [
      for (final item in asJsonMapList(json['comments'])) Comment.fromJson(item),
    ];
    return Post(
      id: json['id'] as String? ?? '',
      author: AppUser.fromJson(asJsonMap(json['author'])),
      content: json['content'] as String? ?? '',
      createdAt: parseApiTime(json['createdAt']),
      mood: MoodTag.fromKey(json['mood'] as String?),
      circle: Circle.preview(asJsonMap(json['circle'])),
      imageHue: json['imageHue'] as int? ?? 0,
      imageTitle: json['imageTitle'] as String? ?? '今日速记',
      liked: json['liked'] as bool? ?? false,
      starred: json['starred'] as bool? ?? false,
      likeCount: json['likeCount'] as int? ?? 0,
      starCount: json['starCount'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? comments.length,
      comments: comments,
    );
  }

  Post copyWith({
    AppUser? author,
    Circle? circle,
    bool? liked,
    bool? starred,
    int? likeCount,
    int? starCount,
    int? commentCount,
    List<Comment>? comments,
    String? content,
  }) {
    return Post(
      id: id,
      author: author ?? this.author,
      content: content ?? this.content,
      createdAt: createdAt,
      mood: mood,
      circle: circle ?? this.circle,
      imageHue: imageHue,
      imageTitle: imageTitle,
      liked: liked ?? this.liked,
      starred: starred ?? this.starred,
      likeCount: likeCount ?? this.likeCount,
      starCount: starCount ?? this.starCount,
      commentCount: commentCount ?? this.commentCount,
      comments: comments ?? this.comments,
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String text;
  final DateTime createdAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      text: json['text'] as String? ?? '',
      createdAt: parseApiTime(json['createdAt']),
    );
  }
}

class Conversation {
  const Conversation({
    required this.id,
    required this.peer,
    this.lastMessage,
    this.messages = const [],
    this.unread = 0,
  });

  final String id;
  final AppUser peer;
  final ChatMessage? lastMessage;
  final List<ChatMessage> messages;
  final int unread;

  String get peerId => peer.id;

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final last = json['lastMessage'];
    return Conversation(
      id: json['id'] as String? ?? '',
      peer: AppUser.fromJson(asJsonMap(json['peer'])),
      lastMessage: last is Map ? ChatMessage.fromJson(asJsonMap(last)) : null,
      unread: json['unread'] as int? ?? 0,
    );
  }

  Conversation copyWith({
    AppUser? peer,
    ChatMessage? lastMessage,
    List<ChatMessage>? messages,
    int? unread,
    bool clearLastMessage = false,
  }) {
    return Conversation(
      id: id,
      peer: peer ?? this.peer,
      lastMessage: clearLastMessage ? null : (lastMessage ?? this.lastMessage),
      messages: messages ?? this.messages,
      unread: unread ?? this.unread,
    );
  }
}

class Notice {
  const Notice({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.kind,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final String kind;

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt: parseApiTime(json['createdAt']),
      kind: json['kind'] as String? ?? 'badge',
    );
  }
}

class SearchResult {
  const SearchResult({
    this.users = const [],
    this.circles = const [],
    this.posts = const [],
  });

  final List<AppUser> users;
  final List<Circle> circles;
  final List<Post> posts;

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      users: [for (final item in asJsonMapList(json['users'])) AppUser.fromJson(item)],
      circles: [for (final item in asJsonMapList(json['circles'])) Circle.fromJson(item)],
      posts: [for (final item in asJsonMapList(json['posts'])) Post.fromJson(item)],
    );
  }
}

class MeProfile {
  const MeProfile({
    required this.user,
    this.joinedCircleIds = const [],
  });

  final AppUser user;
  final List<String> joinedCircleIds;

  factory MeProfile.fromJson(Map<String, dynamic> json) {
    return MeProfile(
      user: AppUser.fromJson(json),
      joinedCircleIds: [
        for (final item in json['joinedCircleIds'] as List? ?? const [])
          item.toString(),
      ],
    );
  }
}

class AppUserDummy {
  static const paletteLen = 8;
}
