import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/page/api_controller.dart';
import 'package:mix_music/page/search/search_tab_page.dart';

import '../../widgets/sliver_search_appbar.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with TickerProviderStateMixin {
  ApiController api = Get.put(ApiController());
  var controller = TextEditingController(text: "");
  RxString keyWord = RxString("");
  final double bottomBarHeight = 46;

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double pinnedHeaderHeight = statusBarHeight + kToolbarHeight + bottomBarHeight;

    return Scaffold(
      body: Obx(
        () => DefaultTabController(
          length: api.searchPlugins.length,
          child: ExtendedNestedScrollView(
            headerSliverBuilder: (BuildContext c, bool f) {
              return [
                SliverSearchAppBar(
                  hintText: "请输入关键字",
                  forceElevated: f,
                  pinned: true,
                  onSubmitted: (value) {
                    keyWord.value = value;
                  },
                  bottom: PreferredSize(
                      preferredSize: Size.fromHeight(bottomBarHeight),
                      child: TabBar(
                        isScrollable: true,
                        tabs: api.searchPlugins
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
        ),
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      children: api.searchPlugins.map((element) => Obx(() => SearchTabPage(plugin: element, keyWord: keyWord.value))).toList(),
    );
  }
}

class CustomScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return BouncingScrollPhysics(); // 自定义滚动物理效果
  }

  @override
  Widget buildViewportChrome(BuildContext context, Widget child, AxisDirection axisDirection) {
    return child; // 不改变滚动条样式
  }
}
