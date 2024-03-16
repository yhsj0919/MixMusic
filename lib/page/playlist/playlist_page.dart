import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/page/api_controller.dart';
import 'package:mix_music/page/playlist/playlist_tab_page.dart';

class PlayListPage extends StatefulWidget {
  const PlayListPage({super.key});

  @override
  _PlayListPageState createState() => _PlayListPageState();
}

class _PlayListPageState extends State<PlayListPage> with TickerProviderStateMixin {
  ApiController api = Get.put(ApiController());
  PlayListPageController controller = PlayListPageController();

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
                title: const Text('歌单'),
                forceElevated: f,
                pinned: true,
                bottom: PreferredSize(
                    preferredSize: Size.fromHeight(bottomBarHeight),
                    child: Row(
                      children: [
                        Expanded(
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
                        IconButton(
                            onPressed: () {
                              controller.open(api.playListPlugins[tabController.index].site);
                            },
                            icon: const Icon(Icons.filter_list))
                      ],
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
      children: api.playListPlugins.map((element) => PlayListTabPage(plugin: element, controller: controller)).toList(),
    );
  }
}
