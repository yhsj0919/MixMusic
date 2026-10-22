import 'package:flutter_test/flutter_test.dart';
import 'package:lemon_js_extensions/lemon_js_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mix_music/common/api/music_api.dart';
import 'package:mix_music/common/entity/song.dart';
import 'package:mix_music/common/plugin/plugin_controller.dart';
import 'package:mix_music/common/plugin/song_matcher.dart';
import 'package:mix_music/common/player/music_cache.dart';

Song track(
  String id, {
  String plugin = 'original',
  String title = '示例歌曲',
  String artist = '示例歌手',
}) => Song(
  pluginId: plugin,
  id: id,
  title: title,
  playQuality: 128,
  details: {
    'artist': [
      {'title': artist},
    ],
  },
);

class MatchApi extends MusicApi {
  MatchApi(super.manager, super.pluginId, this.items);
  final List<Song> items;
  int searches = 0;
  @override
  Future<List<Song>> searchMusic(
    String keyword, [
    int page = 0,
    int size = 20,
  ]) async {
    searches++;
    return items;
  }
}

void main() {
  test('scoring normalizes width, case, punctuation and preserves version differences', () {
    expect(
      SongMatcher.score(
        track('a', title: 'ＡＢＣ，歌曲'),
        track('b', title: 'abc 歌曲'),
      ),
      100,
    );
    for (final suffix in ['Live', '伴奏', '翻唱', 'Remix', '加速']) {
      expect(
        SongMatcher.score(track('a'), track('b', title: '示例歌曲 ($suffix)')),
        0,
      );
    }
    expect(SongMatcher.score(track('a'), track('b', artist: '另一歌手')), 0);
    expect(SongMatcher.similarity('', ''), 0);
    expect(
      SongMatcher.rank(track('a'), [
        track('first'),
        track('second'),
      ]).map((s) => s.id),
      ['first', 'second'],
    );
  });

  test('original succeeds without searching or mutating input', () async {
    final plugins = PluginController(
      store: JsExtensionMemoryStore(),
      storage: JsMemoryKvStore(),
    );
    addTearDown(plugins.disposeController);
    final original = track('a');
    final result = await plugins.matcher.resolve(
      original,
      (s) async => Song.fromJson(s.toJson())..url = 'https://example.test/a',
    );
    expect(result.pluginId, 'original');
    expect(original.url, isNull);
    expect(original.matchedSong, isNull);
  });

  test(
    'source priority, candidate failures and remembered actual source',
    () async {
      final plugins = PluginController(
        store: JsExtensionMemoryStore(),
        storage: JsMemoryKvStore(),
      );
      addTearDown(plugins.disposeController);
      final first = MatchApi(plugins.manager, 'first', [
        track('bad', plugin: 'first'),
        track('good', plugin: 'first'),
      ]);
      final second = MatchApi(plugins.manager, 'second', [
        track('other', plugin: 'second'),
      ]);
      plugins.builtins.addAll({'first': first, 'second': second});
      await plugins.matcher.setSources(['first', 'second']);
      await plugins.matcher.setEnabled(true);
      final calls = <String>[];
      Future<Song> load(Song s) async {
        calls.add('${s.pluginId}/${s.id}');
        if (s.pluginId == 'original' || s.id == 'bad') {
          throw StateError('测试无地址');
        }
        return Song.fromJson(s.toJson())
          ..url = 'https://example.test/audio'
          ..playQuality = 64;
      }

      final original = track('a');
      final result = await plugins.matcher.resolve(original, load);
      expect(result.id, 'good');
      expect(calls, ['original/a', 'first/bad', 'first/good']);
      final candidates = await plugins.matcher.candidates(original);
      expect(candidates, hasLength(3));
      expect(first.searches, 1);
      expect(second.searches, 1);
      await plugins.matcher.candidates(
        Song.fromJson(original.toJson())..playQuality = 64,
      );
      expect(first.searches, 1, reason: '切换音质不重复搜索候选');
      calls.clear();
      await plugins.matcher.resolve(original, load);
      expect(calls, ['original/a', 'first/good']);
      expect(original.playQuality, 128);
    },
  );

  test(
    'disabled matching does not search; batch flag is independent',
    () async {
      final plugins = PluginController(
        store: JsExtensionMemoryStore(),
        storage: JsMemoryKvStore(),
      );
      addTearDown(plugins.disposeController);
      final api = MatchApi(plugins.manager, 'next', [
        track('b', plugin: 'next'),
      ]);
      plugins.builtins['next'] = api;
      await plugins.matcher.setSources(['next']);
      Future<Song> load(Song s) async => Song.fromJson(s.toJson())
        ..url = s.pluginId == 'original' ? null : 'https://example.test/audio';
      await expectLater(
        plugins.matcher.resolve(track('a'), load),
        throwsStateError,
      );
      expect(api.searches, 0);
      expect(
        (await plugins.matcher.resolve(
          track('a'),
          load,
          allowMatch: true,
        )).pluginId,
        'next',
      );
    },
  );

  test('cache identity uses actual source, quality and opaque ID', () {
    final actual = track('b', plugin: 'next')
      ..id = {
        'key': [1, 'x'],
      }
      ..playQuality = 64;
    final original = track('a')..matchedSong = actual;
    expect(MusicCache.keyFor(original), MusicCache.keyFor(actual));
    final restored = Song.fromJson(original.toJson());
    expect(restored.pluginId, 'original');
    expect(restored.actualSong.id, {
      'key': [1, 'x'],
    });
    actual.playQuality = 128;
    expect(MusicCache.keyFor(original), isNot(MusicCache.keyFor(restored)));
  });

  test(
    'cancellation stops candidate searches after original failure',
    () async {
      final plugins = PluginController(
        store: JsExtensionMemoryStore(),
        storage: JsMemoryKvStore(),
      );
      addTearDown(plugins.disposeController);
      final api = MatchApi(plugins.manager, 'next', [
        track('b', plugin: 'next'),
      ]);
      plugins.builtins['next'] = api;
      await plugins.matcher.setSources(['next']);
      await plugins.matcher.setEnabled(true);
      await expectLater(
        plugins.matcher.resolve(
          track('a'),
          (s) async => s,
          cancelled: () => true,
        ),
        throwsStateError,
      );
      expect(api.searches, 0);
    },
  );

  test('match switch and ordered sources persist', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final plugins = PluginController(
      store: JsExtensionMemoryStore(),
      storage: JsMemoryKvStore(),
      preferences: prefs,
    );
    addTearDown(plugins.disposeController);
    await plugins.matcher.setEnabled(true);
    await plugins.matcher.setSources(['b', 'a']);
    final restored = PluginController(
      store: JsExtensionMemoryStore(),
      storage: JsMemoryKvStore(),
      preferences: prefs,
    );
    addTearDown(restored.disposeController);
    expect(restored.matcher.enabled.value, true);
    expect(restored.matcher.sources.value, ['b', 'a']);
  });
}
