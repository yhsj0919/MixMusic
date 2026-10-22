import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lemon_js_extensions/lemon_js_extensions.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart' as mpv;
import 'package:mix_music/common/player/player_controller.dart';
import 'package:mix_music/common/plugin/plugin_controller.dart';
import 'package:mix_music/common/local/local_music_api.dart';
import 'package:mix_music/common/local/local_music_controller.dart';
import 'package:mix_music/common/entity/song.dart';
import 'package:mix_music/common/api/music_api.dart';
import 'package:mix_music/common/player/music_cache.dart';

class RealHttpOverrides extends HttpOverrides {}

class CacheAudioApi extends MusicApi {
  CacheAudioApi(JsExtensionManager manager, this.url)
    : super(manager, 'test.cache');
  final String url;
  int calls = 0;

  @override
  Future<Song> playUrl(Song song) async {
    calls++;
    return Song.fromJson(song.toJson())..url = url;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'native mpv streams once and reopens complete cache after restart',
    () async {
      await HttpOverrides.runWithHttpOverrides(() async {
        mpv.MpvAudioKit.ensureInitialized(
          libmpv: File('build/windows/x64/runner/Debug/libmpv.dll')
              .absolute
              .path,
        );
        final directory = await Directory.systemTemp.createTemp(
          'music-cache-mpv-',
        );
        addTearDown(() => directory.delete(recursive: true));
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() => server.close(force: true));
        final bytes = await File('E:/lemon_audio/example/assets/test-tone.wav')
            .readAsBytes();
        var requests = 0;
        server.listen((request) async {
          if (request.method == 'GET') requests++;
          request.response.headers.contentType = ContentType('audio', 'wav');
          request.response.contentLength = bytes.length;
          if (request.method == 'GET') request.response.add(bytes);
          await request.response.close();
        });
        final plugins = PluginController();
        addTearDown(plugins.disposeController);
        final api = CacheAudioApi(
          plugins.manager,
          'http://127.0.0.1:${server.port}/tone',
        );
        plugins.builtins['test.cache'] = api;
        final events = StreamController<String>.broadcast(sync: true);
        addTearDown(events.close);
        final song = Song(
          pluginId: 'test.cache',
          id: {'id': 1},
          title: '缓存测试',
          playQuality: 128,
        );
        for (var i = 0; i < 2; i++) {
          final controller = PlayerController(
            plugins,
            cache: MusicCache(directory: directory, onLog: events.add),
          );
          addTearDown(controller.disposeController);
          final adapter = controller.engine = MpvPlayer();
          await adapter.player.setRawProperty('ao', 'null');
          await adapter.player.setSourceResolver(controller.resolve);
          final ready = adapter.player.stream.duration
              .firstWhere((duration) => duration > Duration.zero)
              .timeout(const Duration(seconds: 10));
          final cached = events.stream
              .firstWhere(
                (message) =>
                    message.contains(i == 0 ? '[WRITE_COMPLETE]' : '[HIT]'),
              )
              .timeout(const Duration(seconds: 10));
          await adapter.open(
            mpv.Media(
              'mixmusic://cache/$i',
              extras: {'song': song.toJson(), 'loadId': 0},
            ),
          );
          await adapter.play();
          await ready;
          await cached;
          expect(controller.status.value, isEmpty);
          await controller.disposeController();
        }
        expect(api.calls, 1);
        expect(requests, 1);
      }, RealHttpOverrides());
    },
    skip: !const bool.fromEnvironment('MPV_SMOKE'),
  );
  test(
    'native volume ducking, mute, speed, equalizer and reload start position',
    () async {
      mpv.MpvAudioKit.ensureInitialized(
        libmpv: File('build/windows/x64/runner/Debug/libmpv.dll').absolute.path,
      );
      final plugins = PluginController();
      addTearDown(plugins.disposeController);
      plugins.builtins[LocalMusicController.pluginId] = LocalMusicApi(
        plugins.manager,
      );
      final controller = PlayerController(plugins);
      addTearDown(controller.disposeController);
      final intents = <bool>[];
      final adapter = controller.engine = MpvPlayer(
        onPlaybackIntent: intents.add,
      );
      await adapter.player.setRawProperty('ao', 'null');
      await adapter.player.setSourceResolver(controller.resolve);
      await controller.setVolume(.4);
      expect(adapter.player.state.volume, closeTo(40, .1));
      await adapter.setVolume(.2);
      expect(adapter.player.state.volume, closeTo(8, .1));
      await adapter.setVolume(1);
      expect(adapter.player.state.volume, closeTo(40, .1));
      await controller.setMuted(true);
      expect(adapter.player.state.mute, isTrue);
      await controller.setMuted(false);
      expect(adapter.player.state.mute, isFalse);
      await controller.setSpeed(1.5);
      expect(adapter.player.state.rate, closeTo(1.5, .01));
      await controller.equalizer.setBand(0, 6);
      await controller.equalizer.setEnabled(true);
      expect(controller.controlError.value, isEmpty);
      expect(
        adapter.player.state.audioEffects.superequalizer!.params['1b'],
        closeTo(1.995, .001),
      );
      expect(
        await adapter.player.getRawProperty('af'),
        contains('superequalizer'),
      );
      final uri = File('E:/lemon_audio/example/assets/test-tone.wav').uri
          .toString();
      final song = Song(
        pluginId: LocalMusicController.pluginId,
        id: uri,
        title: '测试',
        url: uri,
      );
      final started = adapter.player.stream.position
          .firstWhere(
            (position) => position >= const Duration(milliseconds: 1400),
          )
          .timeout(const Duration(seconds: 10));
      await adapter.open(
        mpv.Media(
          uri,
          extras: {'song': song.toJson(), 'loadId': 0, 'start': 1500},
        ),
      );
      await adapter.play();
      await started;
      expect(adapter.currentState.speed, 1.5);
      expect(
        await adapter.player.getRawProperty('af'),
        contains('superequalizer'),
      );
      await adapter.pause();
      await adapter.open(
        mpv.Media(
          uri,
          extras: {'song': song.toJson(), 'loadId': 0, 'start': 1500},
        ),
      );
      await adapter.seek(const Duration(seconds: 2));
      expect(adapter.currentState.position, const Duration(seconds: 2));
      expect(adapter.player.state.playWhenReady, isFalse);
      final resumed = adapter.player.stream.position
          .firstWhere(
            (position) => position >= const Duration(milliseconds: 1900),
          )
          .timeout(const Duration(seconds: 10));
      await adapter.play();
      await resumed;
      expect(intents, [true, false, true]);
      expect(controller.status.value, isEmpty);
      await controller.equalizer.setEnabled(false);
      expect(controller.controlError.value, isEmpty);
      expect(
        adapter.player.state.audioEffects.superequalizer!.enabled,
        isFalse,
      );
      expect(controller.volume.value, .4);
    },
    skip: !const bool.fromEnvironment('MPV_SMOKE'),
  );
  test('local file uses common source resolver and native decoding', () async {
    mpv.MpvAudioKit.ensureInitialized(
      libmpv: File('build/windows/x64/runner/Debug/libmpv.dll').absolute.path,
    );
    final plugins = PluginController();
    addTearDown(plugins.disposeController);
    plugins.builtins[LocalMusicController.pluginId] = LocalMusicApi(
      plugins.manager,
    );
    final controller = PlayerController(plugins);
    addTearDown(controller.disposeController);
    final adapter = controller.engine = MpvPlayer();
    await adapter.player.setRawProperty('ao', 'null');
    var calls = 0;
    await adapter.player.setSourceResolver((request) {
      calls++;
      return controller.resolve(request);
    });
    final uri = File('E:/lemon_audio/example/assets/test-tone.wav').uri
        .toString();
    final song = Song(
      pluginId: LocalMusicController.pluginId,
      id: uri,
      title: '本地测试音',
      url: uri,
    );
    final ready = adapter.player.stream.duration
        .firstWhere((duration) => duration > Duration.zero)
        .timeout(const Duration(seconds: 10));
    await adapter.open(
      mpv.Media(uri, extras: {'song': song.toJson(), 'loadId': 0}),
    );
    await adapter.play();
    await ready;
    expect(calls, 1);
    expect(controller.song.value!.id, uri);
    expect(controller.status.value, isEmpty);
    expect(adapter.player.state.playWhenReady, isTrue);
  }, skip: !const bool.fromEnvironment('MPV_SMOKE'));
  test('next resolved track starts playing after natural EOF', () async {
    mpv.MpvAudioKit.ensureInitialized(
      libmpv: File('build/windows/x64/runner/Debug/libmpv.dll').absolute.path,
    );
    final adapter = MpvPlayer();
    addTearDown(adapter.dispose);
    await adapter.player.setRawProperty('ao', 'null');
    await adapter.player.setSourceResolver((request) async {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      return File('E:/lemon_audio/example/assets/test-tone.wav').uri.toString();
    });
    for (var i = 0; i < 3; i++) {
      await adapter.open(mpv.Media('mixmusic://auto/$i'));
      await adapter.play();
      await adapter.player.stream.position
          .firstWhere(
            (position) =>
                position > const Duration(milliseconds: 200) &&
                !adapter.player.state.completed,
          )
          .timeout(const Duration(seconds: 8));
      expect(adapter.player.state.playWhenReady, isTrue);
      final ended = adapter.player.stream.playbackState
          .firstWhere((state) => state == mpv.MpvPlaybackState.completed)
          .timeout(const Duration(seconds: 8));
      await adapter.seek(
        adapter.player.state.duration - const Duration(milliseconds: 250),
      );
      await ended;
    }
    await adapter.play();
    await adapter.player.stream.position
        .firstWhere(
          (position) =>
              position > const Duration(milliseconds: 200) &&
              !adapter.player.state.completed,
        )
        .timeout(const Duration(seconds: 8));
  }, skip: !const bool.fromEnvironment('MPV_SMOKE'));

  test('native mpv resolves on load, decodes, pauses and seeks', () async {
    mpv.MpvAudioKit.ensureInitialized(
      libmpv: File('build/windows/x64/runner/Debug/libmpv.dll').absolute.path,
    );
    var nextCalls = 0;
    var previousCalls = 0;
    int? queueIndex;
    final adapter = MpvPlayer(
      onNext: () async {
        nextCalls++;
      },
      onPrevious: () async {
        previousCalls++;
      },
      onQueueItem: (index) async {
        queueIndex = index;
      },
    );
    addTearDown(adapter.dispose);
    await adapter.skipToNext();
    await adapter.skipToPrevious();
    await adapter.skipToQueueItem(2);
    expect(nextCalls, 1);
    expect(previousCalls, 1);
    expect(queueIndex, 2);
    await adapter.player.setRawProperty('ao', 'null');
    var calls = 0;
    await adapter.player.setSourceResolver((request) async {
      calls++;
      expect(request.media.extras!['trackId'], 'smoke');
      await adapter.player.setRawProperty(
        'file-local-options/http-header-fields',
        'Referer: https://example.com/',
      );
      return File('E:/lemon_audio/example/assets/test-tone.wav').uri.toString();
    });
    final ready = adapter.player.stream.duration
        .firstWhere((value) => value > Duration.zero)
        .timeout(const Duration(seconds: 15));
    await adapter.open(
      const mpv.Media('mixmusic://smoke', extras: {'trackId': 'smoke'}),
    );
    await adapter.play();
    expect(await ready, greaterThan(Duration.zero));
    expect(calls, 1);
    await adapter.pause();
    expect(adapter.player.state.playWhenReady, isFalse);
    final sought = adapter.player.stream.position
        .firstWhere((value) => value.inSeconds >= 5)
        .timeout(const Duration(seconds: 5));
    await adapter.seek(const Duration(seconds: 5));
    await adapter.play();
    await sought;
  }, skip: !const bool.fromEnvironment('MPV_SMOKE'));
}
