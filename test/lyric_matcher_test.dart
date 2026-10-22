import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lemon_js_extensions/lemon_js_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mix_music/common/api/music_api.dart';
import 'package:mix_music/common/entity/song.dart';
import 'package:mix_music/common/player/player_controller.dart';
import 'package:mix_music/common/plugin/plugin_controller.dart';

Song track(String id, [String plugin = 'local']) => Song(
  pluginId: plugin,
  id: id,
  title: '测试歌曲',
  details: {
    'artist': [
      {'title': '测试歌手'},
    ],
  },
);

class LyricApi extends MusicApi {
  LyricApi(super.manager, super.pluginId);
  final calls = <String>[];
  List<Song> candidates = [];
  Map<String, dynamic> data = {};
  Completer<Map<String, dynamic>>? gate;
  @override
  Future<List<Song>> searchMusic(
    String keyword, [
    int page = 0,
    int size = 20,
  ]) async {
    calls.add('search');
    return candidates;
  }

  @override
  Future<Map<String, dynamic>> lrc(Song song) async {
    calls.add('lrc:${song.id}');
    if (song.id == 'slow' && gate != null) return gate!.future;
    if (song.id == 'bad') throw StateError('测试歌词失败');
    return data;
  }

  @override
  Future<Song> playUrl(Song song) async => throw StateError('歌词流程不应请求播放地址');
}

