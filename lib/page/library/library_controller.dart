import 'package:lemon_js_extensions/lemon_js_extensions.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../common/entity/music_collection.dart';
import '../../common/entity/album.dart';
import '../../common/entity/artist.dart';
import '../../common/entity/mv.dart';
import '../../common/entity/music_resource.dart';
import '../../common/entity/play_list.dart';
import '../../common/plugin/collection_controller.dart';
import '../../common/plugin/plugin_controller.dart';

enum LibrarySection {
  liked('喜欢的歌曲', 'mySongs', ''),
  created('创建的歌单', 'myPlayLists', '/playlist'),
  playlists('收藏歌单', 'myPlayLists', '/playlist'),
  albums('收藏专辑', 'myAlbums', '/album'),
  artists('收藏歌手', 'myArtists', '/artist'),
  videos('收藏视频', 'myMvs', '/mv');

  const LibrarySection(this.title, this.method, this.route);
  final String title, method, route;
}

class LibraryState {
  List<MusicResource> items = [];
  bool loading = false, hasMore = true, initialized = false;
  String error = '';
  int page = 0, request = 0;
}

class LibraryController extends LxController {
  LibraryController(this.plugins);
  final PluginController plugins;
  late final source = own(''.obs);
  late final section = own(Rx(LibrarySection.liked));
  late final state = own(Rx(LibraryState()));
  late final liked = own(Rx<CollectionController?>(null));
  final _states = <(String, LibrarySection), LibraryState>{};
  final pageSize = 20;

  List<JsExtensionManagerEntry> get sources => plugins.extensions.value
      .where(
        (entry) =>
            entry.state == JsExtensionManagerState.enabled &&
            LibrarySection.values.any(
              (section) =>
                  entry.installed?.extension.service?.publicExports.contains(
                    section.method,
                  ) ??
                  false,
            ),
      )
      .toList();

  bool supports(String method) =>
      plugins.manager
          .find(source.value)
          ?.installed
          ?.extension
          .service
          ?.publicExports
          .contains(method) ??
      false;
  List<LibrarySection> get sections =>
      LibrarySection.values.where((x) => supports(x.method)).toList();

  Future<void> initializeSource() async {
    await plugins.restored;
    if (isDisposed || sources.isEmpty) return;
    final selected = plugins.selectedId.value;
    await selectSource(
      sources.any((x) => x.id == selected) ? selected : sources.first.id,
    );
  }

  Future<void> selectSource(String id) async {
    source.value = id;
    await plugins.loadAccount(id);
    if (isDisposed || source.value != id) return;
    await selectSection(
      sections.contains(section.value) ? section.value : sections.first,
    );
  }

  Future<void> selectSection(LibrarySection value) async {
    section.value = value;
    if (value == LibrarySection.liked) {
      final current = plugins.collection(
        CollectionKind.liked,
        MusicCollection(
          pluginId: source.value,
          id: 'liked',
          title: value.title,
        ),
      );
      liked.value = current;
      if (current.page == 0) await current.loadMore();
      return;
    }
    state.value = _states.putIfAbsent((source.value, value), LibraryState.new);
    if (!state.value.initialized) {
      state.value.initialized = true;
      await loadMore();
    }
  }

  void update(LibraryState value) {
    if (!isDisposed && identical(value, state.value)) state.refresh();
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current.loading || !current.hasMore) return;
    current.loading = true;
    current.error = '';
    final id = source.value, request = current.request;
    final selected = section.value;
    update(current);
    try {
      final api = plugins.music(id);
      final ({List<MusicResource> items, bool hasMore}) page =
          await switch (selected) {
            LibrarySection.created => api.myPlayLists(
              true,
              current.page,
              pageSize,
            ),
            LibrarySection.playlists => api.myPlayLists(
              false,
              current.page,
              pageSize,
            ),
            LibrarySection.albums => api.myAlbums(current.page, pageSize),
            LibrarySection.videos => api.myMvs(current.page, pageSize),
            LibrarySection.artists => api.myArtists(current.page, pageSize),
            LibrarySection.liked => throw StateError('喜欢歌曲由集合加载'),
          };
      if (isDisposed || request != current.request) return;
      current.items = [...current.items, ...page.items];
      current.hasMore = page.hasMore;
      current.page++;
    } catch (error, stack) {
      if (request == current.request) current.error = '$error';
      plugins.addLog(id, 'error', '我的列表加载失败：$error\n$stack');
    } finally {
      if (request == current.request) current.loading = false;
      update(current);
    }
  }

  Future<void> refresh() async {
    if (section.value == LibrarySection.liked) {
      await liked.value?.refresh();
      return;
    }
    final current = state.value;
    current.request++;
    current.page = 0;
    current.items = [];
    current.loading = false;
    current.hasMore = true;
    await loadMore();
  }

  Future<void> createPlayList(String name) async {
    final id = source.value, selected = section.value;
    await plugins.music(id).createPlayList(name);
    _invalidate(id, LibrarySection.created);
    if (!isDisposed && source.value == id && section.value == selected) {
      await selectSection(LibrarySection.created);
    }
  }

  Future<void> deletePlayList(PlayList playlist) async {
    await plugins.music(playlist.pluginId).deletePlayList(playlist);
    _invalidate(playlist.pluginId, LibrarySection.created);
    if (!isDisposed &&
        source.value == playlist.pluginId &&
        section.value == LibrarySection.created) {
      await selectSection(LibrarySection.created);
    }
  }

  Future<void> favorite(MusicResource item, bool value) async {
    final api = plugins.music(item.pluginId);
    final (target, action) = switch (item) {
      PlayList() => (
        LibrarySection.playlists,
        api.favoritePlayList(item, value),
      ),
      Album() => (LibrarySection.albums, api.favoriteAlbum(item, value)),
      Artist() => (LibrarySection.artists, api.favoriteArtist(item, value)),
      Mv() => (LibrarySection.videos, api.favoriteMv(item, value)),
      _ => throw StateError('该资源暂不支持收藏操作'),
    };
    await action;
    _invalidate(item.pluginId, target);
    if (!isDisposed &&
        source.value == item.pluginId &&
        section.value == target) {
      await selectSection(target);
    }
  }

  void _invalidate(String id, LibrarySection selected) {
    final old = _states.remove((id, selected));
    if (old != null) old.request++;
  }
}
