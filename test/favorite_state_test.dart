import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lemon_js_extensions/lemon_js_extensions.dart';
import 'package:mix_music/common/entity/album.dart';
import 'package:mix_music/common/entity/artist.dart';
import 'package:mix_music/common/entity/mv.dart';
import 'package:mix_music/common/entity/play_list.dart';
import 'package:mix_music/common/entity/song.dart';
import 'package:mix_music/common/plugin/plugin_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('favorite fields retain unknown, false and true independently', () {
    for (final state in [null, false, true]) {
      final json = {
        'pluginId': 'fixture',
        'id': {'value': 1},
        'title': '资源',
        'favorited': state,
        'locallyFavorited': true,
      };
      for (final item in [
        Album.fromJson(json),
        Artist.fromJson(json),
        PlayList.fromJson(json),
        Mv.fromJson(json),
      ]) {
        expect(item.favorited, state);
        expect(item.locallyFavorited, true);
        expect(item.toJson()['favorited'], state);
        expect(item.toJson()['locallyFavorited'], true);
      }
      final song = Song.fromJson(json);
      expect(Song.fromJson(song.toJson()).favorited, state);
      expect(Song.fromJson(song.toJson()).locallyFavorited, true);
    }
  });

  test('plugin boundary excludes local state; batch and writes update only platform state', () async {
    final directory = await Directory.systemTemp.createTemp(
      'mixmusic-favorite-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final plugins = PluginController(
      store: JsExtensionFileStore(directoryPath: directory.path),
      storage: JsMemoryKvStore(),
    );
    addTearDown(plugins.disposeController);
    await plugins.install(
      JsExtensionPackage(
        manifestSource: jsonEncode({
          'schemaVersion': 2,
          'id': 'test.favorite',
          'name': '收藏测试',
          'description': '合成数据',
          'version': '1.0.0',
          'versionCode': 1,
          'compatibilityCode': 'mixmusic-source-v1',
          'service': {
            'entry': 'main.mjs',
            'contract': 'mixmusic-source/v1',
            'publicExports': ['getHome', 'favoriteSong', 'playUrl'],
          },
        }),
        serviceModules: {
          'main.mjs': '''
export function getHome() { return {}; }
function check(song) {
  if ('locallyFavorited' in song) throw Error('local state leaked');
  if (song.id.locallyFavorited !== 'opaque') throw Error('ID changed');
}
export function favoriteSong(song, value) { check(song); if (song.title === 'fail') throw Error('failed'); return null; }
export function playUrl(song) { check(song); return {...song,locallyFavorited:false,url:'test'}; }
''',
        },
      ),
    );
    final api = plugins.music('test.favorite');
    final songs = List.generate(
      3,
      (i) => Song(
        pluginId: 'test.favorite',
        id: {'locallyFavorited': 'opaque', 'value': i},
        title: '歌曲',
        locallyFavorited: true,
      ),
    );
    await api.favoriteSong(songs.first, false);
    expect(songs.first.favorited, false);
    expect(songs.first.locallyFavorited, true);
    songs.first.title = 'fail';
    await expectLater(api.favoriteSong(songs.first, true), throwsA(anything));
    expect(songs.first.favorited, false);
    final playing = await api.playUrl(songs.last);
    expect(playing.locallyFavorited, true);
    expect(playing.id, songs.last.id);
  });
}
