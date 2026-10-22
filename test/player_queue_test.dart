import 'package:flutter_test/flutter_test.dart';
import 'package:lemon_audio/lemon_audio.dart';
import 'package:mix_music/common/entity/quality.dart';
import 'package:mix_music/common/entity/song.dart';
import 'package:mix_music/common/player/player_controller.dart';
import 'package:mix_music/common/plugin/plugin_controller.dart';
import 'package:mix_music/common/plugin/collection_controller.dart';
import 'package:mix_music/common/api/music_api.dart';
import 'package:mix_music/common/entity/play_list.dart';

class QueuePlayer extends PlayerController {
  QueuePlayer(super.plugins);
  final played = <Song>[];

  @override
  Future<void> loadSong(Song selected) async {
    played.add(selected);
    song.value = selected;
    playing.value = true;
  }
}

Song track(dynamic id, {String source = 'test'}) => Song(
  pluginId: source,
  id: id,
  title: '$source-$id',
  qualities: [Quality(pluginId: source, id: id, title: '标准', value: 128)],
);

const ended = LemonPlayerState(
  playing: false,
  processingState: LemonProcessingState.completed,
);
const ready = LemonPlayerState(
  playing: true,
  processingState: LemonProcessingState.ready,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PluginController plugins;
  late QueuePlayer player;
  setUp(() {
    plugins = PluginController();
    player = QueuePlayer(plugins);
  });
  tearDown(() async {
    await player.disposeController();
    await plugins.disposeController();
  });

  CollectionController collection(List<Song> songs) {
    final value = CollectionController(
      MusicApi(plugins.manager, 'test'),
      CollectionKind.playlist,
      PlayList(pluginId: 'test', id: 1, title: '歌单'),
      (_, _) {},
    );
    value.songs.value = songs;
    value.hasMore.value = false;
    addTearDown(value.disposeController);
    return value;
  }

  test('play all replaces queue and keeps the playing first track', () async {
    final list = collection([track(1), track(2), track(3)]);
    player.addSong(track(99));
    await player.playSong(track(1), quality: 320);
    player.position.value = const Duration(seconds: 25);
    await player.addCollection(list, play: true);
    expect(player.queue.value.map((song) => song.id), [1, 2, 3]);
    expect(player.currentIndex.value, 0);
    expect(player.song.value!.id, 1);
    expect(player.song.value!.playQuality, 320);
    expect(player.position.value, const Duration(seconds: 25));
    expect(player.played.length, 1);
    await player.next();
    expect(player.song.value!.id, 2);
  });

  test(
    'play all starts first track when a different track is playing',
    () async {
      final list = collection([track(1), track(2)]);
      await player.playSong(track(2));
      await player.addCollection(list, play: true);
      expect(player.queue.value.map((song) => song.id), [1, 2]);
      expect(player.currentIndex.value, 0);
      expect(player.song.value!.id, 1);
      expect(player.played.map((song) => song.id), [2, 1]);
      await player.addCollection(list, play: true);
      expect(player.played.length, 2);
    },
  );

  test('adding a collection without play still appends', () async {
    final list = collection([track(1), track(2)]);
    await player.playSong(track(1));
    await player.addCollection(list);
    expect(player.queue.value.map((song) => song.id), [1, 2]);
    expect(player.played.length, 1);
    expect(player.currentIndex.value, 0);
  });

  test(
    'add snapshots, distinguish sources and opaque IDs, deduplicate maps',
    () {
      final original = track({
        'b': [
          1,
          {'x': 2},
        ],
        'a': 3,
      });
      player.addSong(original, quality: 320);
      expect(original.playQuality, isNull);
      expect(player.queue.value.single.playQuality, 320);
      player.addSong(
        track({
          'a': 3,
          'b': [
            1,
            {'x': 2},
          ],
        }),
      );
      expect(player.queue.value.length, 1);
      player.addSong(track(1));
      player.addSong(track('1'));
      player.addSong(track(1, source: 'other'));
      expect(player.queue.value.length, 4);
      expect(player.played, isEmpty);
      expect(plugins.logs.value, isEmpty);
    },
  );

  test(
    'resuming through the play API restores automatic next after pause',
    () async {
      player.addSong(track(0));
      player.addSong(track(1));
      await player.playAt(0);
      await player.pause();
      await player.play();
      player.updateState(ready);
      player.updateState(ended);
      await Future<void>.delayed(Duration.zero);
      expect(player.currentIndex.value, 1);
      expect(player.played.length, 2);
    },
  );

  test('play song uses queue and preserves chosen quality on replay', () async {
    final first = track(1);
    await player.playSong(first, quality: 320);
    player.addSong(track(2));
    await player.next();
    expect(player.song.value!.id, 2);
    expect(player.song.value!.playQuality, 128);
    await player.previous();
    expect(player.song.value!.id, 1);
    expect(player.song.value!.playQuality, 320);
    expect(first.playQuality, isNull);
    await player.playSong(track(1), quality: 64);
    expect(player.queue.value.length, 2);
    expect(player.song.value!.playQuality, 64);
    await player.playAt(-1);
    await player.playAt(10);
    expect(player.currentIndex.value, 0);
  });

  test(
    'play next reorders an existing item without interrupting current song',
    () async {
      for (var i = 0; i < 4; i++) {
        player.addSong(track(i));
      }
      await player.playAt(2);
      final count = player.played.length;
      player.addSong(track(0), next: true);
      expect(player.queue.value.map((song) => song.id), [1, 2, 0, 3]);
      expect(player.currentIndex.value, 1);
      expect(player.song.value!.id, 2);
      expect(player.played.length, count);
      player.addSong(track(2), next: true);
      expect(player.queue.value.length, 4);
      await player.next();
      expect(player.song.value!.id, 0);
      player.addSong(track(9), next: true);
      await player.next();
      expect(player.song.value!.id, 9);
    },
  );

  test(
    'removal keeps current selection; deleting current advances or stops',
    () async {
      for (var i = 0; i < 4; i++) {
        player.addSong(track(i));
      }
      await player.playAt(2);
      await player.removeSong(0);
      expect(player.currentIndex.value, 1);
      expect(player.song.value!.id, 2);
      expect(player.played.length, 1);
      await player.removeSong(2);
      expect(player.played.length, 1);
      await player.removeSong(1);
      expect(player.song.value!.id, 1);
      expect(player.currentIndex.value, 0);
      await player.removeSong(0);
      expect(player.queue.value, isEmpty);
      expect(player.song.value, isNull);
      expect(player.currentIndex.value, -1);
      expect(player.playing.value, isFalse);
    },
  );

  test(
    'sequence stops on completion at end; loop wraps; single repeats',
    () async {
      player.addSong(track(0));
      player.addSong(track(1));
      await player.playAt(1);
      await player.next(completed: true);
      expect(player.played.length, 1);
      await player.next();
      expect(player.currentIndex.value, 0);
      player.mode.value = PlayMode.loop;
      await player.playAt(1);
      await player.next(completed: true);
      expect(player.currentIndex.value, 0);
      player.mode.value = PlayMode.single;
      final count = player.played.length;
      await player.next(completed: true);
      expect(player.currentIndex.value, 0);
      expect(player.played.length, count + 1);
      await player.next();
      expect(player.currentIndex.value, 1);
    },
  );

  test(
    'shuffle avoids current item and previous follows playback history',
    () async {
      for (var i = 0; i < 5; i++) {
        player.addSong(track(i));
      }
      player.mode.value = PlayMode.shuffle;
      await player.playAt(0);
      await player.next();
      final chosen = player.currentIndex.value;
      expect(chosen, isNot(0));
      await player.next();
      expect(player.currentIndex.value, isNot(chosen));
      await player.previous();
      expect(player.currentIndex.value, chosen);
      await player.previous();
      expect(player.currentIndex.value, 0);
      for (var i = 0; i < PlayMode.values.length; i++) {
        player.cycleMode();
      }
      expect(player.mode.value, PlayMode.shuffle);
    },
  );

  test('completion advances once, pause and errors do not auto skip', () async {
    for (var i = 0; i < 3; i++) {
      player.addSong(track(i));
    }
    await player.playAt(0);
    player.updateState(ready);
    player.updateState(ended);
    player.updateState(ended);
    await Future<void>.delayed(Duration.zero);
    expect(player.currentIndex.value, 1);
    expect(player.played.length, 2);
    player.updateState(ready);
    player.updateState(
      const LemonPlayerState(
        playing: false,
        processingState: LemonProcessingState.ready,
      ),
    );
    expect(player.currentIndex.value, 1);
    player.reportError(StateError('测试播放失败'));
    player.updateState(ended);
    await Future<void>.delayed(Duration.zero);
    expect(player.currentIndex.value, 1);
  });

  test(
    'disabling a source removes its queued songs without stopping others',
    () async {
      player.addSong(track(0, source: 'a'));
      player.addSong(track(1, source: 'b'));
      player.addSong(track(2, source: 'a'));
      await player.playAt(1);
      await player.stopSource('a');
      expect(player.queue.value.length, 1);
      expect(player.currentIndex.value, 0);
      expect(player.song.value!.pluginId, 'b');
      expect(player.playing.value, isTrue);
      await player.stopSource('b');
      expect(player.queue.value, isEmpty);
      expect(player.song.value, isNull);
      expect(player.playing.value, isFalse);
    },
  );

  test('empty queue commands and clearing are safe', () async {
    await player.next();
    await player.previous();
    expect(player.played, isEmpty);
    player.addSong(track(1), next: true);
    await player.next();
    expect(player.currentIndex.value, 0);
    player.position.value = const Duration(seconds: 20);
    await player.clearQueue();
    expect(player.queue.value, isEmpty);
    expect(player.song.value, isNull);
    expect(player.position.value, Duration.zero);
    expect(player.duration.value, Duration.zero);
    expect(player.lyric.value, isNull);
    expect(player.status.value, isEmpty);
  });
}
