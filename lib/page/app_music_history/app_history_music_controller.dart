import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:get/get.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/entity/mix_song.dart';
import 'package:mix_music/entity/page_entity.dart';
import 'package:mix_music/utils/sp.dart';

class AppHistoryMusicController extends GetxController {
  RxList<MixSong> musicList = RxList();
  PageEntity dataPage = PageEntity.zero();
  late EasyRefreshController refreshController;

  @override
  void onInit() {
    super.onInit();
    refreshController = EasyRefreshController(controlFinishLoad: true, controlFinishRefresh: true);

    getHistory(0);
  }

  Future getHistory(int page, {int size = 20}) {
    var list = Sp.getStringList(Constant.KEY_APP_HISTORY_MUSIC_LIST) ?? <String>[];

    int startIndex = page * size;
    int endIndex = startIndex + size;

    if (page == 0) {
      musicList.clear();
      refreshController.finishRefresh();
    }

    if (startIndex < list.length) {
      var ss = list.sublist(startIndex, endIndex.clamp(0, list.length));

      musicList.addAll(ss.map((e) => JsonMapper.fromJson<MixSong>(e)!));
    }

    // 检查是否还有更多数据
    var more = musicList.length < list.length;

    dataPage.first = page == 0;
    dataPage.last = !more;
    dataPage.page = page + 1;
    dataPage.size = size;

    Future.delayed(Duration(milliseconds: 200)).then((v) {
      refreshController.finishLoad(dataPage.last == false ? IndicatorResult.success : IndicatorResult.noMore, true);
    });
    return Future.value();
  }

  void cleanHistory() {
    Sp.remove(Constant.KEY_APP_HISTORY_MUSIC_LIST);
    getHistory(0);
  }
}
