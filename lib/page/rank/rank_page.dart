import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/entity/plugins_info.dart';
import 'package:mix_music/page/app_playing/play_bar.dart';
import 'package:mix_music/widgets/hyper/hyper_appbar.dart';

import 'rank_tab_page.dart';

class RankPage extends StatefulWidget {
  const RankPage({super.key});

  @override
  _RankPageState createState() => _RankPageState();
}

class _RankPageState extends State<RankPage> with TickerProviderStateMixin {
  RankPageController controller = RankPageController();

  late TabController tabController;
  final double bottomBarHeight = 46;
  List<PluginsInfo> plugins = [];

  @override
  void initState() {
    super.initState();
    plugins = ApiFactory.getRankPlugins();

    tabController = TabController(length: plugins.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double pinnedHeaderHeight = statusBarHeight + kToolbarHeight + bottomBarHeight + 8;

    return Scaffold(
      floatingActionButton: PlayBar(),
      body: ExtendedNestedScrollView(
        headerSliverBuilder: (BuildContext c, bool f) {
          return [
            HyperAppbar(
                title: '榜单',
                forceElevated: f,
                bottom: PreferredSize(
                  preferredSize: Size.fromHeight(bottomBarHeight),
                  child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: TabBar(
                        dividerHeight: 0,
                        tabAlignment: TabAlignment.start,
                        indicator: BoxDecoration(
                          color: Colors.white, // 指示器的背景颜色
                          borderRadius: BorderRadius.circular(8),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        // 控制指示器的宽度是否和标签文字一样宽
                        indicatorPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                        isScrollable: true,
                        controller: tabController,
                        overlayColor: WidgetStateProperty.resolveWith<Color>((states) {
                          // 当标签被点击时，显示半透明的蓝色背景
                          if (states.contains(WidgetState.selected)) {
                            return Colors.transparent; // 设置选中时的覆盖颜色
                          }
                          return Colors.transparent; // 未选中时，覆盖层是透明的
                        }),
                        tabs: plugins
                            .map((item) => Tab(
                                  text: item.name,
                                  // icon: AppImage(url: '${item.icon}', width: 15, height: 15),
                                ))
                            .toList(),
                      )),
                ))
          ];
        },
        pinnedHeaderSliverHeightBuilder: () {
          return pinnedHeaderHeight;
        },
        onlyOneScrollInBody: true,
        // physics: NeverScrollableScrollPhysics(),
        body: Column(
          children: <Widget>[Expanded(child: _buildTabBarView())],
        ),
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: tabController,
      children: plugins.map((element) => RankTabPage(plugin: element, controller: controller)).toList(),
    );
  }
}
