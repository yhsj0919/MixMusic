import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lemon_js_extensions/lemon_js_extensions.dart';
import 'package:mix_music/common/api/music_api.dart';
import 'package:mix_music/common/entity/play_list.dart';
import 'package:mix_music/common/entity/album.dart';
import 'package:mix_music/common/entity/artist.dart';
import 'package:mix_music/common/entity/mv.dart';
import 'package:mix_music/common/plugin/plugin_controller.dart';
import 'package:mix_music/page/music_list/music_list_controller.dart';

JsExtensionPackage listPlugin(String id) {
  const methods = [
    'getHome',
    'playList',
    'playListType',
    'albumList',
    'albumType',
    'artistList',
    'artistType',
    'mvList',
    'mvType',
  ];
  return JsExtensionPackage(
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
        'publicExports': methods,
      },
    }),
    serviceModules: {
      'main.mjs': methods
          .map(
            (method) =>
                'export function $method() { return ${method == 'getHome' ? '{songs: []}' : '[]'}; }',
          )
          .join('\n'),
    },
  );
}

class ListApi extends MusicApi {
  ListApi(super.manager, super.pluginId);
  final calls = <(String, Map<String, dynamic>?, int)>[];
  final category = {
    'id': {
      'tags': [7, 'a'],
    },
    'title': '分类',
    'extra': 'keep',
  };
  int categoryCalls = 0;
  bool fail = false;
  Completer<List<PlayList>>? pending;
  List<Map<String, dynamic>> types() {
    categoryCalls++;
    return [
      {
        'id': 'group',
        'title': '分组',
        'subType': [category],
      },
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> playListType() async => types();
  @override
  Future<List<Map<String, dynamic>>> albumType() async => types();
  @override
  Future<List<Map<String, dynamic>>> artistType() async => [
    {
      'id': 'area',
      'independent': true,
      'title': '区域',
      'subType': [
        {'id': 1, 'title': '内地'},
        {'id': 2, 'title': '港台'},
      ],
    },
    {
      'id': 'sex',
      'independent': true,
      'title': '性别',
      'subType': [
        {'id': 0, 'title': '男'},
      ],
    },
  ];
  @override
  Future<List<Artist>> artistList(
    Map<String, dynamic>? category, [
    int page = 0,
    int size = 20,
  ]) async {
    calls.add(('artist', category, page));
    return List.generate(
      page == 0 ? size : 1,
      (i) => Artist(
        pluginId: pluginId,
        id: {'page': page, 'index': i},
        title: '歌手-$i',
      ),
    );
  }

  @override
  Future<List<Map<String, dynamic>>> mvType() async => types();
  @override
  Future<List<PlayList>> playList(
    Map<String, dynamic>? category, [
    int page = 0,
    int size = 20,
  ]) async {
    calls.add(('playlist', category, page));
    final wait = pending;
    pending = null;
    if (wait != null) return wait.future;
    if (fail) throw StateError('测试分页失败');
    return List.generate(
      page == 0 ? size : 2,
      (i) => PlayList(
        pluginId: pluginId,
        id: {'page': page, 'index': i},
        title: '$pluginId-$page-$i',
      ),
    );
  }

  @override
  Future<List<Album>> albumList(
    Map<String, dynamic>? category, [
    int page = 0,
    int size = 20,
  ]) async {
    calls.add(('album', category, page));
    return [
      Album(pluginId: pluginId, id: {'album': 1}, title: '专辑'),
    ];
  }

  @override
  Future<List<Mv>> mvList(
    Map<String, dynamic>? category, [
    int page = 0,
    int size = 20,
  ]) async {
    calls.add(('mv', category, page));
    return [Mv(pluginId: pluginId, id: 'mv', title: 'MV')];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late PluginController plugins;
  late ListApi first, second;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('mixmusic-lists-');
    plugins = PluginController(
      store: JsExtensionFileStore(directoryPath: directory.path),
      storage: JsMemoryKvStore(),
    );
    await plugins.install(listPlugin('test.first'));
    await plugins.install(listPlugin('test.second'));
    first = ListApi(plugins.manager, 'test.first');
    second = ListApi(plugins.manager, 'test.second');
    plugins.builtins.addAll({'test.first': first, 'test.second': second});
  });
  tearDown(() async {
    await plugins.disposeController();
    await directory.delete(recursive: true);
  });

  test(
    'playlist browses all items, sends the original category and paginates',
    () async {
      plugins.selectedId.value = 'test.second';
      final controller = MusicListController(plugins, MusicListKind.playlist);
      addTearDown(controller.disposeController);
      await controller.initializeSource();
      expect(controller.sources.length, 2);
      expect(controller.source.value, 'test.second');
      expect(first.calls, isEmpty);
      expect(controller.state.value.items.length, 20);
      expect(second.categoryCalls, 1);
      await controller.loadMore();
      expect(controller.state.value.items.length, 22);
      expect(controller.state.value.hasMore, isFalse);
      await controller.loadMore();
      expect(second.calls.map((call) => call.$3), [0, 1]);
      await controller.selectCategory(second.category);
      expect(second.calls.last.$2, same(second.category));
      expect(second.calls.last.$3, 0);
      expect(controller.state.value.items.length, 20);
      expect(controller.state.value.items.first.pluginId, 'test.second');
    },
  );

  test(
    'platform tabs retain separate category and pagination states',
    () async {
      final controller = MusicListController(plugins, MusicListKind.playlist);
      addTearDown(controller.disposeController);
      await controller.initializeSource();
      await controller.selectCategory(first.category);
      await controller.loadMore();
      final saved = controller.state.value;
      await controller.selectSource('test.second');
      expect(controller.state.value.items.length, 20);
      expect(controller.state.value.category, isNull);
      final count = first.calls.length;
      await controller.selectSource('test.first');
      expect(controller.state.value, same(saved));
      expect(controller.state.value.items.length, 22);
      expect(controller.state.value.category, same(first.category));
      expect(first.calls.length, count);
    },
  );

  test('changing category ignores an older page result', () async {
    final controller = MusicListController(plugins, MusicListKind.playlist);
    addTearDown(controller.disposeController);
    final pending = first.pending = Completer<List<PlayList>>();
    final initial = controller.initializeSource();
    await Future<void>.delayed(Duration.zero);
    await controller.selectCategory(first.category);
    pending.complete([
      PlayList(pluginId: 'test.first', id: 'old', title: '旧分类'),
    ]);
    await initial;
    expect(controller.state.value.items.length, 20);
    expect(
      controller.state.value.items.any((item) => item.title == '旧分类'),
      isFalse,
    );
    expect(controller.state.value.category, same(first.category));
  });

  test(
    'failed next page retains earlier items and retries the same page',
    () async {
      final controller = MusicListController(plugins, MusicListKind.playlist);
      addTearDown(controller.disposeController);
      await controller.initializeSource();
      first.fail = true;
      await controller.loadMore();
      expect(controller.state.value.items.length, 20);
      expect(controller.state.value.page, 1);
      expect(controller.state.value.error, isNotEmpty);
      first.fail = false;
      await controller.loadMore();
      expect(controller.state.value.items.length, 22);
      expect(first.calls.map((call) => call.$3), [0, 1, 1]);
      expect(controller.state.value.error, isEmpty);
    },
  );

  test(
    'album and MV lists use their own full list and category interfaces',
    () async {
      for (final kind in [MusicListKind.album, MusicListKind.mv]) {
        final controller = MusicListController(plugins, kind);
        await controller.initializeSource();
        expect(first.calls.last.$1, kind.name);
        expect(controller.state.value.items.single.pluginId, 'test.first');
        expect(controller.state.value.categories.single['subType'], [
          first.category,
        ]);
        await controller.disposeController();
      }
    },
  );

  test(
    'artist list supports pagination and combines filter dimensions',
    () async {
      final controller = MusicListController(plugins, MusicListKind.artist);
      addTearDown(controller.disposeController);
      await controller.initializeSource();
      expect(controller.state.value.items.length, 20);
      expect(controller.state.value.items.first, isA<Artist>());
      expect(controller.categoryTitle, '默认分类');
      await controller.loadMore();
      expect(first.calls.last, ('artist', null, 1));
      expect(controller.state.value.items.length, 21);
      expect(controller.state.value.hasMore, isFalse);
      final groups = controller.state.value.categories;
      await controller.selectCategory(
        Map<String, dynamic>.from((groups[0]['subType'] as List).first),
        group: groups[0]['id'],
      );
      expect((first.calls.last.$2!['filters'] as List)[0]['value']['id'], 1);
      expect(controller.categoryTitle, '内地');
      await controller.selectCategory(
        Map<String, dynamic>.from((groups[1]['subType'] as List).first),
        group: groups[1]['id'],
      );
      expect(
        (first.calls.last.$2!['filters'] as List).map(
          (item) => item['value']['id'],
        ),
        [1, 0],
      );
      expect(controller.categoryTitle, '内地 · 男');
      expect(first.calls.last.$3, 0);
      await controller.selectCategory(
        Map<String, dynamic>.from((groups[0]['subType'] as List)[1]),
        group: groups[0]['id'],
      );
      expect(
        (first.calls.last.$2!['filters'] as List).map(
          (item) => item['value']['id'],
        ),
        [2, 0],
      );
      expect(controller.categoryTitle, '港台 · 男');
      final saved = controller.state.value;
      await controller.selectSource('test.second');
      expect(controller.categoryTitle, '默认分类');
      await controller.selectSource('test.first');
      expect(controller.state.value, same(saved));
      expect(controller.categoryTitle, '港台 · 男');
      await controller.selectCategory(null);
      expect(first.calls.last.$2, isNull);
      expect(controller.categoryTitle, '默认分类');
      expect(MusicListKind.artist.route, '/artist');
    },
  );

  test(
    'ordinary artist categories replace each other without rewriting IDs',
    () async {
      final controller = MusicListController(plugins, MusicListKind.artist);
      addTearDown(controller.disposeController);
      await controller.initializeSource();
      final firstCategory = {
        'id': {
          'custom': [1, 'a'],
        },
        'title': '一种分类',
      };
      final nextCategory = {
        'id': {
          'custom': [2, 'b'],
        },
        'title': '另一种分类',
      };
      await controller.selectCategory(firstCategory);
      expect(first.calls.last.$2, same(firstCategory));
      await controller.selectCategory(nextCategory);
      expect(first.calls.last.$2, same(nextCategory));
      expect(controller.categoryTitle, '另一种分类');
      expect(controller.state.value.categories[0]['subType'], [
        {'id': 1, 'title': '内地'},
        {'id': 2, 'title': '港台'},
      ]);
    },
  );

  test('independent filters also work for other lists and preserve object group IDs', () async {
    final controller = MusicListController(plugins, MusicListKind.album);
    addTearDown(controller.disposeController);
    await controller.initializeSource();
    await controller.selectCategory(
      {
        'id': {
          'tag': [1, 'x'],
        },
        'title': '标签',
      },
      group: {
        'dimension': [1, 'x'],
      },
    );
    await controller.selectCategory({'id': 2, 'title': '年份'}, group: 0);
    await controller.selectCategory(
      {
        'id': {
          'tag': [2, 'y'],
        },
        'title': '新标签',
      },
      group: {
        'dimension': [1, 'x'],
      },
    );
    final filters = first.calls.last.$2!['filters'] as List;
    expect(filters.length, 2);
    expect(filters[0]['group'], {
      'dimension': [1, 'x'],
    });
    expect(filters[0]['value']['id'], {
      'tag': [2, 'y'],
    });
    expect(filters[1]['group'], 0);
    expect(controller.categoryTitle, '新标签 · 年份');
  });
}
