import 'package:dimension_link/config/app_config.dart';
import 'package:dimension_link/main.dart';
import 'package:dimension_link/screens/home/home_shell.dart';
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
}
