import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lemon_js_extensions/lemon_js_extensions.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart' as mpv;
import 'package:mix_music/common/entity/song.dart';
import 'package:mix_music/common/player/player_controller.dart';
import 'package:mix_music/common/plugin/plugin_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('missing source URL is reported before opening audio', () async {
    final directory = await Directory.systemTemp.createTemp(
      'mixmusic-player-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final plugins = PluginController(
      store: JsExtensionFileStore(directoryPath: directory.path),
      storage: JsMemoryKvStore(),
    );
    addTearDown(plugins.disposeController);
    await plugins.restored;
    await plugins.manager.install(
      JsExtensionPackage(
        manifestSource: jsonEncode({
          'schemaVersion': 2,
          'id': 'test.player',
          'name': '播放测试',
          'description': '验证空资源地址',
          'version': '1.0.0',
          'versionCode': 1,
          'compatibilityCode': 'mixmusic-source-v1',
          'service': {
            'entry': 'main.mjs',
            'contract': 'mixmusic-source/v1',
            'publicExports': ['getHome', 'playUrl'],
          },
        }),
        serviceModules: {
          'main.mjs': '''
export function getHome() { return {songs: []}; }
export function playUrl(song) { return {...song, url: null}; }
''',
        },
      ),
    );
    final player = PlayerController(plugins);
    addTearDown(player.disposeController);
    final song = Song(
      pluginId: 'test.player',
      id: {'mid': 'test'},
      title: '测试',
    );
    player.song.value = song;
    await expectLater(
      player.resolve(
        mpv.SourceResolveRequest(
          media: mpv.Media(
            'mixmusic://test',
            extras: {'song': song.toJson(), 'loadId': 0},
          ),
          uri: 'mixmusic://test',
          isRetry: false,
        ),
      ),
      throwsStateError,
    );
    expect(player.status.value, contains('未返回可播放地址'));
    expect(plugins.logs.value.last.pluginId, 'test.player');
    expect(plugins.logs.value.last.level, 'error');
    expect(player.engine, isNull);
  });
}
