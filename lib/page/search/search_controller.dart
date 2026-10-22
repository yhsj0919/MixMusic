import 'package:lemon_x/lemon_x.dart';

import '../../common/entity/song.dart';
import '../../common/entity/music_resource.dart';
import '../../common/plugin/plugin_controller.dart';

enum SearchCategory {
  song('歌曲', 'searchMusic'),
  album('专辑', 'searchAlbum'),
  artist('歌手', 'searchArtist'),
  playlist('歌单', 'searchPlayList'),
  mv('MV', 'searchMv');

  const SearchCategory(this.title, this.exportName);
  final String title;
  final String exportName;
}

class SearchController extends LxController {
  SearchController(this.plugins);
  final PluginController plugins;
  late final source = own(''.obs);
  late final songs = own(Rx<List<Song>>([]));
  late final items = own(Rx<List<MusicResource>>([]));
  late final category = own(SearchCategory.song.obs);
  late final loading = own(false.obs);
  late final error = own(''.obs);
  late final hasMore = own(false.obs);
  String keyword = '';
  int page = 0;
  int request = 0;
  static const pageSize = 20;

  Future<void> search(
    String text,
    String pluginId, {
    SearchCategory? type,
  }) async {
    request++;
    keyword = text.trim();
    source.value = pluginId;
    if (type != null) category.value = type;
    page = 0;
    songs.value = [];
    items.value = [];
    error.value = '';
    loading.value = false;
    hasMore.value = keyword.isNotEmpty && pluginId.isNotEmpty;
    if (hasMore.value) await loadMore();
  }

  Future<void> loadMore() async {
    if (loading.value || !hasMore.value) return;
    final current = request;
    final pluginId = source.value;
    loading.value = true;
    error.value = '';
    try {
      final api = plugins.music(pluginId);
      final type = category.value;
      final List<dynamic> result = await switch (type) {
        SearchCategory.song => api.searchMusic(keyword, page, pageSize),
        SearchCategory.album => api.searchAlbum(keyword, page, pageSize),
        SearchCategory.artist => api.searchArtist(keyword, page, pageSize),
        SearchCategory.playlist => api.searchPlayList(keyword, page, pageSize),
        SearchCategory.mv => api.searchMv(keyword, page, pageSize),
      };
      if (isDisposed || current != request) return;
      if (type == SearchCategory.song) {
        songs.value = [...songs.value, ...result.cast<Song>()];
      } else {
        items.value = [...items.value, ...result.cast<MusicResource>()];
      }
      hasMore.value = result.length == pageSize;
      page++;
    } catch (exception, stack) {
      plugins.addLog(pluginId, 'error', '搜索失败：$exception\n$stack');
      if (isDisposed || current != request) return;
      error.value = '$exception';
    } finally {
      if (!isDisposed && current == request) loading.value = false;
    }
  }
}
