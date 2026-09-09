import 'package:dimension_link/models/models.dart';
import 'package:dimension_link/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('演示账号可以登录并发布、点赞、评论', () async {
    final state = AppState();
    final err = await state.login('星野铃', '123456');
    expect(err, isNull);
    expect(state.isLoggedIn, isTrue);
    expect(state.me.nickname, '星野铃');

    final before = state.posts.length;
    await state.composePost(
      content: '测试动态：今晚也要和星星说晚安。',
      circleId: 'c_art',
      mood: MoodTag.happy,
      imageTitle: '测试配图',
    );
    expect(state.posts.length, before + 1);
    expect(state.posts.first.content, contains('测试动态'));
    expect(state.posts.first.author.id, state.me.id);
    expect(state.posts.first.liked, isFalse);

    final id = state.posts.first.id;
    await state.toggleLike(id);
    expect(state.liked(state.posts.first), isTrue);
    expect(state.posts.first.likeCount, 1);
    await state.addComment(id, '第一条留言');
    expect(state.postById(id).commentCount, 1);
    expect(state.postById(id).comments.first.user.id, state.me.id);
  });

  test('错误口令会被拒绝', () async {
    final state = AppState();
    final err = await state.login('星野铃', 'wrong');
    expect(err, isNotNull);
    expect(state.isLoggedIn, isFalse);
  });

  test('搜索能匹配住民与动态', () async {
    final state = AppState();
    await state.login('星野铃', '123456');
    expect(state.searchUsers('桜井').first.nickname, '桜井澪');
    expect(state.searchPosts('开黑'), isNotEmpty);
  });
}
