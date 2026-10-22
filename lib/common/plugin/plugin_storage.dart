import 'dart:convert';

import 'package:lemon_js_extensions/lemon_js_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PluginStorage implements JsKvStore {
  PluginStorage(this.preferences);
  final SharedPreferences preferences;

  String _prefix(String? namespace) =>
      'lemon_js.kv.v1.${_encode(namespace ?? '')}.';
  String _encode(String value) => base64Url.encode(utf8.encode(value));
  String _key(String key, String? namespace) =>
      '${_prefix(namespace)}${_encode(key)}';

  @override
  Future<Object?> get(String key, {String? namespace}) async {
    final source = preferences.getString(_key(key, namespace));
    return source == null ? null : (jsonDecode(source) as Map)['value'];
  }

  @override
  Future<void> set(String key, Object? value, {String? namespace}) async {
    final saved = await preferences.setString(
      _key(key, namespace),
      jsonEncode({'value': value}),
    );
    if (!saved) throw StateError('插件数据保存失败');
  }

  @override
  Future<bool> containsKey(String key, {String? namespace}) async =>
      preferences.containsKey(_key(key, namespace));

  @override
  Future<void> remove(String key, {String? namespace}) async {
    await preferences.remove(_key(key, namespace));
  }

  @override
  Future<List<String>> keys({String? namespace}) async {
    final prefix = _prefix(namespace);
    return [
      for (final key in preferences.getKeys())
        if (key.startsWith(prefix))
          utf8.decode(base64Url.decode(key.substring(prefix.length))),
    ];
  }

  @override
  Future<void> clear({String? namespace}) async {
    for (final key in await keys(namespace: namespace)) {
      await remove(key, namespace: namespace);
    }
  }
}
