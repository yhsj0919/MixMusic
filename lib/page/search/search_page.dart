import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/entity/plugins_info.dart';
import 'package:mix_music/page/app_playing/play_bar.dart';
import 'package:mix_music/page/search/search_album_page.dart';
import 'package:mix_music/page/search/search_artist_page.dart';
import 'package:mix_music/page/search/search_music_page.dart';
import 'package:mix_music/utils/sp.dart';
import 'package:mix_music/widgets/hyper/hyper_card.dart';
import 'package:mix_music/widgets/hyper/hyper_trailing.dart';

import '../../widgets/sliver_search_appbar.dart';
import 'search_mv_page.dart';
import 'search_playlist_page.dart';
import 'search_tab_State.dart';

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
  RxList<PluginsInfo> plugins = RxList();

  late TabController tabController;
  final FocusNode _focusNode = FocusNode();

  static List<Map> allSearchType = [
    {"type": "music", "name": "音乐", "icon": Icons.music_note_outlined},
    {"type": "album", "name": "专辑", "icon": Icons.album_outlined},
    {"type": "artist", "name": "歌手", "icon": Icons.person},
    {"type": "playlist", "name": "歌单", "icon": Icons.playlist_play_outlined},
    {"type": "lyric", "name": "歌词", "icon": Icons.lyrics_outlined},
    {"type": "mv", "name": "MV", "icon": Icons.music_video},
  ];

  RxList<Map> supportType = RxList();

  Rx<Map> currentType = Rx({});

  RxBool showHistory = RxBool(true);

  RxList<String> searchList = RxList();

  @override
  void initState() {
    super.initState();
    getSearchHistory();
    getSupportType();
    getPlugins(type: currentType.value);

    _focusNode.addListener(() {
      if (_focusNode.hasFocus || controller.text.isEmpty) {
        showHistory.value = true;
      } else {
        // showHistory.value = false;
      }
    });
  }

  void getSupportType() {
    var keys = ApiFactory.getSearchKey();
    supportType.addAll(allSearchType.where((item) {
      return keys.contains(item["type"]);
    }));
    if (supportType.isNotEmpty) {
      var cur = supportType.firstWhereOrNull((item) {
            return item["type"] == "music";
          }) ??
          supportType.first;
      currentType.value = cur;
    }
  }

  void getPlugins({required Map? type}) {
    plugins.clear();
    plugins.addAll(ApiFactory.getSearchPlugins(type: currentType.value["type"] ?? ""));
    tabController = TabController(length: plugins.length, vsync: this);
  }

  void getSearchHistory() {
    searchList.value = Sp.getStringList(Constant.KEY_APP_HISTORY_SEARCH_LIST) ?? [];
  }

  void addSearchHistory(String value) {
    Sp.insertStringList(Constant.KEY_APP_HISTORY_SEARCH_LIST, value);
  }

  void removeSearchHistory(String value) {
    Sp.removeStringList(Constant.KEY_APP_HISTORY_SEARCH_LIST, value);
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
              SliverSearchAppBar(
                hintText: "请输入关键字",
                forceElevated: f,
                focusNode: _focusNode,
                pinned: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                onSubmitted: (value) {
                  addSearchHistory(value);
                  getSearchHistory();
                  _focusNode.unfocus();
                  showHistory.value = false;
                  searchController.search(keyword: value);
                },
                // onChanged: (v) {
                //   showHistory.value = controller.text.isEmpty;
                // },
                bottom: PreferredSize(
                    preferredSize: Size.fromHeight(bottomBarHeight),
                    child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Obx(
                                () => TabBar(
                                  indicatorPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                  isScrollable: true,
                                  controller: tabController,
                                  tabs: plugins
                                      .map((item) => Tab(
                                            text: item.name,
                                            // icon: AppImage(url: '${item.icon}', width: 25, height: 25),
                                          ))
                                      .toList(),
                                ),
                              ),
                            ),
                            Obx(() => IconButton(
                                onPressed: () {
                                  _focusNode.unfocus();
                                  showTypeSelectDialog(context);
                                },
                                icon: Icon(currentType.value["icon"] ?? Icons.filter_list)))
                          ],
                        ))),
                textEditingController: controller,
              ),
              // PinnedHeaderSliver(
              //   child: Container(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.2)),
              // ),
            ];
          },
          pinnedHeaderSliverHeightBuilder: () {
            return pinnedHeaderHeight;
          },
          onlyOneScrollInBody: true,
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            child: showHistory.value
                ? ListView.builder(
                    itemCount: searchList.length,
                    itemBuilder: (BuildContext context, int index) {
                      var item = searchList[index];
                      return ListTile(
                        leading: Text(
                          "${index + 1}",
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
                        ),
                        title: Text(item),
                        trailing: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: HyperTrailing(
                              icon: Icons.clear,
                            ),
                          ),
                          onTap: () async {
                            var value = searchList[index];
                            removeSearchHistory(value);
                            getSearchHistory();
                          },
                        ),
                        onTap: () {
                          var value = searchList[index];

                          controller.text = value;
                          addSearchHistory(value);
                          getSearchHistory();
                          _focusNode.unfocus();
                          showHistory.value = false;
                          searchController.search(keyword: value);
                        },
                      );
                    },
                  )
                : Column(
                    children: <Widget>[Expanded(child: _buildTabBarView())],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBarView() {
    return Obx(() => TabBarView(
          controller: tabController,
          children: plugins.map((element) {
            var type = currentType.value["type"];
            return type == "music"
                ? SearchMusicPage(plugin: element, controller: searchController)
                : type == "album"
                    ? SearchAlbumPage(plugin: element, controller: searchController)
                    : type == "artist"
                        ? SearchArtistPage(plugin: element, controller: searchController)
                        : type == "playlist"
                            ? SearchPlayListPage(plugin: element, controller: searchController)
                            : type == "mv"
                                ? SearchMvPage(plugin: element, controller: searchController)
                                : Center(
                                    child: Text("暂未实现"),
                                  );
          }).toList(),
        ));
  }

  void showTypeSelectDialog(BuildContext context) {
    showModalBottomSheet(
        context: context,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        scrollControlDisabledMaxHeightRatio: 3 / 4,
        builder: (BuildContext context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
                child: Text("搜索类型", style: Theme.of(context).textTheme.titleLarge),
              ),
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                child: Wrap(
                    // alignment: WrapAlignment.start,
                    spacing: 16,
                    runSpacing: 16,
                    children: supportType.map((item) {
                      return typeItem(
                          data: item,
                          onTap: (type) {
                            currentType.value = type;
                            getPlugins(type: type);
                            Navigator.of(context).pop();
                          });
                    }).toList()),
              ),
              Container(height: 32)
            ],
          );
        }).then((value) {});
  }

  Widget typeItem({double? widget = 100, double? height = 100, Map data = const {}, Function(Map type)? onTap}) {
    return HyperCard(
      width: widget,
      height: height,
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap == null
            ? null
            : () {
                onTap.call(data);
              },
        child: GridTile(
          header: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            alignment: Alignment.topLeft,
            child: Icon(data["icon"]),
          ),
          footer: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            alignment: Alignment.bottomRight,
            child: Text(data["name"]),
          ),
          child: Container(),
        ),
      ),
    );
  }
}
