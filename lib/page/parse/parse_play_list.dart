import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/entity/plugins_info.dart';
import 'package:mix_music/utils/sp.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/hyper/hyper_group.dart';
import 'package:mix_music/widgets/hyper/hyper_trailing.dart';
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

  RxList<MixPlaylist> historyList = RxList();

  @override
  void initState() {
    super.initState();
    plugins = ApiFactory.getParsePlugins();
    getHistory();
  }

  void getHistory() {
    var list = Sp.getList<MixPlaylist>(Constant.KEY_APP_HISTORY_PARSE_PLAYLIST);

    historyList.clear();
    historyList.addAll(list ?? []);
  }

  void cleanHistory() {
    Sp.remove(Constant.KEY_APP_HISTORY_PARSE_PLAYLIST);
    getHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: PlayBar(),
      body: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              title: Text("歌单导入"),
            ),
            HyperGroup(
              title: SizedBox(
                width: constraints.maxWidth - 64,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("支持:"),
                    Container(width: 8),
                    Expanded(
                        child: ListView.separated(
                      // padding: EdgeInsets.zero,
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
              children: [
                Padding(
                  padding: EdgeInsets.all(8),
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: "请输入链接",
                      border: OutlineInputBorder(
                        // 设置边框
                        borderRadius: BorderRadius.circular(12), // 圆角
                        // borderSide: BorderSide(color: Colors.blue, width: 2), // 边框颜色和宽度
                      ),
                    ),
                    maxLines: 3,
                    onSubmitted: (value) {
                      keyWord.value = value;
                      parsePlayList(url: value);
                    },
                  ),
                ),
                SizedBox(
                  height: 40,
                  child: FilledButton(
                      style: ButtonStyle(
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0), // 设置圆角
                          ),
                        ),
                        padding: WidgetStateProperty.all(EdgeInsets.symmetric(horizontal: 20)),
                      ),
                      onPressed: () {
                        keyWord.value = controller.text;
                        parsePlayList(url: controller.text);
                      },
                      child: Text("解析")),
                ),
                Gap(8),
              ],
            ),
            HyperGroup(
              title: Text("解析结果"),
              children: <Widget>[
                Obx(() => playlist.isEmpty
                    ? SizedBox(
                        height: 100,
                        child: Center(
                          child: Text("暂无数据"),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
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
            ),
            HyperGroup(
              title: Text("历史记录"),
              trailing: InkWell(
                child: Text("清空"),
                onTap: () {
                  showDialog<void>(
                    context: context,
                    barrierDismissible: false, // 用户必须点击按钮来关闭对话框
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('提示'),
                        content: SingleChildScrollView(
                          child: Text('确定清空列表？'),
                        ),
                        actions: <Widget>[
                          TextButton(
                            child: Text('确定'),
                            onPressed: () {
                              cleanHistory();
                              Navigator.of(context).pop(); // 关闭对话框
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              children: <Widget>[
                Obx(() => historyList.isEmpty
                    ? SizedBox(
                        height: 100,
                        child: Center(
                          child: Text("暂无数据"),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: historyList.length,
                        padding: EdgeInsets.zero,
                        itemBuilder: (BuildContext context, int index) {
                          var item = historyList[index];

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
                            trailing: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: EdgeInsets.all(8),
                                child: HyperTrailing(
                                  icon: Icons.clear,
                                ),
                              ),
                              onTap: () async {
                                await Sp.removeList<MixPlaylist>(Constant.KEY_APP_HISTORY_PARSE_PLAYLIST, check: (old) {
                                  return old.package == item.package && old.id.toString() == item.id.toString();
                                });
                                getHistory();
                              },
                            ),
                          );
                        },
                      )),
              ],
            )
          ],
        );
      }),
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
        Sp.insertList(Constant.KEY_APP_HISTORY_PARSE_PLAYLIST, element, index: 0, check: (oldValue, newValue) {
          return oldValue.package == newValue.package && oldValue.id.toString() == newValue.id.toString();
        });
      });
      getHistory();
    }).catchError((e) {
      showError(e);
    });
  }
}
