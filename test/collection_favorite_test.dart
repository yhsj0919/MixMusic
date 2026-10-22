import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lemon_js_extensions/lemon_js_extensions.dart';
import 'package:mix_music/common/entity/album.dart';
import 'package:mix_music/common/entity/artist.dart';
import 'package:mix_music/common/entity/play_list.dart';
import 'package:mix_music/common/entity/song.dart';
import 'package:mix_music/common/plugin/collection_controller.dart';
import 'package:mix_music/common/plugin/plugin_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PluginController plugins;
  setUp(() async {
    final directory = await Directory.systemTemp.createTemp(
      'collection-favorite-',
    );
    addTearDown(() => directory.delete(recursive: true));
    plugins = PluginController(
      store: JsExtensionFileStore(directoryPath: directory.path),
      storage: JsMemoryKvStore(),
    );
    addTearDown(plugins.disposeController);
    await plugins.install(
      JsExtensionPackage(
        manifestSource: jsonEncode({
          'schemaVersion': 2,
          'id': 'test.collection.favorite',
          'name': '合成收藏',
          'description': '功能测试',
          'version': '1.0.0',
          'versionCode': 1,
          'compatibilityCode': 'mixmusic-source-v1',
          'service': {
            'entry': 'main.mjs',
            'contract': 'mixmusic-source/v1',
            'publicExports': [
              'getHome',
              'playListInfo',
              'albumInfo',
              'favoritePlayList',
              'favoriteAlbum',
              'favoriteArtist',
              'artistInfo',
              'artistSong',
              'removeFromPlayList',
            ],
          },
        }),
        serviceModules: {
          'main.mjs': '''
let calls = [];
export function getHome() { return calls; }
export function playListInfo(item) { return {...item, title:'详情', songs:[], favorited:false}; }
export const albumInfo = playListInfo;
export const artistInfo = playListInfo;
export function artistSong() { return []; }
function favorite(kind, item, value) {
  if (item.id.fail) throw new Error('synthetic failure');
  calls.push({kind, id:item.id, value});
}
export function favoritePlayList(item, value) { favorite('playlist', item, value); }
export function favoriteAlbum(item, value) { favorite('album', item, value); }
export function favoriteArtist(item, value) { favorite('artist', item, value); }
export function removeFromPlayList(item, songs) {
  if (item.id.fail) throw new Error('synthetic failure');
  calls.push({kind:'remove', id:item.id, songs});
}
''',
        },
      ),
    );
  });

  test(
    'only editable playlists expose removal and reload after success',
    () async {
      final resource = PlayList(
        pluginId: 'test.collection.favorite',
        id: {'playlist': 1},
        details: {'editable': true, 'dirId': 7},
      );
      final collection = plugins.collection(CollectionKind.playlist, resource);
      expect(collection.canRemoveSongs, isTrue);
      await collection.loadMore();
      final song = Song(
        title: '测试歌曲',
        pluginId: resource.pluginId,
        id: {'song': 2},
        favorited: true,
      );
      collection.songs.value = [song];
      await collection.removeSong(song);
      expect(collection.songs.value, isEmpty);
      expect(collection.page, 1);
      expect(song.favorited, isTrue);
      final calls =
          await plugins.manager.call(resource.pluginId, 'getHome') as List;
      expect(calls.single['kind'], 'remove');
      expect(calls.single['id'], resource.id);
      expect(calls.single['songs'].single['id'], song.id);
      resource.details['editable'] = false;
      expect(collection.canRemoveSongs, isFalse);
      expect(
        plugins
            .collection(
              CollectionKind.album,
              Album(
                pluginId: resource.pluginId,
                id: 'album',
                details: {'editable': true},
              ),
            )
            .canRemoveSongs,
        isFalse,
      );
    },
  );

  test('failed removal keeps loaded songs and page', () async {
    final collection = plugins.collection(
      CollectionKind.playlist,
      PlayList(
        pluginId: 'test.collection.favorite',
        id: {'fail': true},
        details: {'editable': true},
      ),
    );
    final song = Song(
      pluginId: 'test.collection.favorite',
      id: 'song',
      title: '测试歌曲',
    );
    collection.songs.value = [song];
    collection.page = 2;
    await expectLater(collection.removeSong(song), throwsA(anything));
    expect(collection.songs.value, [song]);
    expect(collection.page, 2);
  });

  for (final kind in [
    CollectionKind.playlist,
    CollectionKind.album,
    CollectionKind.artist,
  ]) {
    test('$kind favorite updates both detail and original resource', () async {
      final id = {
        'platform': ['opaque', 1],
      };
      final resource = kind == CollectionKind.playlist
          ? PlayList(pluginId: 'test.collection.favorite', id: id)
          : kind == CollectionKind.album
          ? Album(pluginId: 'test.collection.favorite', id: id)
          : Artist(pluginId: 'test.collection.favorite', id: id);
      final collection = plugins.collection(kind, resource);
      expect(collection.supportsFavorite, isTrue);
      await collection.loadMore();
      expect(identical(collection.info.value, resource), isFalse);
      await collection.favorite(true);
      expect(resource.favorited, isTrue);
      expect(collection.info.value.favorited, isTrue);
      await collection.favorite(false);
      expect(resource.favorited, isFalse);
      expect(collection.info.value.favorited, isFalse);
      final calls =
          await plugins.manager.call(resource.pluginId, 'getHome') as List;
      expect(calls.map((x) => x['value']), [true, false]);
      expect(calls.first['id'], id);
      expect(collection.info.value.title, '详情');
    });

    test('$kind failed favorite preserves current state', () async {
      final resource = kind == CollectionKind.playlist
          ? PlayList(
              pluginId: 'test.collection.favorite',
              id: {'fail': true},
              favorited: true,
            )
          : kind == CollectionKind.album
          ? Album(
              pluginId: 'test.collection.favorite',
              id: {'fail': true},
              favorited: true,
            )
          : Artist(
              pluginId: 'test.collection.favorite',
              id: {'fail': true},
              favorited: true,
            );
      final collection = plugins.collection(kind, resource);
      await expectLater(collection.favorite(false), throwsA(anything));
      expect(resource.favorited, isTrue);
      expect(collection.info.value.favorited, isTrue);
    });
  }
}
