import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/message.dart';

import '../../entity/mix_play_list.dart';
import 'package:mix_music/page/app_playing/play_bar.dart';
import '../../route/routes.dart';
import '../../widgets/sliver_search_appbar.dart';
import '../api_controller.dart';

class ParsePlayList extends StatefulWidget {
  const ParsePlayList({super.key});

  @override
  State<ParsePlayList> createState() => _ParsePlayListState();
}

class _ParsePlayListState extends State<ParsePlayList> {
  RxString keyWord = RxString("");
  final double bottomBarHeight = 46;
  var controller = TextEditingController(text: "");
  ApiController api = Get.put(ApiController());
  RxList<MixPlaylist> playlist = RxList();

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
            )
          ];
        },
        pinnedHeaderSliverHeightBuilder: () {
          return pinnedHeaderHeight;
        },
        onlyOneScrollInBody: true,
        body: Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              height: 50,
              child: Row(
                children: [
                  Container(
                    child: Text("支持:"),
                  ),
                  Container(width: 8),
                  ListView.separated(
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (BuildContext context, int index) {
                      var item = api.parsePlugins[index];
                      return Container(
                        alignment: Alignment.center,
                        child: Text(item.name ?? ""),
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) {
                      return Container(width: 8);
                    },
                    itemCount: api.parsePlugins.length,
                  )
                ],
              ),
            ),
            Obx(() => ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlist.length,
                  itemBuilder: (BuildContext context, int index) {
                    var item = playlist[index];
                    return ListTile(
                      leading: AppImage(url: item.pic ?? ""),
                      title: Text("${item.title}", maxLines: 1),
                      subtitle: Text("${item.subTitle}", maxLines: 1),
                      trailing: Text("${item.package }", maxLines: 1),
                      onTap: () {
                        Get.toNamed(Routes.playListDetail, arguments: item);
                      },
                    );
                  },
                )),
          ],
        ),
      ),
    );
  }

  ///获取歌单
  Future<void> parsePlayList({String? url}) {
    if (api.parsePlugins.isEmpty) {
      showError("暂无插件支持");
      return Future(() => null);
    }
    if (url?.isNotEmpty != true) {
      showError("链接不可为空");
      return Future(() => null);
    }

    return api.parsePlayList(sites: api.parsePlugins.map((element) => element.package !).toList(), url: url).then((value) {
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
