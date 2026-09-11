import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../data/mock_seed.dart';
import '../models/models.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';

/// 应用全局状态。注入 [ApiClient] 时全部走接口；否则使用与接口同结构的本地 seed。
class AppState extends ChangeNotifier {
  AppState({this._api}) {
    if (_api == null) {
      _users = MockSeed.users();
      _circles = MockSeed.circles();
      _posts = MockSeed.posts();
      _conversations = MockSeed.conversations();
      _notices = MockSeed.notices();
    } else {
      _users = [];
      _circles = [];
      _posts = [];
      _conversations = [];
      _notices = [];
    }
  }

  static const _sessionKey = 'dimension_link_user_id';
  final _uuid = const Uuid();
  final ApiClient? _api;

  List<AppUser> _users = [];
  List<Circle> _circles = [];
  List<Post> _posts = [];
  List<Conversation> _conversations = [];
  List<Notice> _notices = [];
  List<AppUser> _searchUsers = [];
  List<Circle> _searchCircles = [];
  List<Post> _searchPosts = [];

  String? _feedError;
  String? _currentUserId;
  bool _booted = false;
  int _tabIndex = 0;

  String? get feedError => _feedError;
  bool get booted => _booted;
  bool get isLoggedIn => _currentUserId != null;
  int get tabIndex => _tabIndex;
  String? get currentUserId => _currentUserId;

  AppUser get me {
    final id = _currentUserId;
    if (id == null) {
      throw StateError('未登录');
    }
    return userById(id);
  }

  List<AppUser> get users => List.unmodifiable(_users);
  List<Circle> get circles => List.unmodifiable(_circles);
  List<Post> get posts {
    final copy = [..._posts]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return copy;
  }

  List<Conversation> get conversations => List.unmodifiable(_conversations);
  List<Notice> get notices => List.unmodifiable(_notices);
  Set<String> get joinedCircleIds => {
        for (final circle in _circles)
          if (circle.joined) circle.id,
      };
  int get unreadChatCount =>
      _conversations.fold<int>(0, (sum, item) => sum + item.unread);

  List<AppUser> get searchResultUsers => List.unmodifiable(_searchUsers);
  List<Circle> get searchResultCircles => List.unmodifiable(_searchCircles);
  List<Post> get searchResultPosts => List.unmodifiable(_searchPosts);

  AppUser userById(String id) =>
      findUser(id) ?? (throw StateError('找不到住民 $id'));

  Circle circleById(String id) =>
      findCircle(id) ?? (throw StateError('找不到圈子 $id'));

  Post postById(String id) =>
      findPost(id) ?? (throw StateError('找不到动态 $id'));

  Conversation conversationById(String id) =>
      findConversation(id) ?? (throw StateError('找不到会话 $id'));

  AppUser? findUser(String id) {
    for (final user in _users) {
      if (user.id == id) {
        return user;
      }
    }
    return null;
  }

  Circle? findCircle(String id) {
    for (final circle in _circles) {
      if (circle.id == id) {
        return circle;
      }
    }
    return null;
  }

  Post? findPost(String id) {
    for (final post in _posts) {
      if (post.id == id) {
        return post;
      }
    }
    return null;
  }

  Conversation? findConversation(String id) {
    for (final conversation in _conversations) {
      if (conversation.id == id) {
        return conversation;
      }
    }
    return null;
  }

  bool isFollowing(String userId) {
    try {
      return userById(userId).isFollowing;
    } catch (_) {
      return false;
    }
  }

  bool liked(Post post) => post.liked;

  bool starred(Post post) => post.starred;

  List<Post> postsOfUser(String userId) =>
      posts.where((p) => p.authorId == userId).toList();

  List<Post> postsOfCircle(String circleId) =>
      posts.where((p) => p.circleId == circleId).toList();

