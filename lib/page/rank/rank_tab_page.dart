import 'package:easy_refresh/easy_refresh.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/entity/mix_rank_type.dart';
import 'package:mix_music/entity/page_entity.dart';
import 'package:mix_music/entity/plugins_info.dart';
import 'package:mix_music/utils/SubordinateScrollController.dart';
import 'package:mix_music/widgets/BlurRectWidget.dart';
import 'package:mix_music/widgets/hyper/hyper_loading.dart';
import 'package:mix_music/widgets/message.dart';
import 'package:mix_music/widgets/page_custom_scroll_view.dart';
import 'package:mix_music/widgets/page_nested_scroll_view.dart';
import 'package:sliver_tools/sliver_tools.dart';

import '../../entity/mix_rank.dart';
import '../../route/routes.dart';
import '../../widgets/app_image.dart';

class RankTabPage extends StatefulWidget {
  const RankTabPage({super.key, required this.plugin, required this.controller});

  final PluginsInfo plugin;
  final RankPageController controller;

  @override
  State<RankTabPage> createState() => _RankTabPageState();
}

class _RankTabPageState extends State<RankTabPage> with AutomaticKeepAliveClientMixin {
  late EasyRefreshController refreshController;
  Rxn<PageEntity> pageEntity = Rxn();
  RxList<MixRankType> rankTypeList = RxList();
  String? currentType;

  bool typeEmpty = false;

  RxBool firstLoad = RxBool(true);

  @override
  void initState() {
    super.initState();
    widget.controller._addState(widget.plugin.package ?? "", this);
    refreshController = EasyRefreshController(controlFinishRefresh: true, controlFinishLoad: true);
    Future.delayed(const Duration(milliseconds: 300)).then((v) {
      getRankList();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: PageCustomScrollView(
        controller: refreshController,
        onRefresh: () {
          return getRankList();
        },
        onLoad: () {
          return getRankList();
        },
        scrollController: SubordinateScrollController(context.findAncestorStateOfType<ExtendedNestedScrollViewState>()!.innerController),
        slivers: [
          Obx(() => SliverAnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              child: firstLoad.value
                  ? const SliverToBoxAdapter(
                      child: HyperLoading(height: 400),
                    )
                  : SliverMainAxisGroup(slivers: rankTypeList.map(_buildGroup).toList())))
        ],
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
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: GridTile(
                          footer: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                              alignment: Alignment.bottomRight,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  color: Theme.of(context).colorScheme.surfaceContainer,
                                  child: Text(
                                    "${e.title}",
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )),
                          child: Hero(tag: "${e.package}${e.id}${e.pic}", child: AppImage(url: e.pic ?? "", radius: 16)),
                        )),
                    onTap: () {
                      Get.toNamed(Routes.rankDetail, arguments: e);
                    },
                  ),
                )
                .toList() ??
            [],
      ),
    ]);
  }

  ///获取专辑
  void getRankList() {
    ApiFactory.api(package: widget.plugin.package!)?.rankList().then((value) {
      firstLoad.value = false;
      pageEntity.value = value.page;

      rankTypeList.clear();
      refreshController.finishRefresh(IndicatorResult.success, true);
      refreshController.finishLoad(IndicatorResult.noMore, true);
      rankTypeList.addAll(value.data ?? []);

      // showComplete("操作成功");
    }).catchError((e) {
      firstLoad.value = false;
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
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  @override
  double get maxExtent => minExtent;

  @override
  double get minExtent => 50;

  @override
  bool shouldRebuild(covariant _HeaderDelegate oldDelegate) => title != oldDelegate.title;
}
