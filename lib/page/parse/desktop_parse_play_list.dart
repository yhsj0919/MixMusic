import 'package:fluent_ui/fluent_ui.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:mix_music/common/api/api_factory.dart';
import 'package:mix_music/common/entity/mix_play_list.dart';
import 'package:mix_music/common/entity/plugins_info.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/utils/db.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/fluent/fluent_group.dart';
import 'package:mix_music/widgets/message.dart';
import 'package:tiny_db/tiny_db.dart';

import '../../route/routes.dart';

class DesktopParsePlayList extends StatefulWidget {
  const DesktopParsePlayList({super.key});

  @override
  State<DesktopParsePlayList> createState() => _DesktopParsePlayListState();
}

class _DesktopParsePlayListState extends State<DesktopParsePlayList> {
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

  Future<void> getHistory() async {
    var list = await AppDB.getList<MixPlaylist>(Constant.KEY_APP_HISTORY_PARSE_PLAYLIST);

    historyList.clear();
    historyList.addAll(list);
  }

  void cleanHistory() {
    AppDB.kvRemove(Constant.KEY_APP_HISTORY_PARSE_PLAYLIST);
    getHistory();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(title: Text('歌单导入')),
      content: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return CustomScrollView(
            slivers: [
              FluentGroup(
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
                            return Container(alignment: Alignment.center, child: Text(item.name ?? ""));
                          },
                          separatorBuilder: (BuildContext context, int index) {
                            return Container(width: 8);
                          },
                          itemCount: plugins.length,
                        ),
                      ),
                    ],
                  ),
                ),
                children: [
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: TextBox(
                      controller: controller,
                      placeholder: '请输入链接',
                      maxLines: 3,
                      onSubmitted: (value) {
                        keyWord.value = value;
                        parsePlayList(url: value);
                      },
                    ),
                  ),
                  Container(
                  alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Button(
                      onPressed: () {
                        keyWord.value = controller.text;
                        parsePlayList(url: controller.text);
                      },
                      child: Text("解析"),
                    ),
                  ),
                  Gap(8),
                ],
              ),
              FluentGroup(
                title: Text("解析结果"),
                children: <Widget>[
                  Obx(
                    () => playlist.isEmpty
                        ? SizedBox(height: 100, child: Center(child: Text("暂无数据")))
                        : ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: playlist.length,
                            itemBuilder: (BuildContext context, int index) {
                              var item = playlist[index];

                              var plugin = ApiFactory.getPlugin(item.package);
                              return ListTile(
                                leading: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    AppImage(url: item.pic ?? ""),
                                    ClipRRect(
                                      borderRadius: BorderRadius.all(Radius.circular(8)),
                                      child: Container(
                                        color: Colors.white,
                                        child: AppImage(url: plugin?.icon ?? "", width: 20, height: 20),
                                      ),
                                    ),
                                  ],
                                ),
                                title: Text("${item.title}", maxLines: 1),
                                subtitle: Text("${item.subTitle}", maxLines: 1),
                                onPressed: () {
                                  context.push(Routes.playListDetail, extra: item);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
              FluentGroup(
                title: Text("历史记录"),
                trailing: Button(
                  child: Text("清空"),
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      barrierDismissible: false, // 用户必须点击按钮来关闭对话框
                      builder: (BuildContext context) {
                        return ContentDialog(
                          title: Text('提示'),
                          content: SingleChildScrollView(child: Text('确定清空列表？')),
                          actions: <Widget>[
                            Button(
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
                  Obx(
                    () => historyList.isEmpty
                        ? SizedBox(height: 100, child: Center(child: Text("暂无数据")))
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: historyList.length,
                            padding: EdgeInsets.zero,
                            itemBuilder: (BuildContext context, int index) {
                              var item = historyList[index];

                              var plugin = ApiFactory.getPlugin(item.package);
                              return ListTile(
                                leading: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    AppImage(url: item.pic ?? ""),
                                    ClipRRect(
                                      borderRadius: BorderRadius.all(Radius.circular(8)),
                                      child: Container(
                                        color: Colors.white,
                                        child: AppImage(url: plugin?.icon ?? "", width: 20, height: 20),
                                      ),
                                    ),
                                  ],
                                ),
                                title: Text("${item.title}", maxLines: 1),
                                subtitle: Text("${item.subTitle}", maxLines: 1),
                                onPressed: () {
                                  Get.toNamed(id: Routes.key, Routes.playListDetail, arguments: item);
                                },
                                trailing: IconButton(
                                  icon: Icon(FluentIcons.cancel),
                                  onPressed: () async {
                                    await AppDB.remove(
                                      table: Constant.KEY_APP_HISTORY_PARSE_PLAYLIST,
                                      queryCondition: where("package").equals(item.package).and(where("id").equals(item.id.toString())),
                                    );
                                    getHistory();
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
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

    ApiFactory.parsePlayList(packages: plugins.map((element) => element.package!).toList(), url: url)
        .then((value) {
          if (value.isEmpty) {
            showInfo("没有匹配到数据");
          }
          playlist.clear();

          value.forEach((element) {
            playlist.add(element!);
            AppDB.insertOrUpdateWithIndex(
              Constant.KEY_APP_HISTORY_PARSE_PLAYLIST,
              element,
              index: 0,
              check: (oldValue, newValue) {
                return oldValue.package == newValue.package && oldValue.id.toString() == newValue.id.toString();
              },
            );
          });
          getHistory();
        })
        .catchError((e) {
          showError(e);
        });
  }
}
