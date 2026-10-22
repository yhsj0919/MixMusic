import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lemon_js_extensions/lemon_js_extensions.dart';
import 'package:mix_music/common/api/music_api.dart';
import 'package:mix_music/common/entity/mv.dart';
import 'package:mix_music/common/plugin/plugin_controller.dart';
import 'package:mix_music/page/mv/mv_controller.dart';

class PendingMvPlugins extends PluginController {
  late final api = PendingMvApi(this);
  @override
  MusicApi music(String pluginId) => api;
}

class PendingMvApi extends MusicApi {
  PendingMvApi(PluginController plugins) : super(plugins.manager, 'test.mv');
  final requests = <Completer<Map<String, dynamic>>>[];
  @override
  Future<Mv> mvInfo(Mv mv) async {
    final request = Completer<Map<String, dynamic>>();
    requests.add(request);
    return Mv.fromJson({...mv.toJson(), ...await request.future});
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'MV JS details print main and quality URLs; empty and error stay factual',
    () async {
      final directory = await Directory.systemTemp.createTemp('mixmusic-mv-');
      addTearDown(() => directory.delete(recursive: true));
      final plugins = PluginController(
        store: JsExtensionFileStore(directoryPath: directory.path),
        storage: JsMemoryKvStore(),
      );
      addTearDown(plugins.disposeController);
      final printed = <String>[];
      final previousPrint = debugPrint;
      debugPrint = (message, {wrapWidth}) => printed.add(message ?? '');
      addTearDown(() => debugPrint = previousPrint);
      await plugins.install(
        JsExtensionPackage(
          manifestSource: jsonEncode({
            'schemaVersion': 2,
            'id': 'test.mv',
            'name': 'MV 接口测试',
            'description': '合成数据',
            'version': '1.0.0',
            'versionCode': 1,
            'compatibilityCode': 'mixmusic-source-v1',
            'service': {
              'entry': 'main.mjs',
              'contract': 'mixmusic-source/v1',
              'publicExports': ['getHome', 'mvInfo', 'favoriteMv'],
            },
          }),
          serviceModules: {
            'main.mjs': '''
export function getHome() { return {songs: []}; }
export function favoriteMv(item, value) {
  if (typeof value !== 'boolean') throw new Error('收藏参数错误');
  if (item.id.mode === 'favorite-error') throw new Error('测试收藏失败');
  if (item.id.nested[1] !== 'a') throw new Error('MV ID 被修改');
  return null;
}
export function mvInfo(item) {
  if (item.id.mode === 'error') throw new Error('测试接口错误');
  if (item.id.mode === 'empty') return {...item, url: null, quality: []};
  return {...item, title: 'MV 详情', desc: '测试简介', url: 'https://example.invalid/default.mp4',
    quality: [{title: '720P', quality: 720, url: 'https://example.invalid/720.mp4'},
      {title: '1080P', quality: 1080, url: 'https://example.invalid/1080.mp4'}]};
}
''',
          },
        ),
      );
      final controller = MvController(
        plugins,
        Mv.fromJson({
          'pluginId': 'test.mv',
          'id': {
            'mode': 'normal',
            'nested': [1, 'a'],
          },
          'title': '原始 MV',
        }),
      );
      addTearDown(controller.disposeController);
      await controller.load();
      expect(controller.info.hasData, isTrue);
      expect(controller.info.value!.id, {
        'mode': 'normal',
        'nested': [1, 'a'],
      });
      expect(controller.info.value!.title, 'MV 详情');
      expect(printed.length, 3);
      expect(printed[1], contains('720.mp4'));
      expect(plugins.logs.value.map((log) => log.message), printed);
      controller.printAddresses();
      expect(printed.length, 6);
      expect(controller.supportsFavorite, isTrue);
      await controller.favorite(true);
      expect(controller.resource.favorited, isTrue);
      expect(controller.info.value!.favorited, isTrue);
      await controller.favorite(false);
      expect(controller.resource.favorited, isFalse);
      expect(controller.info.value!.favorited, isFalse);
      final favoriteFailure = MvController(
        plugins,
        Mv.fromJson({
          'pluginId': 'test.mv',
          'id': {'mode': 'favorite-error'},
          'favorited': false,
        }),
      );
      addTearDown(favoriteFailure.disposeController);
      await favoriteFailure.load();
      await expectLater(favoriteFailure.favorite(true), throwsA(anything));
      expect(favoriteFailure.resource.favorited, isFalse);
      expect(favoriteFailure.info.value!.favorited, isFalse);
      final empty = MvController(
        plugins,
        Mv.fromJson({
          'pluginId': 'test.mv',
          'id': {'mode': 'empty'},
        }),
      );
      addTearDown(empty.disposeController);
      await empty.load();
      expect(empty.info.hasData, isTrue);
      expect(plugins.logs.value.last.message, 'MV 未返回地址');
      final failure = MvController(
        plugins,
        Mv.fromJson({
          'pluginId': 'test.mv',
          'id': {'mode': 'error'},
        }),
      );
      addTearDown(failure.disposeController);
      await failure.load();
      expect(failure.info.hasError, isTrue);
      expect(plugins.logs.value.last.level, 'error');
      expect(plugins.logs.value.last.message, contains('测试接口错误'));
    },
  );

  test(
    'old requests and disposed MV pages do not update or print URLs',
    () async {
      final plugins = PendingMvPlugins();
      addTearDown(plugins.disposeController);
      final controller = MvController(
        plugins,
        Mv.fromJson({'pluginId': 'test.mv', 'id': 1}),
      );
      final first = controller.load();
      expect(controller.supportsFavorite, isFalse);
      final second = controller.load();
      plugins.api.requests[1].complete({'title': 'new', 'url': null});
      await second;
      plugins.api.requests[0].complete({
        'title': 'old',
        'url': 'https://example.invalid/old',
      });
      await first;
      expect(controller.info.value!.title, 'new');
      expect(plugins.logs.value.length, 1);
      final third = controller.load();
      await controller.disposeController();
      plugins.api.requests[2].complete({
        'url': 'https://example.invalid/disposed',
      });
      await third;
      expect(plugins.logs.value.length, 1);
    },
  );
}
