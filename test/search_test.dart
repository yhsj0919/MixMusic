import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart' hide SearchController;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lemon_js_extensions/lemon_js_extensions.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';
import 'package:mix_music/common/api/music_api.dart';
import 'package:mix_music/common/entity/song.dart';
import 'package:mix_music/common/player/player_controller.dart';
import 'package:mix_music/common/plugin/plugin_controller.dart';
import 'package:mix_music/page/search/search_controller.dart';
import 'package:mix_music/page/search/search_page.dart';

Future<PluginController> searchPlugin() async {
  final directory = await Directory.systemTemp.createTemp('mixmusic-search-');
  addTearDown(() => directory.delete(recursive: true));
  final plugins = PluginController(
    store: JsExtensionFileStore(directoryPath: directory.path),
    storage: JsMemoryKvStore(),
  );
  await plugins.install(
    JsExtensionPackage(
      manifestSource: jsonEncode({
        'schemaVersion': 2,
        'id': 'test.search',
        'name': '搜索测试音源',
        'description': '合成搜索数据',
        'version': '1.0.0',
        'versionCode': 1,
        'compatibilityCode': 'mixmusic-source-v1',
        'service': {
          'entry': 'main.mjs',
          'contract': 'mixmusic-source/v1',
          'publicExports': [
            'getHome',
            'searchMusic',
            'searchAlbum',
            'searchArtist',
            'searchPlayList',
            'searchMv',
          ],
        },
      }),
      serviceModules: {
        'main.mjs': '''
let failed = false;
export function getHome() { return {songs: []}; }
function resource(keyword, page, kind) {
  console.log(kind);
  return page === 0 ? [{id: {kind, value: 1}, title: keyword + '-' + kind, subTitle: '测试内容'}] : [];
}
export function searchAlbum(keyword, page) { return resource(keyword, page, 'album'); }
export function searchArtist(keyword, page) { return resource(keyword, page, 'artist'); }
export function searchPlayList(keyword, page) { return resource(keyword, page, 'playlist'); }
export function searchMv(keyword, page) { return resource(keyword, page, 'mv'); }
export function searchMusic(keyword, page, size) {
  console.log(JSON.stringify({keyword, page, size}));
  if (keyword === 'error') throw new Error('测试搜索错误');
  if (keyword === 'retry' && page === 1 && !failed) {
    failed = true;
    throw new Error('测试翻页错误');
  }
  if (keyword === 'empty' || page > 1) return [];
  return Array.from({length: page === 0 ? size : 3}, (_, i) => ({
    id: i === 0 ? {page, i} : i === 1 ? i : String(i),
    title: keyword + '-' + (page * size + i),
    subTitle: '测试歌手',
    quality: [{pluginId: 'test.search', title: '标准', quality: 128}]
  }));
}
''',
      },
    ),
  );
  return plugins;
}

class PendingPlugins extends PluginController {
  final pending = <Completer<List<Song>>>[];
  @override
  MusicApi music(String pluginId) => PendingMusic(this, pluginId);
}

class PendingMusic extends MusicApi {
  PendingMusic(this.plugins, String id) : super(plugins.manager, id);
  final PendingPlugins plugins;
  @override
  Future<List<Song>> searchMusic(
    String keyword, [
    int page = 0,
    int size = 20,
  ]) {
    final result = Completer<List<Song>>();
    plugins.pending.add(result);
    return result.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'search pagination, opaque IDs, retry, empty keyword and logs',
    () async {
      final plugins = await searchPlugin();
      addTearDown(plugins.disposeController);
      final controller = SearchController(plugins);
      addTearDown(controller.disposeController);
      await controller.search(' retry ', 'test.search');
      expect(controller.error.value, isEmpty);
      expect(controller.songs.value.length, 20);
      expect(controller.songs.value.first.pluginId, 'test.search');
      expect(controller.songs.value.first.id, {'page': 0, 'i': 0});
      expect(controller.songs.value[1].id, 1);
      expect(controller.songs.value[2].id, '2');
      expect(controller.hasMore.value, isTrue);
      await controller.loadMore();
      expect(controller.error.value, contains('测试翻页错误'));
      expect(controller.songs.value.length, 20);
      expect(controller.page, 1);
      expect(plugins.logs.value.any((log) => log.level == 'error'), isTrue);
      await controller.loadMore();
      expect(controller.error.value, isEmpty);
      expect(controller.songs.value.length, 23);
      expect(controller.hasMore.value, isFalse);
      final count = plugins.logs.value.length;
      await controller.loadMore();
      expect(plugins.logs.value.length, count);
      await controller.search('  ', 'test.search');
      expect(controller.songs.value, isEmpty);
      expect(plugins.logs.value.length, count);
      await controller.search('empty', 'test.search');
      expect(controller.songs.value, isEmpty);
      expect(controller.hasMore.value, isFalse);
      await controller.search('error', 'test.search');
      expect(controller.error.value, contains('测试搜索错误'));
      expect(controller.loading.value, isFalse);
      for (final type in SearchCategory.values.skip(1)) {
        await controller.search('test', 'test.search', type: type);
        expect(controller.error.value, isEmpty);
        expect(controller.items.value.single.pluginId, 'test.search');
        expect(controller.items.value.single.id, isA<Map>());
        expect(controller.songs.value, isEmpty);
        expect(controller.hasMore.value, isFalse);
      }
    },
  );

