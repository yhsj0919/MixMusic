import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mix_music/page/setting/setting_controller.dart';
import 'package:mix_music/common/download/download_controller.dart';
import 'package:mix_music/common/download/download_files.dart';
import 'package:mix_music/common/entity/song.dart';
import 'package:mix_music/common/entity/quality.dart';
import 'package:mix_music/common/local/local_music_controller.dart';
import 'package:mix_music/common/player/music_cache.dart';
import 'package:mix_music/common/player/player_controller.dart';
import 'package:mix_music/common/plugin/plugin_controller.dart';

class SettingsPlayer extends PlayerController {
  SettingsPlayer(super.plugins, {super.preferences});

  @override
  Future<void> reloadSong(
    Song selected, {
    Duration start = Duration.zero,
    bool play = true,
    bool keepLyric = false,
  }) async {
    song.value = selected;
  }
}

class SettingsFiles extends DownloadFiles {
  bool authorized = true;
  @override
  Future<void> checkDirectory(String directory) async {
    if (!authorized) throw StateError('测试：目录授权失效');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences preferences;
  late PluginController plugins;
  late Directory root;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    plugins = PluginController();
    root = await Directory.systemTemp.createTemp('mixmusic-preferences-');
  });
  tearDown(() async {
    await plugins.disposeController();
    await root.delete(recursive: true);
  });

  test('theme survives controller recreation', () async {
    final first = SettingController(preferences: preferences);
    await first.setDarkMode(true);
    await first.disposeController();
    await preferences.reload();
    final restored = SettingController(preferences: preferences);
    addTearDown(restored.disposeController);
    expect(restored.darkMode.value, isTrue);
  });

  test(
    'playback controls, default quality and equalizer persist without audio',
    () async {
      final player = PlayerController(plugins, preferences: preferences);
      await player.setDefaultQuality(1000);
      await player.setVolume(.35);
      await player.setMuted(true);
      await player.setSpeed(1.25);
      await player.setAllowConcurrentPlayback(true);
      await player.setTitleLyrics(true);
      player.cycleMode();
      await player.equalizer.selectPreset('摇滚');
      await player.equalizer.setBand(0, 7);
      await player.equalizer.setEnabled(true);
      await player.disposeController();
      await preferences.reload();
      final restored = PlayerController(plugins, preferences: preferences);
      addTearDown(restored.disposeController);
      expect(restored.defaultQuality.value, 1000);
      expect(restored.volume.value, .35);
      expect(restored.muted.value, isTrue);
      expect(restored.speed.value, 1.25);
      expect(restored.allowConcurrentPlayback.value, isTrue);
      expect(restored.titleLyrics.value, isTrue);
      expect(restored.mode.value, PlayMode.loop);
      expect(restored.equalizer.enabled.value, isTrue);
      expect(restored.equalizer.preset.value, '自定义');
      expect(restored.equalizer.gains.value.first, 7);
      expect(restored.engine, isNull);
    },
  );

  test(
    'temporary quality does not change defaults or the queue snapshot',
    () async {
      final player = SettingsPlayer(plugins, preferences: preferences);
      addTearDown(player.disposeController);
      await player.setDefaultQuality(320);
      player.addSong(Song(pluginId: 'test', id: 1, title: 'A'));
      player.addSong(Song(pluginId: 'test', id: 2, title: 'B'));
      await player.playAt(0);
      expect(player.song.value!.playQuality, 320);
      await player.changeQuality(128);
      expect(player.song.value!.playQuality, 128);
      expect(player.defaultQuality.value, 320);
      expect(preferences.getInt('playQuality'), 320);
      expect(player.queue.value.first.playQuality, isNull);
      await player.playAt(1);
      expect(player.song.value!.playQuality, 320);
      await player.playAt(0);
      expect(player.song.value!.playQuality, 320);
    },
  );

  test(
    'playback chooses an available quality without raising the preference',
    () {
      final qualities = [
        Quality(pluginId: 'test', id: 1, title: '标准', value: 128),
        Quality(pluginId: 'test', id: 2, title: '高品质', value: 320),
      ];
      expect(Quality.select(qualities, 1000), 320);
      expect(Quality.select(qualities, 128), 128);
    },
  );

  test(
    'download settings restore independently and preserve directory grants',
    () async {
      final files = SettingsFiles();
      final first = DownloadController(
        plugins,
        preferences: preferences,
        files: files,
      );
      await first.restored;
      await first.setDirectory('content://test/tree/download');
      await first.setRetryCount(4);
      await first.setDefaultQuality(2000);
      await first.disposeController();
      await preferences.reload();
      final restored = DownloadController(
        plugins,
        preferences: preferences,
        files: files,
      );
      addTearDown(restored.disposeController);
      await restored.restored;
      expect(restored.selectedDirectory.value, 'content://test/tree/download');
      expect(restored.retryCount.value, 4);
      expect(restored.defaultQuality.value, 2000);
      expect(preferences.getInt('playQuality'), isNull);
      final task = restored.add(
        Song(pluginId: 'test', id: 1, title: 'A', playQuality: 128),
      );
      restored.cancel(task);
      expect(task.song.playQuality, 2000);
    },
  );

  test(
    'lost directory authorization is visible and choosing again clears it',
    () async {
      await preferences.setString(
        'downloadDirectory',
        'content://test/tree/lost',
      );
      final files = SettingsFiles()..authorized = false;
      final controller = DownloadController(
        plugins,
        preferences: preferences,
        files: files,
      );
      addTearDown(controller.disposeController);
      await controller.restored;
      expect(controller.directoryError.value, contains('重新选择'));
      expect(controller.selectedDirectory.value, 'content://test/tree/lost');
      files.authorized = true;
      await controller.setDirectory(root.path);
      expect(controller.directoryError.value, isEmpty);
    },
  );

  test(
    'music directories migrate once then use SP rather than rewriting JSON',
    () async {
      final file = File('${root.path}/directories.json');
      await file.writeAsString('[]');
      final local = LocalMusicController(
        configFile: file,
        preferences: preferences,
      );
      await local.restored;
      await local.addDirectory(root.path);
      await local.disposeController();
      expect(await file.readAsString(), '[]');
      final restored = LocalMusicController(
        configFile: file,
        preferences: preferences,
      );
      addTearDown(restored.disposeController);
      await restored.restored;
      expect(restored.directories.value, [root.absolute.uri.toString()]);
    },
  );

  test('cache settings in SP take priority over the old cache index', () async {
    await File('${root.path}/index.json')
        .writeAsString('{"enabled":true,"limitBytes":1048576,"entries":[]}');
    final cache = MusicCache(directory: root, preferences: preferences);
    await cache.restored;
    await cache.setEnabled(false);
    await cache.setLimit(2 * 1024 * 1024);
    await cache.dispose();
    await preferences.reload();
    final restored = MusicCache(directory: root, preferences: preferences);
    addTearDown(restored.dispose);
    await restored.restored;
    expect(restored.enabled.value, isFalse);
    expect(restored.limitBytes.value, 2 * 1024 * 1024);
  });
}
