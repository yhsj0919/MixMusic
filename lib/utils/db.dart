import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiny_db/tiny_db.dart';

class AppDB {
  static late TinyDb _db;
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = '${appDir.path}/app_database.json';
    _db = TinyDb(JsonStorage(dbPath, createDirs: true));
  }



  static Future<bool> setBool(String key, bool value) {
    return _prefs.setBool(key, value);
  }

  static Future<bool> setInt(String key, int value) {
    return _prefs.setInt(key, value);
  }

  static Future<bool> setDouble(String key, double value) {
    return _prefs.setDouble(key, value);
  }

  static Future<bool> setString(String key, String value) {
    return _prefs.setString(key, value);
  }

  static Future<bool> kvRemove(String key) {
    return _prefs.remove(key);
  }

  static bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  static int? getInt(String key) {
    try {
      return _prefs.getInt(key);
    } catch (e) {
      _prefs.remove(key);
      return null;
    }
  }

  static double? getDouble(String key) {
    return _prefs.getDouble(key);
  }

  static String? getString(String key) {
    return _prefs.getString(key);
  }

  static bool containsKey(String key) {
    return _prefs.containsKey(key);
  }

  static T? getObject<T>(String key) {
    try {
      final obj = _prefs.getString(key);
      if (obj == null) {
        return null;
      }
      // 尝试将字符串列表转换为目标类型 T 的列表
      return JsonMapper.fromJson<T>(obj)!;
    } catch (e) {
      _prefs.remove(key);
      return null;
    }
  }

  static Future<bool> setObject(String key, dynamic value) {
    return _prefs.setString(key, JsonMapper.toJson(value));
  }


  ///插入
  static Future<DocumentId> insertString(String table, String doc) async {
    return _db.table(table).insert({"key": doc});
  }

  static Future<List<DocumentId>> insertStringList(String table, List<String> docs) async {
    await _db.dropTable(table);
    return _db.table(table).insertMultiple(docs.map((e) => {"key": e}).toList());
  }

  ///获取
  static Future<List<String>> getStringList(String table) async {
    return _db.table(table).all().then((value) {
      return value.map((e) => e["key"].toString()).toList();
    });
  }

  ///更新插入
  static Future<List<DocumentId>> insertOrUpdateStringWithIndex<T>(String table, String value, {int? index}) async {
    var list = await getStringList(table);
    await _db.dropTable(table);

    var tmpList = list.contains(value);

    if (!tmpList) {
      list.insert(index ?? 0, value);
    } else {
      var myIndex = index ?? list.indexOf(value);
      list.remove(value);
      list.insert(myIndex, value);
    }
    return _db.table(table).insertMultiple(list.map((e) => {"key": e}).toList());
  }

  static Future<List<DocumentId>> removeStringList(String table, String value) async {
    var list = await getStringList(table);
    await _db.dropTable(table);
    list.remove(value);
    return _db.table(table).insertMultiple(list.map((e) => {"key": e}).toList());
  }

  ///插入
  static Future<DocumentId> insert(String table, Document doc) async {
    return _db.table(table).insert(doc);
  }

  ///更新插入
  static Future<List<DocumentId>> insertOrUpdate({required String table, required Document doc, QueryCondition? queryCondition}) async {
    return _db.table(table).upsert(doc, queryCondition ?? where("id").equals(doc["id"].toString()));
  }

  ///更新插入
  static Future<List<DocumentId>> insertOrUpdateWithIndex<T>(String table, T value, {int? index, required bool Function(T oldValue, T newValue) check}) async {
    var list = await getList<T>(table);
    await _db.dropTable(table);

    var tmpList = list.where((old) {
      return check.call(old, value);
    });

    if (tmpList.isEmpty == true) {
      list.insert(index ?? 0, value);
    } else {
      var myIndex =
          index ??
          list.indexWhere((old) {
            return check.call(old, value);
          });
      list.removeWhere((old) {
        return check.call(old, value);
      });
      print('删除，重新添加数据');
      list.insert(myIndex, value);
    }

    return _db.table(table).insertMultiple(list.map((a) => JsonMapper.toMap(a)!).toList());
  }

  ///更新插入
  static Future<List<DocumentId>> replaceAll({required String table, required List<Document> docs}) async {
    await _db.dropTable(table);

    return _db.table(table).insertMultiple(docs);
  }

  ///删除
  static Future<dynamic> remove<T>({required String table, required QueryCondition queryCondition}) async {
    return await _db.table(table).remove(queryCondition);
  }

  ///删除
  static Future<dynamic> removeAll({required String table}) async {
    await _db.dropTable(table);
  }

  ///获取
  static Future<List<T>> getList<T>(String table) async {
    final list = await _db.table(table).all();
    // 尝试将字符串列表转换为目标类型 T 的列表
    return JsonMapper.deserialize<List<T>>(list) ?? [];
  }
}
