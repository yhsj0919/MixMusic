import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/entity/plugins_info.dart';
import 'package:mix_music/page/app_playing/play_bar.dart';
import 'package:mix_music/page/playlist/playlist_tab_page.dart';
import 'package:mix_music/widgets/hyper/hyper_appbar.dart';

class PlayListPage extends StatefulWidget {
  const PlayListPage({super.key});

  @override
  _PlayListPageState createState() => _PlayListPageState();
}

class _PlayListPageState extends State<PlayListPage> with TickerProviderStateMixin {
  PlayListPageController controller = PlayListPageController();

  late TabController tabController;
  final double bottomBarHeight = 46;

  List<PluginsInfo> plugins = [];

  @override
  void initState() {
    super.initState();
    plugins = ApiFactory.getPlayListPlugins();

    tabController = TabController(length: plugins.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    final double pinnedHeaderHeight = 62 + bottomBarHeight;

    return Scaffold(
      floatingActionButton: PlayBar(),
      body: ExtendedNestedScrollView(
        headerSliverBuilder: (BuildContext c, bool f) {
          return [
            SliverAppBar.large(
              title: Text('歌单'),
              forceElevated: f,
              // toolbarHeight: 62,
            ),
            // PinnedHeaderSliver(
            //   child: Container(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.2)),
            // ),
            PinnedHeaderSliver(
              child: Container(
                width: double.infinity,
                height: bottomBarHeight,
                color: Theme.of(context).colorScheme.surface,
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                        child: TabBar(
                      indicatorPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
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
                          controller.open(plugins[tabController.index].package);
                        },
                        icon: const Icon(Icons.filter_list))
                  ],
                ),
              ),
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
      children: plugins.map((element) => PlayListTabPage(plugin: element, controller: controller)).toList(),
    );
  }
}
