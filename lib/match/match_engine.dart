import '../data/match_atlas.dart';
import '../models/models.dart';

/// 客户端 AI 推荐：按附近 / 同好 / 默契三种模式给住民打分。
class MatchEngine {
  MatchEngine._();

  /// 会互相加分的爱好组合，模拟「气质互补」。
  static const complementary = <String, List<String>>{
    '插画': ['COS', '同人'],
    '同人': ['番剧', '声优', '插画'],
    'COS': ['插画', '漫展'],
    '番剧': ['同人', '声优'],
    '游戏': ['声优', 'COS'],
    '声优': ['同人', '游戏'],
  };

  static List<MatchCandidate> recommend({
    required AppUser me,
    required List<AppUser> users,
    required MatchMode mode,
    List<Post> posts = const [],
    Set<String> excludedIds = const {},
  }) {
    final mePortrait = MatchAtlas.portraitOf(me);
    final myHobbies = MatchAtlas.inferHobbies(
      me,
      extra: _circleHints(me.id, posts),
    );
    final pool = users.where((user) {
      return user.id != me.id && !excludedIds.contains(user.id);
    });

    final scored = [
      for (final user in pool)
        _score(
          me: me,
          mePortrait: mePortrait,
          myHobbies: myHobbies,
          user: user,
          mode: mode,
          posts: posts,
        ),
    ];

    scored.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) {
        return byScore;
      }
      final aKm = a.distanceKm ?? 9999;
      final bKm = b.distanceKm ?? 9999;
      return aKm.compareTo(bKm);
    });
    return scored;
  }

  static MatchCandidate _score({
    required AppUser me,
    required MatchPortrait mePortrait,
    required List<String> myHobbies,
    required AppUser user,
    required MatchMode mode,
    required List<Post> posts,
  }) {
    final portrait = MatchAtlas.portraitOf(user);
    final hobbies = MatchAtlas.inferHobbies(
      user,
      extra: _circleHints(user.id, posts),
    );
    final shared = myHobbies.where(hobbies.contains).toList();
    final km = MatchAtlas.distanceKm(mePortrait, portrait);
    final circleOverlap = _sharedCircleCount(me.id, user.id, posts);
    final affinity = _affinityScore(
      myHobbies: myHobbies,
      theirHobbies: hobbies,
      shared: shared,
      km: km,
      me: me,
      user: user,
      circleOverlap: circleOverlap,
      online: portrait.online,
    );

    final score = switch (mode) {
      MatchMode.nearby => _nearbyScore(km, portrait.online, shared.length),
      MatchMode.hobby => _hobbyScore(shared, myHobbies, hobbies, circleOverlap),
      MatchMode.affinity => affinity,
    };

    return MatchCandidate(
      user: user,
      mode: mode,
      score: score.clamp(1, 99),
      city: portrait.city,
      district: portrait.district,
      hobbies: hobbies,
      sharedHobbies: shared,
      reason: _reason(
        mode: mode,
        user: user,
        portrait: portrait,
        km: km,
        shared: shared,
        score: score,
      ),
      distanceKm: km,
      online: portrait.online,
    );
  }

  static int _nearbyScore(double km, bool online, int sharedCount) {
    var score = 96 - (km * 1.15);
    if (km > 80) {
      score -= 18;
    }
    if (online) {
      score += 6;
    }
    score += sharedCount * 2;
    return score.round().clamp(8, 99);
  }

  static int _hobbyScore(
    List<String> shared,
    List<String> mine,
    List<String> theirs,
    int circleOverlap,
  ) {
    if (mine.isEmpty && theirs.isEmpty) {
      return 36;
    }
    final union = {...mine, ...theirs}.length;
    final jaccard = union == 0 ? 0.0 : shared.length / union;
    var score = 28 + jaccard * 58 + shared.length * 8 + circleOverlap * 6;
    if (shared.isEmpty) {
      score -= 12;
    }
    return score.round().clamp(12, 99);
  }

  static int _affinityScore({
    required List<String> myHobbies,
    required List<String> theirHobbies,
    required List<String> shared,
    required double km,
    required AppUser me,
    required AppUser user,
    required int circleOverlap,
    required bool online,
  }) {
    final hobby = _hobbyScore(shared, myHobbies, theirHobbies, circleOverlap);
    final near = (100 - km.clamp(0, 80) * 0.7);
    final levelGap = (me.level - user.level).abs();
    final levelScore = (100 - levelGap * 3).clamp(40, 100);
    var complement = 0;
    for (final hobbyName in myHobbies) {
      final partners = complementary[hobbyName] ?? const [];
      if (partners.any(theirHobbies.contains)) {
        complement += 8;
      }
    }
    var social = 0.0;
    if (user.isFollowing) {
      social += 10;
    }
    if (online) {
      social += 6;
    }
    final mixed = hobby * 0.38 + near * 0.22 + levelScore * 0.12 + complement + social;
    return mixed.round().clamp(16, 99);
  }

  static List<String> _circleHints(String userId, List<Post> posts) {
    return [
      for (final post in posts)
        if (post.authorId == userId) post.circle.name,
    ];
  }

  static int _sharedCircleCount(String meId, String otherId, List<Post> posts) {
    final mine = {
      for (final post in posts)
        if (post.authorId == meId) post.circleId,
    };
    final theirs = {
      for (final post in posts)
        if (post.authorId == otherId) post.circleId,
    };
    return mine.intersection(theirs).length;
  }

  static String _reason({
    required MatchMode mode,
    required AppUser user,
    required MatchPortrait portrait,
    required double km,
    required List<String> shared,
    required int score,
  }) {
    final sharedText = shared.take(2).join('、');
    switch (mode) {
      case MatchMode.nearby:
        if (km < 1) {
          return sharedText.isEmpty
              ? '信号几乎叠在一起，${user.nickname} 就在你附近。'
              : '信号几乎叠在一起，你们都爱$sharedText。';
        }
        if (km < 15) {
          return '${portrait.city}${portrait.district}，直线 ${km.toStringAsFixed(1)}km，适合周末偶遇。';
        }
        return '虽然隔了 ${km.toStringAsFixed(0)}km，但 ${portrait.city} 的次元门还开着。';
      case MatchMode.hobby:
        if (shared.isEmpty) {
          return '爱好还没完全对上，但气质很像可以一起挖坑的人。';
        }
        return '共同爱好：$sharedText。AI 觉得你们能聊完整晚。';
      case MatchMode.affinity:
        if (score >= 85) {
          return '次元共振 $score%：${sharedText.isEmpty ? '气质高度吻合' : '因$sharedText紧紧咬合'}。';
        }
        if (shared.isNotEmpty) {
          return '默契指数 $score，先从$sharedText 开始认识吧。';
        }
        return 'AI 把你们编进同一条平行线，默契指数 $score。';
    }
  }
}
