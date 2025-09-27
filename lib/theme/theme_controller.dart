import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/common/entity/plugins_info.dart';
import 'package:mix_music/utils/db.dart';
import 'package:mix_music/utils/db.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

class ThemeController extends GetxController {
  Rxn<Color> customerColor = Rxn();
  Rxn<Brightness> themeBrightness = Rxn();
  Rx<fluent.ThemeMode> themeMode = Rx(fluent.ThemeMode.system);
  Rxn<Color> playingColor = Rxn();
  Rxn<Color> mainColor = Rxn();
  final RxMap<String, Color> _pluginColors = RxMap();

  Future<void> getColorScheme(String? image) async {
    if (image != null) {
      var ss = await ColorScheme.fromImageProvider(provider: CachedNetworkImageProvider(image));
      playingColor.value = ss.primary;
    }
  }

  Color? getColorByPackage(String? package) {
    return _pluginColors[package];
  }

  @override
  void onInit() {
    super.onInit();
    refreshMainColor();
  }

  Future<void> refreshMainColor() async {
    List<PluginsInfo> plugins = await AppDB.getList(Constant.KEY_EXTENSION);
    var package = AppDB.getString(Constant.KEY_HOME_SITE) ?? plugins.firstOrNull?.package;

    plugins.forEach((item) async {
      if (item.icon != null) {
        ColorScheme.fromImageProvider(provider: CachedNetworkImageProvider(item.icon ?? "")).then((v) {
          _pluginColors[item.package ?? ""] = v.primary;
          if (package == item.package) {
            mainColor.value = _pluginColors[package];
          }
        });
      }
    });
  }
}
