import 'package:flutter_js/flutter_js.dart';
import 'package:mix_music/entity/app_resp_entity.dart';
import 'package:mix_music/entity/mix_artist_type.dart';
import 'package:mix_music/entity/mix_download.dart';
import 'package:mix_music/entity/mix_mv.dart';
import 'package:mix_music/entity/mix_mv_type.dart';
import 'package:mix_music/entity/mix_play_list_type.dart';
import 'package:mix_music/entity/mix_quality.dart';
import 'package:mix_music/entity/mix_user.dart';
import 'package:mix_music/entity/plugins_info.dart';

import '../entity/mix_album.dart';
import '../entity/mix_album_type.dart';
import '../entity/mix_artist.dart';
import '../entity/mix_play_list.dart';
import '../entity/mix_rank.dart';
import '../entity/mix_rank_type.dart';
import '../entity/mix_song.dart';

abstract class MusicApi {
  PluginsInfo? plugins;
  JavascriptRuntime? current;

  ///=====================================搜索=====================================================
  ///搜索歌曲
  Future<AppRespEntity<List<MixSong>>> searchMusic({required String keyword, required int page, required int size});

  ///搜索专辑
  Future<AppRespEntity<List<MixAlbum>>> searchAlbum({required String keyword, required int page, required int size});

  ///搜索歌手
  Future<AppRespEntity<List<MixArtist>>> searchArtist({required String keyword, required int page, required int size});

  ///搜索歌单
  Future<AppRespEntity<List<MixPlaylist>>> searchPlayList({required String keyword, required int page, required int size});

  ///搜索MV
  Future<AppRespEntity<List<MixMv>>> searchMv({required String keyword, required int page, required int size});

  ///=====================================搜索=====================================================
  ///
  ///
  ///=====================================首页，推荐=====================================================
  ///最新专辑
  Future<AppRespEntity<List<MixAlbum>>> albumRec();

  ///歌单推荐
  Future<AppRespEntity<List<MixPlaylist>>> playListRec();

  ///新歌
  Future<AppRespEntity<List<MixSong>>> songRec();

  ///MV
  Future<AppRespEntity<List<MixMv>>> mvRec();

  ///=====================================首页，推荐=====================================================
  ///
  ///
  ///=====================================歌单=====================================================

  ///歌单
  Future<AppRespEntity<List<MixPlaylist>>> playList({MixPlaylistType? type, required int page, required int size});

  ///歌单分类
  Future<AppRespEntity<List<MixPlaylistType>>> playListType();

  ///获取歌单详情
  Future<AppRespEntity<MixPlaylist>> playListInfo({required MixPlaylist playlist, required int page, required int size});

  ///解析歌单
  Future<AppRespEntity<MixPlaylist>> parsePlayList({required String? url});

  ///=====================================歌单=====================================================
  ///
  ///
  ///=====================================地址=====================================================

  ///获取播放地址
  Future<MixSong> playUrl(MixSong song);

  ///下载地址
  Future<MixDownload> download(MixDownload download);

  ///=====================================地址=====================================================
  ///
  ///
  ///=====================================专辑=====================================================

  ///专辑分类
  Future<AppRespEntity<List<MixAlbumType>>> albumType();

  ///专辑
  Future<AppRespEntity<List<MixAlbum>>> albumList({MixAlbumType? type, required int page, required int size});

  ///获取专辑详情
  Future<AppRespEntity<MixAlbum>> albumInfo({required MixAlbum album, required int page, required int size});

  ///=====================================专辑=====================================================
  ///
  ///
  ///=====================================榜单=====================================================

  ///榜单
  Future<AppRespEntity<List<MixRankType>>> rankList();

  ///获取榜单详情
  Future<AppRespEntity<MixRank>> rankInfo({required MixRank rank, required int page, required int size});

  ///=====================================榜单=====================================================
  ///
  ///
  ///=====================================歌手=====================================================
  ///歌手
  Future<AppRespEntity<List<MixArtist>>> artistList({Map<String, dynamic>? type, required int page, required int size});

  ///歌手分类
  Future<AppRespEntity<List<MixArtistType>>> artistType();

  ///获取歌手详情
  Future<AppRespEntity<MixArtist>> artistInfo({required MixArtist artist});

  ///歌手歌曲
  Future<AppRespEntity<List<MixSong>>> artistSong({required MixArtist artist, required int page, required int size});

  ///歌手专辑
  Future<AppRespEntity<List<MixAlbum>>> artistAlbum({required MixArtist artist, required int page, required int size});

  ///=====================================歌手=====================================================
  ///
  ///
  ///
  ///=====================================用户=====================================================
  ///用户信息
  Future<AppRespEntity<MixUser>> userInfo();

  ///刷新Cookie
  Future<AppRespEntity<dynamic>> userRefresh();

  ///=====================================用户=====================================================
  ///
  ///
  ///=====================================MV=====================================================

  ///MV分类
  Future<AppRespEntity<List<MixMvType>>> mvType();

  ///MV
  Future<AppRespEntity<List<MixMv>>> mvList({Map<String, dynamic>? type, required int page, required int size});

  ///获取MV详情
  Future<AppRespEntity<MixMv>> mvInfo({required MixMv mv});

  ///=====================================MV=====================================================
  ///
  ///
  ///=====================================登录=====================================================
  ///设置Cookie
  Future<AppRespEntity<dynamic>> setCookie({required String cookie});

  ///获取Cookie
  Future<AppRespEntity<String>> getCookie();

  ///发送验证码
  Future<AppRespEntity<dynamic>> sendPhoneCode({required String phone});

  ///验证码登录
  Future<AppRespEntity<MixUser>> loginByPhone({required String phone, required String code});

  ///网页登陆地址
  Future<String> getWebLoginUrl();

  ///=====================================登录=====================================================
  ///
  ///
  ///=====================================公共=====================================================
  ///执行方法
  Future<dynamic> invokeMethod({required String method, List<String> params = const []});

  ///获取所有的key
  List<String> keys({required String obj});

  ///是否包含某个key
  bool contains({required String key, String obj = "music"});

  ///=====================================公共=====================================================

  void dispose();
}
