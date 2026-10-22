import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lemon_js_extensions/lemon_js_extensions.dart';
import 'package:mix_music/common/plugin/collection_controller.dart';
import 'package:mix_music/common/plugin/plugin_controller.dart';
import 'package:mix_music/page/recommend/recommend_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PluginController plugins;
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('mixmusic-recommend-');
    plugins = PluginController(
      store: JsExtensionFileStore(directoryPath: directory.path),
      storage: JsMemoryKvStore(),
    );
    for (final id in ['test.first', 'test.second']) {
      await plugins.install(
        JsExtensionPackage(
          manifestSource: jsonEncode({
            'schemaVersion': 2,
            'id': id,
            'name': id,
            'description': '合成数据',
            'version': '1.0.0',
            'versionCode': 1,
            'compatibilityCode': 'mixmusic-source-v1',
            'service': {
              'entry': 'main.mjs',
              'contract': 'mixmusic-source/v1',
              'publicExports': ['getHome', 'recommendInfo'],
            },
          }),
          serviceModules: {
            'main.mjs':
                '''
let fail = true;
export function getHome() { return {songs: []}; }
export function recommendInfo(page, size) {
  console.log(JSON.stringify({page, size}));
  if ('$id' === 'test.second' && fail) { fail = false; throw new Error('插件自定义异常'); }
  return {id: {daily: 7}, title: '每日推荐', total: 21, hasMore: page === 0,
    songs: Array.from({length: page === 0 ? size : 1}, (_, i) => ({id: {page, index: i}, title: '歌曲'}))};
}
''',
          },
        ),
      );
    }
  });
  tearDown(() async {
    await plugins.disposeController();
    await directory.delete(recursive: true);
  });

  test(
    'daily recommendation is typed, paginated and retains each platform',
    () async {
      final controller = RecommendController(plugins);
      addTearDown(controller.disposeController);
      await controller.initializeSource();
      final first = controller.current.value!;
      expect(first.kind, CollectionKind.recommend);
      expect(first.songs.value.length, 20);
      expect(first.info.value.id, {'daily': 7});
      expect(first.songs.value.first.id, {'page': 0, 'index': 0});
      expect(first.songs.value.first.pluginId, 'test.first');
      final request = jsonDecode(plugins.logs.value.last.message);
      expect(request, {'page': 0, 'size': 20});
      await first.loadMore();
      expect(first.songs.value.length, 21);
      expect(first.hasMore.value, isFalse);
      await controller.selectSource('test.second');
      expect(controller.current.value, isNot(same(first)));
      await controller.selectSource('test.first');
      expect(controller.current.value, same(first));
      expect(first.songs.value.length, 21);
      await controller.refresh();
      expect(first.songs.value.length, 20);
      expect(first.page, 1);
    },
  );

  test('plugin error reaches collection and logs unchanged, retry stays on page zero', () async {
    plugins.selectedId.value = 'test.second';
    final controller = RecommendController(plugins);
    addTearDown(controller.disposeController);
    await controller.initializeSource();
    final collection = controller.current.value!;
    expect(collection.error.value, contains('插件自定义异常'));
    expect(collection.page, 0);
    expect(plugins.logs.value.last.message, contains('插件自定义异常'));
    await collection.loadMore();
    expect(collection.error.value, isEmpty);
    expect(collection.songs.value.length, 20);
    expect(collection.page, 1);
  });
}
