import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lemon_audio/lemon_audio.dart';
import 'package:mix_music/common/entity/song.dart';
import 'package:mix_music/common/player/player_controller.dart';
import 'package:mix_music/common/plugin/plugin_controller.dart';

class TimerPlayer extends PlayerController {
  TimerPlayer(super.plugins);
  int pauses = 0;
  int loads = 0;
  @override
  Future<void> pause() async {
    pauses++;
    await super.pause();
  }

  @override
  Future<void> loadSong(Song selected) async {
    loads++;
    song.value = selected;
    playing.value = true;
    position.value = Duration.zero;
    duration.value = const Duration(minutes: 3);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PluginController plugins;
  late TimerPlayer player;
  setUp(() {
    plugins = PluginController();
    player = TimerPlayer(plugins);
    player.addSong(Song(pluginId: 'test', id: 1, title: '歌曲一'));
    player.addSong(Song(pluginId: 'test', id: 2, title: '歌曲二'));
    player.currentIndex.value = 0;
    player.song.value = player.queue.value.first;
    player.playing.value = true;
    player.duration.value = const Duration(minutes: 3);
  });
  tearDown(() async {
    await player.disposeController();
    await plugins.disposeController();
  });

  test('countdown pauses exactly at deadline and retains song and queue', () {
    fakeAsync((clock) {
      player.sleepTimer.start(1);
      clock.elapse(const Duration(seconds: 59));
      expect(player.sleepTimer.remaining.value, const Duration(seconds: 1));
      expect(player.pauses, 0);
      clock.elapse(const Duration(seconds: 1));
      clock.flushMicrotasks();
      expect(player.pauses, 1);
      expect(player.playing.value, isFalse);
      expect(player.sleepTimer.active, isFalse);
      expect(player.song.value!.id, 1);
      expect(player.queue.value.length, 2);
      player.updateState(
        const LemonPlayerState(
          playing: false,
          processingState: LemonProcessingState.completed,
        ),
      );
      clock.flushMicrotasks();
      expect(player.loads, 0);
      clock.elapse(const Duration(minutes: 2));
      expect(player.pauses, 1);
    });
  });

  for (final mode in PlayMode.values) {
    test('finish song prevents automatic next in ${mode.name}', () {
      fakeAsync((clock) {
        player.mode.value = mode;
        player.sleepTimer.finishSong.value = true;
        player.sleepTimer.start(1);
        clock.elapse(const Duration(minutes: 1));
        expect(player.sleepTimer.waiting.value, isTrue);
        expect(player.pauses, 0);
        player.updateState(
          const LemonPlayerState(
            playing: false,
            processingState: LemonProcessingState.completed,
          ),
        );
        clock.flushMicrotasks();
        expect(player.pauses, 1);
        expect(player.loads, 0);
        expect(player.currentIndex.value, 0);
        expect(player.sleepTimer.active, isFalse);
        player.updateState(
          const LemonPlayerState(
            playing: false,
            processingState: LemonProcessingState.completed,
          ),
        );
        clock.flushMicrotasks();
        expect(player.pauses, 1);
      });
    });
  }

  test('restart resets deadline and zero or cancel prevents later pause', () {
    fakeAsync((clock) {
      player.sleepTimer.start(1);
      clock.elapse(const Duration(seconds: 30));
      player.sleepTimer.start(2);
      clock.elapse(const Duration(minutes: 1));
      expect(player.sleepTimer.remaining.value, const Duration(minutes: 1));
      expect(player.pauses, 0);
      player.sleepTimer.cancel();
      clock.elapse(const Duration(minutes: 3));
      expect(player.pauses, 0);
      player.sleepTimer.start(1);
      player.sleepTimer.start(0);
      clock.elapse(const Duration(minutes: 2));
      expect(player.sleepTimer.active, isFalse);
      expect(player.pauses, 0);
    });
  });

  test(
    'stop after this song is immediate to arm, cancel restores normal next',
    () {
      fakeAsync((clock) {
        player.sleepTimer.start(1);
        player.sleepTimer.afterSong();
        clock.elapse(const Duration(minutes: 2));
        expect(player.sleepTimer.waiting.value, isTrue);
        expect(player.pauses, 0);
        player.sleepTimer.cancel();
        player.updateState(
          const LemonPlayerState(
            playing: false,
            processingState: LemonProcessingState.completed,
          ),
        );
        clock.flushMicrotasks();
        expect(player.loads, 1);
        expect(player.currentIndex.value, 1);
      });
    },
  );

  test('clearing queue cancels pending song end but countdown is independent of track changes', () {
    fakeAsync((clock) {
      player.sleepTimer.afterSong();
      player.clearQueue();
      clock.flushMicrotasks();
      expect(player.sleepTimer.active, isFalse);
      player.sleepTimer.start(1);
      clock.elapse(const Duration(minutes: 1));
      clock.flushMicrotasks();
      expect(player.pauses, 1);
    });
  });

  test('expired finished or missing song does not wait forever; disposal cancels clock', () {
    fakeAsync((clock) {
      player.sleepTimer.finishSong.value = true;
      player.position.value = player.duration.value;
      player.sleepTimer.start(1);
      clock.elapse(const Duration(minutes: 1));
      clock.flushMicrotasks();
      expect(player.pauses, 1);
      expect(player.sleepTimer.active, isFalse);
      player.song.value = null;
      player.sleepTimer.afterSong();
      expect(player.sleepTimer.active, isFalse);
      player.sleepTimer.start(1);
      player.disposeController();
      clock.flushMicrotasks();
      clock.elapse(const Duration(minutes: 2));
      expect(player.pauses, 1);
    });
  });
}
