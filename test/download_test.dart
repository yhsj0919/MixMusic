import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lemon_js_extensions/lemon_js_extensions.dart';
import 'package:mix_music/common/api/music_api.dart';
import 'package:mix_music/common/download/download_controller.dart';
import 'package:mix_music/common/entity/music_download.dart';
import 'package:mix_music/common/entity/song.dart';
import 'package:mix_music/common/plugin/plugin_controller.dart';
import 'package:mix_music/common/plugin/collection_controller.dart';
import 'package:mix_music/common/entity/play_list.dart';
import 'package:mix_music/common/entity/quality.dart';
import 'package:mix_music/common/download/download_collection.dart';
import 'package:mix_music/common/entity/album.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mix_music/common/database/app_database.dart';
import 'package:mix_music/common/download/download_store.dart';

class DownloadApi extends MusicApi {
  DownloadApi(
    JsExtensionManager manager,
    this.port, {
    String plugin = 'test.download',
  }) : super(manager, plugin);
  bool unavailable = false;
  List<Song> candidates = [];

  @override
  Future<List<Song>> searchMusic(
    String keyword, [
    int page = 0,
    int size = 20,
  ]) async => candidates;
  final int port;
  final calls = <dynamic>[];
  final requestedQualities = <int?>[];
  Completer<void>? gate;
  final pageCalls = <(String, int)>[];
  final badPages = <(String, int)>{};
  final pageFailures = <(String, int), int>{};

  @override
  Future<PlayList> playListInfo(
    PlayList item, [
    int page = 0,
    int size = 20,
  ]) async {
    final key = (item.id as String, page);
    pageCalls.add(key);
    final remaining = pageFailures[key] ?? 0;
    if (remaining > 0) pageFailures[key] = remaining - 1;
    if (remaining > 0 || badPages.contains(key)) throw StateError('测试分页失败');
    return PlayList.fromJson({
      ...item.toJson(),
      'total': 2,
      'hasMore': page == 0,
      'songs': [
        {
          'pluginId': pluginId,
          'id': '${item.id}-$page',
          'title': '${item.id}-$page',
        },
      ],
    });
  }

  @override
  Future<Song> playUrl(Song song) async {
    calls.add(song.id);
    requestedQualities.add(song.playQuality);
    if (unavailable) throw StateError('测试无地址');
    await gate?.future;
    return Song.fromJson(song.toJson())
      ..url =
          'http://127.0.0.1:$port/audio?secret=${calls.length}&track=${Uri.encodeComponent('${song.id}')}'
      ..details = {
        'httpHeaders': {'X-Test': 'private'},
      };
  }
}

