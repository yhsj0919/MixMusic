import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mix_music/common/api/music_api.dart';
import 'package:mix_music/common/entity/song.dart';
import 'package:mix_music/common/entity/music_collection.dart';
import 'package:mix_music/common/download/download_collection.dart';
import 'package:mix_music/common/entity/album.dart';
import 'package:mix_music/common/entity/artist.dart';
import 'package:mix_music/common/entity/play_list.dart';
import 'package:mix_music/common/player/player_controller.dart';
import 'package:mix_music/common/plugin/collection_controller.dart';
import 'package:mix_music/common/plugin/plugin_controller.dart';

class CollectionPlugins extends PluginController {
  late final api = CollectionApi(this);
  @override
  MusicApi music(String pluginId) => api;
}

class CollectionApi extends MusicApi {
  CollectionApi(PluginController plugins)
    : super(plugins.manager, 'test.collection');
  final calls = <(String, int)>[];
  Completer<void>? gate;
  bool fail = false;
  int count = 45;
  bool metadata = true;
  List<Map<String, dynamic>> rows(int page, int size) => [
    for (var i = page * size; i < min(count, (page + 1) * size); i++)
      {
        'id': i == 0 ? {'track': 0} : i,
        'title': 'song-$i',
        'favorited': true,
      },
  ];

  Future<Map<String, dynamic>> detail(
    String kind,
    MusicCollection item,
    int page,
    int size,
  ) async {
    calls.add((kind, page));
    await gate?.future;
    if (fail) throw StateError('测试分页错误');
    return {
      ...item.toJson(),
      'songs': rows(page, size),
      if (metadata) ...{'total': count, 'hasMore': (page + 1) * size < count},
    };
  }

  @override
  Future<MusicCollection> recommendInfo([int page = 0, int size = 20]) async =>
      MusicCollection.fromJson(
        await detail(
          'recommend',
          MusicCollection(pluginId: pluginId, id: 'daily', title: '每日推荐'),
          page,
          size,
        ),
      );

  @override
  Future<PlayList> playListInfo(
    PlayList item, [
    int page = 0,
    int size = 20,
  ]) async => PlayList.fromJson(await detail('playlist', item, page, size));
  @override
  Future<Album> albumInfo(Album item, [int page = 0, int size = 20]) async =>
      Album.fromJson(await detail('album', item, page, size));
  @override
  Future<Artist> artistInfo(Artist item, [int page = 0, int size = 20]) async {
    calls.add(('artistInfo', page));
    return Artist.fromJson({...item.toJson(), 'description': '测试简介'});
  }

  @override
  Future<List<Album>> artistAlbum(
    Artist item, [
    int page = 0,
    int size = 20,
  ]) async {
    final result = await detail('artistAlbum', item, page, size);
    return [
      for (final row in result['songs'] as List)
        Album.fromJson({...row as Map, 'pluginId': pluginId}),
    ];
  }

  @override
  Future<List<Song>> artistSong(
    Artist item, [
    int page = 0,
    int size = 20,
  ]) async {
    calls.add(('artistSong', page));
    return rows(
      page,
      size,
    ).map((row) => Song.fromJson({...row, 'pluginId': pluginId})).toList();
  }
}

