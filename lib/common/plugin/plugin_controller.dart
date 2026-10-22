import 'package:flutter/foundation.dart';
import 'package:lemon_x/lemon_x.dart';
import 'package:lemon_js_extensions/lemon_js_extensions.dart';
import 'package:lemon_js_ui_webview/lemon_js_ui_webview.dart';
import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../entity/song.dart';
import '../entity/music_resource.dart';
import '../entity/music_collection.dart';
import '../entity/album.dart';
import '../entity/artist.dart';
import '../entity/play_list.dart';
import '../entity/rank.dart';
import '../entity/mv.dart';
import '../api/music_api.dart';
import '../entity/plugin_log.dart';
import '../entity/plugin_account.dart';
import 'collection_controller.dart';
import 'plugin_storage.dart';
import 'source_matcher.dart';
import 'lyric_matcher.dart';

class PluginController extends LxController {
  late final matcher = own(SourceMatcher(this));
  late final lyricMatcher = own(LyricMatcher(this));
  late final JsExtensionManager manager;
  late final logs = own(Rx<List<PluginLog>>([]));

  PluginController({
    JsExtensionStore? store,
    JsKvStore? storage,
    this.preferences,
  }) {
    action.data('');
    home.data([]);
    manager = JsExtensionManager(
      store: store,
      storage:
          storage ?? (preferences == null ? null : PluginStorage(preferences!)),
      uiPluginsResolver: (_) => [JsUiWebViewPlugin().plugin],
      onConsole: (id, event) {
        debugPrint('[Plugin][$id][${event.level.name}] ${event.text}');
        addLog(id, event.level.name, event.text, time: event.timestamp);
      },
      constraints: [
        JsExtensionConstraint(
          compatibilityCode: 'mixmusic-playback-v1',
          optionalPublicExports: const {
            'getAccount',
            'play',
            'pause',
            'stop',
            'speak',
            'setVolume',
            'getStatus',
          },
        ),
        JsExtensionConstraint(
          compatibilityCode: 'mixmusic-source-v1',
          optionalPublicExports: const {
            'getHome',
            'mySongs',
            'myPlayLists',
            'myAlbums',
            'myMvs',
            'myArtists',
            'createPlayList',
            'deletePlayList',
            'addToPlayList',
            'removeFromPlayList',
            'favoriteSong',
            'favoritePlayList',
            'favoriteAlbum',
            'favoriteArtist',
            'favoriteMv',
            'searchMusic',
            'songComments',
            'searchAlbum',
            'searchArtist',
            'searchPlayList',
            'searchMv',
            'searchSuggest',
            'playUrl',
            'lrc',
            'download',
            'recommendInfo',
            'playListType',
            'playList',
            'playListInfo',
            'albumType',
            'albumList',
            'albumInfo',
            'playListRec',
            'albumRec',
            'songRec',
            'mvRec',
            'rankList',
            'rankInfo',
            'artistType',
            'artistList',
            'artistInfo',
            'artistSong',
            'artistAlbum',
            'mvType',
            'mvList',
            'mvInfo',
            'parsePlayList',
            'getAccount',
          },
        ),
      ],
    );
  }
  late final home = own(RxAsync<List<Song>>());
  late final extensions = own(Rx<List<JsExtensionManagerEntry>>([]));
  late final accounts = own(Rx<Map<String, PluginAccount>>({}));
  late final action = own(RxAsync<String>());
  late final restored = _restore();
  late final homeReady = _restoreHome();
  late final selectedId = own(''.obs);
  late final sections = own(Rx<Map<String, List<MusicResource>>>({}));
  final SharedPreferences? preferences;
  static const sectionTitles = {
    'songs': '新歌',
    'albums': '专辑',
    'playlists': '歌单',
    'ranks': '排行榜',
    'mvs': 'MV',
    'artists': '歌手',
  };
  static const _sectionMethods = {
    'songs': 'songRec',
    'albums': 'albumRec',
    'playlists': 'playListRec',
    'ranks': 'rankList',
    'mvs': 'mvRec',
  };
  late final sectionLoading = own(Rx<Set<String>>({}));
  late final sectionErrors = own(Rx<Map<String, String>>({}));
  final _sectionRequests = <String, Future<void>>{};
  bool _homeHasSongs = false;

  List<JsExtensionManagerEntry> get homeSources => extensions.value
      .where(
        (entry) =>
            entry.state == JsExtensionManagerState.enabled &&
            (entry.installed?.extension.service?.publicExports.contains(
                  'getHome',
                ) ??
                false),
      )
      .toList();

  List<String> get availableSections => [
    for (final key in sectionTitles.keys)
      if ((key == 'songs' ? _homeHasSongs : sections.value.containsKey(key)) ||
          (manager
                  .find(selectedId.value)
                  ?.installed
                  ?.extension
                  .service
                  ?.publicExports
                  .contains(_sectionMethods[key]) ??
              false))
        key,
  ];

