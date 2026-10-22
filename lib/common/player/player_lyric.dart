import 'package:lemon_lyric/lemon_lyric.dart';
import 'package:lemon_x/lemon_x.dart';

import 'player_controller.dart';

class PlayerLyric implements LxDisposable {
  PlayerLyric(this.player) {
    controller = LyricController(
      onSeek: (request) async {
        await player.seek(request.position);
        if (!_disposed) controller.seek(request.position);
      },
    );
    player.lyric.addListener(load);
    player.position.addListener(update);
    player.playing.addListener(playback);
    player.speed.addListener(playback);
    controller.snapshotListenable.addListener(syncTitle);
    load();
    playback();
  }

  final PlayerController player;
  late final LyricController controller;
  bool _disposed = false;
  String? _title;

  Future<void> syncTitle({bool force = false}) async {
    if (_disposed || (!player.titleLyrics.value && !force)) return;
    final text = player.titleLyrics.value
        ? controller.currentLine?.text.trim()
        : null;
    final title = text == null || text.isEmpty ? null : text;
    if (!force && title == _title) return;
    _title = title;
    await player.updateMediaLyric(title);
  }

  Future<void> load() async {
    final data = player.lyric.value;
    controller.setDocument(
      LyricDocument.empty,
      position: player.position.value,
    );
    if (data == null) return;
    try {
      await controller.loadWithAlternatives(
        LyricSource.text(data['lrc'] as String? ?? ''),
        alternatives: {
          for (final key in ['translation', 'romanization'])
            if (data[key] is String && (data[key] as String).isNotEmpty)
              key: LyricSource.text(data[key] as String),
        },
        positionProvider: () => player.position.value,
      );
    } catch (error) {
      if (_disposed) return;
      player.plugins.addLog(
        player.song.value?.pluginId ?? 'player',
        'warn',
        '歌词解析失败：$error',
      );
    }
  }

  void update() {
    final position = player.position.value;
    if (position < controller.snapshot.position) {
      controller.seek(position);
    } else {
      controller.update(position);
    }
  }

  void playback() => controller.setPlayback(
    playing: player.playing.value,
    speed: player.speed.value,
  );

  @override
  void dispose() {
    _disposed = true;
    player.lyric.removeListener(load);
    player.position.removeListener(update);
    player.playing.removeListener(playback);
    player.speed.removeListener(playback);
    controller.snapshotListenable.removeListener(syncTitle);
    controller.dispose();
  }
}