  test(
    'outdated requests cannot replace a new search or a disposed page',
    () async {
      final plugins = PendingPlugins();
      addTearDown(plugins.disposeController);
      final controller = SearchController(plugins);
      final first = controller.search('old', 'first');
      await controller.loadMore();
      expect(plugins.pending.length, 1);
      final second = controller.search('new', 'second');
      plugins.pending[1].complete([
        Song(pluginId: 'second', id: 2, title: 'new'),
      ]);
      await second;
      plugins.pending[0].complete([
        Song(pluginId: 'first', id: 1, title: 'old'),
      ]);
      await first;
      expect(controller.songs.value.single.title, 'new');
      final third = controller.search('closing', 'second');
      await controller.disposeController();
      plugins.pending[2].complete([]);
      await third;
    },
  );

  testWidgets(
    'typing does not request; submit searches and opens quality choice',
    (tester) async {
      final plugins = (await tester.runAsync(searchPlugin))!;
      await tester.runAsync(() => plugins.restored);
      final container = LxContainer();
      container.put(() => plugins);
      container.put(() => PlayerController(plugins));
      await tester.pumpWidget(
        LxScope(
          container: container,
          disposeContainer: false,
          child: MaterialApp(
            home: HyperDeviceDetector(
              builder: (context, device, child) => HyperTheme(
                data: HyperThemeData.light(),
                child: const SearchPage(),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(() async {});
      await tester.pumpAndSettle();
      expect(
        find.text('输入关键词开始搜索'),
        findsOneWidget,
        reason: tester
            .widgetList<Text>(find.byType(Text))
            .map((text) => text.data)
            .join(' | '),
      );
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pumpAndSettle();
      expect(plugins.logs.value, isEmpty);
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.text('test-0'), findsOneWidget);
      expect(plugins.logs.value.length, 1);
      final header = tester.getRect(find.byType(HyperTextField));
      final sites = tester.getRect(
        find.byKey(const ValueKey('search-sources')),
      );
      final types = tester.getRect(
        find.byKey(const ValueKey('search-categories')),
      );
      expect(find.byType(NestedScrollView), findsNothing);
      expect(
        tester.getTopLeft(find.text('test-0')).dy,
        greaterThanOrEqualTo(types.bottom),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -1800));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(plugins.logs.value.length, 2);
      expect(tester.getRect(find.byType(HyperTextField)), header);
      expect(
        tester.getRect(find.byKey(const ValueKey('search-sources'))),
        sites,
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('search-categories'))),
        types,
      );
      await tester.drag(find.byType(ListView), const Offset(0, 2500));
      await tester.pumpAndSettle();
      await tester.tap(find.text('test-0'));
      await tester.pumpAndSettle();
      expect(find.text('选择音质'), findsOneWidget);
      expect(find.text('标准'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(container.dispose);
    },
  );

  for (final platform in [TargetPlatform.android, TargetPlatform.windows]) {
    testWidgets('search filters layout on $platform', (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      tester.view.physicalSize = platform == TargetPlatform.android
          ? const Size(390, 844)
          : const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final plugins = (await tester.runAsync(searchPlugin))!;
      final container = LxContainer();
      container.put(() => plugins);
      await tester.pumpWidget(
        LxScope(
          container: container,
          disposeContainer: false,
          child: MaterialApp(
            home: HyperDeviceDetector(
              builder: (context, device, child) => HyperTheme(
                data: HyperThemeData.light(),
                child: const SearchPage(),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(() async {});
      await tester.pumpAndSettle();
      final sites = tester.getTopLeft(
        find.byKey(const ValueKey('search-sources')),
      );
      final types = tester.getTopLeft(
        find.byKey(const ValueKey('search-categories')),
      );
      if (platform == TargetPlatform.android) {
        expect(types.dy, greaterThan(sites.dy));
      } else {
        expect(types.dy, sites.dy);
        expect(types.dx, greaterThan(sites.dx));
      }
      await tester.enterText(find.byType(TextField), 'test');
      await tester.tap(find.text('专辑'));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.text('test-album'), findsOneWidget);
      expect(plugins.logs.value.length, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(container.dispose);
      debugDefaultTargetPlatformOverride = null;
    });
  }
}
