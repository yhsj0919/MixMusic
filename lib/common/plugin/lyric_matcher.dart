import 'dart:convert';

import 'package:lemon_js_extensions/lemon_js_extensions.dart';
import 'package:lemon_x/lemon_x.dart';

import '../entity/matched_lyric.dart';
import '../entity/song.dart';
import 'plugin_controller.dart';
import 'song_matcher.dart';

class LyricMatcher extends LxController implements LxDisposable {
  LyricMatcher(this.plugins);
  final PluginController plugins;
  final _candidates = <String, List<Song>>{};
  late final enabled = own(
    (plugins.preferences?.getBool('lyricMatch') ?? false).obs,
  );
  late final sources = own(
    Rx<List<String>>(plugins.preferences?.getStringList('lyricSources') ?? []),
  );

  Future<void> setEnabled(bool value) async {
    enabled.value = value;
    await plugins.preferences?.setBool('lyricMatch', value);
  }

  Future<void> setSources(List<String> value) async {
    _candidates.clear();
    sources.value = value;
    await plugins.preferences?.setStringList('lyricSources', value);
  }

  Future<List<Song>> candidates(Song song, {bool refresh = false}) async {
    final original = Song.fromJson(song.toJson())..matchedSong = null;
    final key = jsonEncode([
      original.pluginId,
      original.id,
      original.title,
      SongMatcher.artist(original),
    ]);
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
          plugins.addLog('lyric', 'warn', '歌词候选搜索失败 [$id]：$error');
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
        exports.contains('lrc');
  }

  Future<MatchedLyric?> load(Song song) async {
    try {
      final data = await plugins.music(song.pluginId).lrc(song);
      if (data['lrc'] is String && (data['lrc'] as String).trim().isNotEmpty) {
        return MatchedLyric(
          Song.fromJson(song.toJson())..matchedSong = null,
          data,
        );
      }
    } catch (error) {
      plugins.addLog('lyric', 'warn', '歌词获取失败 [${song.pluginId}]：$error');
    }
    return null;
  }

  Future<MatchedLyric?> resolve(Song song, {bool Function()? cancelled}) async {
    final original = Song.fromJson(song.toJson())..matchedSong = null;
    bool stopped() => isDisposed || (cancelled?.call() ?? false);
    final own = await load(original);
    if (stopped()) return null;
    if (own != null || !enabled.value) return own;
    final ids = sources.value
        .where((id) => id != original.pluginId && available(id))
        .toList();
    final found = await candidates(original);
    final results = [
      for (final id in ids)
        found
            .where(
              (item) =>
                  item.pluginId == id && SongMatcher.matches(original, item),
            )
            .toList(),
    ];
    for (final items in results) {
      for (final candidate in items.take(3)) {
        if (stopped()) return null;
        final result = await load(candidate);
        if (stopped()) return null;
        if (result != null) {
          plugins.addLog(
            'lyric',
            'log',
            '[LyricMatch] ${candidate.pluginId} score=${SongMatcher.score(original, candidate).toStringAsFixed(1)}',
          );
          return result;
        }
      }
    }
    return null;
  }

  @override
  Future<void> dispose() => disposeController();
}
