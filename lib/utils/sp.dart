import 'package:shared_preferences/shared_preferences.dart';

class Sp {
  static late SharedPreferences _prefs;
  static String KEY_MATCH_VIP = "KEY_MATCH_VIP";
  static String KEY_MATCH_SITE = "KEY_MATCH_SITE";
  static String KEY_FIRST_IN = "KEY_FIRST_IN";

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
    return _prefs.getInt(key);
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
}
