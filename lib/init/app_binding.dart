import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/player/music_controller.dart';

class AppBinding implements Bindings {
  @override
  Future<void> dependencies() async {
    ApiFactory.init();
    Get.put(MusicController());
  }
}
