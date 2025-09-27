import 'package:easy_refresh/easy_refresh.dart';
import 'package:get/get.dart';
import 'package:mix_music/common/entity/mix_song.dart';
import 'package:mix_music/common/entity/page_entity.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/utils/db.dart';

class AppHistoryMusicController extends GetxController {
  RxList<MixSong> musicList = RxList();
  PageEntity dataPage = PageEntity.zero();
  late EasyRefreshController refreshController;

  @override
  void onInit() {
    super.onInit();
    refreshController = EasyRefreshController(controlFinishLoad: false, controlFinishRefresh: true);

    getHistory();
  }

  Future addHistory(MixSong music) async {
    await AppDB.insertOrUpdateWithIndex(
      Constant.KEY_APP_HISTORY_MUSIC_LIST,
      music,
      index: 0,
      check: (oldValue, newValue) {
        return oldValue.package == newValue.package && oldValue.id.toString() == newValue.id.toString();
      },
    );
    return getHistory();
  }

  Future getHistory() async {
    var list = await AppDB.getList<MixSong>(Constant.KEY_APP_HISTORY_MUSIC_LIST);

    musicList.clear();

    musicList.addAll(list);
    refreshController.finishRefresh();
    return Future.value();
  }

  Future<void> cleanHistory() async {
    await AppDB.removeAll(table: Constant.KEY_APP_HISTORY_MUSIC_LIST);
    getHistory();
  }
}
