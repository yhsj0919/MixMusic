import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:mix_music/utils/sp.dart';

///Save cookies in  files

class CookieStorage implements Storage {
  CookieStorage([this._storageName]);

  String? _storageName;

  String Function(Uint8List list)? readPreHandler;

  List<int> Function(String value)? writePreHandler;

  @override
  Future<void> init(bool persistSession, bool ignoreExpires) async {
    _storageName = _storageName ?? 'GetCookie';
    _storageName = '${_storageName!}ie${ignoreExpires ? 1 : 0}_ps${persistSession ? 1 : 0}';
  }

  @override
  Future<bool> delete(String key) async {
    return Sp.remove(key);
  }

  @override
  Future<void> deleteAll(List<String> keys) async {
    for (var value in keys) {
      await Sp.remove(value);
    }

    return Future.value();
  }

  @override
  Future<String?> read(String key) async {
    if (readPreHandler != null) {
      return Future.value(readPreHandler!(Uint8List.fromList(Sp.getString(key)?.codeUnits ?? [])));
    } else {
      return Future.value(Sp.getString(key));
    }
  }

  @override
  Future<bool> write(String key, String value) async {
    if (writePreHandler != null) {
      return Sp.setString(key, String.fromCharCodes(writePreHandler!(value)));
    } else {
      return Sp.setString(key, value);
    }
  }
}
