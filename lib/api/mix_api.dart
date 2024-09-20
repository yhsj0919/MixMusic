import 'dart:async';
import 'dart:convert';

import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:mix_music/entity/app_resp_entity.dart';
import 'package:mix_music/entity/mix_album.dart';
import 'package:mix_music/entity/mix_album_type.dart';
import 'package:mix_music/entity/mix_artist.dart';
import 'package:mix_music/entity/mix_artist_type.dart';
import 'package:mix_music/entity/mix_play_list.dart';
import 'package:mix_music/entity/mix_play_list_type.dart';
import 'package:mix_music/entity/mix_rank.dart';
import 'package:mix_music/entity/mix_song.dart';
import 'package:mix_music/entity/plugins_info.dart';
import 'package:mix_music/api/music_api.dart';
import 'package:mix_music/utils/plugins_ext.dart';

import '../entity/mix_rank_type.dart';

class MixApi extends MusicApi {
  static Future<MusicApi> api({required PluginsInfo plugins}) async {
    var api = MixApi._();
    api.plugins = plugins;
    await api._init();
    return api;
  }

  MixApi._();

  Future<void> _init() async {
    current = getJavascriptRuntime();
    await current?.enableAxios();
    await current?.enableCrypto();
    current?.enableStringPlugin(code: plugins?.code ?? "");
  }

  @override
  void dispose() {
    // current?.dispose();
    // plugins = null;
  }

  @override
  Future<AppRespEntity<List<MixPlaylist>>> playList({String? type, required int page, required int size}) {
    return invokeMethod(method: "music.playList.list", params: [type, page, size]).then((value) {
      AppRespEntity<List<MixPlaylist>> data = AppRespEntity.fromJson(value);
      if (data.code == 200) {
        return Future(() => data);
      } else {
        return Future.error(data.msg ?? "操作失败");
      }
    });
  }

  @override
  Future<AppRespEntity<List<MixPlaylistType>>> playListType() {
    return invokeMethod(method: "music.playList.type", params: []).then((value) {
      AppRespEntity<List<MixPlaylistType>> data = AppRespEntity.fromJson(value);
      if (data.code == 200) {
        return Future(() => data);
      } else {
        return Future.error(data.msg ?? "操作失败");
      }
    });
  }

  @override
  Future<AppRespEntity<MixPlaylist>> playListInfo({required MixPlaylist playlist, required int page, required int size}) {
    var ss = JsonMapper.serialize(playlist).replaceAll("\n", "").replaceAll("\\", "\\\\").replaceAll("'", "\\'");
    return invokeMethod(method: "music.playList.info", params: [ss, page, size]).then((value) {
      print(json.encode(value));
      AppRespEntity<MixPlaylist> data = AppRespEntity.fromJson(value);

      if (data.code == 200) {
        return Future(() => data);
      } else {
        return Future.error(data.msg ?? "操作失败");
      }
    });
  }

  @override
  Future<MixSong> playUrl(MixSong song) {
    var lyric = song.lyric;

    if (song.lyric?.contains("[") == true || song.lyric?.contains("]") == true) {
      song.lyric = null;
    }
    var ss = JsonMapper.serialize(song).replaceAll("\n", "").replaceAll("\\", "\\\\").replaceAll("'", "\\'");
    return invokeMethod(method: "music.url.playUrl", params: [ss]).then((value) {
      AppRespEntity<MixSong> data = AppRespEntity.fromJson(value);
      if (data.code == 200) {
        data.data?.lyric ??= lyric;

        return Future(() => data.data!);
      } else {
        return Future.error(data.msg ?? "操作失败");
      }
    });
  }

  @override
  Future<AppRespEntity<List<MixSong>>> searchSong({required String keyword, required int page, required int size}) {
    return invokeMethod(method: "music.search.music", params: [keyword, page, size]).then((value) {
      AppRespEntity<List<MixSong>> data = AppRespEntity.fromJson(value);
      if (data.code == 200) {
        return Future(() => data);
      } else {
        return Future.error(data.msg ?? "操作失败");
      }
    });
  }

  @override
  Future<dynamic> invokeMethod({required String method, List<dynamic> params = const []}) {
    return current!.invokeMethod(method: method, args: params);
  }

  @override
  Future<AppRespEntity<MixAlbum>> albumInfo({required MixAlbum album, required int page, required int size}) {
    var ss = JsonMapper.serialize(album).replaceAll("\n", "").replaceAll("\\", "\\\\").replaceAll("'", "\\'");
    return invokeMethod(method: "music.album.info", params: [ss, page, size]).then((value) {
      AppRespEntity<MixAlbum> data = AppRespEntity.fromJson(value);
      if (data.code == 200) {
        return Future(() => data);
      } else {
        return Future.error(data.msg ?? "操作失败");
      }
    });
  }

  @override
  Future<AppRespEntity<List<MixAlbum>>> albumList({String? type, required int page, required int size}) {
    return invokeMethod(method: "music.album.list", params: [type, page, size]).then((value) {
      AppRespEntity<List<MixAlbum>> data = AppRespEntity.fromJson(value);
      if (data.code == 200) {
        return Future(() => data);
      } else {
        return Future.error(data.msg ?? "操作失败");
      }
    });
  }

  @override
  Future<AppRespEntity<List<MixAlbumType>>> albumType() {
    return invokeMethod(method: "music.album.type", params: []).then((value) {
      AppRespEntity<List<MixAlbumType>> data = AppRespEntity.fromJson(value);
      if (data.code == 200) {
        return Future(() => data);
      } else {
        return Future.error(data.msg ?? "操作失败");
      }
    });
  }

