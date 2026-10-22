import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mix_music/common/entity/song.dart';
import 'package:mix_music/common/player/music_cache.dart';

void main() {
  late Directory directory;
  late HttpServer server;
  late HttpClient client;
  late MusicCache cache;
  late StreamController<String> events;
  late List<String> logs;
  late List<int> payload;
  int downloads = 0;
  int resolutions = 0;
  String mode = '';
  String? receivedAuth;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('mixmusic-cache-');
    client = HttpClient();
    events = StreamController<String>.broadcast(sync: true);
    logs = [];
    payload = List.generate(1024, (i) => i % 256);
    downloads = 0;
    resolutions = 0;
    mode = '';
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      downloads++;
      receivedAuth = request.headers.value(HttpHeaders.authorizationHeader);
      request.response.headers.contentType = ContentType('audio', 'mpeg');
      if (mode == 'range') {
        request.response.statusCode = 206;
        request.response.headers.set(
          HttpHeaders.contentRangeHeader,
          'bytes 100-199/1024',
        );
        request.response.contentLength = 100;
        request.response.add(payload.sublist(100, 200));
      } else if (mode == 'partial') {
        request.response.contentLength = payload.length;
        request.response.add(payload.sublist(0, 100));
        await request.response.flush();
        request.response.deadline = Duration.zero;
        return;
      } else {
        if (mode != 'unknown') request.response.contentLength = payload.length;
        request.response.add(payload);
      }
      await request.response.close();
    });
    cache = MusicCache(
      directory: directory,
      onLog: (message) {
        logs.add(message);
        events.add(message);
      },
    );
    await cache.restored;
  });
  tearDown(() async {
    client.close(force: true);
    await cache.dispose();
    await server.close(force: true);
    await events.close();
    await directory.delete(recursive: true);
  });

  Song track(int quality, {dynamic id = 'song'}) =>
      Song(pluginId: 'test', id: id, title: '测试音频', playQuality: quality);
  Future<Song> source(Song selected) async {
    resolutions++;
    return Song.fromJson(selected.toJson())
      ..url = 'http://127.0.0.1:${server.port}/audio?token=secret'
      ..details = {
        'httpHeaders': {'Authorization': 'Bearer private'},
      };
  }

  Future<List<int>> read(Song song) async {
    if (song.url!.startsWith('file:')) {
      return File.fromUri(Uri.parse(song.url!)).readAsBytes();
    }
    final request = await client.getUrl(Uri.parse(song.url!));
    final response = await request.close();
    return response.fold<List<int>>([], (bytes, chunk) => bytes..addAll(chunk));
  }

  Future<void> store(Song selected) async {
    final complete = events.stream
        .firstWhere((message) => message.contains('[WRITE_COMPLETE]'))
        .timeout(const Duration(seconds: 5));
    final resolved = await cache.resolve(selected, () => source(selected));
    cache.activate(resolved);
    expect(await read(resolved), payload);
    await complete;
  }

  test('cache identity separates source, quality and ID types but normalizes object keys', () {
    expect(
      MusicCache.keyFor(
        track(
          128,
          id: {
            'a': 1,
            'b': [2],
          },
        ),
      ),
      MusicCache.keyFor(
        track(
          128,
          id: {
            'b': [2],
            'a': 1,
          },
        ),
      ),
    );
    expect(
      MusicCache.keyFor(track(128, id: 1)),
      isNot(MusicCache.keyFor(track(128, id: '1'))),
    );
    expect(MusicCache.keyFor(track(128)), isNot(MusicCache.keyFor(track(320))));
    final other = track(128)..pluginId = 'other';
    expect(MusicCache.keyFor(other), isNot(MusicCache.keyFor(track(128))));
  });

  test(
    'complete audio is fetched once and reused across restarts without playUrl',
    () async {
      final selected = track(128);
      await store(selected);
      expect(downloads, 1);
      expect(resolutions, 1);
      expect(receivedAuth, 'Bearer private');
      await cache.dispose();
      cache = MusicCache(directory: directory, onLog: logs.add);
      final hit = await cache.resolve(
        selected,
        () => throw StateError('must not resolve again'),
      );
      expect(hit.url, startsWith('file:'));
      expect(await read(hit), payload);
      expect(downloads, 1);
      expect(cache.usedBytes.value, payload.length);
      expect(logs.any((message) => message.contains('[HIT]')), isTrue);
      expect(logs.join('\n'), isNot(contains('token=secret')));
      expect(logs.join('\n'), isNot(contains('Bearer private')));
    },
  );

  test('switching quality creates separate audio; switching back reuses old version', () async {
    await store(track(128));
    await store(track(320));
    final hit = await cache.resolve(
      track(128),
      () => throw StateError('cached quality'),
    );
    expect(await read(hit), payload);
    expect(downloads, 2);
    expect(resolutions, 2);
    expect(cache.usedBytes.value, payload.length * 2);
  });

  test(
    'capacity eviction and clear protect current audio; disabling persists',
    () async {
      await cache.setLimit(1536);
      await store(track(128, id: 'first'));
      await store(track(128, id: 'second'));
      expect(cache.usedBytes.value, 1024);
      expect(logs.any((message) => message.contains('[EVICT]')), isTrue);
      await cache.clear();
      expect(cache.usedBytes.value, 1024);
      cache.release();
      await cache.clear();
      expect(cache.usedBytes.value, 0);
      await cache.setEnabled(false);
      final direct = await cache.resolve(track(128), () => source(track(128)));
      expect(Uri.parse(direct.url!).port, server.port);
      await cache.dispose();
      cache = MusicCache(directory: directory);
      await cache.restored;
      expect(cache.enabled.value, isFalse);
      expect(cache.limitBytes.value, 1536);
    },
  );

  for (final partial in ['range', 'unknown', 'partial']) {
    test('$partial transfer is never recorded as complete', () async {
      mode = partial;
      final selected = track(128);
      final done = events.stream
          .firstWhere(
            (message) => message.contains(
              partial == 'partial' ? '[TRANSFER_STOP]' : '[SKIP_WRITE]',
            ),
          )
          .timeout(const Duration(seconds: 5));
      final resolved = await cache.resolve(selected, () => source(selected));
      if (partial == 'partial') {
        await expectLater(read(resolved), throwsA(anything));
      } else {
        await read(resolved);
      }
      await done;
      expect(cache.usedBytes.value, 0);
      await cache.resolve(selected, () => source(selected));
      expect(resolutions, 2);
    });
  }
}
