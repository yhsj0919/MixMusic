import 'package:easy_refresh/easy_refresh.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
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
import 'search_tab_State.dart';

class SearchMusicPage extends StatefulWidget {
  const SearchMusicPage({super.key, required this.plugin, required this.controller});

  final PluginsInfo plugin;

  final SearchPageController controller;

  @override
  SearchTabPageState<SearchMusicPage> createState() => _SearchMusicPageState();
}

class _SearchMusicPageState extends SearchTabPageState<SearchMusicPage> with AutomaticKeepAliveClientMixin {
  late EasyRefreshController refreshController;
  MusicController music = Get.put(MusicController());

  Rxn<PageEntity> pageEntity = Rxn();
  RxList<MixSong> songList = RxList();

  RxBool firstLoad = RxBool(true);

  @override
  void initState() {
    super.initState();
    widget.controller.addState(widget.plugin.package ?? "", this);
    refreshController = EasyRefreshController(controlFinishLoad: true, controlFinishRefresh: true);

    searchSong(keyword: widget.controller.keyword);
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
                  return searchSong(keyword: widget.controller.keyword);
                },
                onLoad: () {
                  return searchSong(keyword: widget.controller.keyword, page: pageEntity.value?.page ?? 0);
                },
                scrollController: SubordinateScrollController(context.findAncestorStateOfType<ExtendedNestedScrollViewState>()!.innerController),
                itemCount: songList.length,
                itemBuilder: (BuildContext context, int index) {
                  var song = songList[index];
                  return HyperSongItem(
                    song: song,
                    onTap: () {
                      music.playList(list: songList, index: index);
                    },
                  );
                },
              ),
      ),
    );
  }

  void searchSong({required String? keyword, int page = 0, int size = 20}) {
    if (keyword?.isNotEmpty != true) {
      refreshController.finishRefresh(IndicatorResult.success, true);
      refreshController.finishLoad(IndicatorResult.noMore, true);
      return;
    }
    ApiFactory.api(package: widget.plugin.package!)?.searchMusic(keyword: keyword ?? "", page: page, size: size).then((value) {
      firstLoad.value = false;
      pageEntity.value = value.page;
      if (page == 0) {
        songList.clear();
        refreshController.finishRefresh(IndicatorResult.success, true);
      }
      Future.delayed(Duration(milliseconds: 200)).then((v) {
        refreshController.finishLoad(pageEntity.value?.last == false ? IndicatorResult.success : IndicatorResult.noMore, true);
      });

      songList.addAll(value.data ?? []);

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
  void search({required String keyword}) {
    searchSong(keyword: keyword);
  }

  @override
  bool get wantKeepAlive => true;
}
