import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lemon_js_extensions/lemon_js_extensions.dart';
import 'package:mix_music/common/api/music_api.dart';
import 'package:mix_music/common/entity/rank.dart';
import 'package:mix_music/common/plugin/plugin_controller.dart';
import 'package:mix_music/page/rank/rank_controller.dart';

class PendingRanks extends PluginController {
  final requests = <(String, Completer<List<Rank>>)>[];
  @override
  MusicApi music(String pluginId) => PendingRankApi(this, pluginId);
}

class PendingRankApi extends MusicApi {
  PendingRankApi(this.plugins, String pluginId)
    : super(plugins.manager, pluginId);
  final PendingRanks plugins;
  @override
  Future<List<Rank>> rankList() {
    final request = Completer<List<Rank>>();
    plugins.requests.add((pluginId, request));
    return request.future;
  }
}

JsExtensionPackage rankPlugin(String id, {bool supports = true}) =>
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
          'publicExports': [
            'getHome',
            if (supports) 'rankList',
            if (supports) 'artistAlbum',
          ],
        },
      }),
      serviceModules: {
        'main.mjs':
            '''
export function getHome() { return {songs: []}; }
${supports ? "export function rankList() { console.log('rank request'); return [{id: {rank: [1, 'a']}, title: '测试榜单'}]; }\nexport function artistAlbum() { return []; }" : ''}
''',
      },
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'rank groups decode child objects without changing opaque IDs',
    () async {
      for (final field in ['ranks', 'rankList']) {
        final group = Rank.fromJson({
          'pluginId': 'test.group',
          'id': 1,
          'title': '分组',
          field: [
            {
              'id': {'chart': 7, 'period': 'test'},
              'title': '具体榜单',
            },
          ],
        });
        expect(group.isGroup, isTrue);
        expect(group.ranks.single.pluginId, 'test.group');
        expect(group.ranks.single.id, {'chart': 7, 'period': 'test'});
        expect(group.ranks.single.isGroup, isFalse);
        final copy = Rank.fromJson(group.toJson());
        expect(copy.ranks.single.id, group.ranks.single.id);
      }
    },
  );

  test('empty rank groups are not sent to the chart detail interface', () {
    final group = Rank.fromJson({
      'pluginId': 'test',
      'id': 'empty',
      'ranks': [],
    });
    expect(group.isGroup, isTrue);
    expect(group.ranks, isEmpty);
  });

  test('rank sources filter declarations, reuse home data and request only selected source', () async {
    final directory = await Directory.systemTemp.createTemp('mixmusic-ranks-');
    addTearDown(() => directory.delete(recursive: true));
    final plugins = PluginController(
      store: JsExtensionFileStore(directoryPath: directory.path),
      storage: JsMemoryKvStore(),
    );
    addTearDown(plugins.disposeController);
    await plugins.install(rankPlugin('test.first'));
    await plugins.install(rankPlugin('test.second'));
    await plugins.install(rankPlugin('test.unsupported', supports: false));
    expect(plugins.music('test.first').supportsArtistAlbums, isTrue);
    expect(plugins.music('test.unsupported').supportsArtistAlbums, isFalse);
    final controller = RankController(plugins);
    addTearDown(controller.disposeController);
    expect(
      controller.sources.map((entry) => entry.id),
      containsAll(['test.first', 'test.second']),
    );
    expect(controller.sources.length, 2);
    await plugins.selectSource('test.second');
    final cached = Rank(
      pluginId: 'test.second',
      id: {'cached': true},
      title: '首页榜单',
    );
    plugins.sections.value = {
      'ranks': [cached],
    };
    final before = plugins.logs.value.length;
    await controller.initializeSource();
    expect(controller.source.value, 'test.second');
    expect(controller.ranks.value!.single, same(cached));
    expect(plugins.logs.value.length, before);
    await controller.load('test.first');
    expect(controller.ranks.value!.single.pluginId, 'test.first');
    expect(controller.ranks.value!.single.id, {
      'rank': [1, 'a'],
    });
    expect(
      plugins.logs.value
          .skip(before)
          .where((log) => log.message == 'rank request')
          .map((log) => log.pluginId),
      ['test.first'],
    );
    await plugins.setEnabled('test.first', false);
    expect(controller.sources.map((entry) => entry.id), ['test.second']);
    plugins.selectedId.value = 'test.unsupported';
    plugins.sections.value = {};
    final uncached = RankController(plugins);
    addTearDown(uncached.disposeController);
    final requestsBefore = plugins.logs.value.length;
    await uncached.initializeSource();
    expect(uncached.source.value, 'test.second');
    expect(
      plugins.logs.value
          .skip(requestsBefore)
          .where((log) => log.message == 'rank request')
          .map((log) => log.pluginId),
      ['test.second'],
    );
  });

  test(
    'rank switching discards stale results, reports errors and allows retry',
    () async {
      final plugins = PendingRanks();
      addTearDown(plugins.disposeController);
      final controller = RankController(plugins);
      final first = controller.load('first');
      final second = controller.load('second');
      plugins.requests[1].$2.complete([
        Rank(pluginId: 'second', id: 2, title: '新结果'),
      ]);
      await second;
      plugins.requests[0].$2.complete([
        Rank(pluginId: 'first', id: 1, title: '旧结果'),
      ]);
      await first;
      expect(controller.ranks.value!.single.title, '新结果');
      expect(controller.source.value, 'second');
      final failed = controller.load('second');
      plugins.requests[2].$2.completeError(StateError('测试错误'));
      await failed;
      expect(controller.ranks.hasError, isTrue);
      expect(plugins.logs.value.last.message, contains('测试错误'));
      final retry = controller.load('second');
      plugins.requests[3].$2.complete([]);
      await retry;
      expect(controller.ranks.hasError, isFalse);
      expect(controller.ranks.value, isEmpty);
      final pending = controller.load('first');
      await controller.disposeController();
      plugins.requests[4].$2.complete([]);
      await pending;
    },
  );

  test('empty sources do not trigger rank requests', () async {
    final directory = await Directory.systemTemp.createTemp(
      'mixmusic-empty-ranks-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final plugins = PluginController(
      store: JsExtensionFileStore(directoryPath: directory.path),
      storage: JsMemoryKvStore(),
    );
    addTearDown(plugins.disposeController);
    await plugins.install(rankPlugin('test.unsupported', supports: false));
    final controller = RankController(plugins);
    addTearDown(controller.disposeController);
    await controller.initializeSource();
    expect(controller.source.value, isEmpty);
    expect(controller.sources, isEmpty);
  });
}
