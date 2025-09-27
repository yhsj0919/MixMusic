import 'dart:async';
import 'dart:io';

import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:get/get.dart';
import 'package:mix_music/common/api/api_factory.dart';
import 'package:mix_music/common/entity/mix_album.dart';
import 'package:mix_music/common/entity/mix_mv.dart';
import 'package:mix_music/common/entity/mix_play_list.dart';
import 'package:mix_music/common/entity/mix_song.dart';
import 'package:mix_music/common/entity/plugins_info.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/page/setting/login/user_controller.dart';
import 'package:mix_music/player/music_controller.dart';
import 'package:mix_music/utils/db.dart';
import 'package:mix_music/utils/plugins_ext.dart';
import 'package:mix_music/widgets/message.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:tiny_db/tiny_db.dart';

class HomeController extends GetxController {
  MusicController music = Get.put(MusicController());
  RxList<MixPlaylist> playlist = RxList();
  RxList<MixAlbum> albumList = RxList();
  RxList<MixSong> songList = RxList();
  RxList<MixMv> mvList = RxList();
  RxList<PluginsInfo> plugins = RxList();

  RxnString homeSitePackage = RxnString();
  Rxn<PluginsInfo> plugin = Rxn();

  UserController userController = Get.put(UserController());

  late StreamSubscription _intentSub;

  @override
  Future<void> onInit() async {
    super.onInit();
    getData();

    if (Platform.isAndroid || Platform.isIOS) {
      // Listen to media sharing coming from outside the app while the app is in the memory.
      _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen(
        (value) {
          // setState(() {
          if (value.firstOrNull != null) {
            installPlugin(value.firstOrNull?.path);
          }

          // showInfo(value.firstOrNull?.path);
          //
          // print("这是文件地址1${value.firstOrNull?.path}");
          // print("这是文件信息1${value.firstOrNull?.toMap()}");
          // });
        },
        onError: (err) {
          print("getIntentDataStream error: $err");
        },
      );
      // Get the media sharing coming from outside the app while the app is closed.
      ReceiveSharingIntent.instance.getInitialMedia().then((value) {
        // setState(() {
        if (value.firstOrNull != null) {
          installPlugin(value.firstOrNull?.path);
          // Tell the library that we are done processing the intent.
          ReceiveSharingIntent.instance.reset();
        }
        // });
      });
    }
  }

  void getData() {
    // showInfo("这里运行了");
    plugins.value = ApiFactory.getRecPlugins();
    homeSitePackage.value = AppDB.getString(Constant.KEY_HOME_SITE) ?? ApiFactory.getRecPlugins().firstOrNull?.package;
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
    return ApiFactory.api(package: homeSitePackage.value ?? "")
        ?.playListRec()
        .then((value) {
          playlist.clear();
          playlist.addAll(value.data ?? []);

          // showComplete("操作成功");
        })
        .catchError((e) {
          // showError(e);
        });
  }

  ///获取专辑
  Future<Null>? getAlbumRec() {
    return ApiFactory.api(package: homeSitePackage.value ?? "")
        ?.albumRec()
        .then((value) {
          albumList.clear();
          albumList.addAll(value.data ?? []);

          // showComplete("操作成功");
        })
        .catchError((e) {
          // showError(e);
        });
  }

  ///获取新歌
  Future<Null>? getSongRec() {
    return ApiFactory.api(package: homeSitePackage.value ?? "")
        ?.songRec()
        .then((value) {
          songList.clear();
          songList.addAll(value.data ?? []);

          // showComplete("操作成功");
        })
        .catchError((e) {
          // showError(e);
        });
  }

  ///获取新歌
  Future<Null>? getMvRec() {
    return ApiFactory.api(package: homeSitePackage.value ?? "")
        ?.mvRec()
        .then((value) {
          mvList.clear();
          mvList.addAll(value.data ?? []);

          // showComplete("操作成功");
        })
        .catchError((e) {
          // showError(e);
        });
  }

  void installPlugin(String? path) {
    try {
      if (path != null) {
        File file = File(path);
        var plugins = parseExtension(file.readAsStringSync());
        if (plugins == null) {
          showError("插件无效");
        } else {
          AppDB.insertOrUpdate(table: Constant.KEY_EXTENSION, doc: JsonMapper.toMap(plugins)!, queryCondition: where("package").equals(plugins.package)).then((v) {
            showInfo("${plugins.name} 安装成功");
            initPlugins();
          });
        }
      } else {
        showError('文件不存在');
      }
    } catch (e) {
      showError('文件异常，可能不存在');
    }
  }

  Future<void> initPlugins() async {
    await ApiFactory.init();
    getData();
  }

  @override
  void onClose() {
    super.onClose();
    _intentSub.cancel();
  }
}
