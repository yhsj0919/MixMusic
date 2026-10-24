import 'dart:async';

import 'package:lemon_x/lemon_x.dart';

import '../entity/song.dart';
import '../player/player_controller.dart';
import 'playback_history_store.dart';

class PlayerHistory implements LxDisposable {
  PlayerHistory(this.player, this.store) {
    player.song.addListener(_changed);
    player.position.addListener(_progress);
    unawaited(
      store.ready.catchError((Object error, StackTrace stack) {
        player.plugins.addLog('history', 'error', '初始化播放历史失败：$error\n$stack');
      }),
    );
  }

  final PlayerController player;
  final PlaybackHistoryStore store;
  Song? _recorded;
  Duration _position = Duration.zero;
  Future<void> _writing = Future.value();

  void _changed() {
    _recorded = null;
    _position = player.position.value;
  }

  void _progress() {
    final previous = _position;
    _position = player.position.value;
    final song = player.song.value;
    if (song == null ||
        identical(song, _recorded) ||
        !player.playing.value ||
        _position <= previous) {
      return;
    }
    _recorded = song;
    _writing = _writing.then((_) => store.add(song)).catchError((
      Object error,
      StackTrace stack,
    ) {
      player.plugins.addLog('history', 'error', '保存播放历史失败：$error\n$stack');
    });
  }

  @override
  Future<void> dispose() async {
    player.song.removeListener(_changed);
    player.position.removeListener(_progress);
    await _writing;
  }
}
