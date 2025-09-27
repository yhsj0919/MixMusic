import 'package:easy_refresh/easy_refresh.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:mix_music/common/api/api_factory.dart';
import 'package:mix_music/common/entity/mix_artist.dart';
import 'package:mix_music/common/entity/mix_artist_type.dart';
import 'package:mix_music/common/entity/page_entity.dart';
import 'package:mix_music/common/entity/plugins_info.dart';
import 'package:mix_music/route/routes.dart';
import 'package:mix_music/widgets/fluent/HomeArtistItem.dart';
import 'package:mix_music/widgets/hyper/hyper_loading.dart';
import 'package:mix_music/widgets/message.dart';
import 'package:mix_music/widgets/page_grid_view.dart';

class DesktopArtistTabPage extends StatefulWidget {
  const DesktopArtistTabPage({super.key, required this.plugin, required this.controller});

  final PluginsInfo plugin;
  final ArtistController controller;

  @override
  State<DesktopArtistTabPage> createState() => _DesktopArtistTabPageState();
}

class _DesktopArtistTabPageState extends State<DesktopArtistTabPage> with AutomaticKeepAliveClientMixin {
  late EasyRefreshController refreshController;
  Rxn<PageEntity> pageEntity = Rxn();
  RxList<MixArtist> artistList = RxList();
  RxList<MixArtistType> artistType = RxList();
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
                itemCount: artistList.length,
                itemBuilder: (BuildContext context, int index) {
                  var item = artistList[index];
                  return Center(
                    child: HomeArtistItem(
                      item: item,
                      onTap: () {
                        context.push(Routes.artistDetail, extra: item);
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

  ///获取歌单
  void getPlayList({Map<String, dynamic>? type, int page = 0}) {
    ApiFactory.api(package: widget.plugin.package!)
        ?.artistList(type: type, page: page, size: 20)
        .then((value) {
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
        ?.artistType()
        .then((value) {
          artistType.clear();
          artistType.addAll(value.data ?? []);
        })
        .catchError((e) {
          showError(e);
        });
  }

  void open(FlyoutController controller) {
    if (artistType.isEmpty) {
      getPlayListType();
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
              // shrinkWrap: true,
              itemCount: artistType.length,
              itemBuilder: (BuildContext context, int index) {
                return buildItem(artistType[index]);
              },
            ),
          ),
        );
      },
    );
  }

  Widget buildItem(MixArtistType type) {
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
                        backgroundColor: currentType[type.id] == e.id ? material.Theme.of(context).colorScheme.primary.withOpacity(0.5) : null,
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

class ArtistController {
  var pages = <String, _DesktopArtistTabPageState?>{};

  void _addState(String name, _DesktopArtistTabPageState _tabState) {
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
