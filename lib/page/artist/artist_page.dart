import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/page/api_controller.dart';

import 'package:mix_music/page/app_playing/play_bar.dart';
import 'artist_tab_page.dart';

class ArtistPage extends StatefulWidget {
  const ArtistPage({super.key});

  @override
  _ArtistPageState createState() => _ArtistPageState();
}

class _ArtistPageState extends State<ArtistPage> with TickerProviderStateMixin {
  ApiController api = Get.put(ApiController());
  ArtistController controller = ArtistController();

  late TabController tabController;
  final double bottomBarHeight = 46;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: api.artistPlugins.length, vsync: this);
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
                title: const Text('歌手'),
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
                          tabs: api.artistPlugins
                              .map((item) => Tab(
                                    text: item.name,
                                    // icon: AppImage(url: '${item.icon}', width: 15, height: 15),
                                  ))
                              .toList(),
                        )),
                        IconButton(
                            onPressed: () {
                              if (api.artistPlugins.isNotEmpty) {
                                controller.open(api.artistPlugins[tabController.index].package );
                              }
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
      children: api.artistPlugins.map((element) => ArtistTabPage(plugin: element, controller: controller)).toList(),
    );
  }
}
