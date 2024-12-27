import 'dart:async';
import 'dart:convert';

import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/entity/app_resp_entity.dart';
import 'package:mix_music/entity/mix_album.dart';
import 'package:mix_music/entity/mix_album_type.dart';
import 'package:mix_music/entity/mix_artist.dart';
import 'package:mix_music/entity/mix_artist_type.dart';
import 'package:mix_music/entity/mix_download.dart';
import 'package:mix_music/entity/mix_mv.dart';
import 'package:mix_music/entity/mix_mv_type.dart';
import 'package:mix_music/entity/mix_play_list.dart';
import 'package:mix_music/entity/mix_play_list_type.dart';
import 'package:mix_music/entity/mix_quality.dart';
import 'package:mix_music/entity/mix_rank.dart';
import 'package:mix_music/entity/mix_song.dart';
import 'package:mix_music/entity/mix_user.dart';
import 'package:mix_music/entity/plugins_info.dart';
import 'package:mix_music/api/music_api.dart';
import 'package:mix_music/utils/plugins_ext.dart';
import 'package:mix_music/utils/sp.dart';

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
    await current?.enableBigInt();
    await current?.enableCrypto();
    await current?.enableBase64();
    await current?.enableFastXmlParser();

    await current?.injectMethod("setCookie", (args) async {
      String cookie = args.join(';');
      return await Sp.setString("${Constant.KEY_COOKIE}_${plugins?.package}", cookie);
    });
    await current?.injectMethod("getCookie", (args) {
      return Sp.getString("${Constant.KEY_COOKIE}_${plugins?.package}") ?? "";
    });
    current?.enableStringPlugin(code: plugins?.code ?? "");
  }

  @override
  void dispose() {
    // current?.dispose();
    // plugins = null;
  }

  ///=====================================搜索=====================================================
  @override
  Future<AppRespEntity<List<MixSong>>> searchMusic({required String keyword, required int page, required int size}) {
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
  Future<AppRespEntity<List<MixAlbum>>> searchAlbum({required String keyword, required int page, required int size}) {
    return invokeMethod(method: "music.search.album", params: [keyword, page, size]).then((value) {
      AppRespEntity<List<MixAlbum>> data = AppRespEntity.fromJson(value);
      if (data.code == 200) {
        return Future(() => data);
      } else {
        return Future.error(data.msg ?? "操作失败");
      }
    });
  }

  @override
  Future<AppRespEntity<List<MixArtist>>> searchArtist({required String keyword, required int page, required int size}) {
    return invokeMethod(method: "music.search.artist", params: [keyword, page, size]).then((value) {
      AppRespEntity<List<MixArtist>> data = AppRespEntity.fromJson(value);
      if (data.code == 200) {
        return Future(() => data);
      } else {
        return Future.error(data.msg ?? "操作失败");
      }
    });
  }

  @override
  Future<AppRespEntity<List<MixPlaylist>>> searchPlayList({required String keyword, required int page, required int size}) {
    return invokeMethod(method: "music.search.playlist", params: [keyword, page, size]).then((value) {
      AppRespEntity<List<MixPlaylist>> data = AppRespEntity.fromJson(value);
      if (data.code == 200) {
        return Future(() => data);
      } else {
        return Future.error(data.msg ?? "操作失败");
      }
    });
  }

  @override
  Future<AppRespEntity<List<MixMv>>> searchMv({required String keyword, required int page, required int size}) {
    return invokeMethod(method: "music.search.mv", params: [keyword, page, size]).then((value) {
      AppRespEntity<List<MixMv>> data = AppRespEntity.fromJson(value);
      if (data.code == 200) {
        return Future(() => data);
      } else {
        return Future.error(data.msg ?? "操作失败");
      }
    });
  }

  ///=====================================热门，推荐=====================================================

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
  Future<AppRespEntity<List<MixMv>>> mvRec() {
    return invokeMethod(method: "music.rec.mv", params: []).then((value) {
      AppRespEntity<List<MixMv>> data = AppRespEntity.fromJson(value);
      if (data.code == 200) {
        return Future(() => data);
      } else {
        return Future.error(data.msg ?? "操作失败");
      }
    });
  }

  ///=====================================歌单=====================================================

  @override
  Future<AppRespEntity<List<MixPlaylist>>> playList({MixPlaylistType? type, required int page, required int size}) {
    var myType = JsonMapper.toMap(type);
    return invokeMethod(method: "music.playList.list", params: [myType, page, size]).then((value) {
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
    var myPlaylist = JsonMapper.toMap(playlist);
    return invokeMethod(method: "music.playList.info", params: [myPlaylist, page, size]).then((value) {
      AppRespEntity<MixPlaylist> data = AppRespEntity.fromJson(value);

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

  ///=====================================专辑=====================================================
  @override
  Future<AppRespEntity<MixAlbum>> albumInfo({required MixAlbum album, required int page, required int size}) {
    var myAlbum = JsonMapper.toMap(album);
    return invokeMethod(method: "music.album.info", params: [myAlbum, page, size]).then((value) {
      AppRespEntity<MixAlbum> data = AppRespEntity.fromJson(value);
      if (data.code == 200) {
        return Future(() => data);
      } else {
        return Future.error(data.msg ?? "操作失败");
      }
    });
  }

  @override
  Future<AppRespEntity<List<MixAlbum>>> albumList({MixAlbumType? type, required int page, required int size}) {
    var myType = JsonMapper.toMap(type);

    return invokeMethod(method: "music.album.list", params: [myType, page, size]).then((value) {
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

  ///=====================================榜单=====================================================
  @override
  Future<AppRespEntity<MixRank>> rankInfo({required MixRank rank, required int page, required int size}) {
    var myRank = JsonMapper.toMap(rank);
    return invokeMethod(method: "music.rank.info", params: [myRank, page, size]).then((value) {
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

  ///=====================================歌手=====================================================
  @override
  Future<AppRespEntity<MixArtist>> artistInfo({required MixArtist artist}) {
    var myArtist = JsonMapper.serialize(artistInfo);

    return invokeMethod(method: "music.artist.info", params: [myArtist]).then((value) {
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
    return invokeMethod(method: "music.artist.list", params: [type, page, size]).then((value) {
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
    var myArtist = JsonMapper.toMap(artist);
    return invokeMethod(method: "music.artist.detail.album", params: [myArtist, page, size]).then((value) {
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
    var myArtist = JsonMapper.toMap(artist);
    return invokeMethod(method: "music.artist.detail.song", params: [myArtist, page, size]).then((value) {
      AppRespEntity<List<MixSong>> data = AppRespEntity.fromJson(value);
      if (data.code == 200) {
        return Future(() => data);
      } else {
        return Future.error(data.msg ?? "操作失败");
      }
    });
  }

  ///=====================================MV=====================================================
  @override
  Future<AppRespEntity<List<MixMvType>>> mvType() {
    return invokeMethod(method: "music.mv.type", params: []).then((value) {
      AppRespEntity<List<MixMvType>> data = AppRespEntity.fromJson(value);
      if (data.code == 200) {
        return Future(() => data);
      } else {
        return Future.error(data.msg ?? "操作失败");
      }
    });
  }

  @override
  Future<AppRespEntity<MixMv>> mvInfo({required MixMv mv, required int page, required int size}) {
    var myAlbum = JsonMapper.toMap(mv);
    return invokeMethod(method: "music.mv.info", params: [myAlbum, page, size]).then((value) {
      AppRespEntity<MixMv> data = AppRespEntity.fromJson(value);
      if (data.code == 200) {
        return Future(() => data);
      } else {
        return Future.error(data.msg ?? "操作失败");
      }
    });
  }

  @override
  Future<AppRespEntity<List<MixMv>>> mvList({Map<String, dynamic>? type, required int page, required int size}) {
    return invokeMethod(method: "music.mv.list", params: [type, page, size]).then((value) {
      AppRespEntity<List<MixMv>> data = AppRespEntity.fromJson(value);
      if (data.code == 200) {
        return Future(() => data);
      } else {
        return Future.error(data.msg ?? "操作失败");
      }
    });
  }

  ///=====================================地址=====================================================

  @override
  Future<MixSong> playUrl(MixSong song) {
    var mySong = JsonMapper.toMap(song);
    return invokeMethod(method: "music.url.playUrl", params: [mySong]).then((value) {
      AppRespEntity<MixSong> data = AppRespEntity.fromJson(value);
      if (data.code == 200) {
        // data.data?.lyric ??= lyric;

        return Future(() => data.data!);
      } else {
        return Future.error(data.msg ?? "操作失败");
      }
    });
  }

  @override
  Future<MixDownload> download(MixDownload download) {
    var myDownload = JsonMapper.toMap(download);
    return invokeMethod(method: "music.url.download", params: [myDownload]).then((value) {
      AppRespEntity<MixDownload> data = AppRespEntity.fromJson(value);
      if (data.code == 200) {
        // data.data?.lyric ??= lyric;

        return Future(() => data.data!);
      } else {
        return Future.error(data.msg ?? "操作失败");
      }
    });
  }

  ///=====================================用户=====================================================
  @override
  Future<AppRespEntity<MixUser>> userInfo() {
    return invokeMethod(method: "music.user.info", params: []).then((value) {
      AppRespEntity<MixUser> data = AppRespEntity.fromJson(value);
      if (data.code == 200) {
        return Future(() => data);
      } else {
        return Future.error(data.msg ?? "操作失败");
      }
    });
  }

  @override
  Future<AppRespEntity<dynamic>> userRefresh() {
    return invokeMethod(method: "music.user.refresh", params: []).then((value) {
      AppRespEntity<dynamic> data = AppRespEntity.fromJson(value);
      if (data.code == 200) {
        return Future(() => data);
      } else {
        return Future.error(data.msg ?? "操作失败");
      }
    });
  }

  ///=====================================公共=====================================================

  @override
  Future<dynamic> invokeMethod({required String method, List<dynamic> params = const []}) {
    for (var v in params) {
      if (v != null && v is! String && v is! num && v is! Map && v is! Iterable) {
        return Future.error("$method 参数只支持 String,num,Map,Iterable类型");
      }
    }

    return current!.invokeMethod(method: method, args: params);
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

  @override
  void setCookie({required String cookie}) {
    Sp.setString("${Constant.KEY_COOKIE}_${plugins?.package}", cookie);
  }

  @override
  String getCookie() {
    return Sp.getString("${Constant.KEY_COOKIE}_${plugins?.package}") ?? "";
  }
}
