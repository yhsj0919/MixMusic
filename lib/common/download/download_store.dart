import 'dart:convert';

import 'package:sqlite_async/sqlite_async.dart';

import '../database/app_database.dart';

class DownloadStore {
  DownloadStore(this.database) {
    ready = database.migrate('download', [
      SqliteMigration(1, (tx) async {
        await tx.execute(
          'CREATE TABLE download_tasks (id INTEGER PRIMARY KEY, data TEXT NOT NULL)',
        );
        await tx.execute(
          'CREATE TABLE download_queue (id INTEGER PRIMARY KEY CHECK(id = 1), data TEXT NOT NULL)',
        );
      }),
    ]);
  }

  final AppDatabase database;
  late final Future<void> ready;

  Future<Map<String, dynamic>?> load() async {
    await ready;
    return database.connection.readTransaction((tx) async {
      final queue = await tx.getOptional(
        'SELECT data FROM download_queue WHERE id = 1',
      );
      if (queue == null) return null;
      final tasks = await tx.getAll(
        'SELECT data FROM download_tasks ORDER BY id',
      );
      return {
        'queue': jsonDecode(queue['data'] as String),
        'tasks': tasks.map((row) => jsonDecode(row['data'] as String)).toList(),
      };
    });
  }

  Future<void> save(Map<String, dynamic> snapshot) async {
    // 编码先完成，坏数据不能导致已保存的队列被清空。
    final queue = jsonEncode(snapshot['queue']);
    final tasks = (snapshot['tasks'] as List).map(jsonEncode).toList();
    await ready;
    await database.connection.writeTransaction((tx) async {
      await tx.execute('DELETE FROM download_tasks');
      await tx.executeBatch(
        'INSERT INTO download_tasks(id, data) VALUES(?, ?)',
        [
          for (final (index, task) in tasks.indexed) [index, task],
        ],
      );
      await tx.execute(
        'INSERT OR REPLACE INTO download_queue(id, data) VALUES(1, ?)',
        [queue],
      );
    });
  }
}
