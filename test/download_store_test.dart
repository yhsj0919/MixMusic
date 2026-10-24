import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lemon_js_extensions/lemon_js_extensions.dart';
import 'package:mix_music/common/database/app_database.dart';
import 'package:mix_music/common/download/download_controller.dart';
import 'package:mix_music/common/download/download_collection.dart';
import 'package:mix_music/common/download/download_store.dart';
import 'package:mix_music/common/entity/music_download.dart';
import 'package:mix_music/common/entity/play_list.dart';
import 'package:mix_music/common/entity/song.dart';
import 'package:mix_music/common/history/playback_history_store.dart';
import 'package:mix_music/common/player/music_cache.dart';
import 'package:mix_music/common/plugin/collection_controller.dart';
import 'package:mix_music/common/plugin/plugin_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late AppDatabase database;
  late DownloadStore store;
  late PluginController plugins;
  late DownloadController controller;

  DownloadController create() =>
      DownloadController(plugins, directory: directory, store: store);
  Song song(dynamic id) => Song(
    pluginId: 'fixture',
    id: id,
    title: '歌曲 $id',
    playQuality: 320,
    url: 'https://temporary.invalid',
    details: {
      'httpHeaders': {'Cookie': 'private-value'},
    },
  );
  MusicDownload task(dynamic id, DownloadState state) {
    final item = song(id);
    return MusicDownload(
        item,
        MusicCache.keyFor(item),
        directory: directory.path,
        folder: '专辑',
        allowMatch: true,
      )
      ..state = state
      ..received = 123
      ..total = 456
      ..path = '${directory.path}/saved.mp3';
  }

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('mix_download_store_');
    database = AppDatabase('${directory.path}/test.sqlite');
    store = DownloadStore(database);
    plugins = PluginController(
      store: JsExtensionFileStore(directoryPath: '${directory.path}/plugins'),
      storage: JsMemoryKvStore(),
    );
    await plugins.restored;
    controller = create();
    await controller.restored;
  });
  tearDown(() async {
    await controller.disposeController();
    await plugins.disposeController();
    await database.dispose();
    await directory.delete(recursive: true);
  });

  Future<void> restart() async {
    await controller.disposeController();
    await database.dispose();
    database = AppDatabase('${directory.path}/test.sqlite');
    store = DownloadStore(database);
    controller = create();
    await controller.restored;
  }

  test('任务状态、质量、动态 ID 与路径重启恢复，不保存临时地址和凭据', () async {
    for (final state in DownloadState.values) {
      controller.hyperQueue.append(
        task({
          'state': state.name,
          'id': [1, '2'],
        }, state),
      );
    }
    await restart();
    expect(controller.tasks.value.length, DownloadState.values.length);
    for (var i = 0; i < DownloadState.values.length; i++) {
      final restored = controller.tasks.value[i];
      final original = DownloadState.values[i];
      expect(
        restored.state,
        [
              DownloadState.complete,
              DownloadState.failed,
              DownloadState.cancelled,
            ].contains(original)
            ? original
            : DownloadState.cancelled,
      );
      expect(restored.song.id, {
        'state': original.name,
        'id': [1, '2'],
      });
      expect(restored.song.playQuality, 320);
      expect(restored.path, '${directory.path}/saved.mp3');
      expect(restored.folder, '专辑');
      expect(restored.allowMatch, isTrue);
      expect(restored.song.url, isNull);
      expect(restored.song.details.containsKey('httpHeaders'), isFalse);
    }
    final rows = await database.connection.getAll(
      'SELECT data FROM download_tasks',
    );
    expect(
      jsonEncode(rows.map((row) => row['data']).toList()),
      isNot(contains('private-value')),
    );
  });

  test('移除与清空记录不删文件，也不影响播放历史', () async {
    final file = File('${directory.path}/saved.mp3');
    await file.writeAsBytes([1, 2, 3]);
    final history = PlaybackHistoryStore(database);
    await history.add(song(1));
    controller.hyperQueue.append(task(1, DownloadState.complete));
    controller.hyperQueue.append(task(2, DownloadState.failed));
    await restart();
    controller.remove(controller.tasks.value.first);
    await restart();
    expect(controller.tasks.value.single.song.id, 2);
    controller.hyperQueue.clear();
    await restart();
    expect(controller.tasks.value, isEmpty);
    expect(await file.readAsBytes(), [1, 2, 3]);
    expect((await PlaybackHistoryStore(database).list()).single.id, 1);
  });

  test('批量队列保留分页、顺序与任务引用，恢复不加载网络', () async {
    final collection = plugins.collection(
      CollectionKind.playlist,
      PlayList(pluginId: 'fixture', id: {'list': 1}, title: '测试歌单'),
    );
    collection.page = 2;
    collection.hasMore.value = true;
    collection.songs.value = [song('A'), song('B')];
    final group = DownloadCollection(
      collection,
      320,
      directory: directory.path,
      grouping: DownloadGrouping.collection,
    );
    addTearDown(group.dispose);
    controller.hyperQueue.appendCollection(group.source);
    group.items.value.first.state = DownloadState.complete;
    group.items.value.last.state = DownloadState.downloading;
    controller.hyperQueue.append(task('tail', DownloadState.failed));
    await restart();
    final restored =
        controller.hyperQueue.roots.value.first.source!.key
            as DownloadCollection;
    expect(restored.collection.page, 2);
    expect(restored.collection.hasMore.value, isTrue);
    expect(restored.grouping, DownloadGrouping.collection);
    expect(controller.hyperQueue.roots.value.first.suspended, isTrue);
    expect(controller.tasks.value.map((task) => task.song.id), [
      'A',
      'B',
      'tail',
    ]);
    expect(
      identical(controller.tasks.value[1], restored.items.value[1]),
      isTrue,
    );
    expect(restored.items.value[0].state, DownloadState.complete);
    expect(restored.items.value[1].state, DownloadState.cancelled);
    expect(
      plugins.logs.value.any((log) => log.message.contains('[RESOLVE]')),
      isFalse,
    );
  });

  test('不可编码的数据不覆盖已有数据库记录', () async {
    controller.hyperQueue.append(task('kept', DownloadState.complete));
    await controller.session!.save();
    await expectLater(
      store.save({
        'queue': {'bad': Object()},
        'tasks': [],
      }),
      throwsA(isA<JsonUnsupportedObjectError>()),
    );
    final saved = await store.load();
    expect((saved!['tasks'] as List).single['song']['id'], 'kept');
  });

  test('损坏的下载记录只报错，不覆盖原数据或影响历史', () async {
    await controller.disposeController();
    await store.save({
      'queue': {
        'roots': [
          {
            'item': {'task': 0},
          },
        ],
        'index': -1,
      },
      'tasks': [
        {'state': 'invalid'},
      ],
    });
    controller = create();
    await controller.restored;
    expect(controller.restoreError.value, isNotEmpty);
    await controller.disposeController();
    expect((await store.load())!['tasks'], [
      {'state': 'invalid'},
    ]);
    final history = PlaybackHistoryStore(database);
    await history.add(song(9));
    expect((await history.list()).single.id, 9);
  });
}
