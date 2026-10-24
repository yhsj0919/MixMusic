import 'package:lemon_x/lemon_x.dart';
import 'package:sqlite_async/sqlite_async.dart';

class AppDatabase implements LxDisposable {
  AppDatabase(String path) : connection = SqliteDatabase(path: path);

  final SqliteDatabase connection;

  // 各功能独立维护版本，移除某个功能不影响其他表的迁移。
  Future<void> migrate(String feature, List<SqliteMigration> versions) async {
    if (!RegExp(r'^[a-z_]+$').hasMatch(feature)) {
      throw ArgumentError.value(feature, 'feature');
    }
    final migrations = SqliteMigrations(
      migrationTable: '_${feature}_migrations',
    );
    for (final version in versions) {
      migrations.add(version);
    }
    await migrations.migrate(connection);
  }

  @override
  Future<void> dispose() => connection.close();
}
