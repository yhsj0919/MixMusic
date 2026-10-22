import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lemon_js_extensions/lemon_js_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mix_music/common/plugin/plugin_controller.dart';
import 'package:mix_music/common/api/music_api.dart';
import 'package:mix_music/common/entity/song.dart';
import 'package:mix_music/common/entity/play_list.dart';
import 'package:mix_music/common/entity/album.dart';
import 'package:mix_music/common/entity/mv.dart';

class HomeStorage implements JsKvStore {
  final memory = JsMemoryKvStore();
  final requests = <Completer<Object?>>[];
  Completer<void>? entered;
  final sectionCalls = <String>[];
  final sectionPending = <String, Completer<Object?>>{};

  @override
  Future<Object?> get(String key, {String? namespace}) {
    if (key != 'home') {
      sectionCalls.add(key);
      return sectionPending[key]?.future ??
          memory.get(key, namespace: namespace);
    }
    final request = Completer<Object?>();
    requests.add(request);
    entered?.complete();
    return request.future;
  }

  @override
  Future<void> set(String key, Object? value, {String? namespace}) =>
      memory.set(key, value, namespace: namespace);
  @override
  Future<bool> containsKey(String key, {String? namespace}) =>
      memory.containsKey(key, namespace: namespace);
  @override
  Future<void> remove(String key, {String? namespace}) =>
      memory.remove(key, namespace: namespace);
  @override
  Future<List<String>> keys({String? namespace}) =>
      memory.keys(namespace: namespace);
  @override
  Future<void> clear({String? namespace}) => memory.clear(namespace: namespace);
}

JsExtensionPackage homePlugin(String id, {List<String> exports = const []}) =>
    JsExtensionPackage(
      manifestSource: jsonEncode({
        'schemaVersion': 2,
        'id': id,
        'name': id,
        'description': '合成数据',
        'version': '1.0.0',
        'versionCode': 1,
        'compatibilityCode': 'mixmusic-source-v1',
        'service': {
          'entry': 'main.mjs',
          'contract': 'mixmusic-source/v1',
          'publicExports': ['getHome', ...exports],
        },
      }),
      serviceModules: {
        'main.mjs': '''
import storage from 'lemon_js_extensions/storage';
export async function getHome() { return await storage.get('home'); }
export async function albumRec() { return await storage.get('albums'); }
export async function playListRec() { return await storage.get('playlists'); }
export async function songRec() { return await storage.get('songs'); }
export async function mvRec() { return []; }
''',
      },
    );

class FourHomeApi extends MusicApi {
  FourHomeApi(PluginController plugins) : super(plugins.manager, 'test.four');
  final calls = <String>[];
  final requests = <String, Completer<List>>{};
  Future<List<T>> load<T>(String key) {
    calls.add(key);
    final request = requests[key] = Completer<List>();
    return request.future.then((items) => items.cast<T>());
  }

