import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lemon_js_extensions/lemon_js_extensions.dart';
import 'package:mix_music/common/plugin/collection_controller.dart';
import 'package:mix_music/common/entity/album.dart';
import 'package:mix_music/common/entity/artist.dart';
import 'package:mix_music/common/entity/play_list.dart';
import 'package:mix_music/common/entity/rank.dart';
import 'package:mix_music/common/plugin/plugin_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'JS home and all collection interfaces keep original IDs and use one page',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'mixmusic-detail-',
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
            'id': 'test.details',
            'name': '详情协议测试',
            'description': '合成数据',
            'version': '1.0.0',
            'versionCode': 1,
            'compatibilityCode': 'mixmusic-source-v1',
            'service': {
              'entry': 'main.mjs',
              'contract': 'mixmusic-source/v1',
              'publicExports': [
                'getHome',
                'playListRec',
                'playListInfo',
                'albumInfo',
                'rankInfo',
                'artistInfo',
                'artistSong',
              ],
            },
          }),
          serviceModules: {
            'main.mjs': '''
const item = {id: {value: 1, nested: ['a', 2]}, title: '测试集合'};
export function getHome() { return {songs: [], playlists: [item], albums: [item], artists: [item]}; }
export function playListRec() { return [item]; }
function rows(page) {
  return page === 0 ? [{id: {song: 1}, title: '测试歌曲', quality: []}] : [];
}
export function playListInfo(resource, page, size) {
  console.log(JSON.stringify({resource, page, size}));
  return {...resource, songs: rows(page), total: 1, hasMore: false};
}
export const albumInfo = playListInfo;
export const rankInfo = playListInfo;
export function artistInfo(resource) { return {...resource, description: '简介'}; }
export function artistSong(resource, page) { return rows(page); }
''',
          },
        ),
      );
      await plugins.selectSource('test.details');
      expect(plugins.home.hasError, isFalse);
      expect(plugins.sections.value.keys, containsAll(['playlists']));
      await plugins.loadSection('playlists');
      for (final kind in CollectionKind.values.where(
        (kind) =>
            kind != CollectionKind.recommend && kind != CollectionKind.liked,
      )) {
        final json = plugins.sections.value['playlists']!.single.toJson();
        final resource = switch (kind) {
          CollectionKind.playlist => PlayList.fromJson(json),
          CollectionKind.album => Album.fromJson(json),
          CollectionKind.artist => Artist.fromJson(json),
          CollectionKind.rank => Rank.fromJson(json),
          CollectionKind.recommend => throw StateError('每日推荐单独测试'),
          CollectionKind.liked => throw StateError('我的喜欢单独测试'),
        };
        final collection = plugins.collection(kind, resource);
        await collection.loadMore();
        expect(collection.error.value, isEmpty);
        expect(collection.songs.value.single.pluginId, 'test.details');
        expect(collection.songs.value.single.id, {'song': 1});
        expect(collection.info.value.id, {
          'value': 1,
          'nested': ['a', 2],
        });
        expect(collection.hasMore.value, isFalse);
        if (kind != CollectionKind.artist) {
          final request = jsonDecode(plugins.logs.value.last.message) as Map;
          expect(request['page'], 0);
          expect(request['size'], 20);
          expect((request['resource'] as Map)['id'], resource.id);
        }
      }
    },
  );
}
