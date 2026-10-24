import 'dart:async';
import 'dart:convert';

import 'package:lemon_x/lemon_x.dart';

import '../entity/album.dart';
import '../entity/artist.dart';
import '../entity/music_collection.dart';
import '../entity/play_list.dart';
import '../entity/rank.dart';
import '../entity/song.dart';
import '../plugin/collection_controller.dart';
import '../queue/hyper_queue_source.dart';
import 'player_controller.dart';

class PlayerSession implements LxDisposable {
  PlayerSession(this.player) {
    _restore();
    player.hyperQueue.entries.addListener(_changed);
    player.currentIndex.addListener(_changed);
    player.song.addListener(_changed);
    player.position.addListener(_progress);
    player.duration.addListener(_changed);
    player.playing.addListener(_changed);
  }
  final PlayerController player;
  static const key = 'playbackSession';
  bool pending = false;
  Timer? _timer;
  Future<void> _writing = Future.value();

  // 保留插件资源字段与 opaque id，但不保存可过期的播放地址和请求头。
  static dynamic snapshot(dynamic value) {
    if (value is List) return value.map(snapshot).toList();
    if (value is! Map) return value;
    return <String, dynamic>{
      for (final entry in value.entries)
        if (![
          'url',
          'httpHeaders',
          'headers',
          'cookie',
          'cookies',
          'playUrl',
          'downloadUrl',
        ].contains(entry.key))
          '${entry.key}': entry.key == 'id'
              ? entry.value
              : snapshot(entry.value),
    };
  }

  Map<String, dynamic> _source(HyperQueueSource<Song> source) {
    final collection = source.key as CollectionController;
    return {
      'kind': collection.kind.name,
      'resource': snapshot(collection.resource.toJson()),
      'songs': collection.songs.value
          .map((song) => snapshot(song.toJson()))
          .toList(),
      'page': collection.page,
      'hasMore': collection.hasMore.value,
    };
  }

  HyperQueueSource<Song> _restoreSource(Map data) {
    final kind = CollectionKind.values.byName(data['kind'] as String);
    final json = data['resource'] as Map;
    final resource = switch (kind) {
      CollectionKind.playlist => PlayList.fromJson(json),
      CollectionKind.album => Album.fromJson(json),
      CollectionKind.artist => Artist.fromJson(json),
      CollectionKind.rank => Rank.fromJson(json),
      _ => MusicCollection.fromJson(json),
    };
    final collection = player.plugins.collection(kind, resource);
    collection.page = data['page'] as int;
    collection.hasMore.value = data['hasMore'] as bool;
    collection.songs.value = (data['songs'] as List)
        .map((song) => Song.fromJson(song as Map))
        .toList();
    return HyperQueueSource(
      key: collection,
      title: resource.title,
      items: collection.songs,
      hasMore: collection.hasMore,
      error: collection.error,
      loadMore: collection.loadMore,
    );
  }

  void _restore() {
    final text = player.preferences?.getString(key);
    if (text == null) return;
    try {
      final data = jsonDecode(text) as Map;
      if (data['version'] != 1) return;
      player.hyperQueue.restoreSnapshot(
        data['queue'] as Map,
        item: Song.fromJson,
        source: _restoreSource,
      );
      final current = data['song'];
      if (current != null && player.currentIndex.value >= 0) {
        final song = Song.fromJson(current as Map);
        if (!player.sameSong(
          song,
          player.queue.value[player.currentIndex.value],
        )) {
          throw const FormatException('当前歌曲与队列不一致');
        }
        player.song.value = song;
        player.position.value = Duration(
          milliseconds: (data['position'] as int).clamp(0, 1 << 53),
        );
        player.duration.value = Duration(
          milliseconds: (data['duration'] as int).clamp(0, 1 << 53),
        );
        pending = true;
      }
      player.playing.value = false;
      player.plugins.addLog(
        'player',
        'log',
        '播放快照已恢复：${player.queue.value.length} 首，等待手动继续',
      );
    } catch (error) {
      player.hyperQueue.clear();
      player.song.value = null;
      player.position.value = Duration.zero;
      player.duration.value = Duration.zero;
      pending = false;
      player.plugins.addLog('player', 'warn', '播放快照恢复失败，已忽略');
    }
  }

  void _changed() {
    if (player.preferences == null) return;
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 300), () => unawaited(save()));
  }

  void _progress() {
    if (player.preferences == null || (_timer?.isActive ?? false)) return;
    _timer = Timer(const Duration(seconds: 5), () => unawaited(save()));
  }

  Future<void> save() {
    final preferences = player.preferences;
    if (preferences == null) return Future.value();
    _timer?.cancel();
    final current = player.song.value;
    final inQueue =
        current != null &&
        player.currentIndex.value >= 0 &&
        player.currentIndex.value < player.queue.value.length &&
        player.sameSong(current, player.queue.value[player.currentIndex.value]);
    final data = jsonEncode({
      'version': 1,
      'queue': player.hyperQueue.toSnapshot(
        item: (song) => snapshot(song.toJson()),
        source: _source,
      ),
      'song': inQueue ? snapshot(current.toJson()) : null,
      'position': inQueue ? player.position.value.inMilliseconds : 0,
      'duration': inQueue ? player.duration.value.inMilliseconds : 0,
    });
    return _writing = _writing
        .then((_) async {
          if (!await preferences.setString(key, data)) {
            throw StateError('播放快照保存失败');
          }
        })
        .catchError((Object error) {
          player.plugins.addLog('player', 'warn', '播放快照保存失败');
        });
  }

  @override
  Future<void> dispose() async {
    player.hyperQueue.entries.removeListener(_changed);
    player.currentIndex.removeListener(_changed);
    player.song.removeListener(_changed);
    player.position.removeListener(_progress);
    player.duration.removeListener(_changed);
    player.playing.removeListener(_changed);
    await save();
  }
}
