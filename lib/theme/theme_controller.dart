import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/entity/plugins_info.dart';
import 'package:mix_music/utils/sp.dart';

class ThemeController extends GetxController {
  Rxn<Color> customerColor = Rxn();
  Rxn<Brightness> themeBrightness = Rxn();
  Rxn<Color> playingColor = Rxn();
  RxMap<String, Color> pluginColors = RxMap();

  Future<void> getColorScheme(String? image) async {
    if (image != null) {
      var ss = await ColorScheme.fromImageProvider(provider: CachedNetworkImageProvider(image));
      playingColor.value = ss.primary;
    }
  }

  @override
  void onInit() {
    super.onInit();
    intPluginsColors();
  }

  Future<void> intPluginsColors() async {
    List<PluginsInfo> plugins = Sp.getList(Constant.KEY_EXTENSION) ?? [];

    plugins.forEach((item) async {
      if (item.icon != null) {
       ColorScheme.fromImageProvider(provider: CachedNetworkImageProvider(item.icon ?? "")).then((v){
         pluginColors[item.package ?? ""] = v.primary;
         print('${item.name}初始化颜色');

       });

      }
    });
  }
}
