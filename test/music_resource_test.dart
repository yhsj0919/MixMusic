import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lemon_js_extensions/lemon_js_extensions.dart';
import 'package:mix_music/common/entity/album.dart';
import 'package:mix_music/common/entity/artist.dart';
import 'package:mix_music/common/entity/play_list.dart';
import 'package:mix_music/common/entity/rank.dart';
import 'package:mix_music/common/entity/mv.dart';
import 'package:mix_music/common/entity/song.dart';
import 'package:mix_music/common/plugin/plugin_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('song VIP badge follows plugin metadata and survives serialization', () {
    for (final flag in [null, 0, 1, false, true]) {
      final song = Song.fromJson({
        'pluginId': 'test.resource',
        'id': 1,
        'title': '歌曲',
        'vip': flag,
      });
      expect(song.vip, flag == 1 || flag == true);
      expect(Song.fromJson(song.toJson()).vip, song.vip);
    }
  });

  test(
    'resource objects retain opaque IDs, snapshots, songs and quality fields',
    () {
      for (final id in [
        '123',
        123,
        {
          'nested': [1, 'x'],
        },
      ]) {
        final json = {
          'pluginId': 'test.resource',
          'id': id,
          'title': '资源',
          'subTitle': '副标题',
          'pic': 'cover',
          'description': '简介',
          'custom': {'value': 1},
          'total': 1,
          'hasMore': false,
          'songs': [
            {
              'id': id,
              'title': '歌曲',
              'quality': [
                {'id': 'standard', 'title': '标准', 'quality': 128},
              ],
            },
          ],
        };
        for (final resource in [
          Album.fromJson(json),
          Artist.fromJson(json),
          PlayList.fromJson(json),
          Rank.fromJson(json),
        ]) {
          expect(resource.id, id);
          expect(resource.songs.single.id, id);
          expect(resource.songs.single.pluginId, 'test.resource');
          expect(
            resource.songs.single.qualities.single.pluginId,
            'test.resource',
          );
          expect(resource.songs.single.qualities.single.value, 128);
          expect(resource.total, 1);
          expect(resource.hasMore, isFalse);
          resource.title = '修改标题';
          final restored = jsonDecode(jsonEncode(resource.toJson())) as Map;
          expect(restored['title'], '修改标题');
          expect(restored['id'], id);
          expect(restored['custom'], {'value': 1});
          expect(json['title'], '资源');
        }
        final mv = Mv.fromJson({
          ...json,
          'quality': [
            {
              'id': 'quality-id',
              'title': '高清',
              'quality': 720,
              'httpHeaders': {'x-test': 'value'},
            },
          ],
        });
        expect(mv.qualities.single.id, 'quality-id');
        expect((mv.toJson()['quality'] as List).single['httpHeaders'], {
          'x-test': 'value',
        });
      }
    },
  );

  test(
    'all resource list APIs return objects and serialize typed arguments',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'mixmusic-resource-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final plugins = PluginController(
        store: JsExtensionFileStore(directoryPath: directory.path),
        storage: JsMemoryKvStore(),
      );
      addTearDown(plugins.disposeController);
      const lists = [
        'searchAlbum',
        'searchArtist',
        'searchPlayList',
        'searchMv',
        'playList',
        'albumList',
        'artistList',
        'mvList',
        'playListRec',
        'albumRec',
        'mvRec',
        'rankList',
        'artistAlbum',
      ];
      await plugins.install(
        JsExtensionPackage(
          manifestSource: jsonEncode({
            'schemaVersion': 2,
            'id': 'test.resource',
            'name': '对象测试',
            'description': '合成数据',
            'version': '1.0.0',
            'versionCode': 1,
            'compatibilityCode': 'mixmusic-source-v1',
            'service': {
              'entry': 'main.mjs',
              'contract': 'mixmusic-source/v1',
              'publicExports': ['getHome', ...lists, 'parsePlayList'],
            },
          }),
          serviceModules: {
            'main.mjs':
                '''
const item = {id: {value: [1, 'a']}, title: '测试', extra: '保留'};
export function getHome() { return {songs: [], ranks: [item]}; }
${lists.map((name) => 'export function $name(...args) { console.log(JSON.stringify(args)); return [item]; }').join('\n')}
export function parsePlayList(url) { return item; }
''',
          },
        ),
      );
      final api = plugins.music('test.resource');
      expect((await api.searchAlbum('x')).single, isA<Album>());
      expect((await api.searchArtist('x')).single, isA<Artist>());
      expect((await api.searchPlayList('x')).single, isA<PlayList>());
      expect((await api.searchMv('x')).single, isA<Mv>());
      expect((await api.playList(null)).single, isA<PlayList>());
      expect((await api.albumList(null)).single, isA<Album>());
      expect((await api.artistList(null)).single, isA<Artist>());
      expect((await api.mvList(null)).single, isA<Mv>());
      expect((await api.playListRec()).single, isA<PlayList>());
      expect((await api.albumRec()).single, isA<Album>());
      expect((await api.mvRec()).single, isA<Mv>());
      final rank = (await api.rankList()).single;
      expect(rank.id, {
        'value': [1, 'a'],
      });
      expect(rank.pluginId, 'test.resource');
      expect((await api.parsePlayList('test'))!.details['extra'], '保留');
      final artist = Artist(pluginId: 'test.resource', id: {'artist': 7});
      expect((await api.artistAlbum(artist, 2, 15)).single, isA<Album>());
      final arguments = jsonDecode(plugins.logs.value.last.message) as List;
      expect(arguments[0]['id'], artist.id);
      expect(arguments.sublist(1), [2, 15]);
      await plugins.selectSource('test.resource');
      expect(plugins.sections.value.containsKey('ranks'), isFalse);
      expect((await api.rankList()).single, isA<Rank>());
    },
  );
}
