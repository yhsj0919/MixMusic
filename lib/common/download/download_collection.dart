import 'package:lemon_x/lemon_x.dart';

import '../entity/music_download.dart';
import '../entity/song.dart';
import '../player/music_cache.dart';
import '../plugin/collection_controller.dart';
import '../queue/hyper_queue_source.dart';

class DownloadCollection extends LxController implements LxDisposable {
  DownloadCollection(
    this.collection,
    this.quality, {
    this.directory = '',
    this.grouping = DownloadGrouping.none,
    this.allowMatch = false,
  }) {
    collection.songs.addListener(_sync);
    _sync();
  }
  final CollectionController collection;
  final int? quality;
  final String directory;
  final DownloadGrouping grouping;
  final bool allowMatch;
  late final String? folder = switch (collection.kind) {
    CollectionKind.playlist ||
    CollectionKind.album => collection.resource.title,
    _ => null,
  };
  late final cancelled = own(false.obs);
  late final items = own(Rx<List<MusicDownload>>([]));
  late final source = HyperQueueSource<MusicDownload>(
    key: this,
    title: collection.resource.title,
    items: items,
    hasMore: collection.hasMore,
    error: collection.error,
    loadMore: collection.loadMore,
  );
  int _read = 0;

  void _sync() {
    if (isDisposed) return;
    items.value = [
      ...items.value,
      for (final song in collection.songs.value.skip(_read)) _task(song),
    ];
    _read = collection.songs.value.length;
  }

  MusicDownload _task(Song song) {
    final selected = Song.fromJson(song.toJson())
      ..playQuality = quality ?? song.playQuality
      ..url = null;
    return MusicDownload(
        selected,
        MusicCache.keyFor(selected),
        directory: directory,
        folder: grouping.folder(selected, collection: folder),
        allowMatch: allowMatch,
      )
      ..state = cancelled.value
          ? DownloadState.cancelled
          : DownloadState.waiting;
  }

  @override
  Future<void> dispose() => disposeController();
  @override
  void onDispose() => collection.songs.removeListener(_sync);
}