  @override
  Future<AppRespEntity<MixRank>> rankInfo({required MixRank rank, required int page, required int size}) {
    var ss = JsonMapper.serialize(rank).replaceAll("\n", "").replaceAll("\\", "\\\\").replaceAll("'", "\\'");
    return invokeMethod(method: "music.rank.info", params: [ss, page, size]).then((value) {
      AppRespEntity<MixRank> data = AppRespEntity.fromJson(value);
      if (data.code == 200) {
        return Future(() => data);
      } else {
        return Future.error(data.msg ?? "操作失败");
      }
    });
  }

  @override
  Future<AppRespEntity<List<MixRankType>>> rankList() {
    return invokeMethod(method: "music.rank.list", params: []).then((value) {
      AppRespEntity<List<MixRankType>> data = AppRespEntity.fromJson(value);
      if (data.code == 200) {
        return Future(() => data);
      } else {
        return Future.error(data.msg ?? "操作失败");
      }
    });
  }

  @override
  Future<AppRespEntity<MixArtist>> artistInfo({required MixArtist artist}) {
    var ss = JsonMapper.serialize(artistInfo).replaceAll("\n", "").replaceAll("\\", "\\\\").replaceAll("'", "\\'");

    return invokeMethod(method: "music.artist.info", params: [ss]).then((value) {
      AppRespEntity<MixArtist> data = AppRespEntity.fromJson(value);
      if (data.code == 200) {
        return Future(() => data);
      } else {
        return Future.error(data.msg ?? "操作失败");
      }
    });
  }

  @override
  Future<AppRespEntity<List<MixArtist>>> artistList({Map<String, dynamic>? type, required int page, required int size}) {
    var ss = json.encode(type);
    return invokeMethod(method: "music.artist.list", params: [ss, page, size]).then((value) {
      AppRespEntity<List<MixArtist>> data = AppRespEntity.fromJson(value);
      if (data.code == 200) {
        return Future(() => data);
      } else {
        return Future.error(data.msg ?? "操作失败");
      }
    });
  }

  @override
  Future<AppRespEntity<List<MixArtistType>>> artistType() {
    return invokeMethod(method: "music.artist.type", params: []).then((value) {
      AppRespEntity<List<MixArtistType>> data = AppRespEntity.fromJson(value);
      if (data.code == 200) {
        return Future(() => data);
      } else {
        return Future.error(data.msg ?? "操作失败");
      }
    });
  }

  @override
  Future<AppRespEntity<List<MixAlbum>>> artistAlbum({required MixArtist artist, required int page, required int size}) {
    var ss = JsonMapper.serialize(artist).replaceAll("\n", "").replaceAll("\\", "\\\\").replaceAll("'", "\\'");
    return invokeMethod(method: "music.artist.detail.album", params: [ss, page, size]).then((value) {
      print(value);
      AppRespEntity<List<MixAlbum>> data = AppRespEntity.fromJson(value);
      if (data.code == 200) {
        return Future(() => data);
      } else {
        return Future.error(data.msg ?? "操作失败");
      }
    });
  }

  @override
  Future<AppRespEntity<List<MixSong>>> artistSong({required MixArtist artist, required int page, required int size}) {
    var ss = JsonMapper.serialize(artist).replaceAll("\n", "").replaceAll("\\", "\\\\").replaceAll("'", "\\'");
    return invokeMethod(method: "music.artist.detail.song", params: [ss, page, size]).then((value) {
      AppRespEntity<List<MixSong>> data = AppRespEntity.fromJson(value);
      if (data.code == 200) {
        return Future(() => data);
      } else {
        return Future.error(data.msg ?? "操作失败");
      }
    });
  }

  @override
  Future<AppRespEntity<List<MixAlbum>>> albumRec() {
    return invokeMethod(method: "music.rec.album", params: []).then((value) {
      AppRespEntity<List<MixAlbum>> data = AppRespEntity.fromJson(value);
      if (data.code == 200) {
        return Future(() => data);
      } else {
        return Future.error(data.msg ?? "操作失败");
      }
    });
  }

  @override
  Future<AppRespEntity<List<MixPlaylist>>> playListRec() {
    return invokeMethod(method: "music.rec.playlist", params: []).then((value) {
      AppRespEntity<List<MixPlaylist>> data = AppRespEntity.fromJson(value);
      if (data.code == 200) {
        return Future(() => data);
      } else {
        return Future.error(data.msg ?? "操作失败");
      }
    });
  }

  @override
  Future<AppRespEntity<List<MixSong>>> songRec() {
    return invokeMethod(method: "music.rec.song", params: []).then((value) {
      AppRespEntity<List<MixSong>> data = AppRespEntity.fromJson(value);
      if (data.code == 200) {
        return Future(() => data);
      } else {
        return Future.error(data.msg ?? "操作失败");
      }
    });
  }

  @override
  Future<AppRespEntity<MixPlaylist>> parsePlayList({required String? url}) {
    return invokeMethod(method: "music.parse.playlist", params: [url]).then((value) {
      AppRespEntity<MixPlaylist> data = AppRespEntity.fromJson(value);
      if (data.code == 200) {
        return Future(() => data);
      } else {
        return Future.error(data.msg ?? "操作失败");
      }
    });
  }

  @override
  List<String> keys({required String obj}) {
    JsEvalResult? result = current?.evaluate("Object.keys($obj)");

    if (result?.isError == true) {
      return [];
    } else {
      var check = result?.rawResult as List?;
      return check?.map((e) => "$e").toList() ?? [];
    }
  }

  ///是否包含某个key
  @override
  bool contains({required String key, String obj = "music"}) {
    var check = current?.evaluate("'$key' in $obj").rawResult as bool?;
    return check ?? false;
  }
}
