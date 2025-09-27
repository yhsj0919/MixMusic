import 'package:easy_refresh/easy_refresh.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:mix_music/common/api/api_factory.dart';
import 'package:mix_music/common/entity/mix_album.dart';
import 'package:mix_music/common/entity/mix_album_type.dart';
import 'package:mix_music/common/entity/page_entity.dart';
import 'package:mix_music/common/entity/plugins_info.dart';
import 'package:mix_music/route/routes.dart';
import 'package:mix_music/widgets/fluent/HomeAlbumItem.dart';
import 'package:mix_music/widgets/hyper/hyper_loading.dart';
import 'package:mix_music/widgets/message.dart';
import 'package:mix_music/widgets/page_grid_view.dart';

class DesktopAlbumTabPage extends StatefulWidget {
  const DesktopAlbumTabPage({super.key, required this.plugin, required this.controller});

  final PluginsInfo plugin;
  final AlbumPageController controller;

  @override
  State<DesktopAlbumTabPage> createState() => _DesktopAlbumTabPageState();
}

class _DesktopAlbumTabPageState extends State<DesktopAlbumTabPage> with AutomaticKeepAliveClientMixin {
  late EasyRefreshController refreshController;
  Rxn<PageEntity> pageEntity = Rxn();
  RxList<MixAlbum> albumList = RxList();
  RxList<MixAlbumType> albumType = RxList();
  MixAlbumType? currentType;

  // bool typeEmpty = false;
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
            : PageGridView(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),

                controller: refreshController,
                onRefresh: () {
                  return getAlbumList(type: currentType);
                },
                onLoad: () {
                  return getAlbumList(type: currentType, page: pageEntity.value?.page ?? 0);
                },
                itemCount: albumList.length,
                itemBuilder: (BuildContext context, int index) {
                  var item = albumList[index];
                  return Center(
                    child: HomeAlbumItem(
                      item: item,
                      onTap: () {
                        context.push(Routes.albumDetail, extra: item);
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

  ///获取专辑
  void getAlbumList({MixAlbumType? type, int page = 0}) {
    ApiFactory.api(package: widget.plugin.package ?? "")
        ?.albumList(type: type, page: page, size: 20)
        .then((value) {
          firstLoad.value = false;
          pageEntity.value = value.page;
          if (page == 0) {
            albumList.clear();
            refreshController.finishRefresh();
          }
          Future.delayed(Duration(milliseconds: 200)).then((v) {
            refreshController.finishLoad(pageEntity.value?.last == false ? IndicatorResult.success : IndicatorResult.noMore, true);
          });

          albumList.addAll(value.data ?? []);

          // showComplete("操作成功");
        })
        .catchError((e) {
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
    ApiFactory.api(package: widget.plugin.package ?? "")
        ?.albumType()
        .then((value) {
          albumType.clear();
          albumType.addAll(value.data ?? []);

          // typeEmpty = albumType.isEmpty;
        })
        .catchError((e) {
          print(e);
          showError(e);
        });
  }

  void open(FlyoutController controller) {
    if (albumType.isEmpty ) {
      getAlbumType();
    }
    // if (typeEmpty) {
    //   showFluentInfo(context, "暂无分类");
    //   return;
    // }

    controller.showFlyout(
      autoModeConfiguration: FlyoutAutoConfiguration(preferredMode: FlyoutPlacementMode.bottomCenter),
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      dismissOnPointerMoveAway: false,
      dismissWithEsc: true,
      navigatorKey: Routes.rootNavigatorKey.currentState,
      builder: (context) {
        return FlyoutContent(
          child: Container(
            width: 400,
            height: MediaQuery.of(context).size.height - 318,
            child: ListView.builder(
              // shrinkWrap: true,
              itemCount: albumType.length,
              itemBuilder: (BuildContext context, int index) {
                return buildItem(albumType[index]);
              },
            ),
          ),
        );
      },
    );
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
            children:
                type.subType
                    ?.map(
                      (e) => material.ActionChip(
                        label: Text(e.title ?? ""),
                        onPressed: () {
                          currentType = e;

                          getAlbumList(type: e);

                          Routes.rootNavigatorKey.currentState?.pop();
                        },
                      ),
                    )
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
  var pages = <String, _DesktopAlbumTabPageState?>{};

  void _addState(String name, _DesktopAlbumTabPageState _tabState) {
    pages[name] = _tabState;
  }

  void open(String? name, FlyoutController controller) {
    pages.forEach((key, value) {
      if (key != name) {
        value?.close();
      }
    });

    pages[name]?.open(controller);
  }

  void close(String? name) {
    pages[name]?.close();
  }
}
