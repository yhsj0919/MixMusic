import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lemon_js_extensions/lemon_js_extensions.dart';
import 'package:mix_music/common/api/music_api.dart';
import 'package:mix_music/common/download/download_controller.dart';
import 'package:mix_music/common/download/download_files.dart';
import 'package:mix_music/common/entity/music_download.dart';
import 'package:mix_music/common/entity/play_list.dart';
import 'package:mix_music/common/entity/song.dart';
import 'package:mix_music/common/player/music_cache.dart';
import 'package:mix_music/common/plugin/collection_controller.dart';
import 'package:mix_music/common/plugin/plugin_controller.dart';

class CacheDownloadApi extends MusicApi {
  CacheDownloadApi(JsExtensionManager manager, this.port)
    : super(manager, 'test.cache-download');
  final int port;
  int calls = 0;
  bool forbidResolve = false;
  List<Song> candidates = [];
  @override
  Future<List<Song>> searchMusic(
    String keyword, [
    int page = 0,
    int size = 20,
  ]) async => candidates;
  Song source(Song song) => Song.fromJson(song.toJson())
    ..url = 'http://127.0.0.1:$port/audio.mp3?signature=secret'
    ..details = {
      'httpHeaders': {'X-Test': 'private'},
    };
  @override
  Future<Song> playUrl(Song song) async {
    calls++;
    if (forbidResolve) throw StateError('缓存命中不应解析地址');
    return source(song);
  }

  @override
  Future<PlayList> playListInfo(
    PlayList item, [
    int page = 0,
    int size = 20,
  ]) async => PlayList.fromJson({
    ...item.toJson(),
    'hasMore': false,
    'total': 2,
    'songs': [
      {'id': 'cached', 'title': 'cached'},
      {'id': 'network', 'title': 'network'},
    ],
  });
}

class RefuseSave extends DownloadFiles {
  @override
  Future<String> save(
    File file,
    String directory,
    String name,
    String mime,
  ) async => throw FileSystemException('模拟目标目录写入失败');
}

