/// 解析接口 ISO-8601 时间。
DateTime parseApiTime(dynamic raw) {
  if (raw is DateTime) {
    return raw.toLocal();
  }
  if (raw is String && raw.isNotEmpty) {
    return DateTime.tryParse(raw)?.toLocal() ?? DateTime.now();
  }
  if (raw is num) {
    final value = raw.toInt();
    if (value > 1000000000000) {
      return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true).toLocal();
    }
    if (value > 1000000000) {
      return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true).toLocal();
    }
  }
  return DateTime.now();
}

int asInt(dynamic raw, [int fallback = 0]) {
  if (raw is int) {
    return raw;
  }
  if (raw is num) {
    return raw.toInt();
  }
  if (raw is String) {
    return int.tryParse(raw) ?? fallback;
  }
  return fallback;
}

bool asBool(dynamic raw, [bool fallback = false]) {
  if (raw is bool) {
    return raw;
  }
  if (raw is num) {
    return raw != 0;
  }
  if (raw is String) {
    switch (raw.trim().toLowerCase()) {
      case 'true':
      case '1':
      case 'yes':
        return true;
      case 'false':
      case '0':
      case 'no':
        return false;
    }
  }
  return fallback;
}

String asString(dynamic raw, [String fallback = '']) {
  if (raw == null) {
    return fallback;
  }
  return raw.toString();
}

double asDouble(dynamic raw, [double fallback = 0]) {
  if (raw is double) {
    return raw;
  }
  if (raw is num) {
    return raw.toDouble();
  }
  if (raw is String) {
    return double.tryParse(raw) ?? fallback;
  }
  return fallback;
}

