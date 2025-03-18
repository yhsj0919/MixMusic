import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/player/music_controller.dart';
import 'package:mix_music/route/routes.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/hyper/hyper_group.dart';
import 'package:mix_music/widgets/page_custom_scroll_view.dart';

import 'app_history_music_controller.dart';

class AppHistoryMusicList extends StatefulWidget {
  const AppHistoryMusicList({super.key});

  @override
  State<AppHistoryMusicList> createState() => _AppHistoryMusicListState();
}

class _AppHistoryMusicListState extends State<AppHistoryMusicList> {
  AppHistoryMusicController controller = Get.put(AppHistoryMusicController());
  MusicController music = Get.put(MusicController());

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageCustomScrollView(
        controller: controller.refreshController,
        onRefresh: () {
          return controller.getHistory(0);
        },
        onLoad: () {
          return controller.getHistory(controller.dataPage.page ?? 0);
        },
        slivers: [
          SliverAppBar.large(
            title: Text("播放历史"),
          ),
          HyperGroup(
            title: Text("最近播放"),
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
                            controller.cleanHistory();
                            Navigator.of(context).pop(); // 关闭对话框
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            children: [
              Obx(
                () => ListView.builder(
                  padding: EdgeInsets.all(0),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.musicList.length,
                  shrinkWrap: true,
                  itemBuilder: (BuildContext context, int index) {
                    var song = controller.musicList[index];
                    var plugin = ApiFactory.getPlugin(song.package);
                    return Obx(() => ListTile(
                          selected: music.currentMusic.value?.id.toString() == song.id.toString(),
                          leading: Stack(alignment: Alignment.bottomRight, children: [
                            AppImage(url: song.pic ?? ""),
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
                          title: Row(
                            children: [
                              Flexible(child: Text(song.title ?? "", maxLines: 1, overflow: TextOverflow.ellipsis)),
                              song.vip == 1
                                  ? Container(
                                      alignment: Alignment.center,
                                      margin: const EdgeInsets.symmetric(horizontal: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                                        border: Border.all(width: 1, color: Colors.green),
                                      ),
                                      child: const Text("VIP", maxLines: 1, style: TextStyle(fontSize: 10, color: Colors.green)),
                                    )
                                  : Container(),
                            ],
                          ),
                          subtitle: Text(
                            song.subTitle ?? "",
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          trailing: song.mv != null
                              ? IconButton(
                                  onPressed: () {
                                    Get.toNamed(Routes.mvDetail, arguments: song.mv);
                                  },
                                  icon: Icon(Icons.music_video))
                              : null,
                          onTap: () {
                            music.playList(list: controller.musicList, index: index);
                          },
                        ));
                  },
                ),
              ),
            ],
          ),
          SliverGap(80)
        ],
      ),
    );
  }
}
