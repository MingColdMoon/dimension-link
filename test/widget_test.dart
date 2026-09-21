import 'package:dimension_link/config/app_config.dart';
import 'package:dimension_link/main.dart';
import 'package:dimension_link/models/models.dart';
import 'package:dimension_link/screens/home/home_shell.dart';
import 'package:dimension_link/screens/messages/chat_screen.dart';
import 'package:dimension_link/screens/messages/group_settings_screen.dart';
import 'package:dimension_link/screens/messages/start_chat_screen.dart';
import 'package:dimension_link/state/app_state.dart';
import 'package:dimension_link/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('启动页展示应用名', (tester) async {
    await tester.pumpWidget(const DimensionLinkApp());
    expect(find.text('次元链接'), findsOneWidget);
    if (!AppConfig.current.isProduction) {
      expect(find.byType(Banner), findsOneWidget);
      final banner = tester.widget<Banner>(find.byType(Banner));
      expect(banner.message, AppConfig.current.env.bannerLabel);
    } else {
      expect(find.byType(Banner), findsNothing);
    }
    expect(find.byKey(const Key('network-inspector-fab')), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('次元链接'), findsWidgets);
  });

  testWidgets('登录后广场展示动态与发布入口', (tester) async {
    final state = AppState();
    final err = await state.login('星野铃', '123456');
    expect(err, isNull);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const HomeShell(),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('嗨，星野铃'), findsOneWidget);
    expect(find.text('广场'), findsOneWidget);
    expect(find.textContaining('漫展返图'), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome), findsWidgets);
  });

  testWidgets('消息页可以私聊和拉群', (tester) async {
    final state = AppState();
    await state.login('星野铃', '123456');
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const HomeShell(),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('消息'));
    await tester.pump();

    expect(find.byKey(const Key('start-direct-chat')), findsOneWidget);
    expect(find.byKey(const Key('start-group-chat')), findsOneWidget);

    await tester.tap(find.byKey(const Key('start-direct-chat')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('找人聊天'), findsOneWidget);
    expect(find.byType(StartChatScreen), findsOneWidget);
  });

  testWidgets('选人后可以发私信', (tester) async {
    final state = AppState();
    await state.login('星野铃', '123456');
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const StartChatScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('桜井澪'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('start-chat-submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ChatScreen), findsOneWidget);
    expect(find.text('桜井澪'), findsWidgets);
  });

  testWidgets('选两人后可以拉群并进入群聊', (tester) async {
    final state = AppState();
    await state.login('星野铃', '123456');
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const StartChatScreen(groupMode: true),
        ),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField), '测试小队');
    await tester.tap(find.text('月见黑'));
    await tester.pump();
    await tester.tap(find.text('桜井澪'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('start-chat-submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ChatScreen), findsOneWidget);
    expect(find.text('测试小队'), findsWidgets);
    expect(state.conversations.any((item) => item.title == '测试小队' && item.isGroup), isTrue);
    expect(find.textContaining('月见黑'), findsWidgets);
  });

  testWidgets('匹配页能切换推荐并滑走一张卡片', (tester) async {
    final state = AppState();
    await state.login('星野铃', '123456');
    await state.loadMatches();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const HomeShell(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    await tester.tap(find.text('匹配'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.text('次元匹配'), findsOneWidget);
    expect(find.byKey(const Key('match-mode-nearby')), findsOneWidget);
    expect(find.byKey(const Key('match-deck')), findsOneWidget);
    expect(find.byKey(const Key('match-refresh-fab')), findsNothing);
    expect(find.byIcon(Icons.casino_rounded), findsNothing);

    await tester.tap(find.byKey(const Key('match-mode-nearby')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(state.matchMode, MatchMode.nearby);
    expect(find.text('雪见白'), findsWidgets);

    final before = state.matches.length;
    final removed = state.matches.take(3).length;
    await tester.tap(find.byKey(const Key('match-like')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 480));
    expect(state.matches.length, before - removed);
  });

  testWidgets('宽屏模拟器上匹配牌堆仍居中且能看到住民', (tester) async {
    tester.view.physicalSize = const Size(2560, 1200);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState();
    await state.login('星野铃', '123456');
    await state.loadMatches();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const HomeShell(),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('匹配'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byKey(const Key('match-deck')), findsOneWidget);
    expect(find.text('次元匹配'), findsOneWidget);
    expect(find.byKey(const Key('match-like')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('群聊能打开群资料并发插画卡', (tester) async {
    final state = AppState();
    await state.login('星野铃', '123456');
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const ChatScreen(conversationId: 'cv_group'),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('group-settings')), findsOneWidget);

    await tester.tap(find.byKey(const Key('group-settings')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(GroupSettingsScreen), findsOneWidget);
    expect(find.text('群主'), findsWidgets);
    expect(find.text('管理'), findsWidgets);
    expect(find.byKey(const Key('leave-group')), findsOneWidget);

    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byKey(const Key('send-image')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('chat-illustration-330')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(state.conversationById('cv_group').lastMessage?.isImage, isTrue);
    expect(find.text('樱色舞台'), findsWidgets);
  });
}
