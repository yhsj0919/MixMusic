import 'package:easy_refresh/easy_refresh.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/entity/mix_album.dart';
import 'package:mix_music/entity/mix_mv.dart';
import 'package:mix_music/entity/mix_play_list.dart';
import 'package:mix_music/entity/page_entity.dart';
import 'package:mix_music/entity/plugins_info.dart';
import 'package:mix_music/player/music_controller.dart';
import 'package:mix_music/route/routes.dart';
import 'package:mix_music/utils/SubordinateScrollController.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/hyper/hyper_loading.dart';
import 'package:mix_music/widgets/message.dart';
import 'package:mix_music/widgets/page_grid_view.dart';

import '../../widgets/page_list_view.dart';
import 'search_tab_State.dart';

class SearchMvPage extends StatefulWidget {
  const SearchMvPage({super.key, required this.plugin, required this.controller});

  final PluginsInfo plugin;

  final SearchPageController controller;

  @override
  SearchTabPageState<SearchMvPage> createState() => _SearchMvPageState();
}

class _SearchMvPageState extends SearchTabPageState<SearchMvPage> with AutomaticKeepAliveClientMixin {
  late EasyRefreshController refreshController;
  MusicController music = Get.put(MusicController());

  Rxn<PageEntity> pageEntity = Rxn();
  RxList<MixMv> songList = RxList();

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
            : PageGridView(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200, // 每个项目的最大宽度
                  childAspectRatio: 16 / 9,
                  crossAxisSpacing: 10, // 水平间距
                  mainAxisSpacing: 10, // 垂直间距
                ),
                controller: refreshController,
                onRefresh: () {
                  return searchSong(keyword: widget.controller.keyword);
                },
                onLoad: () {
                  return searchSong(keyword: widget.controller.keyword, page: pageEntity.value?.page ?? 0);
                },
                scrollController: SubordinateScrollController(context.findAncestorStateOfType<ExtendedNestedScrollViewState>()!.innerController),
                itemCount: songList.length,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemBuilder: (BuildContext context, int index) {
                  var item = songList[index];
                  return InkWell(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Hero(
                          tag: "${item.package}${item.id}${item.pic}",
                          child: AppImage(url: item.pic ?? "", width: double.infinity, height: double.infinity, radius: 12),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              color: Theme.of(context).colorScheme.surfaceContainer.withAlpha(200),
                              child: Text(
                                "${item.title}",
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 10),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                    onTap: () {
                      Get.toNamed(Routes.mvDetail, arguments: item);
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
    if (page == 0) {
      dataLoad.value = true;
    }

    ApiFactory.api(package: widget.plugin.package!)?.searchMv(keyword: keyword ?? "", page: page, size: size).then((value) {
      dataLoad.value = false;
      pageEntity.value = value.page;
      if (page == 0) {
        songList.clear();
        refreshController.finishRefresh();
      }
      Future.delayed(Duration(milliseconds: 200)).then((v) {
        refreshController.finishLoad(pageEntity.value?.last == false ? IndicatorResult.success : IndicatorResult.noMore, true);
      });

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
