import 'package:easy_refresh/easy_refresh.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:mix_music/common/api/api_factory.dart';
import 'package:mix_music/common/entity/mix_album.dart';
import 'package:mix_music/common/entity/page_entity.dart';
import 'package:mix_music/common/entity/plugins_info.dart';
import 'package:mix_music/page/search/search_tab_State.dart';
import 'package:mix_music/player/music_controller.dart';
import 'package:mix_music/route/routes.dart';
import 'package:mix_music/widgets/fluent/HomeAlbumItem.dart';
import 'package:mix_music/widgets/hyper/hyper_loading.dart';
import 'package:mix_music/widgets/message.dart';
import 'package:mix_music/widgets/page_grid_view.dart';

class DesktopSearchAlbumPage extends StatefulWidget {
  const DesktopSearchAlbumPage({super.key, required this.plugin, required this.controller});

  final PluginsInfo plugin;

  final SearchPageController controller;

  @override
  SearchTabPageState<DesktopSearchAlbumPage> createState() => _DesktopSearchAlbumPageState();
}

class _DesktopSearchAlbumPageState extends SearchTabPageState<DesktopSearchAlbumPage> with AutomaticKeepAliveClientMixin {
  late EasyRefreshController refreshController;
  MusicController music = Get.put(MusicController());

  Rxn<PageEntity> pageEntity = Rxn();
  RxList<MixAlbum> songList = RxList();

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
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                controller: refreshController,
                onRefresh: () {
                  return searchSong(keyword: widget.controller.keyword);
                },
                onLoad: () {
                  return searchSong(keyword: widget.controller.keyword, page: pageEntity.value?.page ?? 0);
                },
                itemCount: songList.length,
                itemBuilder: (BuildContext context, int index) {
                  var item = songList[index];
                  return Center(
                    child: HomeAlbumItem(
                      item: item,
                      onTap: () {
                        context.go(Routes.albumDetail, extra: item);
                      },
                    ),
                  );
                },
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 180, // 每个元素的最大宽度
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                  childAspectRatio: 3.2 / 4,
                ),
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

    ApiFactory.api(package: widget.plugin.package!)
        ?.searchAlbum(keyword: keyword ?? "", page: page, size: size)
        .then((value) {
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
        })
        .catchError((e) {
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
