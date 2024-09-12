import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/entity/plugins_info.dart';

import 'package:mix_music/page/app_playing/play_bar.dart';
import 'artist_tab_page.dart';

class ArtistPage extends StatefulWidget {
  const ArtistPage({super.key});

  @override
  _ArtistPageState createState() => _ArtistPageState();
}

class _ArtistPageState extends State<ArtistPage> with TickerProviderStateMixin {
  ArtistController controller = ArtistController();

  late TabController tabController;
  final double bottomBarHeight = 46;

  List<PluginsInfo> plugins = [];

  @override
  void initState() {
    super.initState();
    plugins = ApiFactory.getArtistPlugins();

    tabController = TabController(length: plugins.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    final double pinnedHeaderHeight = statusBarHeight + kToolbarHeight + bottomBarHeight;

    return Scaffold(
      floatingActionButton: PlayBar(),
      body: ExtendedNestedScrollView(
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
                        tabs: plugins
                            .map((item) => Tab(
                                  text: item.name,
                                  // icon: AppImage(url: '${item.icon}', width: 15, height: 15),
                                ))
                            .toList(),
                      )),
                      IconButton(
                          onPressed: () {
                            if (plugins.isNotEmpty) {
                              controller.open(plugins[tabController.index].package);
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
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: tabController,
      children: plugins.map((element) => ArtistTabPage(plugin: element, controller: controller)).toList(),
    );
  }
}
