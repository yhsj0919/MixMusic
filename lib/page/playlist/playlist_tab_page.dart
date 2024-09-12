import 'package:easy_refresh/easy_refresh.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/entity/mix_play_list.dart';
import 'package:mix_music/entity/mix_play_list_type.dart';
import 'package:mix_music/entity/page_entity.dart';
import 'package:mix_music/entity/plugins_info.dart';
import 'package:mix_music/route/routes.dart';
import 'package:mix_music/utils/SubordinateScrollController.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/message.dart';

import '../../widgets/page_list_view.dart';

class PlayListTabPage extends StatefulWidget {
  const PlayListTabPage({super.key, required this.plugin, required this.controller});

  final PluginsInfo plugin;
  final PlayListPageController controller;

  @override
  State<PlayListTabPage> createState() => _PlayListTabPageState();
}

class _PlayListTabPageState extends State<PlayListTabPage> with AutomaticKeepAliveClientMixin {
  late EasyRefreshController refreshController;
  Rxn<PageEntity> pageEntity = Rxn();
  RxList<MixPlaylist> playlist = RxList();
  RxList<MixPlaylistType> playlistType = RxList();
  String? currentType;

  @override
  void initState() {
    super.initState();
    widget.controller._addState(widget.plugin.package ?? "", this);
    refreshController = EasyRefreshController(controlFinishLoad: true, controlFinishRefresh: true);
    getPlayList();
    getPlayListType();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Obx(
      () => PageListView(
        controller: refreshController,
        onRefresh: () {
          return getPlayList(type: currentType);
        },
        onLoad: () {
          return getPlayList(type: currentType, page: pageEntity.value?.page ?? 0);
        },
        scrollController: SubordinateScrollController(context.findAncestorStateOfType<ExtendedNestedScrollViewState>()!.innerController),
        itemCount: playlist.length,
        itemBuilder: (BuildContext context, int index) {
          var item = playlist[index];
          return ListTile(
            leading: AppImage(url: item.pic ?? ""),
            title: Text("${item.title}", maxLines: 1),
            subtitle: Text("${item.subTitle}", maxLines: 1),
            onTap: () {
              Get.toNamed(Routes.playListDetail, arguments: item);
            },
          );
        },
      ),
    );
  }

  ///获取歌单
  void getPlayList({String? type, int page = 0}) {
    ApiFactory.api(package: widget.plugin.package!)?.playList(type: type, page: page, size: 20).then((value) {
      pageEntity.value = value.page;
      if (page == 0) {
        playlist.clear();
        refreshController.finishRefresh();
      }
      refreshController.finishLoad((pageEntity.value?.last != null && pageEntity.value?.last == true) ? IndicatorResult.noMore : IndicatorResult.success, true);

      if (pageEntity.value != null) {
        playlist.addAll(value.data ?? []);
      }
      // showComplete("操作成功");
    }).catchError((e) {
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
    ApiFactory.api(package: widget.plugin.package!)?.playListType().then((value) {
      playlistType.clear();
      playlistType.addAll(value.data ?? []);
    }).catchError((e) {
      showError(e);
    });
  }

  void open() {
    if (playlistType.isEmpty) {
      getPlayListType();
    }
    showModalBottomSheet(
        context: context,
        elevation: 0,
        // barrierColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        scrollControlDisabledMaxHeightRatio: 3 / 4,
        builder: (BuildContext context) {
          return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 12.0,
                    color: Theme.of(context).shadowColor.withOpacity(0.1),
                  ),
                ],
              ),
              margin: const EdgeInsets.all(16),
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: playlistType.length,
                itemBuilder: (BuildContext context, int index) {
                  return buildItem(playlistType[index]);
                },
              ));
        }).then((value) {});
  }

  Widget buildItem(MixPlaylistType type) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(title: Text(type.name ?? "")),
        Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            alignment: WrapAlignment.start,
            spacing: 8,
            runSpacing: 8,
            children: type.subType
                    ?.map((e) => ActionChip(
                          label: Text(e.name ?? ""),
                          onPressed: () {
                            currentType = e.id.toString();

                            getPlayList(type: e.id.toString());

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

class PlayListPageController {
  var pages = <String, _PlayListTabPageState?>{};

  void _addState(String name, _PlayListTabPageState _tabState) {
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
