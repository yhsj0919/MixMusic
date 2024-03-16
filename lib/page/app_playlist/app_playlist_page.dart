import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/page/app_main/app_controller.dart';
import 'package:mix_music/player/music_controller.dart';
import 'package:mix_music/widgets/app_image.dart';

class AppPlayListPage extends StatelessWidget {
  AppPlayListPage({super.key, required this.inPanel, this.scrollController});

  bool inPanel;
  ScrollController? scrollController;

  MusicController music = Get.put(MusicController());
  AppController app = Get.put(AppController());

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text("播放列表", style: Theme.of(context).textTheme.titleMedium),
              Obx(() => Text(" (${music.musicList.length})")),
              Expanded(child: Container()),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.playlist_remove_rounded),
              )
            ],
          ),
        ),
        Container(height: 1, width: double.infinity, color: Colors.black12),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: Obx(
              () => ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 0),
                shrinkWrap: true,
                controller: inPanel ? app.panelScrollController : scrollController,
                itemCount: music.musicList.length,
                itemBuilder: (BuildContext context, int index) {
                  var song = music.musicList[index];
                  return Obx(
                    () => ListTile(
                      selected: music.musicIndex.value == index,
                      leading: AppImage(url: song.pic ?? ""),
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
                      onTap: () {
                        music.play(music: song);
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
