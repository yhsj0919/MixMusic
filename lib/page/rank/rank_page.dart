import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/page/api_controller.dart';

import 'rank_tab_page.dart';

class RankPage extends StatefulWidget {
  const RankPage({super.key});

  @override
  _RankPageState createState() => _RankPageState();
}

class _RankPageState extends State<RankPage> with TickerProviderStateMixin {
  ApiController api = Get.put(ApiController());
  RankPageController controller = RankPageController();

  late TabController tabController;
  final double bottomBarHeight = 46;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: api.playListPlugins.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double pinnedHeaderHeight = statusBarHeight + kToolbarHeight + bottomBarHeight;

    return Scaffold(
      body: Obx(
        () => ExtendedNestedScrollView(
          headerSliverBuilder: (BuildContext c, bool f) {
            return [
              SliverAppBar(
                title: const Text('榜单'),
                forceElevated: f,
                pinned: true,
                bottom: PreferredSize(
                    preferredSize: Size.fromHeight(bottomBarHeight),
                    child: TabBar(
                      isScrollable: true,
                      controller: tabController,
                      tabs: api.playListPlugins
                          .map((item) => Tab(
                                text: item.name,
                                // icon: AppImage(url: '${item.icon}', width: 15, height: 15),
                              ))
                          .toList(),
                    )),
              )
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
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: tabController,
      children: api.playListPlugins.map((element) => RankTabPage(plugin: element, controller: controller)).toList(),
    );
  }
}
