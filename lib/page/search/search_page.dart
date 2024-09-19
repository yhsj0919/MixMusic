import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/entity/plugins_info.dart';
import 'package:mix_music/page/app_playing/play_bar.dart';
import 'package:mix_music/page/search/search_tab_page.dart';

import '../../widgets/sliver_search_appbar.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with TickerProviderStateMixin {
  var controller = TextEditingController(text: "");

  SearchPageController searchController = SearchPageController();

  RxString keyWord = RxString("");
  final double bottomBarHeight = 46;
  List<PluginsInfo> plugins = [];

  late TabController tabController;

  @override
  void initState() {
    super.initState();

    plugins = ApiFactory.getSearchPlugins();
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
            SliverSearchAppBar(
              hintText: "请输入关键字",
              forceElevated: f,
              pinned: true,
              onSubmitted: (value) {
                searchController.search(keyword: value);
              },
              bottom: PreferredSize(
                  preferredSize: Size.fromHeight(bottomBarHeight),
                  child: TabBar(
                    controller: tabController,
                    isScrollable: true,
                    tabs: plugins
                        .map((item) => Tab(
                              text: item.name,
                              // icon: AppImage(url: '${item.icon}', width: 15, height: 15),
                            ))
                        .toList(),
                  )),
              textEditingController: controller,
            )
          ];
        },
        pinnedHeaderSliverHeightBuilder: () {
          return pinnedHeaderHeight;
        },
        onlyOneScrollInBody: true,
        body: Column(
          children: <Widget>[Expanded(child: _buildTabBarView())],
        ),
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: tabController,
      children: plugins.map((element) => SearchTabPage(plugin: element, controller: searchController)).toList(),
    );
  }
}
