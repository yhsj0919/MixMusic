import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/api/music_api.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/entity/mix_album.dart';
import 'package:mix_music/entity/mix_mv.dart';
import 'package:mix_music/entity/mix_play_list.dart';
import 'package:mix_music/entity/mix_song.dart';
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

  UserController userController = Get.put(UserController());

  @override
  Future<void> onInit() async {
    super.onInit();

    getData();
  }

  void getData() {
    userController.refreshAllCookie().then((v) {
      userController.getAllUser();
    });

    playlist.clear();
    albumList.clear();
    songList.clear();
    mvList.clear();

    homeSitePackage.value = Sp.getString(Constant.KEY_HOME_SITE) ?? ApiFactory.getRecPlugins().firstOrNull?.package;

    getSongRec();
    getPlayListRec();
    getAlbumRec();
    getMvRec();
  }

  ///获取歌单
  void getPlayListRec() {
    ApiFactory.api(package: homeSitePackage.value ?? "")?.playListRec().then((value) {
      playlist.clear();
      playlist.addAll(value.data ?? []);

      // showComplete("操作成功");
    }).catchError((e) {
      showError(e);
    });
  }

  ///获取专辑
  void getAlbumRec() {
    ApiFactory.api(package: homeSitePackage.value ?? "")?.albumRec().then((value) {
      albumList.clear();
      albumList.addAll(value.data ?? []);

      // showComplete("操作成功");
    }).catchError((e) {
      showError(e);
    });
  }

  ///获取新歌
  void getSongRec() {
    ApiFactory.api(package: homeSitePackage.value ?? "")?.songRec().then((value) {
      songList.clear();
      songList.addAll(value.data ?? []);

      // showComplete("操作成功");
    }).catchError((e) {
      showError(e);
    });
  }

  ///获取新歌
  void getMvRec() {
    ApiFactory.api(package: homeSitePackage.value ?? "")?.mvRec().then((value) {
      mvList.clear();
      mvList.addAll(value.data ?? []);

      // showComplete("操作成功");
    }).catchError((e) {
      showError(e);
    });
  }
}
