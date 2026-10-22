import 'package:lemon_js_extensions/lemon_js_extensions.dart';

import '../entity/song.dart';
import '../entity/album.dart';
import '../entity/artist.dart';
import '../entity/play_list.dart';
import '../entity/rank.dart';
import '../entity/mv.dart';
import '../entity/music_collection.dart';
import '../entity/plugin_account.dart';
import '../entity/comment.dart';

class MusicApi {
  final JsExtensionManager manager;
  final String pluginId;
  MusicApi(this.manager, this.pluginId);

  Song updateMetadata(Song song, Map<String, String> tags) => song;

  Future<CommentPage> songComments(
    Song song, {
    dynamic category,
    int page = 0,
    int size = 20,
    dynamic cursor,
  }) async {
    final data = await _call('songComments', [
      song.toJson(),
      {'category': category, 'page': page, 'size': size, 'cursor': cursor},
    ]) as Map;
    return (
      items: (data['items'] as List)
          .map((item) => Comment.fromJson(item as Map))
          .toList(),
      categories: (data['categories'] as List? ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(),
      category: data['category'],
      total: data['total'] as int?,
      hasMore: data['hasMore'] as bool,
      cursor: data['cursor'],
    );
  }

  bool get supportsArtistAlbums =>
      manager
          .find(pluginId)
          ?.installed
          ?.extension
          .service
          ?.publicExports
          .contains('artistAlbum') ??
      false;

  // 本地收藏由宿主管理；不发送给插件，也不接受插件覆盖。资源 ID 保持原样。
  Object? _pluginData(Object? value) => switch (value) {
    List() => value.map(_pluginData).toList(),
    Map() => {
      for (final entry in value.entries)
        if (entry.key != 'locallyFavorited' && entry.key != 'matchedSong')
          entry.key: entry.key == 'id' ? entry.value : _pluginData(entry.value),
    },
    _ => value,
  };

  Future<Object?> _call(String method, List<Object?> args) async => _pluginData(
    await manager.call(
      pluginId,
      method,
      arguments: _pluginData(args) as List<Object?>,
    ),
  );

  Future<List<Song>> searchMusic(
    String keyword, [
    int page = 0,
    int size = 20,
  ]) async {
    final result = await _call('searchMusic', [keyword, page, size]);
    return (result as List)
        .map((item) => Song.fromJson({...item as Map, 'pluginId': pluginId}))
        .toList();
  }

  Future<List<Album>> searchAlbum(
    String keyword, [
    int page = 0,
    int size = 20,
  ]) async {
    final result = await _call('searchAlbum', [keyword, page, size]);
    return (result as List)
        .map((item) => Album.fromJson({...item as Map, 'pluginId': pluginId}))
        .toList();
  }

  Future<List<Artist>> searchArtist(
    String keyword, [
    int page = 0,
    int size = 20,
  ]) async {
    final result = await _call('searchArtist', [keyword, page, size]);
    return (result as List)
        .map((item) => Artist.fromJson({...item as Map, 'pluginId': pluginId}))
        .toList();
  }

  Future<List<PlayList>> searchPlayList(
    String keyword, [
    int page = 0,
    int size = 20,
  ]) async {
    final result = await _call('searchPlayList', [keyword, page, size]);
    return (result as List)
        .map(
          (item) => PlayList.fromJson({...item as Map, 'pluginId': pluginId}),
        )
        .toList();
  }

  Future<List<Mv>> searchMv(
    String keyword, [
    int page = 0,
    int size = 20,
  ]) async {
    final result = await _call('searchMv', [keyword, page, size]);
    return (result as List)
        .map((item) => Mv.fromJson({...item as Map, 'pluginId': pluginId}))
        .toList();
  }

  Future<List<String>> searchSuggest(String keyword) async {
    final result = await _call('searchSuggest', [keyword]);
    return List<String>.from(result as List);
  }

  Future<Song> playUrl(Song song) async {
    final result = await _call('playUrl', [song.toJson()]);
    return Song.fromJson({
      ...song.toJson(),
      ...result as Map,
      'pluginId': pluginId,
    });
  }

  Future<Map<String, dynamic>> lrc(Song song) async {
    final result = await _call('lrc', [song.toJson()]);
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> download(Map<String, dynamic> download) async {
    final result = await _call('download', [download]);
    return Map<String, dynamic>.from(result as Map);
  }

  Future<MusicCollection> recommendInfo([int page = 0, int size = 20]) async {
    final result = await _call('recommendInfo', [page, size]);
    return MusicCollection.fromJson({
      'id': 'daily',
      'title': '每日推荐',
      ...result as Map,
      'pluginId': pluginId,
    });
  }

  Future<List<Map<String, dynamic>>> playListType() async {
    final result = await _call('playListType', []);
    return (result as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<PlayList>> playList(
    Map<String, dynamic>? category, [
    int page = 0,
    int size = 20,
  ]) async {
    final result = await _call('playList', [category, page, size]);
    return (result as List)
        .map(
          (item) => PlayList.fromJson({...item as Map, 'pluginId': pluginId}),
        )
        .toList();
  }

  Future<PlayList> playListInfo(
    PlayList playlist, [
    int page = 0,
    int size = 20,
  ]) async {
    final result = await _call('playListInfo', [playlist.toJson(), page, size]);
    return PlayList.fromJson({
      ...playlist.toJson(),
      ...result as Map,
      'pluginId': pluginId,
    });
  }

  Future<List<Map<String, dynamic>>> albumType() async {
    final result = await _call('albumType', []);
    return (result as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<Album>> albumList(
    Map<String, dynamic>? category, [
    int page = 0,
    int size = 20,
  ]) async {
    final result = await _call('albumList', [category, page, size]);
    return (result as List)
        .map((item) => Album.fromJson({...item as Map, 'pluginId': pluginId}))
        .toList();
  }

  Future<Album> albumInfo(Album album, [int page = 0, int size = 20]) async {
    final result = await _call('albumInfo', [album.toJson(), page, size]);
    return Album.fromJson({
      ...album.toJson(),
      ...result as Map,
      'pluginId': pluginId,
    });
  }

  Future<List<PlayList>> playListRec() async {
    final result = await _call('playListRec', []);
    return (result as List)
        .map(
          (item) => PlayList.fromJson({...item as Map, 'pluginId': pluginId}),
        )
        .toList();
  }

  Future<List<Album>> albumRec() async {
    final result = await _call('albumRec', []);
    return (result as List)
        .map((item) => Album.fromJson({...item as Map, 'pluginId': pluginId}))
        .toList();
  }

  Future<List<Song>> songRec() async {
    final result = await _call('songRec', []);
    return (result as List)
        .map((item) => Song.fromJson({...item as Map, 'pluginId': pluginId}))
        .toList();
  }

  Future<List<Mv>> mvRec() async {
    final result = await _call('mvRec', []);
    return (result as List)
        .map((item) => Mv.fromJson({...item as Map, 'pluginId': pluginId}))
        .toList();
  }

  Future<List<Rank>> rankList() async {
    final result = await _call('rankList', []);
    return (result as List)
        .map((item) => Rank.fromJson({...item as Map, 'pluginId': pluginId}))
        .toList();
  }

  Future<Rank> rankInfo(Rank rank, [int page = 0, int size = 20]) async {
    final result = await _call('rankInfo', [rank.toJson(), page, size]);
    return Rank.fromJson({
      ...rank.toJson(),
      ...result as Map,
      'pluginId': pluginId,
    });
  }

  Future<List<Map<String, dynamic>>> artistType() async {
    final result = await _call('artistType', []);
    return (result as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<Artist>> artistList(
    Map<String, dynamic>? category, [
    int page = 0,
    int size = 20,
  ]) async {
    final result = await _call('artistList', [category, page, size]);
    return (result as List)
        .map((item) => Artist.fromJson({...item as Map, 'pluginId': pluginId}))
        .toList();
  }

  Future<Artist> artistInfo(
    Artist artist, [
    int page = 0,
    int size = 20,
  ]) async {
    final result = await _call('artistInfo', [artist.toJson(), page, size]);
    return Artist.fromJson({
      ...artist.toJson(),
      ...result as Map,
      'pluginId': pluginId,
    });
  }

  Future<List<Song>> artistSong(
    Artist artist, [
    int page = 0,
    int size = 20,
  ]) async {
    final result = await _call('artistSong', [artist.toJson(), page, size]);
    return (result as List)
        .map((item) => Song.fromJson({...item as Map, 'pluginId': pluginId}))
        .toList();
  }

  Future<List<Album>> artistAlbum(
    Artist artist, [
    int page = 0,
    int size = 20,
  ]) async {
    final result = await _call('artistAlbum', [artist.toJson(), page, size]);
    return (result as List)
        .map((item) => Album.fromJson({...item as Map, 'pluginId': pluginId}))
        .toList();
  }

  Future<List<Map<String, dynamic>>> mvType() async {
    final result = await _call('mvType', []);
    return (result as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<Mv>> mvList(
    Map<String, dynamic>? category, [
    int page = 0,
    int size = 20,
  ]) async {
    final result = await _call('mvList', [category, page, size]);
    return (result as List)
        .map((item) => Mv.fromJson({...item as Map, 'pluginId': pluginId}))
        .toList();
  }

  Future<Mv> mvInfo(Mv mv) async {
    final result = await _call('mvInfo', [mv.toJson()]);
    return Mv.fromJson({
      ...mv.toJson(),
      ...result as Map,
      'pluginId': pluginId,
    });
  }

  Future<PlayList?> parsePlayList(String url) async {
    final result = await _call('parsePlayList', [url]);
    if (result == null) return null;
    if (result is! Map || result['id'] == null) {
      throw StateError('插件未返回有效歌单信息');
    }
    return PlayList.fromJson({...result, 'pluginId': pluginId});
  }

  Future<MusicCollection> mySongs([int page = 0, int size = 20]) async {
    final data = await _call('mySongs', [page, size]);
    return MusicCollection.fromJson({...data as Map, 'pluginId': pluginId});
  }

  Future<({List<PlayList> items, bool hasMore})> myPlayLists(
    bool created, [
    int page = 0,
    int size = 20,
  ]) async {
    final data = await _call('myPlayLists', [created, page, size]) as Map;
    return (
      items: [
        for (final item in data['items'] as List)
          PlayList.fromJson({...item as Map, 'pluginId': pluginId}),
      ],
      hasMore: data['hasMore'] as bool,
    );
  }

  Future<({List<Album> items, bool hasMore})> myAlbums([
    int page = 0,
    int size = 20,
  ]) async {
    final data = await _call('myAlbums', [page, size]) as Map;
    return (
      items: [
        for (final item in data['items'] as List)
          Album.fromJson({...item as Map, 'pluginId': pluginId}),
      ],
      hasMore: data['hasMore'] as bool,
    );
  }

  Future<({List<Mv> items, bool hasMore})> myMvs([
    int page = 0,
    int size = 20,
  ]) async {
    final data = await _call('myMvs', [page, size]) as Map;
    return (
      items: [
        for (final item in data['items'] as List)
          Mv.fromJson({...item as Map, 'pluginId': pluginId}),
      ],
      hasMore: data['hasMore'] as bool,
    );
  }

  Future<({List<Artist> items, bool hasMore})> myArtists([
    int page = 0,
    int size = 20,
  ]) async {
    final data = await _call('myArtists', [page, size]) as Map;
    return (
      items: [
        for (final item in data['items'] as List)
          Artist.fromJson({...item as Map, 'pluginId': pluginId}),
      ],
      hasMore: data['hasMore'] as bool,
    );
  }

  Future<void> createPlayList(String name) async =>
      await _call('createPlayList', [name]);
  Future<void> deletePlayList(PlayList playlist) async =>
      await _call('deletePlayList', [playlist.toJson()]);
  Future<void> addToPlayList(PlayList playlist, List<Song> songs) async =>
      await _call('addToPlayList', [
        playlist.toJson(),
        songs.map((x) => x.toJson()).toList(),
      ]);
  Future<void> removeFromPlayList(PlayList playlist, List<Song> songs) async =>
      await _call('removeFromPlayList', [
        playlist.toJson(),
        songs.map((x) => x.toJson()).toList(),
      ]);
  Future<void> favoriteSong(Song song, bool favorite) async {
    await _call('favoriteSong', [song.toJson(), favorite]);
    song.favorited = favorite;
  }

  Future<void> favoritePlayList(PlayList playlist, bool favorite) async {
    await _call('favoritePlayList', [playlist.toJson(), favorite]);
    playlist.favorited = favorite;
  }

  Future<void> favoriteAlbum(Album album, bool favorite) async {
    await _call('favoriteAlbum', [album.toJson(), favorite]);
    album.favorited = favorite;
  }

  Future<void> favoriteArtist(Artist artist, bool favorite) async {
    await _call('favoriteArtist', [artist.toJson(), favorite]);
    artist.favorited = favorite;
  }

  Future<void> favoriteMv(Mv mv, bool favorite) async {
    await _call('favoriteMv', [mv.toJson(), favorite]);
    mv.favorited = favorite;
  }

  Future<PluginAccount> getAccount() async {
    final result = await _call('getAccount', []);
    return PluginAccount.fromJson(Map<String, dynamic>.from(result as Map));
  }
}
