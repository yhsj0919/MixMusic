import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:mix_music/utils/db.dart';

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
    return AppDB.kvRemove(key);
  }

  @override
  Future<void> deleteAll(List<String> keys) async {
    for (var value in keys) {
      await AppDB.kvRemove(value);
    }

    return Future.value();
  }

  @override
  Future<String?> read(String key) async {
    if (readPreHandler != null) {
      return Future.value(readPreHandler!(Uint8List.fromList(AppDB.getString(key)?.codeUnits ?? [])));
    } else {
      return Future.value(AppDB.getString(key));
    }
  }

  @override
  Future<bool> write(String key, String value) async {
    if (writePreHandler != null) {
      return AppDB.setString(key, String.fromCharCodes(writePreHandler!(value)));
    } else {
      return AppDB.setString(key, value);
    }
  }
}
