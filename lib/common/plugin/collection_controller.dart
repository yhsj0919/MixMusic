import 'package:lemon_x/lemon_x.dart';

import '../api/music_api.dart';
import '../entity/song.dart';
import '../entity/music_collection.dart';
import '../entity/album.dart';
import '../entity/artist.dart';
import '../entity/play_list.dart';
import '../entity/rank.dart';

enum CollectionKind { playlist, album, artist, rank, recommend, liked }

class CollectionController extends LxController implements LxDisposable {
  CollectionController(this.api, this.kind, this.resource, this.onError);
  final MusicApi api;
  final CollectionKind kind;
  final MusicCollection resource;
  final void Function(Object, StackTrace) onError;
  late final info = own(Rx<MusicCollection>(resource));
  late final songs = own(Rx<List<Song>>([]));
  late final hasMore = own(true.obs);
  late final loading = own(false.obs);
  late final error = own(''.obs);
  int page = 0;
  static const pageSize = 20;
  Future<void>? _pending;
  late final albums = own(Rx<List<Album>>([]));
  late final albumsLoading = own(false.obs);
  late final albumsError = own(''.obs);
  late final albumsHasMore = own(true.obs);
  int albumPage = 0;
  Future<void>? _albumsPending;

  @override
  Future<void> dispose() => disposeController();

  bool get supportsFavorite {
    final method = switch (kind) {
      CollectionKind.playlist => 'favoritePlayList',
      CollectionKind.album => 'favoriteAlbum',
      CollectionKind.artist => 'favoriteArtist',
      _ => '',
    };
    return method.isNotEmpty &&
        (api.manager
                .find(resource.pluginId)
                ?.installed
                ?.extension
                .service
                ?.publicExports
                .contains(method) ??
            false);
  }

  Future<void> favorite(bool value) async {
    switch (kind) {
      case CollectionKind.playlist:
        await api.favoritePlayList(resource as PlayList, value);
      case CollectionKind.album:
        await api.favoriteAlbum(resource as Album, value);
      case CollectionKind.artist:
        await api.favoriteArtist(resource as Artist, value);
      default:
        throw StateError('该集合暂不支持收藏操作');
    }
    resource.favorited = value;
    if (isDisposed) return;
    info.value.favorited = value;
    info.refresh();
  }

  bool get canRemoveSongs =>
      kind == CollectionKind.playlist &&
      resource.details['editable'] == true &&
      (api.manager
              .find(resource.pluginId)
              ?.installed
              ?.extension
              .service
              ?.publicExports
              .contains('removeFromPlayList') ??
          false);

  Future<void> removeSong(Song song) async {
    await api.removeFromPlayList(resource as PlayList, [song]);
    await refresh();
  }

  Future<void> loadMoreAlbums() {
    if (!albumsHasMore.value) return Future.value();
    return _albumsPending ??= _loadAlbums().whenComplete(
      () => _albumsPending = null,
    );
  }

  Future<void> _loadAlbums() async {
    albumsLoading.value = true;
    albumsError.value = '';
    try {
      final result = await api.artistAlbum(
        resource as Artist,
        albumPage,
        pageSize,
      );
      if (isDisposed) return;
      albums.value = [...albums.value, ...result];
      albumsHasMore.value = result.length == pageSize;
      albumPage++;
    } catch (exception, stack) {
      if (!isDisposed) {
        albumsError.value = '$exception';
        onError(exception, stack);
      }
    } finally {
      if (!isDisposed) albumsLoading.value = false;
    }
  }

  Future<void> loadMore() {
    if (!hasMore.value) return Future.value();
    return _pending ??= _load().whenComplete(() => _pending = null);
  }

  Future<void> refresh() async {
    await _pending;
    if (isDisposed) return;
    page = 0;
    songs.value = [];
    hasMore.value = true;
    await loadMore();
  }

  Future<void> _load() async {
    loading.value = true;
    error.value = '';
    try {
      MusicCollection detail;
      List<Song> result;
      if (kind == CollectionKind.artist) {
        detail = page == 0
            ? await api.artistInfo(resource as Artist)
            : info.value;
        result = await api.artistSong(resource as Artist, page, pageSize);
      } else {
        detail = await switch (kind) {
          CollectionKind.playlist => api.playListInfo(
            resource as PlayList,
            page,
            pageSize,
          ),
          CollectionKind.album => api.albumInfo(
            resource as Album,
            page,
            pageSize,
          ),
          CollectionKind.rank => api.rankInfo(resource as Rank, page, pageSize),
          CollectionKind.recommend => api.recommendInfo(page, pageSize),
          CollectionKind.liked => api.mySongs(page, pageSize),
          CollectionKind.artist => throw StateError('歌手歌曲由独立接口获取'),
        };
        result = detail.songs;
      }
      if (isDisposed) return;
      info.value = detail;
      final total = detail.total;
      hasMore.value =
          result.isNotEmpty &&
          (kind == CollectionKind.artist
              ? result.length == pageSize
              : detail.hasMore ??
                    (total != null
                        ? songs.value.length + result.length < total
                        : result.length == pageSize));
      page++;
      songs.value = [...songs.value, ...result];
    } catch (exception, stack) {
      if (!isDisposed) {
        error.value = '$exception';
        onError(exception, stack);
      }
    } finally {
      if (!isDisposed) loading.value = false;
    }
  }
}
