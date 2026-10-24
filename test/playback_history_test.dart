import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lemon_js_extensions/lemon_js_extensions.dart';
import 'package:sqlite_async/sqlite_async.dart';
import 'package:mix_music/common/database/app_database.dart';
import 'package:mix_music/common/entity/song.dart';
import 'package:mix_music/common/history/playback_history_store.dart';
import 'package:mix_music/common/history/player_history.dart';
import 'package:mix_music/common/player/player_controller.dart';
import 'package:mix_music/common/plugin/plugin_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late AppDatabase database;
  late PlaybackHistoryStore store;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('mix_history_');
    database = AppDatabase('${directory.path}/test.sqlite');
    store = PlaybackHistoryStore(database);
    await store.ready;
  });
  tearDown(() async {
    await database.dispose();
    await directory.delete(recursive: true);
  });

  Song song(dynamic id, {String plugin = 'test'}) => Song(
    pluginId: plugin,
    id: id,
    title: '歌曲 $id',
    subtitle: '歌手',
    url: 'https://temporary.invalid/audio',
    details: {
      'cookie': 'not-persisted',
      'headers': {'authorization': 'secret'},
    },
    matchedSong: Song(pluginId: 'other', id: 1, title: '匹配源'),
  );

  test('重复播放移到最前，来源与 ID 类型独立，分页与删除', () async {
    await store.add(song(1));
    await store.add(song('1'));
    await store.add(song(1, plugin: 'other'));
    await store.add(song(1));
    final items = await store.list();
    expect(items.length, 3);
    expect(items.first.pluginId, 'test');
    expect(items.first.id, 1);
    expect((await store.list(offset: 1, limit: 1)).single.pluginId, 'other');
    await store.remove(song(1));
    expect((await store.list()).length, 2);
    await store.clear();
    expect(await store.list(), isEmpty);
  });

  test('重开保留 opaque ID，不保存临时地址、凭证或匹配源', () async {
    final id = {
      'mid': 'abc',
      'extra': [1, '2'],
    };
    await store.add(song(id));
    await store.add(
      song({
        'extra': [1, '2'],
        'mid': 'abc',
      }),
    );
    await database.dispose();
    database = AppDatabase('${directory.path}/test.sqlite');
    store = PlaybackHistoryStore(database);
    final restored = (await store.list()).single;
    expect(restored.id, id);
    expect(restored.url, isNull);
    expect(restored.matchedSong, isNull);
    final rows = await database.connection.getAll(
      'SELECT song FROM playback_history',
    );
    expect(rows.single['song'], isNot(contains('not-persisted')));
    expect(rows.single['song'], isNot(contains('temporary.invalid')));
  });

  test('其他功能独立迁移，历史清空不影响其他表', () async {
    await database.migrate('example', [
      SqliteMigration(1, (tx) async {
        await tx.execute('CREATE TABLE example (value TEXT)');
        await tx.execute("INSERT INTO example VALUES ('kept')");
      }),
    ]);
    await store.add(song(1));
    await store.clear();
    expect(
      (await database.connection.get('SELECT value FROM example'))['value'],
      'kept',
    );
    final reopened = PlaybackHistoryStore(database);
    await reopened.ready;
    expect(await reopened.list(), isEmpty);
  });

  test('未播放和暂停不记录，进度前进后记录，移除观察器不影响播放状态', () async {
    final plugins = PluginController(
      store: JsExtensionFileStore(directoryPath: '${directory.path}/plugins'),
      storage: JsMemoryKvStore(),
    );
    await plugins.restored;
    final player = PlayerController(plugins);
    final history = PlayerHistory(player, store);
    try {
      player.song.value = song(1);
      expect(await store.list(), isEmpty);
      player.position.value = const Duration(seconds: 1);
      expect(await store.list(), isEmpty);
      player.playing.value = true;
      player.position.value = const Duration(seconds: 2);
      player.position.value = const Duration(seconds: 3);
      await history.dispose();
      expect((await store.list()).single.id, 1);
      player.song.value = song(2);
      player.position.value = const Duration(seconds: 4);
      expect((await store.list()).single.id, 1);
      expect(player.playing.value, isTrue);
    } finally {
      await player.disposeController();
      await plugins.disposeController();
    }
  });
}
