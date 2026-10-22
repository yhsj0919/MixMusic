import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mix_music/common/plugin/plugin_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('plugin state and app settings share one persistent snapshot', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final storage = PluginStorage(preferences);
    await storage.set('session', 'synthetic-token', namespace: 'test.first');
    await preferences.setInt('playQuality', 320);
    await preferences.setDouble('volume', 0.5);
    final restored = PluginStorage(preferences);
    expect(
      await restored.get('session', namespace: 'test.first'),
      'synthetic-token',
    );
    await restored.set('options', {'enabled': true}, namespace: 'test.first');
    expect(preferences.getInt('playQuality'), 320);
    expect(preferences.getDouble('volume'), 0.5);
    expect(await restored.get('options', namespace: 'test.first'), {
      'enabled': true,
    });
    await preferences.reload();
    expect(
      await PluginStorage(preferences).get('session', namespace: 'test.first'),
      'synthetic-token',
    );
  });

  test('plugin clear and keys only affect the requested namespace', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final storage = PluginStorage(preferences);
    await storage.set('session', 'one', namespace: 'test.first');
    await storage.set('session', 'two', namespace: 'test.second');
    await preferences.setBool('darkMode', true);
    expect(
      await storage.containsKey('session', namespace: 'test.first'),
      isTrue,
    );
    expect(await storage.keys(namespace: 'test.first'), ['session']);
    await storage.clear(namespace: 'test.first');
    expect(await storage.get('session', namespace: 'test.first'), isNull);
    expect(await storage.get('session', namespace: 'test.second'), 'two');
    expect(preferences.getBool('darkMode'), isTrue);
  });
}
