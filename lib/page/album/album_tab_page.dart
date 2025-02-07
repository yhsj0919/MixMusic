import 'dart:math';

import 'package:easy_refresh/easy_refresh.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/entity/mix_album.dart';
import 'package:mix_music/entity/mix_album_type.dart';
import 'package:mix_music/entity/page_entity.dart';
import 'package:mix_music/entity/plugins_info.dart';
import 'package:mix_music/route/routes.dart';
import 'package:mix_music/utils/SubordinateScrollController.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/hyper/hyper_loading.dart';
import 'package:mix_music/widgets/message.dart';

import '../../widgets/page_list_view.dart';

class AlbumTabPage extends StatefulWidget {
  const AlbumTabPage({super.key, required this.plugin, required this.controller});

  final PluginsInfo plugin;
  final AlbumPageController controller;

  @override
  State<AlbumTabPage> createState() => _AlbumTabPageState();
}

class _AlbumTabPageState extends State<AlbumTabPage> with AutomaticKeepAliveClientMixin {
  late EasyRefreshController refreshController;
  Rxn<PageEntity> pageEntity = Rxn();
  RxList<MixAlbum> albumList = RxList();
  RxList<MixAlbumType> albumType = RxList();
  MixAlbumType? currentType;

  bool typeEmpty = false;
  RxBool firstLoad = RxBool(true);

  @override
  void initState() {
    super.initState();
    widget.controller._addState(widget.plugin.package ?? "", this);
    refreshController = EasyRefreshController(controlFinishRefresh: true, controlFinishLoad: true);
    Future.delayed(const Duration(milliseconds: 300)).then((v) {
      getAlbumList();
      getAlbumType();
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
                    return getAlbumList(type: currentType);
                  },
                  onLoad: () {
                    return getAlbumList(type: currentType, page: pageEntity.value?.page ?? 0);
                  },
                  scrollController: SubordinateScrollController(context.findAncestorStateOfType<ExtendedNestedScrollViewState>()!.innerController),
                  itemCount: albumList.length,
                  itemBuilder: (BuildContext context, int index) {
                    var item = albumList[index];
                    return ListTile(
                      leading: Hero(tag: "${item.package}${item.id}${item.pic}", child: AppImage(url: item.pic ?? "")),
                      title: Text("${item.title}", maxLines: 1),
                      subtitle: Text("${item.subTitle}", maxLines: 1),
                      onTap: () {
                        Get.toNamed(Routes.albumDetail, arguments: item);
                      },
                    );
                  },
                )),
    );
  }

  ///获取专辑
  void getAlbumList({MixAlbumType? type, int page = 0}) {
    ApiFactory.api(package: widget.plugin.package ?? "")?.albumList(type: type, page: page, size: 20).then((value) {
      firstLoad.value = false;
      pageEntity.value = value.page;
      if (page == 0) {
        albumList.clear();
        refreshController.finishRefresh();
      }
      refreshController.finishLoad(pageEntity.value?.last == false ? IndicatorResult.success : IndicatorResult.noMore, true);

      albumList.addAll(value.data ?? []);

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

  ///获取专辑类型
  void getAlbumType() {
    ApiFactory.api(package: widget.plugin.package ?? "")?.albumType().then((value) {
      albumType.clear();
      albumType.addAll(value.data ?? []);

      typeEmpty = albumType.isEmpty;
    }).catchError((e) {
      print(e);
      showError(e);
    });
  }

  void open() {
    if (albumType.isEmpty && !typeEmpty) {
      getAlbumType();
    }
    if (typeEmpty) {
      showInfo("暂无分类");
      return;
    }
    showModalBottomSheet(
        context: context,
        elevation: 0,
        // barrierColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        scrollControlDisabledMaxHeightRatio: 3 / 4,
        builder: (BuildContext context) {
          double statusBarHeight = max(MediaQuery.of(context).padding.top, 16);
          double bottom = max(MediaQuery.of(context).padding.bottom, 16);
          return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 12.0,
                    color: Theme.of(context).shadowColor.withOpacity(0.3),
                  ),
                ],
              ),
              // margin: const EdgeInsets.all(16),
              child: ListView.builder(
                // shrinkWrap: true,
                padding: EdgeInsets.only(bottom: bottom),
                itemCount: albumType.length,
                itemBuilder: (BuildContext context, int index) {
                  return buildItem(albumType[index]);
                },
              ));
        }).then((value) {});
  }

  Widget buildItem(MixAlbumType type) {
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
                          label: Text(e.title ?? ""),
                          onPressed: () {
                            currentType = e;

                            getAlbumList(type: e);

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

class AlbumPageController {
  var pages = <String, _AlbumTabPageState?>{};

  void _addState(String name, _AlbumTabPageState _tabState) {
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
