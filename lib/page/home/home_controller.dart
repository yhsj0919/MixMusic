import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/api/music_api.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/entity/mix_album.dart';
import 'package:mix_music/entity/mix_mv.dart';
import 'package:mix_music/entity/mix_play_list.dart';
import 'package:mix_music/entity/mix_song.dart';
import 'package:mix_music/entity/plugins_info.dart';
import 'package:mix_music/page/setting/user_controller.dart';
import 'package:mix_music/player/music_controller.dart';
import 'package:mix_music/utils/sp.dart';
import 'package:mix_music/widgets/message.dart';

class HomeController extends GetxController {
  MusicController music = Get.put(MusicController());
  RxList<MixPlaylist> playlist = RxList();
  RxList<MixAlbum> albumList = RxList();
  RxList<MixSong> songList = RxList();
  RxList<MixMv> mvList = RxList();

  RxnString homeSitePackage = RxnString();
  Rxn<PluginsInfo> plugin = Rxn();

  UserController userController = Get.put(UserController());

  @override
  Future<void> onInit() async {
    super.onInit();

    getData();
  }

  void getData() {
    homeSitePackage.value = Sp.getString(Constant.KEY_HOME_SITE) ?? ApiFactory.getRecPlugins().firstOrNull?.package;
    plugin.value = ApiFactory.getPlugin(homeSitePackage.value);

    userController.refreshAllCookie().then((v) {
      userController.getAllUser();
    });

    playlist.clear();
    albumList.clear();
    songList.clear();
    mvList.clear();

    getSongRec();
    getPlayListRec();
    getAlbumRec();
    getMvRec();
  }

  ///获取歌单
  Future<Null>? getPlayListRec() {
    return ApiFactory.api(package: homeSitePackage.value ?? "")?.playListRec().then((value) {
      playlist.clear();
      playlist.addAll(value.data ?? []);

      // showComplete("操作成功");
    }).catchError((e) {
      // showError(e);
    });
  }

  ///获取专辑
  Future<Null>? getAlbumRec() {
    return ApiFactory.api(package: homeSitePackage.value ?? "")?.albumRec().then((value) {
      albumList.clear();
      albumList.addAll(value.data ?? []);

      // showComplete("操作成功");
    }).catchError((e) {
      // showError(e);
    });
  }

  ///获取新歌
  Future<Null>? getSongRec() {
    return ApiFactory.api(package: homeSitePackage.value ?? "")?.songRec().then((value) {
      songList.clear();
      songList.addAll(value.data ?? []);

      // showComplete("操作成功");
    }).catchError((e) {
      // showError(e);
    });
  }

  ///获取新歌
  Future<Null>? getMvRec() {
    return ApiFactory.api(package: homeSitePackage.value ?? "")?.mvRec().then((value) {
      mvList.clear();
      mvList.addAll(value.data ?? []);

      // showComplete("操作成功");
    }).catchError((e) {
      // showError(e);
    });
  }
}
