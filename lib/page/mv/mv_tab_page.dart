import 'package:easy_refresh/easy_refresh.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/entity/mix_artist.dart';
import 'package:mix_music/entity/mix_artist_type.dart';
import 'package:mix_music/entity/mix_mv.dart';
import 'package:mix_music/entity/mix_mv_type.dart';
import 'package:mix_music/entity/page_entity.dart';
import 'package:mix_music/entity/plugins_info.dart';
import 'package:mix_music/route/routes.dart';
import 'package:mix_music/utils/SubordinateScrollController.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/hyper/hyper_loading.dart';
import 'package:mix_music/widgets/message.dart';
import 'package:mix_music/widgets/page_grid_view.dart';

import '../../widgets/page_list_view.dart';

class MvTabPage extends StatefulWidget {
  const MvTabPage({super.key, required this.plugin, required this.controller});

  final PluginsInfo plugin;
  final ArtistController controller;

  @override
  State<MvTabPage> createState() => _MvTabPageState();
}

class _MvTabPageState extends State<MvTabPage> with AutomaticKeepAliveClientMixin {
  late EasyRefreshController refreshController;
  Rxn<PageEntity> pageEntity = Rxn();
  RxList<MixMv> artistList = RxList();
  RxList<MixMvType> artistType = RxList();
  final Map<String, dynamic> currentType = {};

  RxBool firstLoad = RxBool(true);

  @override
  void initState() {
    super.initState();
    widget.controller._addState(widget.plugin.package ?? "", this);
    refreshController = EasyRefreshController(controlFinishLoad: true, controlFinishRefresh: true);

    Future.delayed(const Duration(milliseconds: 300)).then((v) {
      getPlayListType();
      getPlayList(type: currentType);
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
            : PageGridView(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200, // 每个项目的最大宽度
                  childAspectRatio: 16 / 9,
                  crossAxisSpacing: 10, // 水平间距
                  mainAxisSpacing: 10, // 垂直间距
                ),
                controller: refreshController,
                onRefresh: () {
                  return getPlayList(type: currentType);
                },
                onLoad: () {
                  return getPlayList(type: currentType, page: pageEntity.value?.page ?? 0);
                },
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                scrollController: SubordinateScrollController(context.findAncestorStateOfType<ExtendedNestedScrollViewState>()!.innerController),
                itemCount: artistList.length,
                itemBuilder: (BuildContext context, int index) {
                  var item = artistList[index];
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

  ///获取歌单
  void getPlayList({Map<String, dynamic>? type, int page = 0}) {
    ApiFactory.api(package: widget.plugin.package!)?.mvList(type: type, page: page, size: 20).then((value) {
      firstLoad.value = false;
      pageEntity.value = value.page;
      if (page == 0) {
        artistList.clear();
        refreshController.finishRefresh();
      }
      Future.delayed(Duration(milliseconds: 200)).then((v) {
        refreshController.finishLoad(pageEntity.value?.last == false ? IndicatorResult.success : IndicatorResult.noMore, true);
      });

      artistList.addAll(value.data ?? []);

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

  ///获取歌单类型
  void getPlayListType() {
    ApiFactory.api(package: widget.plugin.package!)?.mvType().then((value) {
      artistType.clear();
      artistType.addAll(value.data ?? []);
    }).catchError((e) {
      showError(e);
    });
  }

  void open() {
    if (artistType.isEmpty) {
      getPlayListType();
    }
    showModalBottomSheet(
        context: context,
        showDragHandle: true,
        useSafeArea: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0), // 设置圆角的大小
        ),
        scrollControlDisabledMaxHeightRatio: 3 / 4,
        builder: (BuildContext context) {
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: artistType.length,
            itemBuilder: (BuildContext context, int index) {
              return buildItem(artistType[index]);
            },
          );
        }).then((value) {});
  }

  Widget buildItem(MixMvType type) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(title: Text(type.title ?? "")),
        Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            alignment: WrapAlignment.start,
            spacing: 8,
            runSpacing: 8,
            children: type.subType
                    ?.map((e) => ActionChip(
                          backgroundColor: currentType[type.id] == e.id ? Theme.of(context).colorScheme.primary.withOpacity(0.5) : null,
                          label: Text(e.title ?? ""),
                          onPressed: () {
                            currentType[type.id] = e.id;

                            getPlayList(type: currentType);

                            Navigator.of(context).pop();
                          },
                        ))
                    .toList() ??
                [],
          ),
        ),
      ],
    );
  }

  void close() {}

  @override
  bool get wantKeepAlive => true;
}

class ArtistController {
  var pages = <String, _MvTabPageState?>{};

  void _addState(String name, _MvTabPageState _tabState) {
    pages[name] = _tabState;
  }

  void open(String? name) {
    pages.forEach((key, value) {
      if (key != name) {
        value?.close();
      }
    });

    pages[name]?.open();
  }

  void close(String? name) {
    pages[name]?.close();
  }
}
