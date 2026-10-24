import 'dart:convert';

import 'package:sqlite_async/sqlite_async.dart';

import '../database/app_database.dart';
import '../entity/song.dart';

class PlaybackHistoryStore {
  PlaybackHistoryStore(this.database) {
    ready = database.migrate('history', [
      SqliteMigration(1, (tx) async {
        await tx.execute('''CREATE TABLE playback_history (
          sequence INTEGER PRIMARY KEY AUTOINCREMENT,
          plugin_id TEXT NOT NULL,
          song_id TEXT NOT NULL,
          song TEXT NOT NULL,
          played_at INTEGER NOT NULL,
          UNIQUE(plugin_id, song_id)
        )''');
      }),
    ]);
  }

  final AppDatabase database;
  late final Future<void> ready;

  static dynamic _identity(dynamic value) {
    if (value is List) return value.map(_identity).toList();
    if (value is Map) {
      final keys = value.keys.cast<String>().toList()..sort();
      return {for (final key in keys) key: _identity(value[key])};
    }
    return value;
  }

  Future<void> add(Song song) async {
    // 只保存原始歌曲展示字段和 opaque id，不保留匹配源、URL 或请求凭据。
    final saved = Song(
      pluginId: song.pluginId,
      id: song.id,
      title: song.title,
      subtitle: song.subtitle,
      cover: song.cover,
    );
    final id = jsonEncode(_identity(song.id));
    final data = jsonEncode(saved.toJson());
    await ready;
    await database.connection.writeTransaction((tx) async {
      await tx.execute(
        'DELETE FROM playback_history WHERE plugin_id = ? AND song_id = ?',
        [song.pluginId, id],
      );
      await tx.execute(
        'INSERT INTO playback_history(plugin_id, song_id, song, played_at) VALUES(?, ?, ?, ?)',
        [song.pluginId, id, data, DateTime.now().millisecondsSinceEpoch],
      );
    });
  }

  Future<List<Song>> list({int offset = 0, int limit = 50}) async {
    if (offset < 0 || limit < 1) throw ArgumentError('无效的分页参数');
    await ready;
    final rows = await database.connection.getAll(
      'SELECT song FROM playback_history ORDER BY sequence DESC LIMIT ? OFFSET ?',
      [limit, offset],
    );
    return rows
        .map((row) => Song.fromJson(jsonDecode(row['song'] as String) as Map))
        .toList();
  }

  Future<void> remove(Song song) async {
    await ready;
    await database.connection.execute(
      'DELETE FROM playback_history WHERE plugin_id = ? AND song_id = ?',
      [song.pluginId, jsonEncode(_identity(song.id))],
    );
  }

  Future<void> clear() async {
    await ready;
    await database.connection.execute('DELETE FROM playback_history');
  }
}
