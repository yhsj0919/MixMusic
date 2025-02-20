import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/page/download/download_controller.dart';
import 'package:mix_music/page/setting/user_controller.dart';
import 'package:mix_music/page/timer/timer_close_controller.dart';
import 'package:mix_music/player/music_controller.dart';
import 'package:mix_music/theme/theme_controller.dart';

class AppBinding implements Bindings {
  @override
  Future<void> dependencies() async {
    ApiFactory.init();
    Get.put(ThemeController());
    Get.put(MusicController());
    Get.put(DownloadController());
    Get.put(TimeCloseController());
  }
}
