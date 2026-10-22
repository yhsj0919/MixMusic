import 'package:flutter_test/flutter_test.dart';
import 'package:mix_music/common/entity/song.dart';
import 'package:mix_music/common/player/equalizer_controller.dart';
import 'package:mix_music/common/player/player_controller.dart';
import 'package:mix_music/common/plugin/plugin_controller.dart';

class QualityPlayer extends PlayerController {
  QualityPlayer(super.plugins);
  Song? reloaded;
  Duration? start;
  bool? resume;
  bool? preserved;
  int reloads = 0;

  @override
  Future<void> reloadSong(
    Song selected, {
    Duration start = Duration.zero,
    bool play = true,
    bool keepLyric = false,
  }) async {
    reloads++;
    reloaded = selected;
    this.start = start;
    resume = play;
    preserved = keepLyric;
  }
}

void main() {
  test(
    'manual source switch retains identity, position, pause and original queue',
    () async {
      final plugins = PluginController();
      final player = QualityPlayer(plugins);
      addTearDown(plugins.disposeController);
      addTearDown(player.disposeController);
      final original = Song(
        pluginId: 'original',
        id: {'id': 1},
        title: '原歌曲',
        playQuality: 128,
      );
      player.song.value = original;
      player.position.value = const Duration(seconds: 40);
      player.playing.value = false;
      final candidate = Song(pluginId: 'other', id: 2, title: '候选歌曲');
      await player.switchSource(original, candidate);
      expect(player.reloaded!.pluginId, 'original');
      expect(player.reloaded!.id, {'id': 1});
      expect(player.reloaded!.actualSong.pluginId, 'other');
      expect(player.start, const Duration(seconds: 40));
      expect(player.resume, false);
      expect(player.preserved, true);
      expect(original.matchedSong, isNull);
      await player.switchSource(
        Song(pluginId: 'changed', id: 3, title: '其他'),
        candidate,
      );
      expect(player.reloads, 1);
    },
  );

  test(
    'volume, mute and speed can be configured before audio initialization',
    () async {
      final plugins = PluginController();
      final player = PlayerController(plugins);
      addTearDown(plugins.disposeController);
      addTearDown(player.disposeController);
      await player.setVolume(.35);
      await player.setMuted(true);
      await player.setSpeed(1.5);
      await Future<void>.delayed(Duration.zero);
      expect(player.engine, isNull);
      expect(player.volume.value, .35);
      expect(player.muted.value, isTrue);
      expect(player.speed.value, 1.5);
      expect(player.lyrics.controller.playbackListenable.value.speed, 1.5);
      await player.setMuted(false);
      expect(player.volume.value, .35);
      await player.setVolume(2);
      await player.setSpeed(.1);
      expect(player.volume.value, 1);
      expect(player.speed.value, .5);
    },
  );

  test(
    'quality reload retains position, pause, identity, lyrics and queue order',
    () async {
      final plugins = PluginController();
      final player = QualityPlayer(plugins);
      addTearDown(plugins.disposeController);
      addTearDown(player.disposeController);
      final track = Song(
        pluginId: 'test',
        id: {
          'track': [1, 'a'],
        },
        title: '测试',
        playQuality: 128,
        url: 'https://example.invalid/old',
      );
      player.addSong(track);
      player.addSong(Song(pluginId: 'other', id: 1, title: '其他歌曲'));
      player.song.value = track;
      player.currentIndex.value = 0;
      player.position.value = const Duration(seconds: 42);
      final lyric = {'lrc': '[00:00]歌词'};
      player.lyric.value = lyric;
      await player.changeQuality(320);
      expect(player.reloaded!.id, track.id);
      expect(player.reloaded!.pluginId, 'test');
      expect(player.reloaded!.playQuality, 320);
      expect(player.reloaded!.url, isNull);
      expect(player.start, const Duration(seconds: 42));
      expect(player.resume, isFalse);
      expect(player.preserved, isTrue);
      expect(player.lyric.value, same(lyric));
      expect(player.queue.value.first.playQuality, 128);
      expect(player.queue.value.last.pluginId, 'other');
      expect(player.currentIndex.value, 0);
      expect(track.playQuality, 128);
      player.playing.value = true;
      await player.changeQuality(320);
      expect(player.resume, isTrue);
      await player.changeQuality(128);
      expect(player.reloads, 2);
    },
  );

  test(
    'equalizer keeps custom bands when disabled and presets reset all bands',
    () async {
      final plugins = PluginController();
      final player = PlayerController(plugins);
      addTearDown(plugins.disposeController);
      addTearDown(player.disposeController);
      final eq = player.equalizer;
      expect(eq.enabled.value, isFalse);
      expect(eq.gains.value.length, EqualizerController.frequencies.length);
      await eq.setBand(0, 30);
      expect(eq.gains.value.first, 12);
      expect(eq.preset.value, '自定义');
      await eq.setEnabled(true);
      await eq.setEnabled(false);
      expect(eq.gains.value.first, 12);
      for (final name in EqualizerController.presets.keys) {
        await eq.selectPreset(name);
        expect(eq.preset.value, name);
        expect(eq.gains.value.length, 18);
        expect(eq.gains.value, EqualizerController.presets[name]);
        expect(
          eq.gains.value.every((value) => value >= -12 && value <= 12),
          isTrue,
        );
      }
      expect(
        EqualizerController.presets.values
            .map((values) => values.join(','))
            .toSet()
            .length,
        EqualizerController.presets.length,
      );
      await eq.selectPreset('平直');
      expect(eq.gains.value.every((value) => value == 0), isTrue);
      expect(player.engine, isNull);
    },
  );
}
