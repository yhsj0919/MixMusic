import 'package:easy_refresh/easy_refresh.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/entity/mix_song.dart';
import 'package:mix_music/entity/page_entity.dart';
import 'package:mix_music/entity/plugins_info.dart';
import 'package:mix_music/player/music_controller.dart';
import 'package:mix_music/utils/SubordinateScrollController.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/hyper/hyper_loading.dart';
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

  RxBool dataLoad = RxBool(false);

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
        child: dataLoad.value
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
                  return Obx(() => ListTile(
                        selected: music.currentMusic.value?.id == song.id,
                        leading: AppImage(url: song.pic ?? ""),
                        title: Row(
                          children: [
                            Flexible(child: Text(song.title ?? "", maxLines: 1, overflow: TextOverflow.ellipsis)),
                            song.vip == 1
                                ? Container(
                                    alignment: Alignment.center,
                                    margin: const EdgeInsets.symmetric(horizontal: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                                      border: Border.all(width: 1, color: Colors.green),
                                    ),
                                    child: const Text("VIP", maxLines: 1, style: TextStyle(fontSize: 10, color: Colors.green)),
                                  )
                                : Container(),
                          ],
                        ),
                        subtitle: Text(song.subTitle ?? "", overflow: TextOverflow.ellipsis, maxLines: 1),
                        onTap: () {
                          music.playList(list: songList, index: index);
                        },
                      ));
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
    if (page == 0) {
      dataLoad.value = true;
    }

    ApiFactory.api(package: widget.plugin.package!)?.searchMusic(keyword: keyword ?? "", page: page, size: size).then((value) {
      dataLoad.value = false;
      pageEntity.value = value.page;
      if (page == 0) {
        songList.clear();
        refreshController.finishRefresh();
      }
      refreshController.finishLoad((pageEntity.value?.last != null && pageEntity.value?.last == true) ? IndicatorResult.noMore : IndicatorResult.success, true);

      songList.addAll(value.data ?? []);
      // showComplete("操作成功");
    }).catchError((e) {
      dataLoad.value = false;

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