/// 兼容数组、逗号分隔字符串，避免 `badges`/`tags` 类型不对导致整条动态解析失败。
List<String> asStringList(dynamic raw) {
  if (raw is List) {
    return [for (final item in raw) item.toString()];
  }
  if (raw is String && raw.trim().isNotEmpty) {
    return raw
        .split(RegExp(r'[,，]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
  return const [];
}

dynamic pick(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key) && json[key] != null) {
      return json[key];
    }
  }
  return null;
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

/// 兼容 `data.items` / `data` 直接为数组 / `list` / `records` 等常见列表包法。
List<Map<String, dynamic>> extractItems(dynamic data) {
  if (data is List) {
    return asJsonMapList(data);
  }
  if (data is Map) {
    final map = asJsonMap(data);
    for (final key in ['items', 'list', 'records', 'posts', 'rows', 'content', 'data']) {
      if (map[key] is List) {
        return asJsonMapList(map[key]);
      }
    }
  }
  return const [];
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
    this.city = '',
    this.district = '',
    this.hobbies = const [],
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
  final String city;
  final String district;
  final List<String> hobbies;

  /// 从后端 `UserPublic` JSON 构造。
  factory AppUser.placeholder(String id) {
    return AppUser(
      id: id,
      nickname: '次元住民',
      handle: '@user',
      bio: '',
      signature: '',
      emoji: '✨',
      accentIndex: 0,
      followers: 0,
      following: 0,
      level: 1,
      badges: const [],
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final handleRaw = asString(json['handle']).trim();
    final handle = handleRaw.startsWith('@') || handleRaw.isEmpty
        ? handleRaw
        : '@$handleRaw';
    return AppUser(
      id: asString(json['id']),
      nickname: asString(json['nickname']),
      handle: handle,
      bio: asString(json['bio']),
      signature: asString(json['signature']),
      emoji: asString(json['emoji'], '✨'),
      accentIndex: asInt(pick(json, ['accentIndex', 'accent_index'])),
      followers: asInt(json['followers']),
      following: asInt(json['following']),
      level: asInt(json['level'], 1),
      badges: asStringList(json['badges']),
      isFollowing: asBool(pick(json, ['isFollowing', 'is_following'])),
      city: asString(json['city']),
      district: asString(json['district']),
      hobbies: asStringList(json['hobbies']),
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
    String? city,
    String? district,
    List<String>? hobbies,
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
      city: city ?? this.city,
      district: district ?? this.district,
      hobbies: hobbies ?? this.hobbies,
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
      id: asString(json['id']),
      user: json['user'] is Map
          ? AppUser.fromJson(asJsonMap(json['user']))
          : AppUser.placeholder(asString(pick(json, ['userId', 'user_id']))),
      content: asString(json['content']),
      createdAt: parseApiTime(pick(json, ['createdAt', 'created_at'])),
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
      id: asString(json['id']),
      name: asString(json['name']),
      emoji: asString(json['emoji']),
      desc: asString(pick(json, ['desc', 'description'])),
      memberCount: asInt(pick(json, ['memberCount', 'member_count'])),
      accentIndex: asInt(pick(json, ['accentIndex', 'accent_index'])),
      tags: asStringList(json['tags']),
      joined: asBool(json['joined']),
    );
  }

  factory Circle.preview(dynamic raw, {String? fallbackId}) {
    if (raw is Map) {
      final json = asJsonMap(raw);
      return Circle(
        id: asString(json['id'], fallbackId ?? ''),
        name: asString(json['name'], '圈子'),
        emoji: asString(json['emoji'], '✦'),
        desc: '',
        memberCount: 0,
        accentIndex: 0,
        tags: const [],
      );
    }
    final id = asString(raw, fallbackId ?? '');
    return Circle(
      id: id,
      name: '圈子',
      emoji: '✦',
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
    final authorRaw = json['author'] ?? json['user'];
    final author = authorRaw is Map
        ? AppUser.fromJson(asJsonMap(authorRaw))
        : AppUser.placeholder(asString(pick(json, ['authorId', 'author_id', 'userId']), 'unknown'));
    final circleId = asString(pick(json, ['circleId', 'circle_id']));
    return Post(
      id: asString(pick(json, ['id', '_id'])),
      author: author,
      content: asString(pick(json, ['content', 'text', 'body'])),
      createdAt: parseApiTime(pick(json, ['createdAt', 'created_at'])),
      mood: MoodTag.fromKey(asString(json['mood'], 'happy')),
      circle: Circle.preview(json['circle'], fallbackId: circleId),
      imageHue: asInt(pick(json, ['imageHue', 'image_hue'])),
      imageTitle: asString(pick(json, ['imageTitle', 'image_title']), '今日速记'),
      liked: asBool(json['liked']),
      starred: asBool(json['starred']),
      likeCount: asInt(pick(json, ['likeCount', 'like_count'])),
      starCount: asInt(pick(json, ['starCount', 'star_count'])),
      commentCount: asInt(pick(json, ['commentCount', 'comment_count']), comments.length),
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

enum MessageKind {
  text,
  image,
  system;

  static MessageKind fromKey(String? key) {
    return switch (key) {
      'image' => MessageKind.image,
      'system' => MessageKind.system,
      _ => MessageKind.text,
    };
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.kind = MessageKind.text,
    this.imageUrl = '',
  });

  final String id;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final MessageKind kind;
  final String imageUrl;

  bool get isImage => kind == MessageKind.image && imageUrl.isNotEmpty;
  bool get isSystem => kind == MessageKind.system || senderId == 'system';

  String get preview {
    if (isSystem) {
      return text;
    }
    if (isImage) {
      return text.isEmpty || text == '[图片]' ? '[图片]' : '[图片] $text';
    }
    return text;
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: asString(json['id']),
      senderId: asString(pick(json, ['senderId', 'sender_id'])),
      text: asString(pick(json, ['text', 'content'])),
      createdAt: parseApiTime(pick(json, ['createdAt', 'created_at'])),
      kind: MessageKind.fromKey(asString(json['kind'], 'text')),
      imageUrl: asString(pick(json, ['imageUrl', 'image_url'])),
    );
  }
}

enum ConversationKind {
  direct,
  group;

  static ConversationKind fromKey(String? key) {
    return key == 'group' ? ConversationKind.group : ConversationKind.direct;
  }
}

class Conversation {
  const Conversation({
    required this.id,
    required this.peer,
    this.kind = ConversationKind.direct,
    this.title = '',
    this.ownerId,
    this.members = const [],
    this.adminIds = const [],
    this.mutedUserIds = const [],
    this.groupMuted = false,
    this.lastMessage,
    this.messages = const [],
    this.unread = 0,
  });

  final String id;
  final ConversationKind kind;
  final String title;
  final String? ownerId;
  final List<AppUser> members;
  final List<String> adminIds;
  final List<String> mutedUserIds;
  final bool groupMuted;
  final AppUser peer;
  final ChatMessage? lastMessage;
  final List<ChatMessage> messages;
  final int unread;

  bool get isGroup => kind == ConversationKind.group;

  bool isOwner(String? userId) => userId != null && ownerId == userId;

  bool isAdmin(String? userId) => userId != null && adminIds.contains(userId);

  bool canManage(String? userId) => isOwner(userId) || isAdmin(userId);

  bool isMemberMuted(String? userId) => userId != null && mutedUserIds.contains(userId);

  bool canSpeak(String? userId) {
    if (!isGroup || userId == null) {
      return true;
    }
    if (isOwner(userId)) {
      return true;
    }
    if (isMemberMuted(userId)) {
      return false;
    }
    if (isAdmin(userId)) {
      return true;
    }
    return !groupMuted;
  }

  String get peerId => peer.id;
  String get displayName => isGroup
      ? (title.trim().isEmpty ? '群聊' : title.trim())
      : peer.nickname;
  String get displayEmoji => isGroup ? '🪐' : peer.emoji;
  int get displayAccent => isGroup ? 6 : peer.accentIndex;

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final last = json['lastMessage'];
    final kind = ConversationKind.fromKey(asString(json['kind']));
    final title = asString(json['title']);
    final members = [
      for (final item in asJsonMapList(json['members'])) AppUser.fromJson(item),
    ];
    final peer = json['peer'] is Map
        ? AppUser.fromJson(asJsonMap(json['peer']))
        : kind == ConversationKind.group
            ? AppUser(
                id: asString(json['id']),
                nickname: title.trim().isEmpty ? '群聊' : title.trim(),
                handle: '@group',
                bio: '',
                signature: '',
                emoji: '🪐',
                accentIndex: 6,
                followers: 0,
                following: 0,
                level: 1,
                badges: const ['群聊'],
              )
            : AppUser.placeholder(asString(pick(json, ['peerId', 'peer_id'])));
    return Conversation(
      id: asString(json['id']),
      kind: kind,
      title: title,
      ownerId: asString(pick(json, ['ownerId', 'owner_id'])).isEmpty
          ? null
          : asString(pick(json, ['ownerId', 'owner_id'])),
      members: members,
      adminIds: asStringList(pick(json, ['adminIds', 'admin_ids'])),
      mutedUserIds: asStringList(pick(json, ['mutedUserIds', 'muted_user_ids'])),
      groupMuted: asBool(pick(json, ['groupMuted', 'group_muted'])),
      peer: peer,
      lastMessage: last is Map ? ChatMessage.fromJson(asJsonMap(last)) : null,
      unread: asInt(json['unread']),
    );
  }

  Conversation copyWith({
    AppUser? peer,
    ConversationKind? kind,
    String? title,
    String? ownerId,
    List<AppUser>? members,
    List<String>? adminIds,
    List<String>? mutedUserIds,
    bool? groupMuted,
    ChatMessage? lastMessage,
    List<ChatMessage>? messages,
    int? unread,
    bool clearLastMessage = false,
  }) {
    return Conversation(
      id: id,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      ownerId: ownerId ?? this.ownerId,
      members: members ?? this.members,
      adminIds: adminIds ?? this.adminIds,
      mutedUserIds: mutedUserIds ?? this.mutedUserIds,
      groupMuted: groupMuted ?? this.groupMuted,
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
      id: asString(json['id']),
      title: asString(json['title']),
      body: asString(json['body']),
      createdAt: parseApiTime(pick(json, ['createdAt', 'created_at'])),
      kind: asString(json['kind'], 'badge'),
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
      joinedCircleIds: asStringList(
        pick(json, ['joinedCircleIds', 'joined_circle_ids']),
      ),
    );
  }
}

/// 次元匹配推荐模式。
enum MatchMode {
  nearby('nearby', '附近', '把同一座城市的次元信号拉近'),
  hobby('hobby', '同好', '爱好重叠的人会被点亮'),
  affinity('affinity', '默契', 'AI 综合气质、圈子与互动做推荐');

  const MatchMode(this.key, this.label, this.hint);
  final String key;
  final String label;
  final String hint;

  static MatchMode fromKey(String? key) {
    return MatchMode.values.firstWhere(
      (item) => item.key == key || item.name == key,
      orElse: () => MatchMode.affinity,
    );
  }
}

/// 匹配分对应的卡片边框档位，分数越高越亮。
enum MatchBorderTier {
  white,
  purple,
  gold,
  red;

  static MatchBorderTier fromScore(int score) {
    if (score >= 85) {
      return MatchBorderTier.red;
    }
    if (score >= 70) {
      return MatchBorderTier.gold;
    }
    if (score >= 50) {
      return MatchBorderTier.purple;
    }
    return MatchBorderTier.white;
  }
}

/// AI / 服务端返回的一位推荐住民。
class MatchCandidate {
  const MatchCandidate({
    required this.user,
    required this.mode,
    required this.score,
    required this.city,
    required this.district,
    required this.hobbies,
    required this.sharedHobbies,
    required this.reason,
    this.distanceKm,
    this.online = false,
  });

  final AppUser user;
  final MatchMode mode;
  final int score;
  final String city;
  final String district;
  final List<String> hobbies;
  final List<String> sharedHobbies;
  final String reason;
  final double? distanceKm;
  final bool online;

  String get userId => user.id;

  bool get isResonance => score >= 80;

  MatchBorderTier get borderTier => MatchBorderTier.fromScore(score);

  String get placeLabel {
    final districtText = district.trim();
    if (districtText.isEmpty) {
      return city;
    }
    return '$city · $districtText';
  }

  String get distanceLabel {
    final km = distanceKm;
    if (km == null) {
      return placeLabel;
    }
    if (km < 0.1) {
      return '就在你身边 · $placeLabel';
    }
    if (km < 1) {
      return '${(km * 1000).round()}m · $placeLabel';
    }
    return '${km.toStringAsFixed(km < 10 ? 1 : 0)}km · $placeLabel';
  }

  /// 窄卡上只留距离或区名，避免竖排换行。
  String get shortDistanceLabel {
    final km = distanceKm;
    if (km == null) {
      final districtText = district.trim();
      return districtText.isEmpty ? city : districtText;
    }
    if (km < 0.1) {
      return '身边';
    }
    if (km < 1) {
      return '${(km * 1000).round()}m';
    }
    return '${km.toStringAsFixed(km < 10 ? 1 : 0)}km';
  }

  factory MatchCandidate.fromJson(Map<String, dynamic> json) {
    final userRaw = json['user'];
    return MatchCandidate(
      user: userRaw is Map
          ? AppUser.fromJson(asJsonMap(userRaw))
          : AppUser.placeholder(asString(pick(json, ['userId', 'user_id']))),
      mode: MatchMode.fromKey(asString(json['mode'], 'affinity')),
      score: asInt(json['score']),
      city: asString(json['city']),
      district: asString(json['district']),
      hobbies: asStringList(json['hobbies']),
      sharedHobbies: asStringList(pick(json, ['sharedHobbies', 'shared_hobbies'])),
      reason: asString(pick(json, ['reason', 'prompt'])),
      distanceKm: json.containsKey('distanceKm') || json.containsKey('distance_km')
          ? asDouble(pick(json, ['distanceKm', 'distance_km']))
          : null,
      online: asBool(json['online']),
    );
  }
}

class AppUserDummy {
  static const paletteLen = 8;
}
