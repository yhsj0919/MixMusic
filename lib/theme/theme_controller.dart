import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ThemeController extends GetxController {
  Rxn<Color> customerColor = Rxn();
  Rxn<Brightness> themeBrightness = Rxn();
  Rxn<Color> playingColor = Rxn();

  Future<void> getColorScheme(String? image) async {
    if (image != null) {
      var ss = await ColorScheme.fromImageProvider(provider: CachedNetworkImageProvider(image));
      playingColor.value = ss.primary;
    }
  }
}
