import 'package:easy_refresh/easy_refresh.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:get/get.dart';
import 'package:mix_music/common/api/api_factory.dart';
import 'package:mix_music/common/entity/mix_mv.dart';
import 'package:mix_music/common/entity/mix_mv_type.dart';
import 'package:mix_music/common/entity/page_entity.dart';
import 'package:mix_music/common/entity/plugins_info.dart';
import 'package:mix_music/page/mv/desktop/desptop_mv_detail_page.dart';
import 'package:mix_music/route/routes.dart';
import 'package:mix_music/widgets/fluent/HomeMvItem.dart';
import 'package:mix_music/widgets/hyper/hyper_loading.dart';
import 'package:mix_music/widgets/message.dart';
import 'package:mix_music/widgets/page_grid_view.dart';

class DesktopMvTabPage extends StatefulWidget {
  const DesktopMvTabPage({super.key, required this.plugin, required this.controller});

  final PluginsInfo plugin;
  final MvController controller;

  @override
  State<DesktopMvTabPage> createState() => _DesktopMvTabPageState();
}

class _DesktopMvTabPageState extends State<DesktopMvTabPage> with AutomaticKeepAliveClientMixin {
  late EasyRefreshController refreshController;
  Rxn<PageEntity> pageEntity = Rxn();
  RxList<MixMv> mvList = RxList();
  RxList<MixMvType> mvType = RxList();
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
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),

                controller: refreshController,
                onRefresh: () {
                  return getPlayList(type: currentType);
                },
                onLoad: () {
                  return getPlayList(type: currentType, page: pageEntity.value?.page ?? 0);
                },
                itemCount: mvList.length,
                itemBuilder: (BuildContext context, int index) {
                  var item = mvList[index];
                  return Center(
                    child: HomeMvItem(
                      item: item,
                      onTap: () {
                        Navigator.of(context, rootNavigator: true).push(FluentPageRoute(builder: (context) => DesktopMvDetailPage(item: item)));
                      },
                    ),
                  );
                },
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 260, // 每个项目的最大宽度
                  childAspectRatio: 1.35,
                  crossAxisSpacing: 4, // 水平间距
                  mainAxisSpacing: 4, // 垂直间距
                ),
              ),
      ),
    );
  }

  ///获取歌单
  void getPlayList({Map<String, dynamic>? type, int page = 0}) {
    ApiFactory.api(package: widget.plugin.package!)
        ?.mvList(type: type, page: page, size: 20)
        .then((value) {
          firstLoad.value = false;
          pageEntity.value = value.page;
          if (page == 0) {
            mvList.clear();
            refreshController.finishRefresh();
          }
          Future.delayed(Duration(milliseconds: 200)).then((v) {
            refreshController.finishLoad(pageEntity.value?.last == false ? IndicatorResult.success : IndicatorResult.noMore, true);
          });

          mvList.addAll(value.data ?? []);

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

  ///获取歌单类型
  void getPlayListType() {
    ApiFactory.api(package: widget.plugin.package!)
        ?.mvType()
        .then((value) {
          mvType.clear();
          mvType.addAll(value.data ?? []);
        })
        .catchError((e) {
          showError(e);
        });
  }

  void open(FlyoutController controller) {
    if (mvType.isEmpty) {
      getPlayListType();
      return;
    }

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
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: mvType.length,
              itemBuilder: (BuildContext context, int index) {
                return buildItem(mvType[index]);
              },
            ),
          ),
        );
      },
    );
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
            children:
                type.subType
                    ?.map(
                      (e) => material.ActionChip(
                        label: Text(e.title ?? ""),
                        onPressed: () {
                          currentType[type.id] = e.id;

                          getPlayList(type: currentType);

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

class MvController {
  var pages = <String, _DesktopMvTabPageState?>{};

  void _addState(String name, _DesktopMvTabPageState _tabState) {
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
