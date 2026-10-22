import 'dart:async';

import 'package:lemon_x/lemon_x.dart';

import 'player_controller.dart';

class SleepTimer extends LxController implements LxDisposable {
  SleepTimer(this.player);
  final PlayerController player;
  late final minutes = own(30.obs);
  late final finishSong = own(false.obs);
  late final remaining = own(Rx(Duration.zero));
  late final waiting = own(false.obs);
  Timer? _timer;

  bool get active => remaining.value > Duration.zero || waiting.value;

  bool get _hasSongToFinish =>
      player.song.value != null &&
      (player.duration.value == Duration.zero ||
          player.position.value < player.duration.value);

  void start(int value) {
    cancel();
    minutes.value = value;
    if (value == 0) return;
    final duration = Duration(minutes: value);
    remaining.value = duration;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (player.isDisposed) {
        timer.cancel();
        return;
      }
      final left = duration - Duration(seconds: timer.tick);
      remaining.value = left > Duration.zero ? left : Duration.zero;
      if (left <= Duration.zero) {
        timer.cancel();
        if (finishSong.value && _hasSongToFinish) {
          waiting.value = true;
        } else {
          unawaited(stop());
        }
      }
    });
  }

  void afterSong() {
    cancel();
    waiting.value = _hasSongToFinish;
  }

  void cancel() {
    _timer?.cancel();
    remaining.value = Duration.zero;
    waiting.value = false;
  }

  Future<void> stop() async {
    cancel();
    await player.pause();
  }

  @override
  Future<void> dispose() {
    _timer?.cancel();
    return disposeController();
  }
}