  final _collections = <CollectionController>[];
  final builtins = <String, MusicApi>{};
  int _homeRequest = 0;

  MusicApi music(String pluginId) =>
      builtins[pluginId] ?? MusicApi(manager, pluginId);

  String? authenticationRoute(String pluginId) => manager
      .find(pluginId)
      ?.installed
      ?.extension
      .manifest
      .flows['authentication']
      ?.route;

  CollectionController collection(
    CollectionKind kind,
    MusicCollection resource,
  ) {
    final id = resource.pluginId;
    for (final item in _collections) {
      if (item.kind == kind &&
          item.api.pluginId == id &&
          const DeepCollectionEquality().equals(
            item.resource.id,
            resource.id,
          )) {
        return item;
      }
    }
    final item = own(
      CollectionController(music(id), kind, resource, (error, stack) {
        if (!isDisposed) addLog(id, 'error', '集合加载失败：$error\n$stack');
      }),
    );
    _collections.add(item);
    return item;
  }

  Future<void> loadSection(String section) {
    if (section == 'songs'
        ? _homeHasSongs
        : sections.value.containsKey(section)) {
      return Future.value();
    }
    final key = '$_homeRequest:$section';
    return _sectionRequests[key] ??= _loadSection(section, _homeRequest)
        .whenComplete(() {
          _sectionRequests.remove(key);
        });
  }

  Future<void> _loadSection(String section, int request) async {
    final id = selectedId.value;
    final api = music(id);
    sectionLoading.value = {...sectionLoading.value, section};
    sectionErrors.value = {...sectionErrors.value}..remove(section);
    try {
      if (section == 'songs') {
        final result = await api.songRec();
        if (isDisposed || request != _homeRequest) return;
        _homeHasSongs = true;
        home.data(result);
        return;
      }
      final result = await switch (section) {
        'playlists' => api.playListRec(),
        'albums' => api.albumRec(),
        'mvs' => api.mvRec(),
        'ranks' => api.rankList(),
        _ => throw ArgumentError.value(section),
      };
      if (request != _homeRequest || isDisposed) return;
      sections.value = {...sections.value, section: result};
    } catch (error, stack) {
      addLog(id, 'error', '加载失败：$error\n$stack');
      if (!isDisposed && request == _homeRequest) {
        sectionErrors.value = {...sectionErrors.value, section: '$error'};
      }
    } finally {
      if (!isDisposed && request == _homeRequest) {
        sectionLoading.value = {...sectionLoading.value}..remove(section);
      }
    }
  }

  Future<void> _restore() async {
    await manager.restore();
    refresh();
  }

  Future<void> _restoreHome() async {
    await restored;
    if (isDisposed || selectedId.value.isNotEmpty) return;
    if (preferences != null && homeSources.isNotEmpty) {
      final saved = preferences!.getString('homeSource');
      final id = homeSources.any((entry) => entry.id == saved)
          ? saved!
          : homeSources.first.id;
      await selectSource(id);
    }
  }

  void refresh() => extensions.value = manager.extensions;

  Future<void> loadAccounts() async {
    await restored;
    await Future.wait(extensions.value.map((entry) => loadAccount(entry.id)));
  }

  Future<void> loadAccount(String id) async {
    final entry = manager.find(id);
    final installed = entry?.installed;
    if (entry?.state != JsExtensionManagerState.enabled ||
        !(installed?.extension.service?.publicExports.contains('getAccount') ??
            false)) {
      accounts.value = {...accounts.value}..remove(id);
      return;
    }
    PluginAccount account;
    try {
      account = await music(id).getAccount();
    } catch (error) {
      addLog(id, 'error', '账号信息获取失败');
      account = PluginAccount(status: 'unknown', message: '账号信息获取失败，请重试');
    }
    if (isDisposed ||
        manager.find(id)?.installed != installed ||
        manager.find(id)?.state != JsExtensionManagerState.enabled) {
      return;
    }
    accounts.value = {...accounts.value, id: account};
  }

  Future<void> install(JsExtensionPackage package) async {
    await restored;
    package = package.copyWithUiPlugins([
      ...package.uiPlugins,
      JsUiWebViewPlugin().plugin,
    ]);
    final manifest = JsExtensionManifest.parse(package.manifestSource);
    if (manager.find(manifest.id) == null) {
      await manager.install(package, grantedPermissions: manifest.permissions);
    } else {
      await manager.update(
        manifest.id,
        package,
        grantedPermissions: manifest.permissions,
        allowSameVersion: true,
      );
    }
    refresh();
    await loadAccount(manifest.id);
  }

  Future<void> setEnabled(String id, bool enabled) async {
    await restored;
    if (enabled) {
      await manager.enable(id);
    } else {
      await manager.disable(id);
    }
    if (!enabled && selectedId.value == id) {
      _homeRequest++;
      selectedId.value = '';
      _homeHasSongs = false;
      sectionErrors.value = {};
      sectionLoading.value = {};
      home.data([]);
      sections.value = {};
    }
    refresh();
    await loadAccount(id);
  }

