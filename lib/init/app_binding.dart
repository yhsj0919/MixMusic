import 'package:get/get.dart';
import 'package:mix_music/page/api_controller.dart';
import 'package:mix_music/player/music_controller.dart';

class AppBinding implements Bindings {
  @override
  void dependencies() {
    Get.put(ApiController());
    Get.put(MusicController());
  }
}
