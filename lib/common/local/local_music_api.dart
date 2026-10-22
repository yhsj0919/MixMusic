import 'dart:io';

import 'package:lemon_js_extensions/lemon_js_extensions.dart';

import '../api/music_api.dart';
import '../entity/song.dart';
import 'local_music_controller.dart';

class LocalMusicApi extends MusicApi {
  LocalMusicApi(JsExtensionManager manager)
    : super(manager, LocalMusicController.pluginId);

  @override
  Future<Song> playUrl(Song song) async {
    final uri = Uri.parse(song.id as String);
    if (uri.scheme == 'file' && !await File.fromUri(uri).exists()) {
      throw StateError('文件不存在');
    }
    return Song.fromJson({...song.toJson(), 'url': uri.toString()});
  }

  @override
  Future<Map<String, dynamic>> lrc(Song song) async => {};

  @override
  Song updateMetadata(Song song, Map<String, String> tags) {
    final values = tags.map((key, value) => MapEntry(key.toLowerCase(), value));
    return Song.fromJson({
      ...song.toJson(),
      'title': values['title'] ?? song.title,
      'subTitle': values['artist'] ?? song.subtitle,
      'albumName': values['album'],
      'metadata': values,
    });
  }
}
