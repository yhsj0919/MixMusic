import 'dart:convert';
import 'dart:io';

import 'package:lemon_x/lemon_x.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../entity/song.dart';
import 'local_files.dart';

class LocalMusicController extends LxController {
  LocalMusicController({this.configFile, LocalFiles? files, this.preferences})
    : files = files ?? LocalFiles();
  static const pluginId = 'mixmusic.local';
  final LocalFiles files;
  final SharedPreferences? preferences;
  File? configFile;
  late final directories = own(Rx<List<String>>([]));
  late final entries = own(RxAsync<List<LocalEntry>>());
  late final selected = own(''.obs);
  late final restored = _restore();
  Future<void> _saving = Future.value();
  int _request = 0;

  Future<File> get config async => configFile ??= File(
    '${(await getApplicationSupportDirectory()).path}/music_directories.json',
  );

  Future<void> _restore() async {
    final stored = preferences?.getStringList('musicDirectories');
    if (stored != null) {
      if (!isDisposed) directories.value = stored;
      return;
    }
    final file = await config;
    final saved = await file.exists()
        ? List<String>.from(jsonDecode(await file.readAsString()) as List)
        : <String>[];
    if (!isDisposed) {
      directories.value = saved.map(LocalFiles.normalize).toSet().toList();
      await preferences?.setStringList('musicDirectories', directories.value);
    }
  }

  Future<void> _save() {
    if (preferences != null) {
      return preferences!.setStringList('musicDirectories', directories.value);
    }
    final data = jsonEncode(directories.value);
    Future<void> write() async {
      final file = await config;
      await file.parent.create(recursive: true);
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsString(data, flush: true);
      await temporary.rename(file.path);
    }

    return _saving = _saving.then(
      (_) => write(),
      onError: (Object error) => write(),
    );
  }

  Future<void> addDirectory(String uri) async {
    await restored;
    final normalized = LocalFiles.normalize(uri);
    if (directories.value.contains(normalized)) return;
    directories.value = [...directories.value, normalized];
    await _save();
  }

  Future<void> removeDirectory(String uri) async {
    await restored;
    directories.value = directories.value.where((item) => item != uri).toList();
    await _save();
    await files.release(uri);
    _request++;
    selected.value = '';
    entries.data([]);
  }

  Future<void> openDirectory(String uri) async {
    final request = ++_request;
    selected.value = uri;
    entries.loading();
    try {
      final result = await files.list(uri);
      if (!isDisposed && request == _request) entries.data(result);
    } catch (error, stack) {
      if (!isDisposed && request == _request) entries.error(error, stack);
    }
  }

  Song song(LocalEntry item) =>
      Song(pluginId: pluginId, id: item.uri, title: item.name, url: item.uri);
}
