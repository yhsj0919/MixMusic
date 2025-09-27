import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:get/get.dart';
import 'package:mix_music/common/api/api_factory.dart';
import 'package:mix_music/common/entity/plugins_info.dart';
import 'package:mix_music/page/search/desktop/desktop_search_album_page.dart';
import 'package:mix_music/page/search/desktop/desktop_search_artist_page.dart';
import 'package:mix_music/page/search/desktop/desktop_search_music_page.dart';
import 'package:mix_music/page/search/desktop/desktop_search_mv_page.dart';
import 'package:mix_music/page/search/search_tab_State.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/fluent/auto_suggest_box.dart';

import 'desktop_search_playlist_page.dart';

class DesktopSearchPage extends StatefulWidget {
  const DesktopSearchPage({super.key});

  @override
  _DesktopSearchPageState createState() => _DesktopSearchPageState();
}

class _DesktopSearchPageState extends State<DesktopSearchPage> with TickerProviderStateMixin {
  RxList<PluginsInfo> plugins = RxList();

  SearchPageController searchController = SearchPageController();

  Rx<Map> currentType = Rx({});
  static List<Map> allSearchType = [
    {"type": "music", "name": "音乐", "icon": FluentIcons.music_note},
    {"type": "album", "name": "专辑", "icon": WindowsIcons.music_album},
    {"type": "artist", "name": "歌手", "icon": FluentIcons.contact},
    {"type": "playlist", "name": "歌单", "icon": FluentIcons.playlist_music},
    {"type": "lyric", "name": "歌词", "icon": FluentIcons.text_box},
    {"type": "mv", "name": "MV", "icon": FluentIcons.my_movies_t_v},
  ];

  RxList<Map> supportType = RxList();

  @override
  void initState() {
    super.initState();
    getSupportType();
    getPlugins(type: currentType.value);
  }

  void getSupportType() {
    var keys = ApiFactory.getSearchKey();
    supportType.addAll(
      allSearchType.where((item) {
        return keys.contains(item["type"]);
      }),
    );
    if (supportType.isNotEmpty) {
      var cur =
          supportType.firstWhereOrNull((item) {
            return item["type"] == "music";
          }) ??
          supportType.first;
      currentType.value = cur;
    }
  }

  void getPlugins({required Map? type}) {
    plugins.clear();
    plugins.addAll(ApiFactory.getSearchPlugins(type: currentType.value["type"] ?? ""));
  }

  int currentIndex = 0;
  List<bool> isSelected = [true, false, false, false, false];

  RxList<Tab> tab = RxList([]);

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: Text('搜索'),
        commandBar: AutoSuggestBox2<String>(
          placeholder: '请输入关键字',

          onChanged: (String text, TextChangedReason2 reason) {
            if (reason == TextChangedReason2.suggestionChosen) {
              searchController.search(keyword: text);
            }
          },
          sorter: (text, List<AutoSuggestBoxItem2<String>> items) {
            return items;
          },
          itemsBuilder: (String text) {
            if (text.isNotEmpty) {
              return getSuggest(text).then((v) {
                return v.map<AutoSuggestBoxItem2<String>>((value) => AutoSuggestBoxItem2<String>(value: value, label: value)).toList();
              });
            } else {
              return Future.value(<AutoSuggestBoxItem2<String>>[]);
            }
          },
        ),
      ),
      content: Obx(
        () => TabView(
          header: Container(),
          tabs: plugins.map((plugin) {
            var type = currentType.value["type"];
            return Tab(
              text: Text(plugin.name ?? ""),
              selectedBackgroundColor: WidgetStateProperty.all((FluentTheme.of(context).brightness == Brightness.light ? Colors.black : Colors.white).withValues(alpha: 0.1)),
              icon: AppImage(url: plugin.icon ?? "", width: 16, height: 16),
              body: type == "music"
                  ? DesktopSearchMusicPage(plugin: plugin, controller: searchController)
                  : type == "album"
                  ? DesktopSearchAlbumPage(plugin: plugin, controller: searchController)
                  : type == "artist"
                  ? DesktopSearchArtistPage(plugin: plugin, controller: searchController)
                  : type == "playlist"
                  ? DesktopSearchPlayListPage(plugin: plugin, controller: searchController)
                  : type == "mv"
                  ? DesktopSearchMvPage(plugin: plugin, controller: searchController)
                  : Center(child: Text("暂未实现")),
            );
          }).toList(),
          currentIndex: currentIndex,
          onChanged: (index) => setState(() => currentIndex = index),
          tabWidthBehavior: TabWidthBehavior.sizeToContent,
          closeButtonVisibility: CloseButtonVisibilityMode.always,
          showScrollButtons: true,
          footer: Container(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: material.ToggleButtons(
              isSelected: isSelected,
              constraints: BoxConstraints(minWidth: 30, minHeight: 30),
              borderRadius: BorderRadius.all(Radius.circular(6)),
              children: supportType.map((item) {
                return Icon(item["icon"], size: 16);
              }).toList(),
              onPressed: (index) {
                setState(() {
                  // 取消选择
                  for (int i = 0; i < isSelected.length; i++) {
                    isSelected[i] = i == index;
                  }
                  var type = supportType[index];
                  currentType.value = type;
                  getPlugins(type: type);
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<List<String>> getSuggest(String key) async {
    var plugin = plugins[currentIndex];
    try {
      var resp = await ApiFactory.api(package: plugin.package!)?.searchSuggest(keyword: key);

      print(resp?.data);
      return Future.value(resp?.data ?? []);
    } catch (e) {
      print("搜索建议异常：${e}");
      return Future.value([]);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