  @override
  Future<List<Song>> songRec() => load<Song>('songs');
  @override
  Future<List<PlayList>> playListRec() => load<PlayList>('playlists');
  @override
  Future<List<Album>> albumRec() => load<Album>('albums');
  @override
  Future<List<Mv>> mvRec() => load<Mv>('mvs');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PluginController plugins;
  late HomeStorage storage;
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('mixmusic-home-');
    addTearDown(() => directory.delete(recursive: true));
    storage = HomeStorage();
    plugins = PluginController(
      store: JsExtensionFileStore(directoryPath: directory.path),
      storage: storage,
    );
    addTearDown(plugins.disposeController);
    await plugins.install(homePlugin('test.first'));
    await plugins.install(homePlugin('test.second'));
  });

  Map<String, Object> data(String value) => {
    'songs': [
      {'id': value, 'title': value},
    ],
    'albums': [
      {'id': value, 'title': value},
    ],
  };

  Future<void> enter() async {
    await storage.entered!.future.timeout(const Duration(seconds: 5));
  }

  Future<void> select(String id, Map<String, Object> result) async {
    storage.entered = Completer<void>();
    final pending = plugins.selectSource(id);
    await enter();
    storage.requests.last.complete(result);
    await pending;
  }

  test(
    'four recommendations start together; a failure stays local and retries',
    () async {
      await plugins.install(
        homePlugin(
          'test.four',
          exports: ['songRec', 'playListRec', 'albumRec', 'mvRec'],
        ),
      );
      final api = FourHomeApi(plugins);
      plugins.builtins['test.four'] = api;
      final pending = plugins.selectSource('test.four');
      await Future<void>.delayed(Duration.zero);
      expect(api.calls, ['songs', 'playlists', 'albums', 'mvs']);
      expect(storage.requests, isEmpty);
      api.requests['songs']!.complete([
        Song(pluginId: 'test.four', id: 1, title: '新歌'),
      ]);
      api.requests['playlists']!.complete([
        PlayList(pluginId: 'test.four', id: 2, title: '歌单'),
      ]);
      api.requests['mvs']!.complete([]);
      await Future<void>.delayed(Duration.zero);
      expect(plugins.home.value!.single.title, '新歌');
      expect(plugins.sections.value['playlists']!.single.title, '歌单');
      expect(plugins.sectionLoading.value, {'albums'});
      api.requests['albums']!.completeError(StateError('测试分区错误'));
      await pending;
      expect(plugins.home.hasError, isFalse);
      expect(plugins.sectionErrors.value.keys, contains('albums'));
      final retry = plugins.loadSection('albums');
      api.requests['albums']!.complete([
        Album(
          pluginId: 'test.four',
          id: {
            'album': [7, 'a'],
          },
          title: '专辑',
        ),
      ]);
      await retry;
      expect(plugins.sections.value['albums']!.single.id, {
        'album': [7, 'a'],
      });
      expect(plugins.sectionErrors.value, isEmpty);
      await plugins.loadSection('albums');
      expect(api.calls.where((key) => key == 'albums').length, 2);
      expect(api.calls.where((key) => key == 'songs').length, 1);
    },
  );

  test(
    'old recommendation completion cannot replace the selected source',
    () async {
      await plugins.install(
        homePlugin(
          'test.four',
          exports: ['songRec', 'playListRec', 'albumRec', 'mvRec'],
        ),
      );
      final api = FourHomeApi(plugins);
      plugins.builtins['test.four'] = api;
      final pending = plugins.selectSource('test.four');
      await Future<void>.delayed(Duration.zero);
      api.requests['songs']!.complete([]);
      api.requests['playlists']!.complete([]);
      api.requests['mvs']!.complete([]);
      await select('test.second', data('new'));
      api.requests['albums']!.complete([
        Album(pluginId: 'test.four', id: 1, title: 'old'),
      ]);
      await pending;
      expect(plugins.selectedId.value, 'test.second');
      expect(plugins.sections.value['albums']!.single.title, 'new');
      expect(plugins.sectionLoading.value, isEmpty);
    },
  );

  test('one default home source restores from SP and changing it replaces the value', () async {
    SharedPreferences.setMockInitialValues({'homeSource': 'test.second'});
    final preferences = await SharedPreferences.getInstance();
    final restored = PluginController(
      store: JsExtensionFileStore(directoryPath: directory.path),
      storage: storage,
      preferences: preferences,
    );
    addTearDown(restored.disposeController);
    storage.entered = Completer<void>();
    final ready = restored.homeReady;
    await enter();
    expect(restored.selectedId.value, 'test.second');
    storage.requests.last.complete(data('second'));
    await ready;
    storage.entered = Completer<void>();
    final changed = restored.selectSource('test.first');
    await enter();
    storage.requests.last.complete(data('first'));
    await changed;
    expect(preferences.getString('homeSource'), 'test.first');
    expect(restored.home.value!.single.title, 'first');
  });

  test(
    'late home results cannot overwrite the selected source, including A-B-A',
    () async {
      storage.entered = Completer<void>();
      final first = plugins.selectSource('test.first');
      await enter();
      storage.entered = Completer<void>();
      final second = plugins.selectSource('test.second');
      await enter();
      storage.entered = Completer<void>();
      final third = plugins.selectSource('test.first');
      final thirdEntered = storage.entered!.future;
      await Future<void>.delayed(Duration.zero);
      storage.requests[1].complete(data('other'));
      await second;
      storage.requests[0].complete(data('old'));
      await first;
      await thirdEntered.timeout(const Duration(seconds: 5));
      expect(plugins.home.isLoading, isTrue);
      expect(plugins.sections.value, isEmpty);
      storage.requests[2].complete(data('new'));
      await third;
      expect(plugins.selectedId.value, 'test.first');
      expect(plugins.home.value!.single.title, 'new');
      expect(plugins.sections.value['albums']!.single.title, 'new');
    },
  );

  test('late home errors do not replace a successful newer source', () async {
    storage.entered = Completer<void>();
    final first = plugins.selectSource('test.first');
    await enter();
    storage.entered = Completer<void>();
    final second = plugins.selectSource('test.second');
    await enter();
    storage.requests[1].complete(data('new'));
    await second;
    storage.requests[0].completeError(StateError('旧请求错误'));
    await first;
    expect(plugins.home.hasError, isFalse);
    expect(plugins.home.value!.single.title, 'new');
  });
}
