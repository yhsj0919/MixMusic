import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:mix_music/main.dart';
import 'package:lemon_x/lemon_x.dart';
import 'package:mix_music/common/plugin/plugin_controller.dart';

void main() {
  testWidgets('plugin action can first be read inside Obx', (tester) async {
    final plugins = (await tester.runAsync(() async => PluginController()))!;
    await tester.pumpWidget(
      MaterialApp(
        home: Obx(() => Text(plugins.action.isLoading ? '处理中' : '可安装')),
      ),
    );
    expect(find.text('可安装'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(plugins.disposeController);
  });

  for (final (size, platform) in [
    (const Size(390, 844), TargetPlatform.android),
    (const Size(800, 1280), TargetPlatform.android),
    (const Size(1280, 800), TargetPlatform.android),
    (const Size(1280, 800), TargetPlatform.windows),
    (const Size(500, 800), TargetPlatform.windows),
  ]) {
    testWidgets('navigation and theme at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MainApp());
      await tester.pumpAndSettle();
      expect(find.text('推荐'), findsWidgets);
      final desktop = platform == TargetPlatform.windows;
      final tabletPlayer =
          platform == TargetPlatform.android &&
          size.width > size.height &&
          size.shortestSide >= 600;
      expect(
        find.byType(HyperSidebar),
        desktop ? findsOneWidget : findsNothing,
      );
      expect(
        find.text('选择歌曲后显示封面与歌词'),
        tabletPlayer ? findsOneWidget : findsNothing,
      );
      expect(
        find.text('选择歌曲开始播放'),
        tabletPlayer ? findsNothing : findsOneWidget,
      );
      await tester.tap(
        find.descendant(
          of: find.byType(HyperButton),
          matching: find.text('设置'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('深色模式'), findsOneWidget);
      await tester.tap(find.byType(HyperSwitch));
      await tester.pumpAndSettle();
      expect(
        tester.widget<HyperSwitch>(find.byType(HyperSwitch)).value,
        isTrue,
      );
      final context = tester.element(find.text('深色模式'));
      expect(HyperTheme.of(context).colors.brightness, Brightness.dark);
      final plugins = context.lx.find<PluginController>();
      plugins.addLog('test', 'error', '测试错误');
      await tester.ensureVisible(find.text('插件日志'));
      await tester.tap(find.text('插件日志'));
      await tester.pumpAndSettle();
      expect(find.byType(HyperDialog), findsOneWidget);
      expect(find.textContaining('测试错误'), findsOneWidget);
      await tester.tap(find.text('清空'));
      await tester.pumpAndSettle();
      expect(find.text('暂无日志'), findsOneWidget);
      await tester.tap(find.text('关闭'));
      await tester.pumpAndSettle();
      GoRouter.of(context)
          .go('/settings/extensions/ui?plugin=missing&route=test');
      await tester.pumpAndSettle();
      expect(find.text('插件页面'), findsOneWidget);
      final back = find.byKey(ValueKey(desktop ? 'desktop-back' : 'page-back'));
      await tester.tap(back);
      await tester.pumpAndSettle();
      expect(find.text('插件管理'), findsWidgets);
      await tester.tap(back);
      await tester.pumpAndSettle();
      expect(find.text('深色模式'), findsOneWidget);
      expect(find.text('返回'), findsNothing);
      expect(
        find.byKey(const ValueKey('desktop-back')),
        desktop ? findsOneWidget : findsNothing,
      );
      expect(
        find.byKey(const ValueKey('page-back')),
        desktop ? findsNothing : findsOneWidget,
      );
      await tester.tap(
        find.byKey(ValueKey(desktop ? 'desktop-back' : 'page-back')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(HyperSwitch), findsNothing);
      expect(find.byType(HyperResult), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      debugDefaultTargetPlatformOverride = null;
    });
  }
}
