import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/page/album/album_tab_page.dart';
import 'package:mix_music/page/api_controller.dart';
import 'package:mix_music/page/app_playing/play_bar.dart';

class AlbumPage extends StatefulWidget {
  const AlbumPage({super.key});

  @override
  _AlbumPageState createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> with TickerProviderStateMixin {
  ApiController api = Get.put(ApiController());
  AlbumPageController controller = AlbumPageController();

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
      floatingActionButton: PlayBar(),
      body: Obx(
        () => ExtendedNestedScrollView(
          headerSliverBuilder: (BuildContext c, bool f) {
            return [
              SliverAppBar(
                title: const Text('专辑'),
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
      children: api.playListPlugins.map((element) => AlbumTabPage(plugin: element, controller: controller)).toList(),
    );
  }
}
