import 'package:easy_refresh/easy_refresh.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/entity/mix_rank_type.dart';
import 'package:mix_music/entity/page_entity.dart';
import 'package:mix_music/entity/plugins_info.dart';
import 'package:mix_music/page/api_controller.dart';
import 'package:mix_music/utils/SubordinateScrollController.dart';
import 'package:mix_music/widgets/BlurRectWidget.dart';
import 'package:mix_music/widgets/message.dart';
import 'package:mix_music/widgets/page_sliver_view.dart';

import '../../entity/mix_rank.dart';
import '../../route/routes.dart';
import '../../widgets/app_image.dart';
import '../app_main/app_controller.dart';

class RankTabPage extends StatefulWidget {
  const RankTabPage({super.key, required this.plugin, required this.controller});

  final PluginsInfo plugin;
  final RankPageController controller;

  @override
  State<RankTabPage> createState() => _RankTabPageState();
}

class _RankTabPageState extends State<RankTabPage> with AutomaticKeepAliveClientMixin {
  late EasyRefreshController refreshController;
  ApiController api = Get.put(ApiController());
  var app = Get.put(AppController());
  Rxn<PageEntity> pageEntity = Rxn();
  RxList<MixRankType> rankTypeList = RxList();
  String? currentType;

  bool typeEmpty = false;

  @override
  void initState() {
    super.initState();
    widget.controller._addState(widget.plugin.site ?? "", this);
    refreshController = EasyRefreshController(controlFinishRefresh: true, controlFinishLoad: true);
    getRankList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(
        () => PageSliverView(
          controller: refreshController,
          onRefresh: () {
            return getRankList();
          },
          onLoad: () {
            return getRankList();
          },
          scrollController: SubordinateScrollController(context.findAncestorStateOfType<ExtendedNestedScrollViewState>()!.innerController),
          slivers: rankTypeList.map(_buildGroup).toList(),
        ),
      ),
    );
  }

  Widget _buildGroup(MixRankType rankTypes) {
    return SliverMainAxisGroup(slivers: [
      SliverPersistentHeader(
        pinned: true,
        delegate: _HeaderDelegate(rankTypes.title ?? ""),
      ),
      SliverGrid.extent(
        childAspectRatio: 1 / 1,
        maxCrossAxisExtent: 150,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: rankTypes.rankList
                ?.map(
                  (e) => InkWell(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    child: GridTile(
                      footer: BlurRectWidget(
                        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
                        child: Center(child: Text(e.title ?? "", maxLines: 1)),
                      ),
                      child: AppImage(url: e.pic ?? ""),
                    ),
                    onTap: () {
                      Get.toNamed(Routes.rankDetail, arguments: e, id: Routes.key);
                    },
                  ),
                )
                .toList() ??
            [],
      ),
    ]);
  }

  ///获取专辑
  Future<void> getRankList() {
    return api.rankList(site: widget.plugin.site!).then((value) {
      pageEntity.value = value.page;

      rankTypeList.clear();
      refreshController.finishRefresh(IndicatorResult.success, true);
      refreshController.finishLoad(IndicatorResult.noMore, true);
      rankTypeList.addAll(value.data ?? []);

      // showComplete("操作成功");
    }).catchError((e) {
      refreshController.finishRefresh(IndicatorResult.fail, true);

      showError(e);
    });
  }

  void open() {}

  void close() {}

  @override
  bool get wantKeepAlive => true;
}

class RankPageController {
  var pages = <String, _RankTabPageState?>{};

  void _addState(String name, _RankTabPageState _tabState) {
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

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  const _HeaderDelegate(this.title);

  final String title;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      alignment: Alignment.centerLeft,
      color: Theme.of(context).scaffoldBackgroundColor,
      height: 40,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  @override
  double get maxExtent => minExtent;

  @override
  double get minExtent => 40;

  @override
  bool shouldRebuild(covariant _HeaderDelegate oldDelegate) => title != oldDelegate.title;
}
