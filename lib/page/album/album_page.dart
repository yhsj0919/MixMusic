import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/entity/plugins_info.dart';
import 'package:mix_music/page/album/album_tab_page.dart';
import 'package:mix_music/page/app_playing/play_bar.dart';
import 'package:mix_music/widgets/hyper/hyper_appbar.dart';

class AlbumPage extends StatefulWidget {
  const AlbumPage({super.key});

  @override
  _AlbumPageState createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> with TickerProviderStateMixin {
  AlbumPageController controller = AlbumPageController();

  late TabController tabController;
  final double bottomBarHeight = 46;

  List<PluginsInfo> plugins = [];

  @override
  void initState() {
    super.initState();
    plugins = ApiFactory.getAlbumPlugins();

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
              title: Text('专辑'),
              forceElevated: f,
              
              toolbarHeight: 62,
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(bottomBarHeight),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TabBar(
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
                        ),
                      ),
                      IconButton(
                          onPressed: () {
                            controller.open(plugins[tabController.index].package);
                          },
                          icon: const Icon(Icons.filter_list))
                    ],
                  ),
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
      children: plugins.map((element) => AlbumTabPage(plugin: element, controller: controller)).toList(),
    );
  }
}
