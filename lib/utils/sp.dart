import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Sp {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
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

  static Future<bool> setStringList(String key, List<String> value) {
    return _prefs.setStringList(key, value);
  }

  static Future<bool> remove(String key) {
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

  static List<String>? getStringList(String key) {
    return _prefs.getStringList(key);
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

  static List<T>? getList<T>(String key) {
    final list = _prefs.getStringList(key);
    if (list == null) {
      return null;
    }
    // 尝试将字符串列表转换为目标类型 T 的列表
    return list.map((item) => JsonMapper.fromJson<T>(item)!).toList();
  }

  static Future<bool> setList(String key, List<dynamic> value) {
    return _prefs.setStringList(key, value.where((item) => item != null).map((e) => JsonMapper.toJson(e)).toList());
  }

  static Future<bool?> addList<T>(String key, T value, {bool Function(T oldValue, T newValue)? check}) {
    var list = _prefs.getStringList(key)?.map((a) => JsonMapper.fromJson<T>(a)!).toList() ?? [];
    var tmpList = list.where((old) {
      if (check == null) return false;
      return check.call(old, value);
    });

    if (tmpList.isEmpty == true) {
      list.add(value);
    } else {
      return Future.error("数据已存在");
    }

    return setList(key, list);
  }

  static Future<bool?> removeList<T>(String key, {required bool Function(T old) check}) {
    var list = _prefs.getStringList(key)?.map((a) => JsonMapper.fromJson<T>(a)!).toList() ?? [];
    list.removeWhere((old) {
      return check.call(old);
    });
    return setList(key, list);
  }

  static Future<bool?> replaceList<T>(String key, T value, {required bool Function(T oldValue, T newValue) check}) {
    var list = _prefs.getStringList(key)?.map((a) => JsonMapper.fromJson<T>(a)!).toList() ?? [];
    var tmpList = list.where((old) {
      return check.call(old, value);
    });

    if (tmpList.isEmpty == true) {
      list.add(value);
    } else {
      var index = list.indexWhere((old) {
        return check.call(old, value);
      });
      list.removeWhere((old) {
        return check.call(old, value);
      });
      print('删除，重新添加数据');
      list.insert(index, value);
    }

    return setList(key, list);
  }

  static Future<bool?> insertList<T>(String key, T value, {int? index, required bool Function(T oldValue, T newValue) check}) {
    var list = _prefs.getStringList(key)?.map((a) => JsonMapper.fromJson<T>(a)!).toList() ?? [];
    var tmpList = list.where((old) {
      return check.call(old, value);
    });

    if (tmpList.isEmpty == true) {
      list.insert(index ?? 0, value);
    } else {
      var myIndex = index ??
          list.indexWhere((old) {
            return check.call(old, value);
          });
      list.removeWhere((old) {
        return check.call(old, value);
      });
      print('删除，重新添加数据');
      list.insert(myIndex, value);
    }

    return setList(key, list);
  }

  static Future<bool?> insertStringList(String key, String value, {int? index}) {

    var list = _prefs.getStringList(key) ?? [];
    var tmpList = list.contains(value);

    if (!tmpList) {
      list.insert(index ?? 0, value);
    } else {
      var myIndex = index ?? list.indexOf(value);
      list.remove(value);
      list.insert(myIndex, value);
    }
    return setStringList(key, list);
  }

  static Future<bool?> removeStringList<T>(String key,String value) {
    var list = _prefs.getStringList(key)?? [];
    list.remove(value);
    return setStringList(key, list);
  }
}