class CollectionPlayer extends PlayerController {
  CollectionPlayer(super.plugins);
  final played = <Song>[];
  @override
  Future<void> loadSong(Song selected) async {
    song.value = selected;
    playing.value = true;
    status.value = '';
    played.add(selected);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CollectionPlugins plugins;
  late CollectionPlayer player;
  late CollectionController collection;
  final resource = <String, dynamic>{
    'pluginId': 'test.collection',
    'id': {'list': 1},
    'title': '测试集合',
  };
  setUp(() {
    plugins = CollectionPlugins();
    player = CollectionPlayer(plugins);
    collection = plugins.collection(
      CollectionKind.playlist,
      PlayList.fromJson(resource),
    );
  });
  tearDown(() async {
    await player.disposeController();
    await plugins.disposeController();
  });

  test(
    'view, playback and download use one loader and query only each new page',
    () async {
      plugins.api.count = 65;
      await collection.loadMore();
      final downloads = DownloadCollection(collection, null);
      addTearDown(downloads.disposeController);
      await downloads.source.loadMore();
      expect(collection.songs.value.length, 40);
      await player.addCollection(collection, play: true);
      await player.loadMoreQueue(viewing: true);
      expect(collection.songs.value.length, 60);
      expect(
        collection.songs.value.every((song) => song.favorited == true),
        isTrue,
      );
    },
  );

  test('artist albums load only on demand, merge requests and keep song pages independent', () async {
    plugins.api.count = 25;
    final artist = plugins.collection(
      CollectionKind.artist,
      Artist.fromJson(resource),
    );
    await player.addCollection(artist, play: true);
    expect(
      plugins.api.calls.where((call) => call.$1 == 'artistAlbum'),
      isEmpty,
    );
    expect(artist.albums.value, isEmpty);
    plugins.api.gate = Completer<void>();
    final first = artist.loadMoreAlbums();
    expect(artist.loadMoreAlbums(), same(first));
    expect(artist.albumsLoading.value, isTrue);
    plugins.api.gate!.complete();
    await first;
    expect(artist.albums.value.length, 20);
    expect(artist.albums.value.first.id, {'track': 0});
    expect(artist.songs.value.length, 20);
    expect(player.queue.value.length, 20);
    plugins.api.gate = null;
    await artist.loadMoreAlbums();
    expect(artist.albums.value.length, 25);
    expect(artist.albumPage, 2);
    expect(artist.albumsHasMore.value, isFalse);
    await artist.loadMoreAlbums();
    expect(
      plugins.api.calls.where((call) => call.$1 == 'artistAlbum').length,
      2,
    );
    expect(
      plugins.collection(CollectionKind.artist, Artist.fromJson(resource)),
      same(artist),
    );
  });

  test('artist album failures retry the same page and ignore late results after disposal', () async {
    final artist = plugins.collection(
      CollectionKind.artist,
      Artist.fromJson(resource),
    );
    plugins.api.fail = true;
    await artist.loadMoreAlbums();
    expect(artist.albumsError.value, contains('测试分页错误'));
    expect(artist.albumPage, 0);
    expect(artist.error.value, isEmpty);
    plugins.api.fail = false;
    await artist.loadMoreAlbums();
    expect(artist.albumsError.value, isEmpty);
    expect(artist.albums.value.length, 20);
    expect(plugins.api.calls, [('artistAlbum', 0), ('artistAlbum', 0)]);
    plugins.api.gate = Completer<void>();
    final pending = artist.loadMoreAlbums();
    await artist.disposeController();
    plugins.api.gate!.complete();
    await pending;
  });

  test(
    'daily recommendation uses the shared lazy playback and download source',
    () async {
      final daily = plugins.collection(
        CollectionKind.recommend,
        MusicCollection(
          pluginId: 'test.collection',
          id: 'daily',
          title: '每日推荐',
        ),
      );
      final downloads = DownloadCollection(daily, 128);
      addTearDown(downloads.disposeController);
      await player.addCollection(daily, play: true);
      expect(player.queue.value.length, 20);
      expect(downloads.items.value.length, 20);
      expect(plugins.api.calls, [('recommend', 0)]);
      await daily.loadMore();
      expect(player.queue.value.length, 40);
      expect(downloads.items.value.length, 40);
      await daily.loadMore();
      expect(player.queue.value.length, 45);
      expect(downloads.items.value.length, 45);
      expect(daily.hasMore.value, isFalse);
    },
  );

  test('details share opaque identity and load only requested pages', () async {
    expect(
      plugins.collection(
        CollectionKind.playlist,
        PlayList.fromJson({...resource}),
      ),
      same(collection),
    );
    await collection.loadMore();
    expect(collection.songs.value.length, 20);
    expect(collection.songs.value.first.id, {'track': 0});
    expect(collection.songs.value.first.pluginId, 'test.collection');
    expect(collection.info.value.id, {'list': 1});
    expect(plugins.api.calls, [('playlist', 0)]);
    await collection.loadMore();
    await collection.loadMore();
    expect(collection.songs.value.length, 45);
    expect(collection.hasMore.value, isFalse);
    await collection.loadMore();
    expect(plugins.api.calls.length, 3);
  });

  test(
    'disposing the plugin owner disposes collections with pending pages',
    () async {
      plugins.api.gate = Completer<void>();
      final pending = collection.loadMore();
      await player.disposeController();
      await plugins.disposeController();
      expect(collection.isDisposed, isTrue);
      plugins.api.gate!.complete();
      await pending;
    },
  );

  test(
    'album and artist use their own interfaces; missing totals use page length',
    () async {
      plugins.api.count = 23;
      plugins.api.metadata = false;
      final album = plugins.collection(
        CollectionKind.album,
        Album.fromJson(resource),
      );
      await album.loadMore();
      await album.loadMore();
      expect(album.songs.value.length, 23);
      expect(album.hasMore.value, isFalse);
      final artist = plugins.collection(
        CollectionKind.artist,
        Artist.fromJson(resource),
      );
      await artist.loadMore();
      await artist.loadMore();
      expect(artist.songs.value.length, 23);
      expect(artist.info.value.description, '测试简介');
      expect(
        plugins.api.calls.where((call) => call.$1 == 'artistInfo').length,
        1,
      );
    },
  );

  test(
    'viewing and playback share one pending page; adding does not fetch all',
    () async {
      await player.addCollection(collection, play: true);
      expect(player.queue.value.length, 20);
      expect(plugins.api.calls.length, 1);
      player.addSong(Song(pluginId: 'manual', id: 'last', title: '手动加入'));
      await player.playAt(16);
      expect(plugins.api.calls.length, 1);
      plugins.api.gate = Completer<void>();
      await player.playAt(17);
      final viewing = collection.loadMore();
      final playback = player.loadMoreQueue();
      expect(plugins.api.calls, [('playlist', 0), ('playlist', 1)]);
      plugins.api.gate!.complete();
      await Future.wait([viewing, playback]);
      expect(player.queue.value.length, 41);
      expect(player.currentIndex.value, 17);
      expect(player.queue.value.last.pluginId, 'manual');
      expect(player.queue.value[20].id, 20);
      await player.removeSong(3);
      plugins.api.gate = null;
      await collection.loadMore();
      await Future<void>.delayed(Duration.zero);
      expect(player.queue.value.length, 45);
      expect(player.queue.value.any((item) => item.id == 3), isFalse);
      expect(player.queue.value.last.pluginId, 'manual');
    },
  );

  test('failed pages do not advance or repeatedly auto retry', () async {
    await player.addCollection(collection, play: true);
    plugins.api.fail = true;
    await player.playAt(19);
    await Future<void>.delayed(Duration.zero);
    expect(collection.page, 1);
    expect(collection.error.value, contains('测试分页错误'));
    expect(player.queue.value.length, 20);
    final calls = plugins.api.calls.length;
    await player.loadMoreQueue();
    await player.next(completed: true);
    expect(plugins.api.calls.length, calls);
    expect(player.currentIndex.value, 19);
    plugins.api.fail = false;
    await player.loadMoreQueue(retry: true);
    expect(player.queue.value.length, 40);
    await player.next();
    expect(player.currentIndex.value, 20);
  });

  test(
    'clearing detaches queued collection even when a page is pending',
    () async {
      await collection.loadMore();
      await player.addCollection(collection);
      plugins.api.gate = Completer<void>();
      final pending = player.loadMoreQueue(viewing: true);
      await player.clearQueue();
      plugins.api.gate!.complete();
      await pending;
      expect(collection.songs.value.length, 40);
      expect(player.queue.value, isEmpty);
      expect(player.song.value, isNull);
    },
  );

  test('clearing during initial load cancels adding the collection', () async {
    plugins.api.gate = Completer<void>();
    final pending = player.addCollection(collection, play: true);
    await player.clearQueue();
    plugins.api.gate!.complete();
    await pending;
    expect(player.queue.value, isEmpty);
    expect(player.played, isEmpty);
  });

  test(
    'next-play priority survives a page appended at the collection boundary',
    () async {
      await player.addCollection(collection, play: true);
      plugins.api.gate = Completer<void>();
      await player.playAt(19);
      player.addSong(
        Song(pluginId: 'manual', id: 'next', title: '下一首'),
        next: true,
      );
      final pending = player.next(completed: true);
      expect(player.song.value!.id, 19);
      plugins.api.gate!.complete();
      await pending;
      expect(player.song.value!.id, 'next');
      expect(player.queue.value[21].id, 20);
      await player.next();
      expect(player.song.value!.id, 20);
    },
  );

  test(
    'disabled source cannot refill queue when pending collection finishes',
    () async {
      await player.addCollection(collection, play: true);
      plugins.api.gate = Completer<void>();
      final pending = player.loadMoreQueue(viewing: true);
      await player.stopSource('test.collection');
      plugins.api.gate!.complete();
      await pending;
      expect(player.queue.value, isEmpty);
      expect(player.song.value, isNull);
    },
  );
}
