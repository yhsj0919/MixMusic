import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lemon_audio/lemon_audio.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart' as mpv;
import 'package:lemon_js_extensions/lemon_js_extensions.dart';
import 'package:mix_music/common/api/music_api.dart';
import 'package:mix_music/common/entity/song.dart';
import 'package:mix_music/common/player/music_cache.dart';
import 'package:mix_music/common/player/player_controller.dart';
import 'package:mix_music/common/plugin/plugin_controller.dart';

class RecoveryApi extends MusicApi {
  RecoveryApi(JsExtensionManager manager) : super(manager, 'fixture');
  int calls = 0;
  @override
  Future<Song> playUrl(Song song) async {
    if (++calls == 1) throw StateError('temporary resolve failure');
    return Song.fromJson(song.toJson())
      ..url = File('E:/lemon_audio/example/assets/test-tone.wav').uri
          .toString();
  }
}

class MissingAddressApi extends MusicApi {
  MissingAddressApi(JsExtensionManager manager) : super(manager, 'fixture');
  String? url;
  @override
  Future<Song> playUrl(Song song) async =>
      Song.fromJson(song.toJson())..url = url;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'missing address survives native error, later file errors remain visible',
    () async {
      mpv.MpvAudioKit.ensureInitialized(
        libmpv: File('build/windows/x64/runner/Release/libmpv.dll')
            .absolute
            .path,
      );
      final directory = await Directory.systemTemp.createTemp(
        'mix_source_error_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final plugins = PluginController(
        store: JsExtensionMemoryStore(),
        storage: JsMemoryKvStore(),
      );
      addTearDown(plugins.disposeController);
      final api = MissingAddressApi(plugins.manager);
      plugins.builtins['fixture'] = api;
      final controller = PlayerController(
        plugins,
        cache: MusicCache(directory: directory),
      );
      addTearDown(controller.disposeController);
      await controller.cache.restored;
      controller.cache.enabled.value = false;
      final adapter = controller.engine = MpvPlayer();
      await adapter.player.setRawProperty('ao', 'null');
      await adapter.player.setSourceResolver(controller.resolve);
      final states = adapter.stateStream.listen(controller.updateState);
      addTearDown(states.cancel);
      final errors = adapter.player.stream.error.listen((error) {
        if (error is mpv.MpvEndFileError) controller.reportError(error);
      });
      addTearDown(errors.cancel);
      final selected = Song(
        pluginId: 'fixture',
        id: 'no-address',
        title: '无地址',
      );
      controller.song.value = selected;
      Future<void> openAndFail(String uri) async {
        final ended = adapter.player.stream.error
            .firstWhere((error) => error is mpv.MpvEndFileError)
            .timeout(const Duration(seconds: 10));
        await adapter.open(
          mpv.Media(uri, extras: {'song': selected.toJson(), 'loadId': 0}),
        );
        await adapter.play();
        await ended;
      }

      await openAndFail('mixmusic://no-address');
      expect(controller.status.value, '播放失败：音源未返回可播放地址');
      expect(adapter.currentState.errorMessage, '音源未返回可播放地址');
      expect(controller.playing.value, isFalse);
      // 地址解析成功，随后真正的文件加载失败，不应沿用上次“没有地址”。
      api.url = File('${directory.path}/missing.wav').uri.toString();
      await openAndFail('mixmusic://bad-file');
      expect(controller.status.value, contains('MpvEndFileError'));
      expect(controller.status.value, isNot(contains('音源未返回可播放地址')));
    },
    skip: !const bool.fromEnvironment('MPV_RECOVERY_SMOKE'),
  );
  test('resolver retry success clears both host and adapter failure without switching songs', () async {
    mpv.MpvAudioKit.ensureInitialized(
      libmpv: File('build/windows/x64/runner/Release/libmpv.dll').absolute.path,
    );
    final directory = await Directory.systemTemp.createTemp('mix_recovery_');
    addTearDown(() => directory.delete(recursive: true));
    final plugins = PluginController(
      store: JsExtensionFileStore(directoryPath: '${directory.path}/plugins'),
      storage: JsMemoryKvStore(),
    );
    addTearDown(plugins.disposeController);
    await plugins.restored;
    final api = RecoveryApi(plugins.manager);
    plugins.builtins['fixture'] = api;
    final controller = PlayerController(
      plugins,
      cache: MusicCache(directory: directory),
    );
    addTearDown(controller.disposeController);
    controller.cache.enabled.value = false;
    final adapter = controller.engine = MpvPlayer();
    await adapter.player.setRawProperty('ao', 'null');
    await adapter.player.setSourceResolver(controller.resolve);
    final states = adapter.stateStream.listen(controller.updateState);
    addTearDown(states.cancel);
    final errors = adapter.player.stream.error.listen((error) {
      if (error is mpv.MpvEndFileError) controller.reportError(error);
    });
    addTearDown(errors.cancel);
    final selected = Song(
      pluginId: 'fixture',
      id: {'mid': 'same'},
      title: '同一首歌',
    );
    controller.song.value = selected;
    final playing = adapter.stateStream
        .firstWhere(
          (state) =>
              state.playing &&
              state.position > const Duration(milliseconds: 200),
        )
        .timeout(const Duration(seconds: 10));
    await adapter.open(
      mpv.Media(
        'mixmusic://recovery',
        extras: {'song': selected.toJson(), 'loadId': 0},
      ),
    );
    await adapter.play();
    await playing;
    expect(api.calls, 2);
    expect(controller.status.value, isEmpty);
    expect(controller.playing.value, isTrue);
    expect(adapter.currentState.errorMessage, isNull);
    expect(
      adapter.currentState.processingState,
      isNot(LemonProcessingState.error),
    );
    controller.reportError(StateError('another failure'));
    expect(adapter.currentState.processingState, LemonProcessingState.error);
    expect(controller.playing.value, isFalse);
  }, skip: !const bool.fromEnvironment('MPV_RECOVERY_SMOKE'));
  test('native load failure publishes error and notification play reloads valid media', () async {
    mpv.MpvAudioKit.ensureInitialized(
      libmpv: File('build/windows/x64/runner/Release/libmpv.dll').absolute.path,
    );
    var retries = 0;
    late MpvPlayer adapter;
    adapter = MpvPlayer(
      onRetry: () async {
        retries++;
        await adapter.open(
          mpv.Media(
            File('E:/lemon_audio/example/assets/test-tone.wav').uri.toString(),
          ),
        );
        await adapter.play();
      },
    );
    addTearDown(adapter.dispose);
    await adapter.player.setRawProperty('ao', 'null');
    final subscription = adapter.player.stream.error.listen((error) {
      if (error is mpv.MpvEndFileError) adapter.fail(error);
    });
    addTearDown(subscription.cancel);
    final error = adapter.stateStream
        .firstWhere(
          (state) => state.processingState == LemonProcessingState.error,
        )
        .timeout(const Duration(seconds: 10));
    await adapter.open(
      mpv.Media(
        File('${Directory.systemTemp.path}/mixmusic_missing_audio.wav').uri
            .toString(),
      ),
    );
    try {
      await adapter.play();
    } catch (failure) {
      adapter.fail(failure);
    }
    expect((await error).playing, isFalse);
    final position = adapter.currentState.position;
    // 底层再次发出 playWhenReady，也不能覆盖已锁定的失败状态。
    await adapter.player.play();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(adapter.currentState.processingState, LemonProcessingState.error);
    expect(adapter.currentState.playing, isFalse);
    expect(adapter.currentState.position, position);
    final advancing = adapter.player.stream.position
        .firstWhere((value) => value > const Duration(milliseconds: 200))
        .timeout(const Duration(seconds: 10));
    await adapter.play();
    await advancing;
    expect(retries, 1);
    expect(
      adapter.currentState.processingState,
      isNot(LemonProcessingState.error),
    );
  }, skip: !const bool.fromEnvironment('MPV_RECOVERY_SMOKE'));
}
