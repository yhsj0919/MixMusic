import 'package:get/get.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/entity/mix_song.dart';
import 'package:mix_music/utils/sp.dart';

class AppHistoryMusicController extends GetxController {
  RxList<MixSong> musicList = RxList();

  @override
  void onInit() {
    super.onInit();
    getHistory();
  }

  Future getHistory() {
    var list = Sp.getList<MixSong>(Constant.KEY_APP_HISTORY_MUSIC_LIST) ?? [];

    musicList.clear();
    musicList.addAll(list);
    return Future.value();
  }

  void cleanHistory() {
    Sp.remove(Constant.KEY_APP_HISTORY_MUSIC_LIST);
    getHistory();
  }
}