  List<Post> searchPosts(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return posts;
    }
    return posts.where((p) {
      return p.content.toLowerCase().contains(q) ||
          p.author.nickname.toLowerCase().contains(q) ||
          p.circle.name.toLowerCase().contains(q);
    }).toList();
  }

  List<AppUser> searchUsers(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return _users;
    }
    return _users
        .where(
          (u) =>
              u.nickname.toLowerCase().contains(q) ||
              u.handle.toLowerCase().contains(q) ||
              u.bio.toLowerCase().contains(q),
        )
        .toList();
  }

  List<Circle> searchCircles(String query) {
    final q = query.trim();
    if (q.isEmpty) {
      return _circles;
    }
    return _circles
        .where((c) => c.name.contains(q) || c.desc.contains(q))
        .toList();
  }

  Future<void> restoreSession() async {
    if (_api != null) {
      await _restoreRemoteSession();
    } else {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_sessionKey);
      if (saved != null && _users.any((u) => u.id == saved)) {
        _currentUserId = saved;
      }
    }
    _booted = true;
    notifyListeners();
  }

  Future<void> _restoreRemoteSession() async {
    final api = _api!;
    await api.restoreTokens();
    if (api.accessToken == null || api.accessToken!.isEmpty) {
      return;
    }
    try {
      final me = await api.getMe();
      _applyMe(me);
      await _refreshHome();
    } on ApiException {
      await api.clearTokens();
      _currentUserId = null;
    }
  }

  Future<String?> login(String handleOrName, String password) async {
    if (_api != null) {
      return _loginRemote(handleOrName, password);
    }
    return _loginLocal(handleOrName, password);
  }

  Future<String?> _loginRemote(String handleOrName, String password) async {
    final api = _api!;
    try {
      final session = await api.login(
        identifier: handleOrName.trim(),
        password: password,
      );
      await api.persistSession(session);
      _upsertUser(session.user);
      _currentUserId = session.user.id;
      await _refreshHome();
      notifyListeners();
      return null;
    } on ApiException catch (error) {
      return error.message;
    } catch (_) {
      return '连不上次元服务器，请确认后端已启动，且开发环境地址对本平台有效。';
    }
  }

  Future<String?> _loginLocal(String handleOrName, String password) async {
    final key = handleOrName.trim().replaceFirst('@', '').toLowerCase();
    AppUser? found;
    for (final user in _users) {
      final hit = user.handle.replaceFirst('@', '').toLowerCase() == key ||
          user.nickname.toLowerCase() == key ||
          user.handle.toLowerCase() == '@$key';
      if (hit) {
        found = user;
        break;
      }
    }
    if (found == null) {
      return '找不到这位次元住民';
    }
    if ((found.password ?? '123456') != password) {
      return '通行证口令不对哦';
    }
    await _setSession(found.id);
    return null;
  }

  Future<String?> register({
    required String nickname,
    required String handle,
    required String password,
  }) async {
    if (nickname.trim().length < 2) {
      return '昵称再可爱一点点';
    }
    if (password.length < 4) {
      return '口令至少 4 位';
    }
    if (_api != null) {
      return _registerRemote(
        nickname: nickname,
        handle: handle,
        password: password,
      );
    }
    return _registerLocal(
      nickname: nickname,
      handle: handle,
      password: password,
    );
  }

  Future<String?> _registerRemote({
    required String nickname,
    required String handle,
    required String password,
  }) async {
    final cleaned = handle.trim().replaceFirst('@', '');
    final api = _api!;
    try {
      final session = await api.register(
        nickname: nickname.trim(),
        handle: cleaned,
        password: password,
      );
      await api.persistSession(session);
      _upsertUser(session.user);
      _currentUserId = session.user.id;
      await _refreshHome();
      notifyListeners();
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  Future<String?> _registerLocal({
    required String nickname,
    required String handle,
    required String password,
  }) async {
    var cleaned = handle.trim().replaceFirst('@', '');
    if (cleaned.isEmpty) {
      cleaned = 'user_${_users.length}';
    }
    if (_users.any((u) => u.handle.toLowerCase() == '@${cleaned.toLowerCase()}')) {
      return '这个 @ 已经被占用啦';
    }
    final user = AppUser(
      id: 'u_${_uuid.v4().substring(0, 8)}',
      nickname: nickname.trim(),
      handle: '@$cleaned',
      bio: '刚刚穿越过来的新住民',
      signature: '请多指教～',
      emoji: '✨',
      accentIndex: _users.length % AppUserDummy.paletteLen,
      followers: 0,
      following: 0,
      level: 1,
      badges: const ['初入次元'],
      password: password,
    );
    _users = [..._users, user];
    await _setSession(user.id);
    return null;
  }

  void _applyMe(MeProfile profile) {
    _upsertUser(profile.user);
    _currentUserId = profile.user.id;
    if (_circles.isEmpty && profile.joinedCircleIds.isNotEmpty) {
      _circles = [
        for (final id in profile.joinedCircleIds)
          Circle(
            id: id,
            name: id,
            emoji: '✦',
            desc: '',
            memberCount: 0,
            accentIndex: 0,
            tags: const [],
            joined: true,
          ),
      ];
    }
  }

  void _upsertUser(AppUser user) {
    final index = _users.indexWhere((item) => item.id == user.id);
    if (index < 0) {
      _users = [..._users, user];
      return;
    }
    final copy = [..._users];
    copy[index] = user;
    _users = copy;
  }

  void _upsertCircle(Circle circle) {
    final index = _circles.indexWhere((item) => item.id == circle.id);
    if (index < 0) {
      _circles = [..._circles, circle];
      return;
    }
    final existing = _circles[index];
    // PostCard 里的 circle 只有预览字段，不能覆盖完整圈子。
    if (circle.desc.isEmpty && existing.desc.isNotEmpty) {
      return;
    }
    final copy = [..._circles];
    copy[index] = circle;
    _circles = copy;
  }

  void _upsertPost(Post post) {
    _upsertUser(post.author);
    _upsertCircle(post.circle);
    for (final comment in post.comments) {
      _upsertUser(comment.user);
    }
    final index = _posts.indexWhere((item) => item.id == post.id);
    if (index < 0) {
      _posts = [post, ..._posts];
      return;
    }
    final copy = [..._posts];
    copy[index] = post;
    _posts = copy;
  }

  void _upsertConversation(Conversation conversation) {
    if (!conversation.isGroup) {
      _upsertUser(conversation.peer);
    }
    for (final member in conversation.members) {
      _upsertUser(member);
    }
    final index = _conversations.indexWhere((item) => item.id == conversation.id);
    if (index < 0) {
      _conversations = [conversation, ..._conversations];
      return;
    }
    final existing = _conversations[index];
    final copy = [..._conversations];
    copy[index] = conversation.copyWith(
      messages: conversation.messages.isEmpty ? existing.messages : conversation.messages,
    );
    _conversations = copy;
  }

  Future<void> _refreshHome() async {
    final api = _api;
    if (api == null) {
      return;
    }
    _feedError = null;
    try {
      final posts = await api.listPosts();
      _posts = [];
      for (final post in posts) {
        _upsertPost(post);
      }
      if (posts.isEmpty) {
        _feedError = '广场还没有动态';
      }
    } catch (error) {
      debugPrint('加载动态失败: $error');
      _feedError = '动态加载失败，打开「网络」看看 /posts 响应';
    }
    try {
      _circles = await api.listCircles();
    } catch (error) {
      debugPrint('加载圈子失败: $error');
    }
    try {
      _conversations = await api.listConversations();
      for (final conversation in _conversations) {
        _upsertUser(conversation.peer);
      }
    } catch (error) {
      debugPrint('加载私信失败: $error');
    }
    try {
      _notices = await api.listNotices();
    } catch (error) {
      debugPrint('加载通知失败: $error');
    }
  }

  Future<void> logout({bool notifyRemote = true}) async {
    final api = _api;
    if (api != null) {
      if (notifyRemote) {
        try {
          await api.logoutRemote();
        } on ApiException {
          // 本地仍退出。
        }
      }
      await api.clearTokens();
      _users = [];
      _circles = [];
      _posts = [];
      _conversations = [];
      _notices = [];
      _feedError = null;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    _currentUserId = null;
    notifyListeners();
  }

  Future<void> _setSession(String id) async {
    _currentUserId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, id);
    notifyListeners();
  }

  void setTab(int index) {
    if (_tabIndex == index) {
      return;
    }
    _tabIndex = index;
    notifyListeners();
  }

  Future<void> toggleLike(String postId) async {
    final api = _api;
    if (api != null) {
      try {
        final result = await api.toggleLike(postId);
        _replacePost(
          postId,
          (post) => post.copyWith(liked: result.liked, likeCount: result.likeCount),
        );
      } on ApiException {
        return;
      }
      notifyListeners();
      return;
    }
    _replacePost(postId, (post) {
      final liked = !post.liked;
      return post.copyWith(
        liked: liked,
        likeCount: post.likeCount + (liked ? 1 : -1),
      );
    });
    notifyListeners();
  }

  Future<void> toggleStar(String postId) async {
    final api = _api;
    if (api != null) {
      try {
        final result = await api.toggleStar(postId);
        _replacePost(
          postId,
          (post) => post.copyWith(starred: result.starred, starCount: result.starCount),
        );
      } on ApiException {
        return;
      }
      notifyListeners();
      return;
    }
    _replacePost(postId, (post) {
      final starred = !post.starred;
      return post.copyWith(
        starred: starred,
        starCount: post.starCount + (starred ? 1 : -1),
      );
    });
    notifyListeners();
  }

  Future<String?> addComment(String postId, String content) async {
    final text = content.trim();
    if (text.isEmpty) {
      return '先写点什么再发布吧';
    }
    final api = _api;
    if (api != null) {
      try {
        final comment = await api.createComment(postId, text);
        _upsertUser(comment.user);
        _replacePost(
          postId,
          (post) => post.copyWith(
            comments: [...post.comments, comment],
            commentCount: post.commentCount + 1,
          ),
        );
        notifyListeners();
        return null;
      } on ApiException catch (error) {
        return error.message;
      }
    }
    final meId = _currentUserId;
    if (meId == null) {
      return '请先登录';
    }
    _replacePost(postId, (post) {
      return post.copyWith(
        comments: [
          ...post.comments,
          Comment(
            id: _uuid.v4(),
            user: userById(meId),
            content: text,
            createdAt: DateTime.now(),
          ),
        ],
        commentCount: post.commentCount + 1,
      );
    });
    notifyListeners();
    return null;
  }

  Future<String?> composePost({
    required String content,
    required String circleId,
    required MoodTag mood,
    required String imageTitle,
  }) async {
    final text = content.trim();
    if (text.isEmpty) {
      return '先写点什么再发布吧';
    }
    final api = _api;
    if (api != null) {
      try {
        final post = await api.createPost(
          content: text,
          circleId: circleId,
          mood: mood.name,
          imageTitle: imageTitle.trim(),
        );
        _upsertPost(post);
        notifyListeners();
        return null;
      } on ApiException catch (error) {
        return error.message;
      }
    }
    final meId = _currentUserId;
    if (meId == null) {
      return '请先登录';
    }
    _posts = [
      Post(
        id: _uuid.v4(),
        author: userById(meId),
        content: text,
        createdAt: DateTime.now(),
        mood: mood,
        circle: circleById(circleId),
        imageHue: DateTime.now().millisecond % 360,
        imageTitle: imageTitle.trim().isEmpty ? '今日速记' : imageTitle.trim(),
        liked: false,
        starred: false,
        likeCount: 0,
        starCount: 0,
        commentCount: 0,
      ),
      ..._posts,
    ];
    notifyListeners();
    return null;
  }

  Future<String?> toggleFollow(String userId) async {
    final meId = _currentUserId;
    if (meId == null || userId == meId) {
      return '不能关注自己';
    }
    final api = _api;
    if (api != null) {
      try {
        final result = await api.toggleFollow(userId);
        final existing = findUser(userId) ?? AppUser.placeholder(userId);
        _upsertUser(
          existing.copyWith(
            isFollowing: result.isFollowing,
            followers: result.followers,
          ),
        );
        notifyListeners();
        return null;
      } on ApiException catch (error) {
        return error.message;
      }
    }
    final following = isFollowing(userId);
    _users = _users.map((user) {
      if (user.id == userId) {
        return user.copyWith(
          isFollowing: !following,
          followers: user.followers + (following ? -1 : 1),
        );
      }
      if (user.id == meId) {
        return user.copyWith(following: user.following + (following ? -1 : 1));
      }
      return user;
    }).toList();
    notifyListeners();
    return null;
  }

  Future<void> toggleJoinCircle(String circleId) async {
    final api = _api;
    if (api != null) {
      try {
        final result = await api.toggleJoinCircle(circleId);
        final existing = findCircle(circleId) ?? Circle.preview(circleId);
        _upsertCircle(
          existing.copyWith(
            joined: result.joined,
            memberCount: result.memberCount,
          ),
        );
      } on ApiException {
        return;
      }
      notifyListeners();
      return;
    }
    final circle = circleById(circleId);
    _upsertCircle(
      circle.copyWith(
        joined: !circle.joined,
        memberCount: circle.memberCount + (circle.joined ? -1 : 1),
      ),
    );
    notifyListeners();
  }

  Future<String?> sendMessage(String conversationId, String text) async {
    final body = text.trim();
    if (body.isEmpty) {
      return '先写点什么再发布吧';
    }
    final api = _api;
    if (api != null) {
      try {
        final message = await api.sendMessage(conversationId, body);
        _conversations = _conversations.map((item) {
          if (item.id != conversationId) {
            return item;
          }
          return item.copyWith(
            unread: 0,
            lastMessage: message,
            messages: [...item.messages, message],
          );
        }).toList();
        notifyListeners();
        return null;
      } on ApiException catch (error) {
        return error.message;
      }
    }
    final meId = _currentUserId;
    if (meId == null) {
      return '请先登录';
    }
    final message = ChatMessage(
      id: _uuid.v4(),
      senderId: meId,
      text: body,
      createdAt: DateTime.now(),
    );
    _conversations = _conversations.map((item) {
      if (item.id != conversationId) {
        return item;
      }
      return item.copyWith(
        unread: 0,
        lastMessage: message,
        messages: [...item.messages, message],
      );
    }).toList();
    notifyListeners();
    return null;
  }

  Future<void> markConversationRead(String conversationId) async {
    final api = _api;
    if (api != null) {
      try {
        final unread = await api.markConversationRead(conversationId);
        _conversations = _conversations.map((item) {
          if (item.id != conversationId) {
            return item;
          }
          return item.copyWith(unread: unread);
        }).toList();
      } on ApiException {
        return;
      }
      notifyListeners();
      return;
    }
    _conversations = _conversations.map((item) {
      if (item.id != conversationId) {
        return item;
      }
      return item.copyWith(unread: 0);
    }).toList();
    notifyListeners();
  }

  Future<String?> updateProfile({
    required String nickname,
    required String bio,
    required String signature,
  }) async {
    final api = _api;
    if (api != null) {
      try {
        final user = await api.updateMe(
          nickname: nickname.trim(),
          bio: bio.trim(),
          signature: signature.trim(),
        );
        _upsertUser(user);
        notifyListeners();
        return null;
      } on ApiException catch (error) {
        return error.message;
      }
    }
    final meId = _currentUserId;
    if (meId == null) {
      return '请先登录';
    }
    _users = _users.map((user) {
      if (user.id != meId) {
        return user;
      }
      return user.copyWith(
        nickname: nickname.trim(),
        bio: bio.trim(),
        signature: signature.trim(),
      );
    }).toList();
    notifyListeners();
    return null;
  }

  Future<Conversation> ensureConversation(String peerId) async {
    final api = _api;
    if (api != null) {
      final conversation = await api.createConversation(peerId);
      _upsertConversation(conversation);
      notifyListeners();
      return findConversation(conversation.id) ?? conversation;
    }
    final existing = _conversations.where((item) => !item.isGroup && item.peerId == peerId);
    if (existing.isNotEmpty) {
      return existing.first;
    }
    final created = Conversation(
      id: _uuid.v4(),
      peer: userById(peerId),
    );
    _conversations = [created, ..._conversations];
    notifyListeners();
    return created;
  }

  Future<String?> createGroupChat({
    required List<String> memberIds,
    String title = '',
  }) async {
    final unique = [...{...memberIds.where((id) => id != _currentUserId)}];
    if (unique.length < 2) {
      return '拉群至少再邀请两位住民';
    }
    final api = _api;
    if (api != null) {
      try {
        final conversation = await api.createGroup(memberIds: unique, title: title);
        _upsertConversation(conversation);
        notifyListeners();
        return null;
      } on ApiException catch (error) {
        return error.message;
      }
    }
    final meId = _currentUserId;
    if (meId == null) {
      return '请先登录';
    }
    final members = [userById(meId), ...unique.map(userById)];
    final name = title.trim().isEmpty
        ? members.take(3).map((user) => user.nickname).join('、')
        : title.trim();
    final created = Conversation(
      id: _uuid.v4(),
      kind: ConversationKind.group,
      title: name,
      ownerId: meId,
      members: members,
      peer: AppUser(
        id: 'group_${members.length}',
        nickname: name,
        handle: '@group',
        bio: '',
        signature: '',
        emoji: '🪐',
        accentIndex: 6,
        followers: 0,
        following: 0,
        level: 1,
        badges: const ['群聊'],
      ),
    );
    _conversations = [created, ..._conversations];
    notifyListeners();
    return null;
  }

  Conversation? lastCreatedConversation() => _conversations.isEmpty ? null : _conversations.first;

  Future<void> loadPostDetail(String postId) async {
    final api = _api;
    if (api == null) {
      return;
    }
    try {
      final post = await api.getPost(postId);
      final comments = await api.listComments(postId);
      _upsertPost(post.copyWith(comments: comments, commentCount: comments.length));
      notifyListeners();
    } on ApiException {
      return;
    }
  }

  Future<void> loadUserProfile(String userId) async {
    final api = _api;
    if (api == null) {
      return;
    }
    try {
      final user = await api.getUser(userId);
      _upsertUser(user);
      final posts = await api.listPosts(authorId: userId);
      for (final post in posts) {
        _upsertPost(post);
      }
      notifyListeners();
    } on ApiException {
      return;
    }
  }

  Future<void> loadCircleDetail(String circleId) async {
    final api = _api;
    if (api == null) {
      return;
    }
    try {
      final circle = await api.getCircle(circleId);
      _upsertCircle(circle);
      final posts = await api.listPosts(circleId: circleId);
      for (final post in posts) {
        _upsertPost(post);
      }
      notifyListeners();
    } on ApiException {
      return;
    }
  }

  Future<void> loadConversationMessages(String conversationId) async {
    final api = _api;
    if (api == null) {
      return;
    }
    try {
      final messages = await api.listMessages(conversationId);
      _conversations = _conversations.map((item) {
        if (item.id != conversationId) {
          return item;
        }
        return item.copyWith(
          messages: messages,
          lastMessage: messages.isEmpty ? item.lastMessage : messages.last,
        );
      }).toList();
      notifyListeners();
    } on ApiException {
      return;
    }
  }

  Future<void> runSearch(String query) async {
    final api = _api;
    if (api == null) {
      _searchUsers = searchUsers(query);
      _searchCircles = searchCircles(query);
      _searchPosts = searchPosts(query);
      notifyListeners();
      return;
    }
    try {
      final result = await api.search(query);
      _searchUsers = result.users;
      _searchCircles = result.circles;
      _searchPosts = result.posts;
      for (final user in result.users) {
        _upsertUser(user);
      }
      for (final circle in result.circles) {
        _upsertCircle(circle);
      }
      for (final post in result.posts) {
        _upsertPost(post);
      }
      notifyListeners();
    } on ApiException {
      return;
    }
  }

  void _replacePost(String postId, Post Function(Post post) update) {
    _posts = [
      for (final post in _posts)
        if (post.id == postId) update(post) else post,
    ];
  }
}
