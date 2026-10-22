import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lemon_js_extensions/lemon_js_extensions.dart';
import 'package:mix_music/common/plugin/plugin_controller.dart';

Future<JsExtensionPackage> zipPackage(int version) async {
  final files = {
    'manifest.json': jsonEncode({
      'schemaVersion': 2,
      'id': 'test.source',
      'name': '通用验证插件',
      'description': '测试安装生命周期',
      'version': '$version.0.0',
      'versionCode': version,
      'compatibilityCode': 'mixmusic-source-v1',
      'service': {
        'entry': 'service/main.mjs',
        'contract': 'mixmusic-source/v1',
        'publicExports': ['getHome'],
      },
    }),
    'service/main.mjs': "export function getHome() { return {songs: [{id: {song: 1}, title: '验证歌曲'}]}; }",
  };
  final archive = Archive();
  for (final file in files.entries) {
    final bytes = utf8.encode(file.value);
    archive.addFile(ArchiveFile(file.key, bytes.length, bytes));
  }
  return JsExtensionPackage.zipBytes(
    Uint8List.fromList(ZipEncoder().encode(archive)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('playback plugin installs without becoming a source', () async {
    final controller = PluginController(
      store: JsExtensionMemoryStore(),
      storage: JsMemoryKvStore(),
    );
    addTearDown(controller.disposeController);
    await controller.install(
      JsExtensionPackage(
        manifestSource: jsonEncode({
          'schemaVersion': 2,
          'id': 'test.output',
          'name': '播放终端',
          'description': '通用播放插件安装测试',
          'version': '1.0.0',
          'versionCode': 1,
          'compatibilityCode': 'mixmusic-playback-v1',
          'service': {
            'entry': 'main.mjs',
            'contract': 'mixmusic-playback/v1',
            'publicExports': ['play'],
          },
        }),
        serviceModules: {
          'main.mjs': 'export function play(media) { return !!media.url; }',
        },
      ),
    );
    expect(controller.homeSources, isEmpty);
    expect(
      await controller.manager.call(
        'test.output',
        'play',
        arguments: [
          {'url': 'https://example.test/audio'},
        ],
      ),
      true,
    );
  });
  test(
    'valid plugin without getHome installs but is not a home source',
    () async {
      final controller = PluginController(
        store: JsExtensionMemoryStore(),
        storage: JsMemoryKvStore(),
      );
      addTearDown(controller.disposeController);
      final package = JsExtensionPackage(
        manifestSource: jsonEncode({
          'schemaVersion': 2,
          'id': 'test.lyric',
          'name': '歌词验证',
          'description': '无首页接口的安装验证',
          'version': '1.0.0',
          'versionCode': 1,
          'compatibilityCode': 'mixmusic-source-v1',
          'service': {
            'entry': 'service/main.mjs',
            'contract': 'mixmusic-source/v1',
            'publicExports': ['lrc'],
          },
        }),
        serviceModules: {
          'service/main.mjs': 'export function lrc() { return {lrc: ""}; }',
        },
      );
      await controller.install(package);
      expect(controller.extensions.value.single.id, 'test.lyric');
      expect(controller.homeSources, isEmpty);
    },
  );
  test(
    'ZIP install update disable restore uninstall and data deletion',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'mixmusic-install-test-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final store = JsExtensionFileStore(directoryPath: directory.path);
      final storage = JsMemoryKvStore();
      final controller = PluginController(store: store, storage: storage);
      addTearDown(controller.disposeController);
      await controller.install(await zipPackage(1));
      expect(controller.extensions.value.single.id, 'test.source');
      await controller.selectSource('test.source');
      expect(controller.home.hasError, isFalse);
      expect(controller.home.value!.single.id, {'song': 1});
      await storage.set('login', 'test-session', namespace: 'test.source');
      await controller.setEnabled('test.source', false);
      expect(
        controller.extensions.value.single.state,
        JsExtensionManagerState.disabled,
      );
      expect(controller.home.value, isEmpty);
      await expectLater(
        () => controller.manager.call('test.source', 'getHome'),
        throwsStateError,
      );
      await controller.disposeController();

      final restored = PluginController(store: store, storage: storage);
      addTearDown(restored.disposeController);
      await restored.restored;
      expect(
        restored.extensions.value.single.state,
        JsExtensionManagerState.disabled,
      );
      await restored.setEnabled('test.source', true);
      await restored.install(await zipPackage(2));
      expect(restored.extensions.value.single.versionCode, 2);
      expect(
        await storage.get('login', namespace: 'test.source'),
        'test-session',
      );
      await restored.install(await zipPackage(2));
      await expectLater(
        restored.install(await zipPackage(1)),
        throwsStateError,
      );
      await restored.uninstall('test.source');
      expect(restored.extensions.value, isEmpty);
      expect(
        await storage.get('login', namespace: 'test.source'),
        'test-session',
      );
      await restored.install(await zipPackage(2));
      await restored.uninstall('test.source', clearStorage: true);
      expect(restored.extensions.value, isEmpty);
      expect(await storage.get('login', namespace: 'test.source'), isNull);
      expect(await store.load('test.source'), isNull);
    },
  );
}
