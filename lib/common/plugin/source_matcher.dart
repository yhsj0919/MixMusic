import 'package:lemon_x/lemon_x.dart';
import 'package:lemon_js_extensions/lemon_js_extensions.dart';

import '../entity/song.dart';
import '../player/music_cache.dart';
import 'plugin_controller.dart';
import 'song_matcher.dart';

class SourceMatcher extends LxController implements LxDisposable {
  SourceMatcher(this.plugins);
  final PluginController plugins;
  late final enabled = own(
    (plugins.preferences?.getBool('sourceMatch') ?? false).obs,
  );
  late final sources = own(
    Rx<List<String>>(plugins.preferences?.getStringList('matchSources') ?? []),
  );
  final _matches = <String, Song>{};
  final _candidates = <String, List<Song>>{};

  Future<void> setEnabled(bool value) async {
    enabled.value = value;
    await plugins.preferences?.setBool('sourceMatch', value);
  }

  Future<void> setSources(List<String> value) async {
    _candidates.clear();
    _matches.clear();
    sources.value = value;
    await plugins.preferences?.setStringList('matchSources', value);
  }

  Future<List<Song>> candidates(Song song, {bool refresh = false}) async {
    final original = Song.fromJson(song.toJson())..matchedSong = null;
    final key = MusicCache.keyFor(
      Song.fromJson(original.toJson())..playQuality = null,
    );
    if (!refresh && _candidates.containsKey(key)) return _candidates[key]!;
    final ids = sources.value
        .where((id) => id != original.pluginId && available(id))
        .toList();
    final keyword = '${original.title} ${SongMatcher.artist(original)}'.trim();
    final lists = await Future.wait(
      ids.map((id) async {
        try {
          return SongMatcher.rank(
            original,
            await plugins.music(id).searchMusic(keyword, 0, 20),
            minimum: 0,
          );
        } catch (error) {
          plugins.addLog('match', 'warn', '搜索失败 [$id]：$error');
          return <Song>[];
        }
      }),
    );
    return _candidates[key] = [for (final list in lists) ...list];
  }

  bool available(String id) {
    if (plugins.builtins.containsKey(id)) return true;
    final entry = plugins.manager.find(id);
    final exports = entry?.installed?.extension.service?.publicExports ?? [];
    return entry?.state == JsExtensionManagerState.enabled &&
        exports.contains('searchMusic') &&
        exports.contains('playUrl');
  }

  Future<Song> resolve(
    Song original,
    Future<Song> Function(Song) load, {
    bool? allowMatch,
    bool Function()? cancelled,
  }) async {
    original = Song.fromJson(original.toJson())..matchedSong = null;
    Object? failure;
    try {
      final result = await load(original);
      if (result.url?.isNotEmpty == true) return result;
    } catch (error) {
      failure = error;
    }
    if (isDisposed || (cancelled?.call() ?? false)) throw StateError('匹配已结束');
    if (!(allowMatch ?? enabled.value)) {
      throw failure ?? StateError('音源未返回可播放地址');
    }
    final key = MusicCache.keyFor(original);
    final remembered = _matches[key];
    if (remembered != null &&
        sources.value.contains(remembered.pluginId) &&
        available(remembered.pluginId)) {
      try {
        final result = await load(
          Song.fromJson(remembered.toJson())..url = null,
        );
        if (result.url?.isNotEmpty == true) return result;
      } catch (error) {
        plugins.addLog('match', 'warn', '已匹配来源不可用：$error');
      }
    }
    final ids = sources.value
        .where((id) => id != original.pluginId && available(id))
        .toList();
    if (isDisposed || (cancelled?.call() ?? false)) throw StateError('匹配已结束');
    final found = await candidates(original);
    final results = [
      for (final id in ids)
        found
            .where(
              (song) =>
                  song.pluginId == id &&
                  SongMatcher.score(original, song) >= SongMatcher.threshold,
            )
            .toList(),
    ];
    for (var i = 0; i < results.length; i++) {
      for (final candidate in results[i].take(3)) {
        if (remembered != null && SongMatcher.sameSong(candidate, remembered)) {
          continue;
        }
        if (isDisposed || (cancelled?.call() ?? false)) {
          throw StateError('匹配已结束');
        }
        plugins.addLog(
          'match',
          'log',
          '[Match] ${ids[i]} score=${SongMatcher.score(original, candidate).toStringAsFixed(1)}',
        );
        try {
          final selected = Song.fromJson(candidate.toJson())
            ..playQuality = original.playQuality;
          final result = await load(selected);
          if (result.url?.isNotEmpty != true) continue;
          _matches[key] = Song.fromJson(result.toJson())..url = null;
          return result;
        } catch (error) {
          plugins.addLog('match', 'warn', '候选不可用 [${ids[i]}]：$error');
        }
      }
    }
    throw failure ?? StateError('未找到可播放的匹配音源');
  }

  @override
  Future<void> dispose() => disposeController();
}
