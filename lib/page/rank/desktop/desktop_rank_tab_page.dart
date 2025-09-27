import 'package:easy_refresh/easy_refresh.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:mix_music/common/api/api_factory.dart';
import 'package:mix_music/common/entity/mix_rank_type.dart';
import 'package:mix_music/common/entity/page_entity.dart';
import 'package:mix_music/common/entity/plugins_info.dart';
import 'package:mix_music/route/routes.dart';
import 'package:mix_music/utils/SubordinateScrollController.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/fluent/HomeRankItem.dart';
import 'package:mix_music/widgets/hyper/hyper_loading.dart';
import 'package:mix_music/widgets/message.dart';
import 'package:mix_music/widgets/page_custom_scroll_view.dart';
import 'package:sliver_tools/sliver_tools.dart';

class DesktopRankTabPage extends StatefulWidget {
  const DesktopRankTabPage({super.key, required this.plugin, required this.controller});

  final PluginsInfo plugin;
  final RankPageController controller;

  @override
  State<DesktopRankTabPage> createState() => _DesktopRankTabPageState();
}

class _DesktopRankTabPageState extends State<DesktopRankTabPage> with AutomaticKeepAliveClientMixin {
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
        slivers: [
          Obx(
            () => SliverAnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              child: firstLoad.value ? const SliverToBoxAdapter(child: HyperLoading(height: 400)) : SliverMainAxisGroup(slivers: rankTypeList.map(_buildGroup).toList()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroup(MixRankType rankTypes) {
    return SliverMainAxisGroup(
      slivers: [
        SliverPersistentHeader(pinned: true, delegate: _HeaderDelegate(rankTypes.title ?? "")),
        SliverGrid.extent(
          childAspectRatio: 160 / 182,
          maxCrossAxisExtent: 160,
          crossAxisSpacing: 4,
          mainAxisSpacing: 8,
          children:
              rankTypes.rankList
                  ?.map(
                    (e) => HomeRankItem(
                      onTap: () {
                        context.push(Routes.rankDetail, extra: e);
                      },
                      item: e,
                    ),
                  )
                  .toList() ??
              [],
        ),
      ],
    );
  }

  ///获取专辑
  void getRankList() {
    ApiFactory.api(package: widget.plugin.package!)
        ?.rankList()
        .then((value) {
          firstLoad.value = false;
          pageEntity.value = value.page;

          rankTypeList.clear();
          refreshController.finishRefresh(IndicatorResult.success, true);
          refreshController.finishLoad(IndicatorResult.noMore, true);
          rankTypeList.addAll(value.data ?? []);

          // showComplete("操作成功");
        })
        .catchError((e) {
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
  var pages = <String, _DesktopRankTabPageState?>{};

  void _addState(String name, _DesktopRankTabPageState _tabState) {
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
      decoration: BoxDecoration(
        color: FluentTheme.of(context).brightness == Brightness.light ? Colors.white : Color(0xff1a2227),
        borderRadius: BorderRadius.circular(4), // 圆角半径
      ),
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      margin: EdgeInsets.symmetric(horizontal: 4),

      child: Text(title, style: FluentTheme.of(context).typography.subtitle),
    );
  }

  @override
  double get maxExtent => minExtent;

  @override
  double get minExtent => 50;

  @override
  bool shouldRebuild(covariant _HeaderDelegate oldDelegate) => true;
}