Future<void> until(bool Function() condition) async {
  final limit = DateTime.now().add(const Duration(seconds: 5));
  while (!condition()) {
    if (DateTime.now().isAfter(limit)) throw StateError('等待下载状态超时');
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  late Directory directory;
  late HttpServer server;
  late PluginController plugins;
  late DownloadController controller;
  late DownloadApi api;
  late int status;
  late String mime;
  late int requests;
  final badTracks = <String>{};
  final bytes = List.generate(1024, (i) => i % 256);

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'mixmusic-download-test-',
    );
    status = 200;
    mime = 'audio/mpeg';
    requests = 0;
    badTracks.clear();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      requests++;
      expect(request.headers.value('X-Test'), 'private');
      request.response.statusCode =
          badTracks.contains(request.uri.queryParameters['track'])
          ? 503
          : status;
      request.response.headers.set('Content-Type', mime);
      request.response.contentLength = bytes.length;
      request.response.add(bytes);
      await request.response.close();
    });
    plugins = PluginController();
    api = DownloadApi(plugins.manager, server.port);
    plugins.builtins['test.download'] = api;
    controller = DownloadController(
      plugins,
      directory: directory,
      retryDelay: const Duration(milliseconds: 10),
    );
  });
  tearDown(() async {
    api.gate?.complete();
    await controller.disposeController();
    await plugins.disposeController();
    await server.close(force: true);
    await directory.delete(recursive: true);
  });
  Song song(dynamic id) => Song(
    pluginId: 'test.download',
    id: id,
    title: '../test:name',
    playQuality: 128,
  );

  CollectionController collection(String id) {
    final result = CollectionController(
      api,
      CollectionKind.playlist,
      PlayList.fromJson({'pluginId': 'test.download', 'id': id, 'title': id}),
      (_, _) {},
    );
    addTearDown(result.dispose);
    return result;
  }

  test('persistent retry resolves fresh URL; completed record survives and does not redownload', () async {
    await controller.disposeController();
    final database = AppDatabase('${directory.path}/downloads.sqlite');
    final store = DownloadStore(database);
    DownloadController create() => DownloadController(
      plugins,
      directory: directory,
      store: store,
      retryCount: 0,
    );
    try {
      controller = create();
      await controller.restored;
      status = 503;
      final first = controller.add(song('persistent'));
      await until(() => first.state == DownloadState.failed);
      expect(api.calls.length, 1);
      await controller.disposeController();
      controller = create();
      await controller.restored;
      expect(api.calls.length, 1);
      expect(controller.tasks.value.single.state, DownloadState.failed);
      status = 200;
      final resumed = controller.tasks.value.single;
      controller.retry(resumed);
      await until(() => resumed.state == DownloadState.complete);
      expect(api.calls.length, 2);
      final path = resumed.path;
      final count = requests;
      await controller.disposeController();
      controller = create();
      await controller.restored;
      final completed = controller.tasks.value.single;
      expect(completed.path, path);
      expect(completed.state, DownloadState.complete);
      expect(identical(controller.add(song('persistent')), completed), isTrue);
      expect(requests, count);
      controller.remove(completed);
      final again = controller.add(song('persistent'));
      await until(() => again.state == DownloadState.complete);
      expect(File(again.path!).absolute.uri, File(path!).absolute.uri);
      expect(requests, count);
      expect(api.calls.length, 2);
    } finally {
      await controller.disposeController();
      await database.dispose();
      controller = DownloadController(plugins, directory: directory);
    }
  });

  test(
    'persistent batch resumes at the next page only after manual retry',
    () async {
      await controller.disposeController();
      final database = AppDatabase('${directory.path}/batch.sqlite');
      final store = DownloadStore(database);
      DownloadController create() =>
          DownloadController(plugins, directory: directory, store: store);
      try {
        controller = create();
        await controller.restored;
        final source = collection('A');
        source.page = 1;
        source.hasMore.value = true;
        source.songs.value = [song('A-0')];
        final group = DownloadCollection(
          source,
          320,
          directory: directory.path,
        );
        addTearDown(group.dispose);
        controller.hyperQueue.appendCollection(group.source);
        group.items.value.single.state = DownloadState.complete;
        await controller.disposeController();
        controller = create();
        await controller.restored;
        expect(api.calls, isEmpty);
        expect(api.pageCalls, isEmpty);
        final resumed =
            controller.hyperQueue.roots.value.single.source!.key
                as DownloadCollection;
        controller.retryCollection(resumed);
        await until(
          () =>
              controller.tasks.value.length == 2 &&
              controller.tasks.value.last.state == DownloadState.complete,
        );
        expect(api.calls, ['A-1']);
        expect(api.pageCalls, [('A', 1)]);
        expect(controller.tasks.value.map((task) => task.song.id), [
          'A-0',
          'A-1',
        ]);
        expect(resumed.items.value.last, same(controller.tasks.value.last));
      } finally {
        await controller.disposeController();
        await database.dispose();
        controller = DownloadController(plugins, directory: directory);
      }
    },
  );

  test('viewing loads metadata ahead of a blocked download without resolving more URLs', () async {
    api.gate = Completer<void>();
    final a = collection('A');
    controller.addCollection(a);
    controller.addCollection(collection('B'));
    await until(() => api.calls.isNotEmpty);
    expect(api.calls, ['A-0']);
    final viewing = controller.loadMore();
    final samePage = controller.loadMore();
    await Future.wait([viewing, samePage]);
    expect(api.pageCalls, [('A', 0), ('A', 1)]);
    expect(controller.tasks.value.map((task) => task.song.id), ['A-0', 'A-1']);
    await controller.loadMore();
    expect(api.pageCalls.last, ('B', 0));
    expect(controller.tasks.value.map((task) => task.song.id), [
      'A-0',
      'A-1',
      'B-0',
    ]);
    expect(api.calls, ['A-0']);
    expect(requests, 0);
    expect(
      plugins.logs.value.any((log) => log.message.contains('[VIEW_PAGE]')),
      isTrue,
    );
  });

  test('viewing a later group does not change execution order', () async {
    api.gate = Completer<void>();
    controller.addCollection(collection('A'));
    controller.addCollection(collection('B'));
    await until(() => api.calls.isNotEmpty);
    final b = controller.hyperQueue.roots.value.last.source!.key;
    await controller.loadMore(key: b);
    expect(api.pageCalls, [('A', 0), ('B', 0)]);
    expect(api.calls, ['A-0']);
    final gate = api.gate!;
    api.gate = null;
    gate.complete();
    await until(
      () =>
          controller.tasks.value.length == 4 &&
          controller.tasks.value.every(
            (task) => task.state == DownloadState.complete,
          ),
    );
    expect(api.calls, ['A-0', 'A-1', 'B-0', 'B-1']);
    expect(api.pageCalls.where((call) => call == ('B', 0)).length, 1);
  });

  test('viewing skips cancelled groups and does not automatically retry failed pages', () async {
    api.gate = Completer<void>();
    controller.addCollection(collection('A'));
    controller.addCollection(collection('B'));
    await until(() => api.calls.isNotEmpty);
    api.badPages.add(('A', 1));
    await controller.loadMore();
    final attempts = api.pageCalls.where((call) => call == ('A', 1)).length;
    await controller.loadMore();
    expect(api.pageCalls.where((call) => call == ('A', 1)).length, attempts);
    final b = controller.hyperQueue.roots.value.last.source!.key;
    controller.cancelCollection(b);
    await controller.loadMore(key: b);
    expect(api.pageCalls.where((call) => call == ('B', 1)), isEmpty);
  });

  test('batch quality choices reuse loaded songs without requests', () async {
    final a = collection('A');
    a.songs.value = [
      song(1)
        ..qualities = [
          Quality(pluginId: 'test.download', id: 1, title: '标准', value: 128),
          Quality(pluginId: 'test.download', id: 1, title: '高品质', value: 320),
        ],
      song(2)
        ..qualities = [
          Quality(pluginId: 'test.download', id: 2, title: '标准', value: 128),
        ],
    ];
    expect(controller.qualities(a).map((item) => item.value), [128, 320]);
    expect(api.pageCalls, isEmpty);
    expect(api.calls, isEmpty);
  });

  test(
    'batch selection applies to every page and completion keeps group headers',
    () async {
      controller.addCollection(collection('A'), quality: 320);
      await until(
        () =>
            controller.tasks.value.length == 2 &&
            controller.tasks.value.every(
              (task) => task.state == DownloadState.complete,
            ),
      );
      expect(api.requestedQualities, [320, 320]);
      final rows = controller.entries;
      expect(rows.length, 3);
      final group = rows.first.source!.key as DownloadCollection;
      expect(rows.skip(1).map((entry) => entry.item!.song.id), ['A-0', 'A-1']);
      expect(controller.collectionStatus(group), contains('完成 2 / 2'));
      expect(
        controller.hyperQueue.entries.value.where(
          (entry) => entry.source != null,
        ),
        isEmpty,
      );
    },
  );

  test(
    'batch deduplicates same quality but keeps different qualities separate',
    () async {
      final a = collection('A');
      api.gate = Completer<void>();
      controller.addCollection(a, quality: 320);
      controller.addCollection(a, quality: 320);
      controller.addCollection(a, quality: 128);
      expect(controller.hyperQueue.roots.value.length, 2);
      await until(() => api.calls.isNotEmpty);
      expect(api.pageCalls, [('A', 0)]);
      final gate = api.gate!;
      api.gate = null;
      gate.complete();
      await until(
        () =>
            controller.tasks.value.length == 4 &&
            controller.tasks.value.every(
              (task) => task.state == DownloadState.complete,
            ),
      );
      expect(api.requestedQualities, [320, 320, 128, 128]);
      expect(
        controller.entries.where((entry) => entry.source != null).length,
        2,
      );
    },
  );

  test('cancel A during resolution preserves B and single task order without fetching A next page', () async {
    api.gate = Completer<void>();
    final a = collection('A');
    controller.addCollection(a);
    controller.addCollection(collection('B'));
    final single = controller.add(song('single'));
    await until(() => api.calls.isNotEmpty);
    expect(api.pageCalls, [('A', 0)]);
    final group = controller.entries.first.source!.key as DownloadCollection;
    controller.cancelCollection(group);
    final gate = api.gate!;
    api.gate = null;
    gate.complete();
    await until(() => single.state == DownloadState.complete);
    expect(group.cancelled.value, isTrue);
    expect(controller.collectionStatus(group), contains('已取消'));
    expect(api.pageCalls.where((call) => call.$1 == 'A').toList(), [('A', 0)]);
    expect(
      controller.hyperQueue.itemsIn(group).single.state,
      DownloadState.cancelled,
    );
    final headers = controller.entries
        .where((entry) => entry.source != null)
        .map((entry) => entry.source!.title);
    expect(headers, ['A', 'B']);
    expect(api.calls, ['A-0', 'B-0', 'B-1', 'single']);
    expect(controller.entries.last.item, same(single));
  });

  test(
    'cancel keeps completed files; later page items inherit cancelled state',
    () async {
      api.badPages.add(('A', 1));
      final a = collection('A');
      controller.addCollection(a);
      await until(() => controller.entries.any((entry) => entry.suspended));
      final group = controller.entries.first.source!.key as DownloadCollection;
      final completed = controller.tasks.value.single;
      controller.cancelCollection(group);
      expect(await File(completed.path!).exists(), isTrue);
      api.badPages.clear();
      await a.loadMore();
      expect(
        controller.hyperQueue.itemsIn(group).last.state,
        DownloadState.cancelled,
      );
      expect(api.calls, ['A-0']);
    },
  );

  test('retrying a cancelled song also resumes its containing group', () async {
    api.gate = Completer<void>();
    controller.addCollection(collection('A'));
    await until(() => api.calls.isNotEmpty);
    final group = controller.entries.first.source!.key as DownloadCollection;
    controller.cancelCollection(group);
    final gate = api.gate!;
    api.gate = null;
    gate.complete();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    controller.retry(controller.tasks.value.single);
    await until(
      () =>
          controller.tasks.value.length == 2 &&
          controller.tasks.value.every(
            (task) => task.state == DownloadState.complete,
          ),
    );
    expect(group.cancelled.value, isFalse);
    expect(api.calls, ['A-0', 'A-0', 'A-1']);
  });

  test('retry count is configurable; zero skips after one attempt', () async {
    expect(controller.retryCount.value, 2);
    controller.setRetryCount(0);
    badTracks.add('bad');
    final bad = controller.add(song('bad'));
    final good = controller.add(song('good'));
    await until(() => good.state == DownloadState.complete);
    expect(bad.state, DownloadState.failed);
    expect(bad.attempts, 1);
    expect(api.calls, ['bad', 'good']);
  });

  test(
    'default retries parse three fresh URLs, then skip to the next song',
    () async {
      badTracks.add('bad');
      final bad = controller.add(song('bad'));
      final good = controller.add(song('good'));
      await until(() => good.state == DownloadState.complete);
      expect(bad.state, DownloadState.failed);
      expect(bad.attempts, 3);
      expect(api.calls, ['bad', 'bad', 'bad', 'good']);
      expect(
        plugins.logs.value.any((log) => log.message.contains('[SKIP]')),
        isTrue,
      );
    },
  );

  test('configured retry count one permits exactly two attempts', () async {
    controller.setRetryCount(1);
    badTracks.add('bad');
    final bad = controller.add(song('bad'));
    final good = controller.add(song('good'));
    await until(() => good.state == DownloadState.complete);
    expect(bad.attempts, 2);
    expect(api.calls, ['bad', 'bad', 'good']);
  });

  test('disposing during retry delay cancels further requests', () async {
    await controller.disposeController();
    controller = DownloadController(
      plugins,
      directory: directory,
      retryDelay: const Duration(seconds: 2),
    );
    badTracks.add('bad');
    controller.add(song('bad'));
    await until(
      () => controller.tasks.value.single.state == DownloadState.retrying,
    );
    await controller.disposeController();
    expect(api.calls, ['bad']);
    expect(requests, 1);
  });

  test(
    'cancelling retry delay stops further attempts and continues the queue',
    () async {
      await controller.disposeController();
      controller = DownloadController(
        plugins,
        directory: directory,
        retryDelay: const Duration(seconds: 2),
      );
      badTracks.add('bad');
      final bad = controller.add(song('bad'));
      final good = controller.add(song('good'));
      await until(() => bad.state == DownloadState.retrying);
      controller.cancel(bad);
      await until(() => good.state == DownloadState.complete);
      expect(bad.state, DownloadState.cancelled);
      expect(api.calls, ['bad', 'good']);
    },
  );

  test('failed first playlist is suspended after three attempts; B still downloads', () async {
    api.badPages.add(('A', 0));
    controller.addCollection(collection('A'));
    controller.addCollection(collection('B'));
    await until(
      () =>
          controller.tasks.value.length == 2 &&
          controller.tasks.value.every(
            (task) => task.state == DownloadState.complete,
          ),
    );
    expect(api.pageCalls.where((call) => call.$1 == 'A').toList(), [
      ('A', 0),
      ('A', 0),
      ('A', 0),
    ]);
    expect(api.calls, ['B-0', 'B-1']);
    final suspended = controller.hyperQueue.entries.value.firstWhere(
      (entry) => entry.suspended,
    );
    api.badPages.clear();
    controller.retryCollection(suspended.source!.key);
    await until(
      () =>
          controller.tasks.value.length == 4 &&
          controller.tasks.value.every(
            (task) => task.state == DownloadState.complete,
          ),
    );
    expect(api.calls, ['B-0', 'B-1', 'A-0', 'A-1']);
  });

  test('manual playlist retry resumes failed page without redownloading completed songs', () async {
    api.badPages.add(('A', 1));
    final a = collection('A');
    controller.addCollection(a);
    controller.addCollection(collection('B'));
    await until(
      () =>
          controller.tasks.value.length == 3 &&
          controller.tasks.value.every(
            (task) => task.state == DownloadState.complete,
          ),
    );
    expect(a.page, 1);
    expect(api.calls, ['A-0', 'B-0', 'B-1']);
    final suspended = controller.hyperQueue.entries.value.firstWhere(
      (entry) => entry.suspended,
    );
    api.badPages.clear();
    controller.retryCollection(suspended.source!.key);
    await until(
      () =>
          controller.tasks.value.length == 4 &&
          controller.tasks.value.every(
            (task) => task.state == DownloadState.complete,
          ),
    );
    expect(api.pageCalls.where((call) => call == ('A', 0)).length, 1);
    expect(api.calls, ['A-0', 'B-0', 'B-1', 'A-1']);
  });

  test('a successful page resets the retry budget for the next page', () async {
    api.pageFailures[('A', 0)] = 2;
    api.pageFailures[('A', 1)] = 2;
    controller.addCollection(collection('A'));
    await until(
      () =>
          controller.tasks.value.length == 2 &&
          controller.tasks.value.every(
            (task) => task.state == DownloadState.complete,
          ),
    );
    expect(api.pageCalls, [
      ('A', 0),
      ('A', 0),
      ('A', 0),
      ('A', 1),
      ('A', 1),
      ('A', 1),
    ]);
    expect(
      controller.hyperQueue.entries.value.any((entry) => entry.suspended),
      isFalse,
    );
  });

  test('directory change only affects newly queued tasks', () async {
    api.gate = Completer<void>();
    final first = controller.add(song('old-directory'));
    final second = controller.add(song('new-directory'));
    await until(() => api.calls.isNotEmpty);
    final next = Directory('${directory.path}/new');
    await controller.setDirectory(next.uri.toString());
    final third = controller.add(song('created-after-directory-change'));
    expect(Directory(controller.selectedDirectory.value).uri, next.uri);
    final gate = api.gate!;
    api.gate = null;
    gate.complete();
    await until(() => third.state == DownloadState.complete);
    expect(File(first.path!).parent.path, directory.path);
    expect(File(second.path!).parent.path, directory.path);
    expect(File(third.path!).parent.uri, next.uri);
    expect(await File(first.path!).readAsBytes(), bytes);
    expect(await File(second.path!).readAsBytes(), bytes);
  });

  test(
    'artist grouping snapshots the first artist and sanitizes folder names',
    () async {
      await controller.setGrouping(DownloadGrouping.artist);
      final track = Song.fromJson({
        ...song('grouped').toJson(),
        'artist': [
          {'title': '甲/乙'},
          {'title': '第二位'},
        ],
      });
      final task = controller.add(track);
      await controller.setGrouping(DownloadGrouping.none);
      await until(() => task.state == DownloadState.complete);
      expect(
        File(task.path!).parent.uri,
        Directory('${directory.path}/甲_乙').uri,
      );
      expect(await File(task.path!).readAsBytes(), bytes);
    },
  );

  test(
    'missing artist or failed subfolder creation falls back to root',
    () async {
      await controller.setGrouping(DownloadGrouping.artist);
      final missing = controller.add(song('no-artist'));
      await File('${directory.path}/blocked').writeAsString('not a directory');
      final task = controller.add(
        Song.fromJson({
          ...song('blocked-artist').toJson(),
          'artist': [
            {'title': 'blocked'},
          ],
        }),
      );
      await until(() => task.state == DownloadState.complete);
      expect(File(missing.path!).parent.uri, directory.uri);
      expect(File(task.path!).parent.uri, directory.uri);
      expect(
        plugins.logs.value.any(
          (log) => log.message.contains('FOLDER_FALLBACK'),
        ),
        isTrue,
      );
    },
  );

  test('collection grouping remains fixed across later pages', () async {
    await controller.setGrouping(DownloadGrouping.collection);
    final collection = CollectionController(
      api,
      CollectionKind.playlist,
      PlayList(pluginId: api.pluginId, id: 'folder-list', title: '我的歌单'),
      (_, _) {},
    );
    controller.addCollection(collection);
    await controller.setGrouping(DownloadGrouping.none);
    await until(
      () =>
          controller.tasks.value.length == 2 &&
          controller.tasks.value.every(
            (task) => task.state == DownloadState.complete,
          ),
    );
    for (final task in controller.tasks.value) {
      expect(
        File(task.path!).parent.uri,
        Directory('${directory.path}/我的歌单').uri,
      );
    }
  });

  test(
    'batch matches only when enabled and records actual source and quality',
    () async {
      api.unavailable = true;
      await controller.setRetryCount(0);
      final other = DownloadApi(
        plugins.manager,
        server.port,
        plugin: 'alternate',
      );
      other.candidates = [
        Song(pluginId: 'alternate', id: 'other', title: '示例歌曲'),
      ];
      plugins.builtins['alternate'] = other;
      await plugins.matcher.setSources(['alternate']);
      await controller.setAllowMatch(true);
      final batch = collection('match-batch');
      batch.songs.value = [
        Song(pluginId: api.pluginId, id: 'original', title: '示例歌曲'),
      ];
      batch.hasMore.value = false;
      controller.addCollection(batch);
      await until(
        () =>
            controller.tasks.value.isNotEmpty &&
            controller.tasks.value.single.state == DownloadState.complete,
      );
      final task = controller.tasks.value.single;
      expect(task.song.pluginId, api.pluginId);
      expect(task.song.actualSong.pluginId, 'alternate');
      expect(task.path, contains(task.key.substring(0, 12)));
      expect(api.calls, ['original']);
      expect(other.calls, ['other']);
      expect(plugins.matcher.enabled.value, false);
      expect(requests, 1);
    },
  );

  test('folder grouping is persisted and restored', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    await controller.disposeController();
    controller = DownloadController(
      plugins,
      directory: directory,
      preferences: preferences,
    );
    await controller.setGrouping(DownloadGrouping.artist);
    expect(preferences.getString('downloadGrouping'), 'artist');
    await controller.disposeController();
    controller = DownloadController(
      plugins,
      directory: directory,
      preferences: preferences,
    );
    expect(controller.grouping.value, DownloadGrouping.artist);
  });

  test('removed album batch can be queued again without downloading existing files', () async {
    final album = CollectionController(
      api,
      CollectionKind.album,
      Album(pluginId: api.pluginId, id: 'requeue-album', title: '再次下载'),
      (_, _) {},
    );
    addTearDown(album.dispose);
    album.songs.value = [song('album-first'), song('album-second')];
    album.hasMore.value = false;
    controller.addCollection(album);
    await until(
      () =>
          controller.tasks.value.length == 2 &&
          controller.tasks.value.every(
            (task) => task.state == DownloadState.complete,
          ),
    );
    for (final task in controller.tasks.value.toList()) {
      controller.remove(task);
    }
    expect(controller.tasks.value, isEmpty);
    controller.addCollection(album);
    expect(controller.tasks.value, hasLength(2));
    await until(
      () => controller.tasks.value.every(
        (task) => task.state == DownloadState.complete,
      ),
    );
    expect(api.calls, ['album-first', 'album-second']);
    expect(requests, 2);
    expect(
      plugins.logs.value.where((log) => log.message.contains('SKIP_EXISTING')),
      hasLength(2),
    );
  });

  test(
    'album batches use the album title; individual songs stay at root',
    () async {
      await controller.setGrouping(DownloadGrouping.collection);
      final album = CollectionController(
        api,
        CollectionKind.album,
        Album(pluginId: api.pluginId, id: 'album', title: '测试专辑'),
        (_, _) {},
      );
      addTearDown(album.dispose);
      album.songs.value = [song('album-song')];
      album.hasMore.value = false;
      controller.addCollection(album);
      final single = controller.add(song('single-song'));
      await until(() => single.state == DownloadState.complete);
      expect(
        File(controller.tasks.value.first.path!).parent.uri,
        Directory('${directory.path}/测试专辑').uri,
      );
      expect(File(single.path!).parent.uri, directory.uri);
    },
  );

  test('queue resolves only at execution; request headers, progress and final file use lemon_net', () async {
    api.gate = Completer<void>();
    final first = controller.add(song({'id': 1}));
    final second = controller.add(song(2));
    expect(identical(first, controller.add(song({'id': 1}))), isTrue);
    await until(() => api.calls.isNotEmpty);
    expect(api.calls, [
      {'id': 1},
    ]);
    expect(second.state, DownloadState.waiting);
    final gate = api.gate!;
    api.gate = null;
    gate.complete();
    await until(() => second.state == DownloadState.complete);
    expect(api.calls, [
      {'id': 1},
      2,
    ]);
    expect(requests, 2);
    expect(first.received, bytes.length);
    expect(await File(first.path!).readAsBytes(), bytes);
    expect(File(first.path!).parent.path, directory.path);
    controller.remove(first);
    expect(await File(first.path!).exists(), isTrue);
    expect(
      plugins.logs.value.any((entry) => entry.toString().contains('secret=')),
      isFalse,
    );
  });

  test(
    'failed HTTP response is not a song; retry resolves a fresh URL',
    () async {
      status = 403;
      final task = controller.add(song('retry'));
      await until(() => task.state == DownloadState.failed);
      await until(() => directory.listSync().isEmpty);
      expect(task.error, contains('403'));
      status = 200;
      controller.retry(task);
      await until(() => task.state == DownloadState.complete);
      expect(api.calls, ['retry', 'retry', 'retry', 'retry']);
      expect(task.attempts, 1);
      expect(await File(task.path!).readAsBytes(), bytes);
    },
  );

  test('cancel during resolution never downloads; cancelled queue item is not resolved', () async {
    api.gate = Completer<void>();
    final first = controller.add(song('active'));
    final second = controller.add(song('waiting'));
    await until(() => api.calls.isNotEmpty);
    controller.cancel(first);
    controller.cancel(second);
    final gate = api.gate!;
    api.gate = null;
    gate.complete();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(requests, 0);
    expect(api.calls, ['active']);
    controller.retry(first);
    await until(() => first.state == DownloadState.complete);
    expect(api.calls, ['active', 'active']);
  });

  test('HTML response is rejected even with an audio-looking URL', () async {
    mime = 'text/html';
    final task = controller.add(song('html'));
    await until(() => task.state == DownloadState.failed);
    await until(() => directory.listSync().isEmpty);
    expect(task.error, contains('不是音频'));
  });
}
