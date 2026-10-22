import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lemon_js_extensions/lemon_js_extensions.dart';
import 'package:mix_music/common/api/music_api.dart';
import 'package:mix_music/common/entity/comment.dart';
import 'package:mix_music/common/entity/song.dart';
import 'package:mix_music/common/plugin/plugin_controller.dart';
import 'package:mix_music/page/comment/comment_controller.dart';

class PendingComments extends MusicApi {
  PendingComments(super.manager, super.pluginId);
  final requests = <Completer<CommentPage>>[];
  @override
  Future<CommentPage> songComments(
    Song song, {
    dynamic category,
    int page = 0,
    int size = 20,
    dynamic cursor,
  }) {
    final pending = Completer<CommentPage>();
    requests.add(pending);
    return pending.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PluginController plugins;
  late Song song;
  late CommentController controller;
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('mixmusic-comments-');
    plugins = PluginController(
      store: JsExtensionFileStore(directoryPath: directory.path),
      storage: JsMemoryKvStore(),
    );
    await plugins.install(
      JsExtensionPackage(
        manifestSource: jsonEncode({
          'schemaVersion': 2,
          'id': 'test.comments',
          'name': '评论测试',
          'description': '合成数据',
          'version': '1.0.0',
          'versionCode': 1,
          'compatibilityCode': 'mixmusic-source-v1',
          'service': {
            'entry': 'main.mjs',
            'contract': 'mixmusic-source/v1',
            'publicExports': ['getHome', 'songComments'],
          },
        }),
        serviceModules: {
          'main.mjs': '''
export function getHome() { return {songs:[]}; }
export function songComments(song, options) {
  if(song.id.fail) throw new Error('测试评论失败');
  if(song.id.key[1]!=='opaque') throw new Error('歌曲 ID 被修改');
  if(options.page===1 && options.cursor?.seqNo!=='next') throw new Error('游标错误');
  if(song.id.noCategories && options.category!=null) throw new Error('宿主不应提供默认分类');
  const categories=[{id:7,title:'精选'},{id:{channel:[2,'x']},title:'朋友动态'},{id:'custom',title:'其他'}];
  const category=song.id.noCategories?null:(options.category??categories[0].id);
  const count=options.page===0?2:1;
  return {items:Array.from({length:count},(_,i)=>({id:{page:options.page,i},
    content:JSON.stringify(category),userName:'测试用户',time:1000,likes:3})),
    ...(song.id.noCategories?{}:{categories,category}),
    hasMore:options.page===0,total:3,cursor:{seqNo:'next',total:3,totalVer:'v1'}};
}
''',
        },
      ),
    );
    song = Song(
      pluginId: 'test.comments',
      id: <String, dynamic>{
        'key': [1, 'opaque'],
      },
      title: '测试歌曲',
    );
    controller = CommentController(plugins, song);
  });
  tearDown(() async {
    await controller.disposeController();
    await plugins.disposeController();
    await directory.delete(recursive: true);
  });

  test('comments use typed API, opaque IDs and plugin pagination', () async {
    await controller.loadMore();
    expect(controller.items.value.length, 2);
    expect(controller.items.value.first.id, {'page': 0, 'i': 0});
    expect(controller.items.value.first.userName, '测试用户');
    expect(controller.items.value.first.likes, 3);
    expect(controller.category.value, 7);
    expect(controller.categories.value.map((item) => item['title']), [
      '精选',
      '朋友动态',
      '其他',
    ]);
    expect(controller.cursor, {'seqNo': 'next', 'total': 3, 'totalVer': 'v1'});
    await controller.loadMore();
    expect(controller.items.value.length, 3);
    expect(controller.hasMore.value, false);
    await controller.loadMore();
    expect(controller.page, 2);
    await controller.selectCategory({
      'channel': [2, 'x'],
    });
    expect(controller.page, 1);
    expect(controller.items.value.length, 2);
    expect(controller.items.value.first.content, '{"channel":[2,"x"]}');
    expect(
      controller.isSelected({
        'channel': [2, 'x'],
      }),
      isTrue,
    );
    await controller.selectCategory({
      'channel': [2, 'x'],
    });
    expect(controller.page, 1);
    expect(controller.hasMore.value, true);
    await controller.loadMore();
    expect(controller.items.value.length, 3);
    expect(controller.hasMore.value, false);
    await controller.selectCategory('custom');
    expect(controller.items.value.first.content, '"custom"');
    expect(controller.page, 1);
    await controller.loadMore();
    expect(controller.items.value.length, 3);
    expect(controller.hasMore.value, false);
  });

  test('plugins without categories receive no host default', () async {
    song.id['noCategories'] = true;
    await controller.loadMore();
    expect(controller.categories.value, isEmpty);
    expect(controller.category.value, isNull);
    expect(controller.items.value.length, 2);
    await controller.loadMore();
    expect(controller.items.value.length, 3);
    await controller.refresh();
    expect(controller.category.value, isNull);
    expect(controller.categories.value, isEmpty);
  });

  test(
    'failed next page preserves earlier comments and retries that page',
    () async {
      await controller.loadMore();
      song.id['fail'] = true;
      await controller.loadMore();
      expect(controller.page, 1);
      expect(controller.items.value.length, 2);
      expect(controller.error.value, contains('测试评论失败'));
      song.id['fail'] = false;
      await controller.loadMore();
      expect(controller.error.value, isEmpty);
      expect(controller.items.value.length, 3);
    },
  );

  test('sorting and disposal ignore late results; loading does not duplicate calls', () async {
    final api = PendingComments(plugins.manager, song.pluginId);
    plugins.builtins[song.pluginId] = api;
    final first = controller.loadMore();
    await controller.loadMore();
    expect(api.requests.length, 1);
    final second = controller.selectCategory({
      'custom': [1, 'pending'],
    });
    api.requests[1].complete((
      items: [Comment(id: 2, content: 'new', userName: '用户')],
      categories: <Map<String, dynamic>>[],
      category: null,
      total: 1,
      hasMore: false,
      cursor: null,
    ));
    await second;
    api.requests[0].complete((
      items: [Comment(id: 1, content: 'old', userName: '用户')],
      categories: <Map<String, dynamic>>[],
      category: null,
      total: 1,
      hasMore: false,
      cursor: null,
    ));
    await first;
    expect(controller.items.value.single.content, 'new');
    final third = controller.refresh();
    await controller.disposeController();
    api.requests[2].complete((
      items: <Comment>[],
      categories: <Map<String, dynamic>>[],
      category: null,
      total: 0,
      hasMore: false,
      cursor: null,
    ));
    await third;
  });
}
