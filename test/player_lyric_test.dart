import 'package:flutter_test/flutter_test.dart';
import 'package:mix_music/common/player/player_controller.dart';
import 'package:mix_music/common/plugin/plugin_controller.dart';

class TitleLyricPlayer extends PlayerController {
  TitleLyricPlayer(super.plugins);
  final titles = <String?>[];

  @override
  Future<void> updateMediaLyric(String? text) async => titles.add(text);
}

void main() {
  test(
    'title lyrics follow lines, deduplicate ticks and restore when disabled',
    () async {
      final plugins = PluginController();
      final player = TitleLyricPlayer(plugins);
      addTearDown(plugins.disposeController);
      addTearDown(player.disposeController);
      player.lyric.value = {'lrc': '[00:00]第一句\n[00:03]第二句'};
      await player.lyrics.load();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(player.titles, isEmpty);
      await player.setTitleLyrics(true);
      expect(player.titles.last, '第一句');
      final count = player.titles.length;
      player.position.value = const Duration(seconds: 1);
      player.lyrics.update();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(player.titles.length, count);
      player.position.value = const Duration(seconds: 4);
      player.lyrics.update();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(player.titles.last, '第二句');
      player.position.value = Duration.zero;
      player.lyrics.update();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(player.titles.last, '第一句');
      await player.setTitleLyrics(false);
      expect(player.titles.last, isNull);
      final disabledCount = player.titles.length;
      player.position.value = const Duration(seconds: 4);
      player.lyrics.update();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(player.titles.length, disabledCount);
      await player.setTitleLyrics(true);
      expect(player.titles.last, '第二句');
      player.lyric.value = null;
      await player.lyrics.load();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(player.titles.last, isNull);
      expect(player.engine, isNull);
    },
  );

  test('global lyrics update without creating a playback page', () async {
    final plugins = PluginController();
    final player = PlayerController(plugins);
    final lyric = player.lyrics;
    player.lyric.value = {'lrc': '[00:00]开始\n[00:03]继续'};
    await Future<void>.delayed(Duration.zero);
    expect(lyric.controller.document.lines.first.text, '开始');
    player.position.value = const Duration(seconds: 4);
    player.playing.value = true;
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(lyric.controller.currentLine?.text, '继续');
    expect(player.lyrics, same(lyric));
    player.lyric.value = {'lrc': '[00:00]下一首'};
    await Future<void>.delayed(Duration.zero);
    expect(lyric.controller.document.lines.single.text, '下一首');
    player.lyric.value = null;
    await Future<void>.delayed(Duration.zero);
    expect(lyric.controller.document.lines, isEmpty);
    await player.disposeController();
    await plugins.disposeController();
  });

  test(
    'lyrics merge translations, follow position and clear between songs',
    () async {
      final plugins = PluginController();
      final player = PlayerController(plugins);
      player.lyric.value = {
        'lrc': '[00:00.00]第一句\n[00:03.00]第二句',
        'translation': '[00:00.00]First\n[00:03.00]Second',
      };
      final lyric = player.lyrics;
      await lyric.load();
      expect(lyric.controller.document.lines.first.text, '第一句');
      expect(
        lyric.controller.document.lines.first.alternatives['translation'],
        'First',
      );
      player.position.value = const Duration(seconds: 4);
      lyric.update();
      await Future<void>.delayed(const Duration(milliseconds: 25));
      expect(lyric.controller.currentLine?.text, '第二句');
      player.position.value = Duration.zero;
      lyric.update();
      expect(lyric.controller.currentLine?.text, '第一句');
      player.lyric.value = null;
      await lyric.load();
      expect(lyric.controller.document.lines, isEmpty);
      player.position.value = const Duration(seconds: 9);
      await Future<void>.delayed(Duration.zero);
      await player.disposeController();
      await plugins.disposeController();
    },
  );

  test('enhanced LRC retains word timing', () async {
    final plugins = PluginController();
    final player = PlayerController(plugins);
    player.lyric.value = {
      'lrc': '[00:00.00]<00:00.00>Hello <00:01.00>world<00:02.00>',
    };
    final lyric = player.lyrics;
    await lyric.load();
    expect(
      lyric.controller.document.lines.first.tokens.length,
      greaterThanOrEqualTo(2),
    );
    await player.disposeController();
    await plugins.disposeController();
  });
}
