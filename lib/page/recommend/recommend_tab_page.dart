import 'package:easy_refresh/easy_refresh.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/entity/mix_play_list_type.dart';
import 'package:mix_music/entity/mix_song.dart';
import 'package:mix_music/entity/page_entity.dart';
import 'package:mix_music/entity/plugins_info.dart';
import 'package:mix_music/player/music_controller.dart';
import 'package:mix_music/route/routes.dart';
import 'package:mix_music/utils/SubordinateScrollController.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/hyper/hyper_loading.dart';
import 'package:mix_music/widgets/hyper/hyper_song_item.dart';
import 'package:mix_music/widgets/message.dart';

import '../../widgets/page_list_view.dart';

class RecommendTabPage extends StatefulWidget {
  const RecommendTabPage({super.key, required this.plugin});

  final PluginsInfo plugin;

  @override
  State<RecommendTabPage> createState() => _RecommendTabPageState();
}

class _RecommendTabPageState extends State<RecommendTabPage> with AutomaticKeepAliveClientMixin {
  late EasyRefreshController refreshController;
  Rxn<PageEntity> pageEntity = Rxn();

  // RxList<MixPlaylist> playlist = RxList();
  RxList<MixSong> songList = RxList();

  RxList<MixPlaylistType> playlistType = RxList();
  RxBool firstLoad = RxBool(true);

  bool typeEmpty = false;
  MusicController music = Get.put(MusicController());

  @override
  void initState() {
    super.initState();
    refreshController = EasyRefreshController(controlFinishLoad: true, controlFinishRefresh: true);
    Future.delayed(const Duration(milliseconds: 300)).then((v) {
      getPlayList();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Obx(
      () => AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          child: firstLoad.value
              ? const HyperLoading()
              : PageListView(
                  controller: refreshController,
                  onRefresh: () {
                    return getPlayList();
                  },
                  onLoad: () {
                    return getPlayList(page: pageEntity.value?.page ?? 0);
                  },
                  scrollController: SubordinateScrollController(context.findAncestorStateOfType<ExtendedNestedScrollViewState>()!.innerController),
                  itemCount: songList.length,
                  itemBuilder: (BuildContext context, int index) {
                    var item = songList[index];
                    return HyperSongItem(
                      song: item,
                      onTap: () {
                        music.playList(list: songList, index: index);
                      },
                    );
                  },
                )),
    );
  }

  ///获取歌单
  void getPlayList({int page = 0}) {
    ApiFactory.api(package: widget.plugin.package!)?.recommendInfo(page: page, size: 20).then((value) {
      firstLoad.value = false;
      pageEntity.value = value.page;
      if (page == 0) {
        songList.clear();
        refreshController.finishRefresh();
      }
      Future.delayed(Duration(milliseconds: 200)).then((v) {
        refreshController.finishLoad(pageEntity.value?.last == false ? IndicatorResult.success : IndicatorResult.noMore, true);
      });
      songList.addAll(value.data?.songs ?? []);

      // showComplete("操作成功");
    }).catchError((e) {
      firstLoad.value = false;
      if (page == 0) {
        refreshController.finishRefresh(IndicatorResult.fail, true);
      } else {
        refreshController.finishLoad(IndicatorResult.fail, true);
      }
      showError(e);
    });
  }

  @override
  bool get wantKeepAlive => true;
}
