import 'dart:io';

import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/entity/app_resp_entity.dart';
import 'package:mix_music/entity/mix_album.dart';
import 'package:mix_music/entity/mix_album_type.dart';
import 'package:mix_music/entity/mix_play_list.dart';
import 'package:mix_music/entity/mix_play_list_type.dart';
import 'package:mix_music/entity/mix_rank.dart';
import 'package:mix_music/entity/mix_song.dart';
import 'package:path_provider/path_provider.dart';

import '../api/mix_api.dart';
import '../entity/mix_rank_type.dart';
import '../entity/plugins_info.dart';

class ApiController extends GetxController {
  RxList<PluginsInfo> plugins = RxList();
  RxList<PluginsInfo> playListPlugins = RxList();
  RxList<PluginsInfo> searchPlugins = RxList();
  RxList<PluginsInfo> albumPlugins = RxList();
  var pluginRoot = "";

  @override
  Future<void> onInit() async {
    super.onInit();

    if (Platform.isAndroid) {
      pluginRoot = "storage/emulated/0/MixMusic/plugins";
    } else {
      pluginRoot = "${(await getApplicationDocumentsDirectory()).path}/MixMusic/plugins";
    }

    await ApiFactory.init(pluginRoot: pluginRoot);

    getPlugins();
  }

  PluginsInfo getPlugin(int index) {
    return plugins[index];
  }

  ///获取插件
  void getPlugins() {
    plugins.addAll(ApiFactory.getPlugins());
    playListPlugins.addAll(ApiFactory.getPlugins().where((e) => e.method?.contains("playList") == true));
    searchPlugins.addAll(ApiFactory.getPlugins().where((e) => e.method?.contains("searchMusic") == true));
    albumPlugins.addAll(ApiFactory.getPlugins().where((e) => e.method?.contains("albumList") == true));
  }

  ///搜索音乐
  Future<AppRespEntity<List<MixSong>>> searchSong({required String site, required String keyword, int page = 0, int size = 20}) async {
    return ApiFactory.api(site: site)!.searchSong(keyword: keyword, page: page, size: size);
  }

  // void playUrl({required MixSong song}) async {
  //   if (currentPlugin.value == null) {
  //     return Future.error("插件不存在");
  //   }
  //   (await MixApi.api(plugins: currentPlugin.value!)).playUrl(song).then((value) {
  //     print(value.url);
  //   }).catchError((e) {
  //     print('出现错误:$e');
  //   });
  // }
  ///歌单分类
  Future<AppRespEntity<List<MixPlaylistType>>> playListType({required String site}) async {
    return ApiFactory.api(site: site)!.playListType();
  }

  ///歌单
  Future<AppRespEntity<List<MixPlaylist>>> playList({required String site, String? type, int page = 0, int size = 20}) async {
    return ApiFactory.api(site: site)!.playList(type: type, page: page, size: size);
  }

  ///歌单详情
  Future<AppRespEntity<MixPlaylist>> playListInfo({required String site, required MixPlaylist playlist, int page = 0, int size = 20}) async {
    return ApiFactory.api(site: site)!.playListInfo(playlist: playlist, page: page, size: size);
  }

  ///专辑分类
  Future<AppRespEntity<List<MixAlbumType>>> albumType({required String site}) async {
    return ApiFactory.api(site: site)!.albumType();
  }

  ///专辑
  Future<AppRespEntity<List<MixAlbum>>> albumList({required String site, String? type, int page = 0, int size = 20}) async {
    return ApiFactory.api(site: site)!.albumList(type: type, page: page, size: size);
  }

  ///专辑详情
  Future<AppRespEntity<MixAlbum>> albumInfo({required String site, required MixAlbum album, int page = 0, int size = 20}) async {
    return ApiFactory.api(site: site)!.albumInfo(album: album, page: page, size: size);
  }

  ///榜单
  Future<AppRespEntity<List<MixRankType>>> rankList({required String site}) async {
    return ApiFactory.api(site: site)!.rankList();
  }

  ///榜单详情
  Future<AppRespEntity<MixRank>> rankInfo({required String site, required MixRank rank, int page = 0, int size = 20}) async {
    return ApiFactory.api(site: site)!.rankInfo(rank: rank, page: page, size: size);
  }

  Future<String> invokeMethod({required PluginsInfo plugin, required String method, List<String> params = const []}) async {
    return (await MixApi.api(plugins: plugin)).invokeMethod(method: method, params: params);
  }

  @override
  void onClose() {
    super.onClose();
  }
}
