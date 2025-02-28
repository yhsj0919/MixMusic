import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/entity/mix_song.dart';
import 'package:mix_music/page/app_playlist/app_download_type_page.dart';
import 'package:mix_music/player/music_controller.dart';
import 'package:mix_music/route/routes.dart';
import 'package:mix_music/widgets/app_image.dart';

class HyperSongItem extends StatelessWidget {
  HyperSongItem({super.key, required this.song, this.onTap});

  final MixSong song;
  final GestureTapCallback? onTap;

  final MusicController music = Get.put(MusicController());

  @override
  Widget build(BuildContext context) {
    return Obx(() => ListTile(
          selected: music.currentMusic.value?.id == song.id,
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
          subtitle: Text(song.subTitle ?? "", overflow: TextOverflow.ellipsis, maxLines: 1),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              song.mv != null
                  ? IconButton(
                      onPressed: () {
                        Get.toNamed(Routes.mvDetail, arguments: song.mv);
                      },
                      icon: Icon(Icons.music_video))
                  : Container(),
              IconButton(
                  onPressed: () {
                    showBottomDownload(context, song);
                  },
                  icon: Icon(Icons.download_rounded)),
            ],
          ),
          onTap: onTap,
        ));
  }

  void showBottomDownload(BuildContext context, MixSong song) {
    showModalBottomSheet(
        context: context,
        showDragHandle: true,
        useSafeArea: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0), // 设置圆角的大小
        ),
        scrollControlDisabledMaxHeightRatio: 1 / 2,
        builder: (BuildContext context) {
          return AppDownloadTypePage(
            song: song,
            onTap: () {
              Navigator.of(context).pop();
            },
          );
        }).then((value) {});
  }
}
