import 'dart:io';

import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/api/common_api.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/entity/mix_download.dart';
import 'package:mix_music/entity/mix_user.dart';
import 'package:mix_music/entity/plugins_info.dart';
import 'package:mix_music/utils/sp.dart';

import '../../widgets/message.dart';

class UserController extends GetxController {
  List<PluginsInfo> plugins = [];
  RxMap<String, MixUser> userInfos = RxMap<String, MixUser>();

  @override
  onInit() {
    super.onInit();
    plugins = ApiFactory.getUserPlugins();
  }

  Future<void> getAllUser() async {
    print(plugins);

    userInfos.clear();
    var value = await Future.wait(plugins.map((e) => userInfo(package: e.package ?? "")));

    print(value);

    value.where((element) => element != null).toList().forEach((e) {
      userInfos[e?.package ?? ""] = e!;
    });
  }

  Future<List> refreshAllCookie() async {
    userInfos.clear();
    return await Future.wait(plugins.map((e) => refreshCookie(package: e.package ?? "")));
  }

  Future<dynamic> refreshCookie({required String package}) async {
    try {
      var value = await ApiFactory.api(package: package)?.userRefresh();
      return value?.data;
    } catch (e) {
      return null;
    }
  }

  Future<MixUser?> userInfo({required String package}) async {
    try {
      var value = await ApiFactory.api(package: package)?.userInfo();
      return value?.data;
    } catch (e) {
      return null;
    }
  }
}
