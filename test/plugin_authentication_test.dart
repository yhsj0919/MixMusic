import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lemon_js_extensions/lemon_js_extensions.dart';
import 'package:mix_music/common/plugin/plugin_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('authentication entry follows manifest, binds UI service and restores WebView support', () async {
    final directory = await Directory.systemTemp.createTemp('mixmusic-auth-');
    addTearDown(() => directory.delete(recursive: true));
    final store = JsExtensionFileStore(directoryPath: directory.path);
    final storage = JsMemoryKvStore();
    final plugins = PluginController(store: store, storage: storage);
    addTearDown(plugins.disposeController);
    expect(plugins.authenticationRoute('unknown'), isNull);
    await plugins.install(
      JsExtensionPackage(
        manifestSource: jsonEncode({
          'schemaVersion': 2,
          'id': 'test.authentication',
          'name': '认证测试',
          'description': '合成数据',
          'version': '1.0.0',
          'versionCode': 1,
          'compatibilityCode': 'mixmusic-source-v1',
          'service': {
            'entry': 'main.mjs',
            'contract': 'mixmusic-source/v1',
            'publicExports': ['getHome'],
            'uiExports': ['submit'],
          },
          'ui': {
            'routes': {
              'signIn': {'entry': 'login.mjs', 'title': '登录'},
            },
          },
          'flows': {
            'authentication': {'route': 'signIn'},
          },
        }),
        serviceModules: {
          'main.mjs': '''
export function getHome() { return {songs: []}; }
export function submit() { return {completed: true}; }
''',
        },
        uiModules: {
          'login.mjs': 'export default {type: "Text", props: {data: "测试"}};',
        },
      ),
    );
    expect(plugins.authenticationRoute('test.authentication'), 'signIn');
    final installed = plugins.manager.find('test.authentication')!.installed!;
    expect(
      installed.extension.ui!.plugins.map((plugin) => plugin.name),
      contains('quickjs_ui:plugin:webview'),
    );
    expect(await installed.session.callUi('submit'), {'completed': true});
    expect(() => installed.session.callPublic('submit'), throwsStateError);
    await plugins.disposeController();
    final restored = PluginController(store: store, storage: storage);
    addTearDown(restored.disposeController);
    await restored.restored;
    expect(restored.authenticationRoute('test.authentication'), 'signIn');
    expect(
      restored.manager
          .find('test.authentication')!
          .installed!
          .extension
          .ui!
          .plugins
          .map((plugin) => plugin.name),
      contains('quickjs_ui:plugin:webview'),
    );
  });
}
