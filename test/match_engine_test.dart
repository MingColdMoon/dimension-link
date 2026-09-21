import 'package:dimension_link/data/match_atlas.dart';
import 'package:dimension_link/data/mock_seed.dart';
import 'package:dimension_link/match/match_engine.dart';
import 'package:dimension_link/models/models.dart';
import 'package:dimension_link/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  AppUser meUser() => MockSeed.users().firstWhere((user) => user.id == MockSeed.meId);

  test('附近推荐把更近的住民排在前面', () {
    final list = MatchEngine.recommend(
      me: meUser(),
      users: MockSeed.users(),
      mode: MatchMode.nearby,
    );
    expect(list, isNotEmpty);
    expect(list.any((item) => item.userId == MockSeed.meId), isFalse);
    expect(list.first.userId, 'u_yukimi');
    expect(list.first.distanceKm, lessThan(1));
    expect(list.first.distanceKm!, lessThan(list.last.distanceKm!));
    expect(list.first.city, '上海');
  });

  test('同好推荐会点亮重叠爱好', () {
    final list = MatchEngine.recommend(
      me: meUser(),
      users: MockSeed.users(),
      mode: MatchMode.hobby,
      posts: MockSeed.posts(),
    );
    final yukimi = list.firstWhere((item) => item.userId == 'u_yukimi');
    expect(yukimi.sharedHobbies, containsAll(['插画', '同人']));
    expect(yukimi.score, greaterThan(60));
    expect(yukimi.reason, contains('共同爱好'));
  });

  test('默契推荐分数落在 1-99 且可排除已读', () {
    final list = MatchEngine.recommend(
      me: meUser(),
      users: MockSeed.users(),
      mode: MatchMode.affinity,
      posts: MockSeed.posts(),
      excludedIds: {'u_yukimi'},
    );
    expect(list.every((item) => item.userId != 'u_yukimi'), isTrue);
    expect(list.every((item) => item.score >= 1 && item.score <= 99), isTrue);
    expect(list.first.mode, MatchMode.affinity);
  });

  test('雪见白与星野铃的直线距离小于一公里', () {
    final a = MatchAtlas.portraitOf(meUser());
    final b = MatchAtlas.portraits['u_yukimi']!;
    expect(MatchAtlas.distanceKm(a, b), lessThan(1));
  });

  test('次元匹配能切换模式、跳过并记录心动', () async {
    final state = AppState();
    await state.login('星野铃', '123456');
    await state.loadMatches();
    expect(state.matches, isNotEmpty);

    await state.setMatchMode(MatchMode.nearby);
    expect(state.matchMode, MatchMode.nearby);
    expect(state.matches.first.userId, 'u_yukimi');

    final skipped = state.matches.first;
    await state.passMatch(skipped.userId);
    expect(state.matches.any((item) => item.userId == skipped.userId), isFalse);

    final liked = await state.likeMatch(state.matches.first.userId);
    expect(liked, isNotNull);
    expect(state.likedMatchIds, contains(liked!.userId));
    expect(state.matches.any((item) => item.userId == liked.userId), isFalse);
  });

  test('可以一次心动当前平铺的三张', () async {
    final state = AppState();
    await state.login('星野铃', '123456');
    await state.loadMatches();
    final batch = state.matches.take(3).toList();
    expect(batch, hasLength(3));
    final liked = await state.likeMatches(batch.map((item) => item.userId));
    expect(liked, hasLength(3));
    expect(state.likedMatchIds, containsAll(batch.map((item) => item.userId)));
    expect(state.matches.any((item) => batch.any((liked) => liked.userId == item.userId)), isFalse);
  });
}