class WaitingAudioPlayer extends PlayerController {
  WaitingAudioPlayer(super.plugins);
  final gate = Completer<void>();
  @override
  Future<void> initializeAudio() async {
    await gate.future;
    throw StateError('模拟音频初始化失败');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PluginController plugins;
  late LyricApi local;
  late LyricApi lyrics;
  setUp(() {
    plugins = PluginController(
      store: JsExtensionMemoryStore(),
      storage: JsMemoryKvStore(),
    );
    local = LyricApi(plugins.manager, 'local');
    lyrics = LyricApi(plugins.manager, 'lyrics');
    plugins.builtins.addAll({'local': local, 'lyrics': lyrics});
  });
  tearDown(() => plugins.disposeController());

  test('original lyrics remain independent of matched audio and preserve extra fields', () async {
    local.data = {
      'lrc': '[00:00]<00:00>原歌词<00:01>',
      'translation': '[00:00]翻译',
      'format': 'enhancedLrc',
      'extra': {'words': true},
    };
    final original = track('song')..matchedSong = track('other', 'audio');
    final result = await plugins.lyricMatcher.resolve(original);
    expect(result!.source.pluginId, 'local');
    expect(result.data, local.data);
    expect(local.calls, ['lrc:song']);
    expect(lyrics.calls, isEmpty);
    expect(original.matchedSong!.pluginId, 'audio');
  });

  test('local empty lyrics match independently of playback matching', () async {
    lyrics.candidates = [track('bad', 'lyrics'), track('good', 'lyrics')];
    lyrics.data = {'lrc': '[00:00]匹配歌词', 'romanization': '[00:00]test'};
    await plugins.lyricMatcher.setEnabled(true);
    await plugins.lyricMatcher.setSources(['lyrics']);
    final result = await plugins.lyricMatcher.resolve(track('local-song'));
    expect(result!.source.id, 'good');
    expect(result.data['romanization'], isNotNull);
    expect(plugins.matcher.enabled.value, false);
    expect(lyrics.calls, ['search', 'lrc:bad', 'lrc:good']);
  });

  test('disabled or low confidence does not fetch candidate lyrics', () async {
    lyrics.candidates = [track('wrong', 'lyrics')..title = '完全不同的内容'];
    await plugins.lyricMatcher.setSources(['lyrics']);
    expect(await plugins.lyricMatcher.resolve(track('a')), isNull);
    expect(lyrics.calls, isEmpty);
    await plugins.lyricMatcher.setEnabled(true);
    expect(await plugins.lyricMatcher.resolve(track('a')), isNull);
    expect(lyrics.calls, ['search']);
  });

  test('new lyric request wins and stop clears global lyric source', () async {
    final player = PlayerController(plugins);
    addTearDown(player.disposeController);
    local.gate = Completer<Map<String, dynamic>>();
    local.data = {'lrc': '[00:00]新歌词'};
    final slow = player.loadLyric(track('slow'));
    await player.loadLyric(track('fast'));
    local.gate!.complete({'lrc': '[00:00]旧歌词'});
    await slow;
    expect(player.lyric.value!['lrc'], '[00:00]新歌词');
    expect(player.lyricSource.value!.id, 'fast');
    await player.stopPlayback();
    expect(player.lyric.value, isNull);
    expect(player.lyricSource.value, isNull);
  });

  test('lyric starts before audio initialization and audio failure does not discard it', () async {
    final player = WaitingAudioPlayer(plugins);
    addTearDown(player.disposeController);
    local.data = {'lrc': '[00:00]独立歌词'};
    final pending = player.reloadSong(track('song'));
    await Future<void>.delayed(Duration.zero);
    expect(player.lyric.value!['lrc'], '[00:00]独立歌词');
    expect(player.engine, isNull);
    player.gate.complete();
    await pending;
    expect(player.lyric.value!['lrc'], '[00:00]独立歌词');
  });

  test('a lyric plugin needs no playback export', () async {
    await plugins.install(
      JsExtensionPackage(
        manifestSource: jsonEncode({
          'schemaVersion': 2,
          'id': 'test.lyrics',
          'name': '歌词示例',
          'description': '歌词功能验证',
          'version': '1.0.0',
          'versionCode': 1,
          'compatibilityCode': 'mixmusic-source-v1',
          'service': {
            'entry': 'main.mjs',
            'contract': 'mixmusic-source/v1',
            'publicExports': ['searchMusic', 'lrc'],
          },
        }),
        serviceModules: {
          'main.mjs': '''
export function searchMusic() { return [{id:1,title:'测试歌曲',artist:[{title:'测试歌手'}]}]; }
export function lrc() { return {lrc:'[00:00]独立插件歌词'}; }
''',
        },
      ),
    );
    expect(plugins.lyricMatcher.available('test.lyrics'), true);
    expect(plugins.matcher.available('test.lyrics'), false);
    expect(plugins.homeSources, isEmpty);
    await plugins.lyricMatcher.setEnabled(true);
    await plugins.lyricMatcher.setSources(['test.lyrics']);
    expect(
      (await plugins.lyricMatcher.resolve(track('song')))!.data['lrc'],
      '[00:00]独立插件歌词',
    );
  });

  test('lyric failure does not change playback status', () async {
    final player = PlayerController(plugins);
    addTearDown(player.disposeController);
    player.playing.value = true;
    player.status.value = '';
    await player.loadLyric(track('bad'));
    expect(player.playing.value, true);
    expect(player.status.value, '');
    expect(player.lyric.value, isNull);
  });

  test(
    'audio-only reload does not invalidate a pending lyric request',
    () async {
      final player = WaitingAudioPlayer(plugins);
      addTearDown(player.disposeController);
      local.gate = Completer<Map<String, dynamic>>();
      final first = player.reloadSong(track('slow'));
      final second = player.reloadSong(track('slow'), keepLyric: true);
      local.gate!.complete({'lrc': '[00:00]仍然有效'});
      await Future<void>.delayed(Duration.zero);
      expect(player.lyric.value!['lrc'], '[00:00]仍然有效');
      player.gate.complete();
      await Future.wait([first, second]);
    },
  );

  test('candidate list reuses automatic search, exposes low scores and supports refresh', () async {
    lyrics.candidates = [
      track('good', 'lyrics'),
      track('other', 'lyrics')..title = '不同的歌曲',
    ];
    lyrics.data = {'lrc': '[00:00]歌词'};
    await plugins.lyricMatcher.setEnabled(true);
    await plugins.lyricMatcher.setSources(['lyrics']);
    await plugins.lyricMatcher.resolve(track('song'));
    final items = await plugins.lyricMatcher.candidates(track('song'));
    expect(items.map((s) => s.id), ['good', 'other']);
    expect(lyrics.calls.where((call) => call == 'search'), hasLength(1));
    await plugins.lyricMatcher.candidates(track('song'), refresh: true);
    expect(lyrics.calls.where((call) => call == 'search'), hasLength(2));
  });

  test('manual lyric switch does not alter audio, progress, status or original identity', () async {
    final player = PlayerController(plugins);
    addTearDown(player.disposeController);
    final original = track('song')
      ..matchedSong = track('audio', 'audio-source');
    player.song.value = original;
    player.playing.value = true;
    player.position.value = const Duration(seconds: 30);
    lyrics.data = {'lrc': '[00:00]手动歌词'};
    expect(await player.switchLyric(original, track('chosen', 'lyrics')), true);
    expect(player.lyricSource.value!.pluginId, 'lyrics');
    expect(player.lyric.value!['lrc'], '[00:00]手动歌词');
    expect(player.song.value, same(original));
    expect(player.song.value!.actualSong.pluginId, 'audio-source');
    expect(player.position.value, const Duration(seconds: 30));
    expect(player.playing.value, true);
    expect(player.status.value, '');
    expect(player.engine, isNull);
  });

  test('empty manual candidate keeps the current lyrics', () async {
    final player = PlayerController(plugins);
    addTearDown(player.disposeController);
    final original = track('song');
    player.song.value = original;
    player.lyric.value = {'lrc': '[00:00]保留'};
    expect(await player.switchLyric(original, track('empty', 'lyrics')), false);
    expect(player.lyric.value!['lrc'], '[00:00]保留');
  });

  test(
    'old dialog and late manual results cannot replace another song lyrics',
    () async {
      final player = PlayerController(plugins);
      addTearDown(player.disposeController);
      final original = track('song');
      player.song.value = original;
      lyrics.gate = Completer<Map<String, dynamic>>();
      final pending = player.switchLyric(original, track('slow', 'lyrics'));
      player.song.value = track('next');
      local.data = {'lrc': '[00:00]下一首'};
      await player.loadLyric(player.song.value!);
      lyrics.gate!.complete({'lrc': '[00:00]过期'});
      expect(await pending, false);
      expect(player.lyric.value!['lrc'], '[00:00]下一首');
      final before = lyrics.calls.length;
      expect(await player.switchLyric(original, track('old', 'lyrics')), false);
      expect(lyrics.calls.length, before);
    },
  );

  test('lyric settings persist separately from audio matching', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final configured = PluginController(
      store: JsExtensionMemoryStore(),
      storage: JsMemoryKvStore(),
      preferences: prefs,
    );
    addTearDown(configured.disposeController);
    await configured.lyricMatcher.setEnabled(true);
    await configured.lyricMatcher.setSources(['lyrics']);
    final restored = PluginController(
      store: JsExtensionMemoryStore(),
      storage: JsMemoryKvStore(),
      preferences: prefs,
    );
    addTearDown(restored.disposeController);
    expect(restored.lyricMatcher.enabled.value, true);
    expect(restored.lyricMatcher.sources.value, ['lyrics']);
    expect(restored.matcher.enabled.value, false);
    expect(restored.matcher.sources.value, isEmpty);
  });
}
