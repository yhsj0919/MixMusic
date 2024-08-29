import 'dart:async';
import 'dart:convert';

import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:mix_music/api/music_api.dart';
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
import 'package:mix_music/utils/plugins_ext.dart';

import '../entity/mix_rank_type.dart';

class MixApi extends MusicApi {
  PluginsInfo plugins;
  JavascriptRuntime? current;

  static Future<MusicApi> api({required PluginsInfo plugins}) async {
    var api = MixApi._(plugins: plugins);
    await api._init();
    return api;
  }

  MixApi._({required this.plugins});

  Future<void> _init() async {
    current = getJavascriptRuntime();
    await current?.enableAxios();
    await current?.enableCrypto();
    await current?.enableFilePlugin(path: plugins.path!);
  }

  @override
  Future<AppRespEntity<List<MixPlaylist>>> playList({String? type, required int page, required int size}) {
    return invokeMethod(method: "playList", params: [type, page, size]).then((value) {
      AppRespEntity<List<MixPlaylist>> data = AppRespEntity.fromJson(json.decode(value));
      if (data.code == 200) {
        return Future(() => data);
      } else {
        return Future.error(data.msg ?? "操作失败");
      }
    });
  }

  @override
  Future<AppRespEntity<List<MixPlaylistType>>> playListType() {
    return invokeMethod(method: "playListType", params: []).then((value) {
      AppRespEntity<List<MixPlaylistType>> data = AppRespEntity.fromJson(json.decode(value));
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
    return invokeMethod(method: "playListInfo", params: [ss, page, size]).then((value) {
      AppRespEntity<MixPlaylist> data = AppRespEntity.fromJson(json.decode(value));

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
    return invokeMethod(method: "playUrl", params: [ss]).then((value) {
      AppRespEntity<MixSong> data = AppRespEntity.fromJson(json.decode(value));
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
    return invokeMethod(method: "searchMusic", params: [keyword, page, size]).then((value) {
      AppRespEntity<List<MixSong>> data = AppRespEntity.fromJson(json.decode(value));
      if (data.code == 200) {
        return Future(() => data);
      } else {
        return Future.error(data.msg ?? "操作失败");
      }
    });
  }

  @override
  Future<dynamic> invokeMethod({required String method, List<dynamic> params = const []}) {
    var ddd = current?.evaluate("typeof $method === 'function'");
    if (ddd?.rawResult == false) {
      return Future.error("${plugins.name}尚未实现此功能");
    }
    var ss = "$method(${params.map((e) => "'$e'").join(",")})";
    print("当前请求:$ss");
    return current!.invokeCode("$method(${params.map((e) => "'$e'").join(",")})");
  }

  @override
  Future<AppRespEntity<MixAlbum>> albumInfo({required MixAlbum album, required int page, required int size}) {
    var ss = JsonMapper.serialize(album).replaceAll("\n", "").replaceAll("\\", "\\\\").replaceAll("'", "\\'");
    return invokeMethod(method: "albumInfo", params: [ss, page, size]).then((value) {
      AppRespEntity<MixAlbum> data = AppRespEntity.fromJson(json.decode(value));
      if (data.code == 200) {
        return Future(() => data);
      } else {
        return Future.error(data.msg ?? "操作失败");
      }
    });
  }

  @override
  Future<AppRespEntity<List<MixAlbum>>> albumList({String? type, required int page, required int size}) {
    return invokeMethod(method: "albumList", params: [type, page, size]).then((value) {
      AppRespEntity<List<MixAlbum>> data = AppRespEntity.fromJson(json.decode(value));
      if (data.code == 200) {
        return Future(() => data);
      } else {
        return Future.error(data.msg ?? "操作失败");
      }
    });
  }

  @override
  Future<AppRespEntity<List<MixAlbumType>>> albumType() {
    return invokeMethod(method: "albumType", params: []).then((value) {
      AppRespEntity<List<MixAlbumType>> data = AppRespEntity.fromJson(json.decode(value));
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
    return invokeMethod(method: "rankInfo", params: [ss, page, size]).then((value) {
      AppRespEntity<MixRank> data = AppRespEntity.fromJson(json.decode(value));
      if (data.code == 200) {
        return Future(() => data);
      } else {
        return Future.error(data.msg ?? "操作失败");
      }
    });
  }

  @override
  Future<AppRespEntity<List<MixRankType>>> rankList() {
    return invokeMethod(method: "rankList", params: []).then((value) {
      AppRespEntity<List<MixRankType>> data = AppRespEntity.fromJson(json.decode(value));
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

    return invokeMethod(method: "artistInfo", params: [ss]).then((value) {
      AppRespEntity<MixArtist> data = AppRespEntity.fromJson(json.decode(value));
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
    return invokeMethod(method: "artistList", params: [ss, page, size]).then((value) {
      AppRespEntity<List<MixArtist>> data = AppRespEntity.fromJson(json.decode(value));
      if (data.code == 200) {
        return Future(() => data);
      } else {
        return Future.error(data.msg ?? "操作失败");
      }
    });
  }

  @override
  Future<AppRespEntity<List<MixArtistType>>> artistType() {
    return invokeMethod(method: "artistType", params: []).then((value) {
      AppRespEntity<List<MixArtistType>> data = AppRespEntity.fromJson(json.decode(value));
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
    return invokeMethod(method: "artistAlbum", params: [ss, page, size]).then((value) {
      AppRespEntity<List<MixAlbum>> data = AppRespEntity.fromJson(json.decode(value));
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
    return invokeMethod(method: "artistSong", params: [ss, page, size]).then((value) {
      AppRespEntity<List<MixSong>> data = AppRespEntity.fromJson(json.decode(value));
      if (data.code == 200) {
        return Future(() => data);
      } else {
        return Future.error(data.msg ?? "操作失败");
      }
    });
  }

  @override
  Future<AppRespEntity<List<MixAlbum>>> albumRec() {
    return invokeMethod(method: "albumRec", params: []).then((value) {
      AppRespEntity<List<MixAlbum>> data = AppRespEntity.fromJson(json.decode(value));
      if (data.code == 200) {
        return Future(() => data);
      } else {
        return Future.error(data.msg ?? "操作失败");
      }
    });
  }

  @override
  Future<AppRespEntity<List<MixPlaylist>>> playListRec() {
    return invokeMethod(method: "playListRec", params: []).then((value) {
      AppRespEntity<List<MixPlaylist>> data = AppRespEntity.fromJson(json.decode(value));
      if (data.code == 200) {
        return Future(() => data);
      } else {
        return Future.error(data.msg ?? "操作失败");
      }
    });
  }

  @override
  Future<AppRespEntity<List<MixSong>>> songRec() {
    return invokeMethod(method: "songRec", params: []).then((value) {
      AppRespEntity<List<MixSong>> data = AppRespEntity.fromJson(json.decode(value));
      if (data.code == 200) {
        return Future(() => data);
      } else {
        return Future.error(data.msg ?? "操作失败");
      }
    });
  }

  @override
  Future<AppRespEntity<MixPlaylist>> parsePlayList({required String? url}) {
    return invokeMethod(method: "parsePlayList", params: [url]).then((value) {
      AppRespEntity<MixPlaylist> data = AppRespEntity.fromJson(json.decode(value));
      if (data.code == 200) {
        return Future(() => data);
      } else {
        return Future.error(data.msg ?? "操作失败");
      }
    });
  }
}
