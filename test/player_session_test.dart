import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lemon_js_extensions/lemon_js_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mix_music/common/api/music_api.dart';
import 'package:mix_music/common/entity/play_list.dart';
import 'package:mix_music/common/entity/song.dart';
import 'package:mix_music/common/player/player_controller.dart';
import 'package:mix_music/common/player/player_session.dart';
import 'package:mix_music/common/plugin/collection_controller.dart';
import 'package:mix_music/common/plugin/plugin_controller.dart';

class SessionPlayer extends PlayerController {
  SessionPlayer(super.plugins, {super.preferences});
  Song? resumed;
  Duration? start;
  @override
  Future<void> reloadSong(
    Song song, {
    Duration start = Duration.zero,
    bool play = true,
    bool keepLyric = false,
  }) async {
    session.pending = false;
    resumed = song;
    this.start = start;
  }
}

class SessionApi extends MusicApi {
  SessionApi(JsExtensionManager manager) : super(manager, 'fixture');
  final calls = <String>[];
  @override
  Future<Map<String, dynamic>> lrc(Song song) async {
    calls.add('lyric');
    return {'lrc': '[00:00]恢复的歌词'};
  }

  @override
  Future<PlayList> playListInfo(
    PlayList resource, [
    int page = 0,
    int size = 20,
  ]) async {
    calls.add('${resource.id}:$page');
    return PlayList(
      pluginId: 'fixture',
      id: resource.id,
      total: 40,
      songs: [
        for (var i = page * size; i < (page + 1) * size; i++)
          Song(pluginId: 'fixture', id: '${resource.id}-$i', title: '$i'),
      ],
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences preferences;
  late PluginController plugins;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    plugins = PluginController(store: JsExtensionMemoryStore());
  });
  tearDown(() => plugins.disposeController());

  test('restart restores queue and position paused, with fresh address resolution deferred', () async {
    final api = SessionApi(plugins.manager);
    plugins.builtins['fixture'] = api;
    final player = SessionPlayer(plugins, preferences: preferences);
    final song = Song(
      pluginId: 'fixture',
      id: {
        'value': [1, 'x'],
        'url': 'opaque-id',
      },
      title: '歌曲',
      url: 'https://expired.test/song',
      playQuality: 320,
      details: {
        'httpHeaders': {'Cookie': 'secret'},
        'album': {'url': 'expired'},
      },
      matchedSong: Song(
        pluginId: 'matched',
        id: 2,
        title: '匹配',
        url: 'https://expired.test/matched',
      ),
    );
    player.addSong(song);
    player.addSong(Song(pluginId: 'other', id: 3, title: '下一首'));
    player.currentIndex.value = 0;
    player.song.value = song;
    player.position.value = const Duration(seconds: 42);
    player.duration.value = const Duration(minutes: 4);
    player.playing.value = true;
    player.mode.value = PlayMode.shuffle;
    await player.disposeController();
    final text = preferences.getString(PlayerSession.key)!;
    expect(text, isNot(contains('expired.test')));
    expect(text, isNot(contains('secret')));
    final restored = SessionPlayer(plugins, preferences: preferences);
    addTearDown(restored.disposeController);
    expect(restored.queue.value.map((song) => song.pluginId), [
      'fixture',
      'other',
    ]);
    expect(restored.song.value!.id, song.id);
    expect(restored.song.value!.matchedSong!.id, 2);
    expect(restored.song.value!.actualSong.url, isNull);
    expect(restored.position.value, const Duration(seconds: 42));
    expect(restored.duration.value, const Duration(minutes: 4));
    expect(restored.mode.value, PlayMode.shuffle);
    expect(restored.playing.value, isFalse);
    expect(restored.engine, isNull);
    expect(restored.resumed, isNull);
    expect(api.calls, isEmpty);
    expect(restored.lyric.value, isNull);
    await restored.seek(const Duration(seconds: 60));
    expect(restored.engine, isNull);
    await restored.play();
    await Future<void>.delayed(Duration.zero);
    expect(restored.start, const Duration(seconds: 60));
    expect(restored.resumed!.id, song.id);
    expect(api.calls, ['lyric']);
    expect(restored.lyric.value!['lrc'], '[00:00]恢复的歌词');
    expect(restored.lyricSource.value!.pluginId, 'fixture');
  });

  test(
    'partial collections retain pages, removals and appended source barriers',
    () async {
      final api = SessionApi(plugins.manager);
      plugins.builtins['fixture'] = api;
      final a = plugins.collection(
        CollectionKind.playlist,
        PlayList(pluginId: 'fixture', id: 'a'),
      );
      final b = plugins.collection(
        CollectionKind.playlist,
        PlayList(pluginId: 'fixture', id: 'b'),
      );
      await a.loadMore();
      final player = SessionPlayer(plugins, preferences: preferences);
      await player.addCollection(a);
      await player.addCollection(b);
      player.hyperQueue.remove(0);
      player.addSong(Song(pluginId: 'fixture', id: 'tail', title: '尾曲'));
      player.currentIndex.value = 18;
      player.song.value = player.queue.value[18];
      await player.disposeController();
      final freshPlugins = PluginController(store: JsExtensionMemoryStore());
      addTearDown(freshPlugins.disposeController);
      final freshApi = SessionApi(freshPlugins.manager);
      freshPlugins.builtins['fixture'] = freshApi;
      final restored = SessionPlayer(freshPlugins, preferences: preferences);
      addTearDown(restored.disposeController);
      expect(freshApi.calls, isEmpty);
      expect(restored.queue.value.first.id, 'a-1');
      expect(restored.queue.value.last.id, 'tail');
      expect(restored.hyperQueue.hasMore, isTrue);
      await restored.loadMoreQueue(viewing: true);
      expect(freshApi.calls, ['a:1']);
      expect(restored.queue.value.where((song) => song.id == 'a-0'), isEmpty);
      expect(restored.queue.value[19].id, 'a-20');
      await restored.loadMoreQueue(viewing: true);
      expect(freshApi.calls, ['a:1', 'b:0']);
      expect(restored.queue.value.last.id, 'tail');
    },
  );

  test('cleared queue cannot resurrect and malformed snapshots do not break startup', () async {
    final player = SessionPlayer(plugins, preferences: preferences);
    player.addSong(Song(pluginId: 'fixture', id: 1, title: '歌曲'));
    player.currentIndex.value = 0;
    player.song.value = player.queue.value.first;
    await player.session.save();
    await player.clearQueue();
    await player.disposeController();
    final restored = SessionPlayer(plugins, preferences: preferences);
    expect(restored.queue.value, isEmpty);
    expect(restored.song.value, isNull);
    await restored.disposeController();
    await preferences.setString(PlayerSession.key, '{broken');
    final malformed = SessionPlayer(plugins, preferences: preferences);
    addTearDown(malformed.disposeController);
    expect(malformed.queue.value, isEmpty);
    expect(malformed.engine, isNull);
    expect(
      () => jsonDecode(preferences.getString(PlayerSession.key)!),
      throwsFormatException,
    );
  });
}