Future<void> until(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) throw StateError('等待缓存下载超时');
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  late Directory directory;
  late Directory destination;
  late MusicCache cache;
  late PluginController plugins;
  late DownloadController downloads;
  late CacheDownloadApi api;
  late HttpServer server;
  late HttpClient client;
  late StreamController<String> events;
  late List<int> payload;
  int requests = 0;
  String mime = 'audio/mpeg';

  Song song([int quality = 128, dynamic id = 'cached']) => Song(
    pluginId: 'test.cache-download',
    id: id,
    title: '$id',
    playQuality: quality,
  );

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'mixmusic-cache-download-',
    );
    destination = await Directory('${directory.path}/downloads').create();
    payload = List.generate(256 * 1024, (i) => i % 256);
    requests = 0;
    mime = 'audio/mpeg';
    events = StreamController<String>.broadcast(sync: true);
    client = HttpClient();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      requests++;
      expect(request.headers.value('X-Test'), 'private');
      request.response.headers.set('Content-Type', mime);
      request.response.contentLength = payload.length;
      request.response.add(payload);
      await request.response.close();
    });
    plugins = PluginController();
    api = CacheDownloadApi(plugins.manager, server.port);
    plugins.builtins[api.pluginId] = api;
    cache = MusicCache(
      directory: Directory('${directory.path}/cache'),
      onLog: events.add,
    );
    await cache.restored;
    downloads = DownloadController(
      plugins,
      directory: destination,
      cache: cache,
      retryCount: 0,
    );
  });

  tearDown(() async {
    await downloads.disposeController();
    await cache.dispose();
    await plugins.disposeController();
    client.close(force: true);
    await server.close(force: true);
    await events.close();
    await directory.delete(recursive: true);
  });

  Future<void> warm(Song selected) async {
    final complete = events.stream
        .firstWhere((event) => event.contains('[WRITE_COMPLETE]'))
        .timeout(const Duration(seconds: 5));
    final resolved = await cache.resolve(
      selected,
      () async => api.source(selected),
    );
    await (await (await client.getUrl(
      Uri.parse(resolved.url!),
    )).close()).drain<void>();
    await complete;
  }

  test(
    'automatic matching reads the actual cache without resolving its address',
    () async {
      final actual = song();
      await warm(actual);
      api.forbidResolve = true;
      api.candidates = [actual];
      await plugins.matcher.setSources([api.pluginId]);
      await plugins.matcher.setEnabled(true);
      final original = Song(
        pluginId: 'missing-source',
        id: 'original',
        title: actual.title,
        playQuality: 128,
      );
      final result = await plugins.matcher.resolve(
        original,
        (candidate) => cache.resolve(
          candidate,
          () => plugins.music(candidate.pluginId).playUrl(candidate),
        ),
      );
      expect(result.pluginId, api.pluginId);
      expect(result.url, startsWith('file:'));
      expect(api.calls, 0);
      expect(requests, 1);
      expect(original.matchedSong, isNull);
    },
  );

  test('current matched version exports actual cache without calling the original source', () async {
    final actual = song();
    await warm(actual);
    api.forbidResolve = true;
    final original = Song(
      pluginId: 'original',
      id: {'id': 1},
      title: '原歌曲',
      matchedSong: actual,
    );
    final task = downloads.add(original);
    await until(() => task.state == DownloadState.complete);
    expect(task.song.pluginId, 'original');
    expect(task.key, MusicCache.keyFor(actual));
    expect(api.calls, 0);
    expect(requests, 1);
    expect(await File(task.path!).readAsBytes(), payload);
  });

  test(
    'current matched version resolves a fresh actual address when uncached',
    () async {
      final actual = song()..url = 'https://expired.invalid/audio';
      final task = downloads.add(
        Song(pluginId: 'original', id: 1, title: '原歌曲', matchedSong: actual),
      );
      await until(() => task.state == DownloadState.complete);
      expect(api.calls, 1);
      expect(requests, 1);
      expect(task.song.actualSong.pluginId, api.pluginId);
      expect(task.song.pluginId, 'original');
    },
  );

  test('complete cache copies to formal audio without playUrl or another HTTP request', () async {
    await warm(song());
    api.forbidResolve = true;
    final task = downloads.add(song());
    await until(() => task.state == DownloadState.complete);
    expect(api.calls, 0);
    expect(requests, 1);
    expect(task.path, endsWith('.mp3'));
    expect(task.received, payload.length);
    expect(task.total, payload.length);
    expect(await File(task.path!).readAsBytes(), payload);
    expect(
      plugins.logs.value.any((log) => log.message.contains('[CACHE_HIT]')),
      isTrue,
    );
    expect(
      plugins.logs.value.any((log) => log.message.contains('signature=')),
      isFalse,
    );
    final source = File(
      '${cache.directory!.path}/${MusicCache.keyFor(song())}.audio',
    );
    expect(await source.exists(), isTrue);
    await cache.clear();
    expect(await source.exists(), isFalse);
    expect(await File(task.path!).readAsBytes(), payload);
  });

  test(
    'a different quality misses cache and dynamically resolves its own source',
    () async {
      await warm(song());
      final task = downloads.add(song(320), quality: 320);
      await until(() => task.state == DownloadState.complete);
      expect(api.calls, 1);
      expect(requests, 2);
    },
  );

  test(
    'batch shares the cache path and only resolves the uncached song',
    () async {
      await warm(song());
      final collection = CollectionController(
        api,
        CollectionKind.playlist,
        PlayList.fromJson({
          'pluginId': api.pluginId,
          'id': 'list',
          'title': 'list',
        }),
        (_, _) {},
      );
      addTearDown(collection.dispose);
      downloads.addCollection(collection, quality: 128);
      await until(
        () =>
            downloads.tasks.value.length == 2 &&
            downloads.tasks.value.every(
              (task) => task.state == DownloadState.complete,
            ),
      );
      expect(api.calls, 1);
      expect(requests, 2);
      for (final task in downloads.tasks.value) {
        expect(await File(task.path!).readAsBytes(), payload);
      }
    },
  );

  test('missing complete file is invalidated and falls back to a freshly resolved download', () async {
    await warm(song());
    await File('${cache.directory!.path}/${MusicCache.keyFor(song())}.audio')
        .delete();
    final task = downloads.add(song());
    await until(() => task.state == DownloadState.complete);
    expect(api.calls, 1);
    expect(requests, 2);
  });

  test('a temporary part is not a cache hit', () async {
    await File('${cache.directory!.path}/${MusicCache.keyFor(song())}.part')
        .writeAsBytes(payload.take(20).toList());
    final task = downloads.add(song());
    await until(() => task.state == DownloadState.complete);
    expect(api.calls, 1);
    expect(requests, 1);
  });

  test(
    'disabled cache uses the normal freshly resolved download path',
    () async {
      await warm(song());
      await cache.setEnabled(false);
      final task = downloads.add(song());
      await until(() => task.state == DownloadState.complete);
      expect(api.calls, 1);
      expect(requests, 2);
    },
  );

  test('existing formal file skips cache export and URL resolution', () async {
    await warm(song());
    final target = File(
      '${destination.path}/cached-${MusicCache.keyFor(song()).substring(0, 12)}.mp3',
    );
    await target.writeAsBytes([1, 2, 3]);
    final task = downloads.add(song());
    await until(
      () =>
          task.state == DownloadState.complete &&
          !destination.listSync().any((entry) => entry.path.endsWith('.part')),
    );
    expect(await target.readAsBytes(), [1, 2, 3]);
    expect(api.calls, 0);
    expect(requests, 1);
    expect(
      await File('${cache.directory!.path}/${MusicCache.keyFor(song())}.audio')
          .exists(),
      isTrue,
    );
  });

  test(
    'legacy complete entry without format uses file header without resolving',
    () async {
      mime = 'audio/flac';
      payload = [...ascii.encode('fLaC'), ...List.filled(1024, 0)];
      await warm(song());
      await cache.dispose();
      final index = File('${cache.directory!.path}/index.json');
      final data = jsonDecode(await index.readAsString()) as Map;
      for (final entry in data['entries'] as List) {
        (entry as Map).remove('mime');
      }
      await index.writeAsString(jsonEncode(data));
      cache = MusicCache(directory: cache.directory, onLog: events.add);
      await downloads.disposeController();
      downloads = DownloadController(
        plugins,
        directory: destination,
        cache: cache,
        retryCount: 0,
      );
      api.forbidResolve = true;
      final task = downloads.add(song());
      await until(() => task.state == DownloadState.complete);
      expect(task.path, endsWith('.flac'));
      expect(api.calls, 0);
      expect(requests, 1);
    },
  );

  test(
    'cancelling during copy cleans the part and never falls back to network',
    () async {
      await warm(song());
      api.forbidResolve = true;
      void changed() {
        if (plugins.logs.value.last.message.contains('[COPY_PROGRESS]')) {
          downloads.cancel(downloads.tasks.value.single);
        }
      }

      plugins.logs.addListener(changed);
      addTearDown(() => plugins.logs.removeListener(changed));
      final task = downloads.add(song());
      await until(
        () =>
            task.state == DownloadState.cancelled &&
            destination.listSync().isEmpty,
      );
      expect(api.calls, 0);
      expect(requests, 1);
      expect(
        await File(
          '${cache.directory!.path}/${MusicCache.keyFor(song())}.audio',
        ).exists(),
        isTrue,
      );
    },
  );

  test(
    'destination failure never deletes cache or redownloads audio',
    () async {
      await warm(song());
      await downloads.disposeController();
      downloads = DownloadController(
        plugins,
        directory: destination,
        cache: cache,
        files: RefuseSave(),
        retryCount: 0,
      );
      final task = downloads.add(song());
      await until(
        () =>
            task.state == DownloadState.failed &&
            destination.listSync().isEmpty,
      );
      expect(api.calls, 0);
      expect(requests, 1);
      expect(
        await File(
          '${cache.directory!.path}/${MusicCache.keyFor(song())}.audio',
        ).exists(),
        isTrue,
      );
    },
  );

  test(
    'clear protects a copying cache without changing playback protection',
    () async {
      await warm(song());
      final other = song(128, 'playing');
      await warm(other);
      cache.activate(other);
      Future<void>? clearing;
      final copied = File('${destination.path}/export.mp3');
      final result = await cache.copyTo(
        song(),
        copied,
        onProgress: (_, _) {
          clearing ??= cache.clear();
        },
      );
      await clearing;
      expect(result, isNotNull);
      expect(
        await File(
          '${cache.directory!.path}/${MusicCache.keyFor(song())}.audio',
        ).exists(),
        isTrue,
      );
      expect(await copied.readAsBytes(), payload);
      final protected = File(
        '${cache.directory!.path}/${MusicCache.keyFor(other)}.audio',
      );
      expect(await protected.exists(), isTrue);
      await cache.clear();
      expect(await protected.exists(), isTrue);
      expect(await copied.exists(), isTrue);
      cache.release();
      await cache.clear();
      expect(cache.usedBytes.value, 0);
    },
  );
}
