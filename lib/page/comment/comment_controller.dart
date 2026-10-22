import 'package:lemon_x/lemon_x.dart';
import 'package:collection/collection.dart';

import '../../common/entity/comment.dart';
import '../../common/entity/song.dart';
import '../../common/plugin/plugin_controller.dart';

class CommentController extends LxController {
  CommentController(this.plugins, this.song);
  final PluginController plugins;
  final Song song;
  late final items = own(Rx<List<Comment>>([]));
  late final categories = own(Rx<List<Map<String, dynamic>>>([]));
  late final category = own(Rx<dynamic>(null));
  late final loading = own(false.obs);
  late final hasMore = own(true.obs);
  late final total = own(Rx<int?>(null));
  late final error = own(''.obs);
  int page = 0, _request = 0;
  dynamic cursor;

  bool isSelected(dynamic id) =>
      const DeepCollectionEquality().equals(category.value, id);

  Future<void> selectCategory(dynamic id) async {
    if (isSelected(id)) return;
    category.value = id;
    await refresh();
  }

  Future<void> refresh() async {
    _request++;
    items.value = [];
    total.value = null;
    page = 0;
    cursor = null;
    hasMore.value = true;
    loading.value = false;
    await loadMore();
  }

  Future<void> loadMore() async {
    if (loading.value || !hasMore.value || isDisposed) return;
    final request = _request;
    loading.value = true;
    error.value = '';
    try {
      final result = await plugins
          .music(song.pluginId)
          .songComments(
            song,
            category: category.value,
            page: page,
            cursor: cursor,
          );
      if (isDisposed || request != _request) return;
      items.value = [...items.value, ...result.items];
      categories.value = result.categories;
      category.value = result.category;
      total.value = result.total;
      hasMore.value = result.hasMore;
      cursor = result.cursor;
      page++;
    } catch (e, stack) {
      if (isDisposed || request != _request) return;
      error.value = '$e';
      plugins.addLog(song.pluginId, 'error', '评论加载失败：$e\n$stack');
    } finally {
      if (!isDisposed && request == _request) loading.value = false;
    }
  }
}
