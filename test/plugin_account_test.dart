import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lemon_js_extensions/lemon_js_extensions.dart';
import 'package:mix_music/common/plugin/plugin_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'plugin account loads, refreshes and follows enable and uninstall',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'mixmusic-account-',
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
            'id': 'test.account',
            'name': '账号测试',
            'description': '合成账号数据',
            'version': '1.0.0',
            'versionCode': 1,
            'compatibilityCode': 'mixmusic-source-v1',
            'service': {
              'entry': 'main.mjs',
              'contract': 'mixmusic-source/v1',
              'publicExports': ['getHome', 'getAccount'],
            },
          }),
          serviceModules: {
            'main.mjs': '''
export function getHome() { return {songs: []}; }
let reads = 0;
export function getAccount(...args) {
  if (args.length) throw Error('host must not control session refresh');
  const refresh = ++reads === 2;
  return {status: 'signedIn', id: {key: 'opaque'}, name: '测试用户', pic: null,
    isVip: !refresh, vipEndTime: refresh ? null : '2030-01-01T00:00:00.000Z'};
}
''',
          },
        ),
      );
      var account = plugins.accounts.value['test.account']!;
      expect(account.name, '测试用户');
      expect(account.id, {'key': 'opaque'});
      expect(account.isVip, isTrue);
      expect(account.vipEndTime!.toUtc(), DateTime.utc(2030));
      await plugins.loadAccount('test.account');
      account = plugins.accounts.value['test.account']!;
      expect(account.isVip, isFalse);
      expect(account.vipEndTime, isNull);
      await plugins.setEnabled('test.account', false);
      expect(plugins.accounts.value.containsKey('test.account'), isFalse);
      await plugins.setEnabled('test.account', true);
      expect(plugins.accounts.value['test.account']!.isVip, isTrue);
      await plugins.uninstall('test.account');
      expect(plugins.accounts.value, isEmpty);
    },
  );
}