  Future<void> uninstall(String id, {bool clearStorage = false}) async {
    await restored;
    await manager.uninstall(id, clearStorage: clearStorage);
    accounts.value = {...accounts.value}..remove(id);
    if (selectedId.value == id) {
      _homeRequest++;
      selectedId.value = '';
      _homeHasSongs = false;
      sectionErrors.value = {};
      sectionLoading.value = {};
      home.data([]);
      sections.value = {};
    }
    refresh();
  }

  Future<void> manage(String id, Future<String> Function() task) async {
    await action.guard(task);
    if (action.hasError) {
      addLog(id, 'error', '${action.errorValue}\n${action.stackTrace}');
    } else {
      addLog(id, 'log', action.value!);
    }
  }

  Future<void> selectSource(String pluginId) async {
    await restored;
    if (isDisposed) return;
    await _load(pluginId, (request) => _selectSource(pluginId, request));
  }

  Future<List<Song>> _selectSource(String pluginId, int request) async {
    if (!homeSources.any((entry) => entry.id == pluginId)) {
      throw StateError('首页音源不可用');
    }
    selectedId.value = pluginId;
    sections.value = {};
    sectionLoading.value = {};
    sectionErrors.value = {};
    _homeHasSongs = false;
    await preferences?.setString('homeSource', pluginId);
    if (isDisposed || request != _homeRequest) return [];
    final exports = manager
        .find(pluginId)!
        .installed!
        .extension
        .service!
        .publicExports;
    final keys = [
      'songs',
      'playlists',
      'albums',
      'mvs',
    ].where((key) => exports.contains(_sectionMethods[key])).toList();
    if (keys.isEmpty) return _getHome(pluginId, request);
    home.data([]);
    await Future.wait(keys.map(loadSection));
    return home.value ?? [];
  }

  Future<void> loadExternal(String manifestPath) => _load('external', (
    request,
  ) async {
    await restored;
    final package = await JsExtensionPackage.file(manifestPath: manifestPath);
    final manifest = JsExtensionManifest.parse(package.manifestSource);
    final pluginId = manifest.id;
    final installed = manager.find(pluginId);
    if (installed == null) {
      await manager.install(package, grantedPermissions: manifest.permissions);
    } else if (installed.record.versionCode <
        JsExtensionManifest.parse(package.manifestSource).versionCode) {
      await manager.update(pluginId, package);
    }
    if (isDisposed || request != _homeRequest) return [];
    refresh();
    return _selectSource(pluginId, request);
  });

  Future<List<Song>> _getHome(String pluginId, int request) async {
    final result = await manager.call(pluginId, 'getHome') as Map;
    if (!isDisposed &&
        request == _homeRequest &&
        selectedId.value == pluginId) {
      sections.value = {
        for (final key in ['playlists', 'albums', 'artists', 'mvs', 'ranks'])
          if (result[key] is List)
            key: [
              for (final item in result[key] as List)
                switch (key) {
                  'playlists' => PlayList.fromJson({
                    ...item as Map,
                    'pluginId': pluginId,
                  }),
                  'albums' => Album.fromJson({
                    ...item as Map,
                    'pluginId': pluginId,
                  }),
                  'artists' => Artist.fromJson({
                    ...item as Map,
                    'pluginId': pluginId,
                  }),
                  'ranks' => Rank.fromJson({
                    ...item as Map,
                    'pluginId': pluginId,
                  }),
                  _ => Mv.fromJson({...item as Map, 'pluginId': pluginId}),
                },
            ],
      };
      _homeHasSongs = result['songs'] is List;
    }
    final songs = (result['songs'] as List? ?? [])
        .map((item) => Song.fromJson({...item as Map, 'pluginId': pluginId}))
        .toList();
    return songs;
  }

  @override
  Future<void> onDispose() => manager.dispose();

  void addLog(String pluginId, String level, String message, {DateTime? time}) {
    if (isDisposed) return;
    final entries = [
      ...logs.value,
      PluginLog(
        pluginId: pluginId,
        level: level,
        message: message,
        time: time ?? DateTime.now(),
      ),
    ];
    logs.value = entries.length > 500
        ? entries.sublist(entries.length - 500)
        : entries;
  }

  Future<void> _load(
    String pluginId,
    Future<List<Song>> Function(int) task,
  ) async {
    final request = ++_homeRequest;
    addLog(pluginId, 'log', '开始加载');
    home.loading();
    try {
      final songs = await task(request);
      if (isDisposed || request != _homeRequest) return;
      home.data(songs);
      if (isDisposed || request != _homeRequest) return;
      addLog(pluginId, 'log', '加载成功：${songs.length} 首歌曲');
    } catch (error, stack) {
      if (isDisposed || request != _homeRequest) return;
      home.error(error, stack);
      addLog(pluginId, 'error', '$error\n$stack');
    }
  }
}
