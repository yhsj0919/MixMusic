import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/entity/plugins_info.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/hyper/hyper_group.dart';
import 'package:mix_music/widgets/message.dart';

import '../../entity/mix_play_list.dart';
import 'package:mix_music/page/app_playing/play_bar.dart';
import '../../route/routes.dart';
import '../../widgets/sliver_search_appbar.dart';

class ParsePlayList extends StatefulWidget {
  const ParsePlayList({super.key});

  @override
  State<ParsePlayList> createState() => _ParsePlayListState();
}

class _ParsePlayListState extends State<ParsePlayList> {
  RxString keyWord = RxString("");
  final double bottomBarHeight = 46;
  var controller = TextEditingController(text: "");
  RxList<MixPlaylist> playlist = RxList();
  List<PluginsInfo> plugins = [];

  @override
  void initState() {
    super.initState();
    plugins = ApiFactory.getParsePlugins();
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
                hintText: "请输入歌单链接",
                forceElevated: f,
                pinned: true,
                onSubmitted: (value) {
                  keyWord.value = value;
                  parsePlayList(url: value);
                },
                textEditingController: controller,
                optionsBuilder: (v) {
                  return [];
                },
              )
            ];
          },
          pinnedHeaderSliverHeightBuilder: () {
            return pinnedHeaderHeight;
          },
          onlyOneScrollInBody: true,
          body: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
            return HyperGroup(
              inSliver: false,
              title: SizedBox(
                width: constraints.maxWidth - 64,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("支持:"),
                    Container(width: 8),
                    Expanded(
                        child: ListView.separated(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (BuildContext context, int index) {
                        var item = plugins[index];
                        return Container(
                          alignment: Alignment.center,
                          child: Text(item.name ?? ""),
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) {
                        return Container(width: 8);
                      },
                      itemCount: plugins.length,
                    ))
                  ],
                ),
              ),
              children: <Widget>[
                Obx(() => playlist.isEmpty
                    ? Container(
                        height: 200,
                        child: Center(
                          child: Text("暂无数据"),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: playlist.length,
                        itemBuilder: (BuildContext context, int index) {
                          var item = playlist[index];

                          var plugin = ApiFactory.getPlugin(item.package);
                          return ListTile(
                            leading: Stack(alignment: Alignment.bottomRight, children: [
                              AppImage(url: item.pic ?? ""),
                              ClipRRect(
                                  borderRadius: BorderRadius.all(Radius.circular(8)),
                                  child: Container(
                                    color: Colors.white,
                                    child: AppImage(
                                      url: plugin?.icon ?? "",
                                      width: 20,
                                      height: 20,
                                    ),
                                  ))
                            ]),
                            title: Text("${item.title}", maxLines: 1),
                            subtitle: Text("${item.subTitle}", maxLines: 1),
                            onTap: () {
                              Get.toNamed(Routes.playListDetail, arguments: item);
                            },
                          );
                        },
                      )),
              ],
            );
          })),
    );
  }

  ///获取歌单
  void parsePlayList({String? url}) {
    if (plugins.isEmpty) {
      showError("暂无插件支持");
    }
    if (url?.isNotEmpty != true) {
      showError("链接不可为空");
    }

    ApiFactory.parsePlayList(packages: plugins.map((element) => element.package!).toList(), url: url).then((value) {
      if (value.isEmpty) {
        showInfo("没有匹配到数据");
      }
      playlist.clear();

      value.forEach((element) {
        playlist.add(element!);
      });
    }).catchError((e) {
      showError(e);
    });
  }
}
