import 'package:lemon_js_extensions/lemon_js_extensions.dart';
import 'package:lemon_x/lemon_x.dart';
import 'package:collection/collection.dart';

import '../../common/entity/music_resource.dart';
import '../../common/plugin/plugin_controller.dart';

enum MusicListKind {
  playlist('歌单', 'playList', 'playListType', '/playlist'),
  album('专辑', 'albumList', 'albumType', '/album'),
  artist('歌手', 'artistList', 'artistType', '/artist'),
  mv('MV', 'mvList', 'mvType', '/mv');

  const MusicListKind(this.title, this.method, this.typeMethod, this.route);
  final String title, method, typeMethod, route;
}

class MusicListState {
  List<MusicResource> items = [];
  List<Map<String, dynamic>> categories = [];
  Map<String, dynamic>? category;
  bool initialized = false, loading = false, hasMore = true;
  String error = '', categoryError = '';
  int page = 0, request = 0;
}

class MusicListController extends LxController {
  MusicListController(this.plugins, this.kind);
  final PluginController plugins;
  final MusicListKind kind;
  late final source = own(''.obs);
  late final state = own(Rx(MusicListState()));
  final _states = <String, MusicListState>{};
  static const pageSize = 20;

  String get categoryTitle {
    final selected = state.value;
    final filters = selected.category?['filters'] as List?;
    if (filters == null) {
      return selected.category?['title']?.toString() ?? '默认分类';
    }
    final titles = [
      for (final filter in filters) filter['value']['title'].toString(),
    ];
    return titles.isEmpty ? '默认分类' : titles.join(' · ');
  }

  List<JsExtensionManagerEntry> get sources => plugins.extensions.value
      .where(
        (entry) =>
            entry.state == JsExtensionManagerState.enabled &&
            (entry.installed?.extension.service?.publicExports.contains(
                  kind.method,
                ) ??
                false),
      )
      .toList();

  Future<void> initializeSource() async {
    await plugins.restored;
    if (isDisposed || sources.isEmpty) return;
    final selected = plugins.selectedId.value;
    await selectSource(
      sources.any((entry) => entry.id == selected)
          ? selected
          : sources.first.id,
    );
  }

  Future<void> selectSource(String id) async {
    source.value = id;
    final selected = _states.putIfAbsent(id, MusicListState.new);
    state.value = selected;
    if (selected.initialized) return;
    selected.initialized = true;
    await Future.wait([loadMore(), loadCategories()]);
  }

  void _update(MusicListState selected) {
    if (!isDisposed && identical(selected, state.value)) state.refresh();
  }

  Future<void> loadCategories() async {
    final id = source.value;
    final selected = state.value;
    if (!(plugins.manager
            .find(id)
            ?.installed
            ?.extension
            .service
            ?.publicExports
            .contains(kind.typeMethod) ??
        false)) {
      return;
    }
    selected.categoryError = '';
    try {
      final api = plugins.music(id);
      selected.categories = await switch (kind) {
        MusicListKind.playlist => api.playListType(),
        MusicListKind.album => api.albumType(),
        MusicListKind.artist => api.artistType(),
        MusicListKind.mv => api.mvType(),
      };
    } catch (error, stack) {
      selected.categoryError = '$error';
      plugins.addLog(id, 'error', '分类加载失败：$error\n$stack');
    }
    _update(selected);
  }

  Future<void> selectCategory(
    Map<String, dynamic>? category, {
    dynamic group,
  }) async {
    if (category != null && group != null) {
      final filters = state.value.category?['filters'] as List? ?? [];
      final updated = [...filters];
      final index = updated.indexWhere(
        (filter) =>
            const DeepCollectionEquality().equals(filter['group'], group),
      );
      final selection = {'group': group, 'value': category};
      if (index < 0) {
        updated.add(selection);
      } else {
        updated[index] = selection;
      }
      state.value.category = {'filters': updated};
    } else {
      state.value.category = category;
    }
    await refreshList();
  }

  Future<void> refreshList() async {
    final selected = state.value;
    selected.request++;
    selected.items = [];
    selected.page = 0;
    selected.hasMore = true;
    selected.loading = false;
    await loadMore();
  }

  Future<void> loadMore() async {
    final selected = state.value;
    if (selected.loading || !selected.hasMore || isDisposed) return;
    final id = source.value;
    final request = selected.request;
    final api = plugins.music(id);
    selected.loading = true;
    selected.error = '';
    _update(selected);
    try {
      final result = await switch (kind) {
        MusicListKind.playlist => api.playList(
          selected.category,
          selected.page,
          pageSize,
        ),
        MusicListKind.album => api.albumList(
          selected.category,
          selected.page,
          pageSize,
        ),
        MusicListKind.artist => api.artistList(
          selected.category,
          selected.page,
          pageSize,
        ),
        MusicListKind.mv => api.mvList(
          selected.category,
          selected.page,
          pageSize,
        ),
      };
      if (isDisposed || request != selected.request) return;
      selected.items = [...selected.items, ...result];
      selected.page++;
      selected.hasMore = result.length >= pageSize;
    } catch (error, stack) {
      if (isDisposed || request != selected.request) return;
      selected.error = '$error';
      plugins.addLog(id, 'error', '${kind.title}列表加载失败：$error\n$stack');
    } finally {
      if (!isDisposed && request == selected.request) {
        selected.loading = false;
        _update(selected);
      }
    }
  }
}
