import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lemon_js_extensions/lemon_js_extensions.dart';
import 'package:mix_music/common/plugin/plugin_controller.dart';
import 'package:mix_music/page/parse/parse_controller.dart';

JsExtensionPackage parser(String id, String expression) => JsExtensionPackage(
  manifestSource: jsonEncode({
    'schemaVersion': 2,
    'id': id,
    'name': id,
    'description': '合成歌单解析测试',
    'version': '1.0.0',
    'versionCode': 1,
    'compatibilityCode': 'mixmusic-source-v1',
    'service': {
      'entry': 'main.mjs',
      'contract': 'mixmusic-source/v1',
      'publicExports': ['getHome', 'parsePlayList'],
    },
  }),
  serviceModules: {
    'main.mjs':
        '''
export function getHome() { return {songs: []}; }
export function parsePlayList(text) { $expression }
''',
  },
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late PluginController plugins;
  late ParseController controller;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('mixmusic-parse-');
    plugins = PluginController(
      store: JsExtensionFileStore(directoryPath: directory.path),
      storage: JsMemoryKvStore(),
    );
    await plugins.restored;
    controller = ParseController(plugins);
  });
  tearDown(() async {
    await controller.disposeController();
    await plugins.disposeController();
    await directory.delete(recursive: true);
  });

  test('empty input and absent parsers report errors', () async {
    await controller.parse('   ');
    expect(controller.result.hasError, isTrue);
    await controller.parse('https://example.invalid/share');
    expect(controller.result.errorValue.toString(), contains('没有支持歌单解析的插件'));
  });

  test(
    'parsers receive complete share text and preserve opaque IDs and sources',
    () async {
      for (final id in ['test.first', 'test.second']) {
        await plugins.install(
          parser(id, "return {id:{key:[1,'a']},title:text};"),
        );
      }
      await controller.parse('  分享歌单 https://example.invalid/share  ');
      final items = controller.result.value!;
      expect(items.map((item) => item.pluginId), ['test.first', 'test.second']);
      expect(items.first.id, {
        'key': [1, 'a'],
      });
      expect(items.first.title, '分享歌单 https://example.invalid/share');
    },
  );

  test('a malformed plugin result is not shown as an empty playlist', () async {
    await plugins.install(parser('test.invalid', 'return {};'));
    await controller.parse('share');
    expect(controller.result.hasError, isTrue);
    expect(controller.result.errorValue.toString(), contains('插件未返回有效歌单信息'));
  });

  test('one parser failure does not hide another result', () async {
    await plugins.install(parser('test.fail', "throw new Error('测试解析错误');"));
    await plugins.install(
      parser('test.good', "return {id:'playlist',title:'歌单'};"),
    );
    await controller.parse('share');
    expect(controller.result.value!.single.pluginId, 'test.good');
    expect(
      plugins.logs.value.any((log) => log.message.contains('测试解析错误')),
      isTrue,
    );
  });

  test(
    'unmatched links return empty and a failed parse can be retried',
    () async {
      await plugins.install(
        parser(
          'test.parse',
          "if(text==='bad') throw new Error('无法解析'); return null;",
        ),
      );
      await controller.parse('bad');
      expect(controller.result.hasError, isTrue);
      await controller.parse('none');
      expect(controller.result.hasData, isTrue);
      expect(controller.result.value, isEmpty);
    },
  );

  test(
    'disabled parsers are skipped and duplicate submits do not parse twice',
    () async {
      await plugins.install(
        parser('test.disabled', "throw new Error('不应调用');"),
      );
      await plugins.setEnabled('test.disabled', false);
      await plugins.install(
        parser(
          'test.active',
          "globalThis.calls=(globalThis.calls||0)+1; return {id:globalThis.calls,title:'歌单'};",
        ),
      );
      expect(controller.sources.map((entry) => entry.id), ['test.active']);
      final first = controller.parse('share');
      await controller.parse('share');
      await first;
      expect(controller.result.value!.single.id, 1);
    },
  );
}
