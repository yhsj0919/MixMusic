import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/entity/mix_download.dart';
import 'package:mix_music/entity/mix_song.dart';
import 'package:mix_music/page/download/download_controller.dart';
import 'package:mix_music/player/music_controller.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/message.dart';

class AppDownloadTypePage extends StatelessWidget {
  AppDownloadTypePage({super.key, required this.song, this.scrollController, this.onTap});

  final GestureTapCallback? onTap;

  final ScrollController? scrollController;
  final MixSong song;

  // MusicController music = Get.put(MusicController());
  final DownloadController controller = Get.put(DownloadController());

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            width: 50,
            height: 50,
            child: AppImage(url: song.pic ?? ""),
          ),
          title: Text(song.title ?? "", maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(song.subTitle ?? "", overflow: TextOverflow.ellipsis, maxLines: 1),
        ),
        Container(height: 1, width: double.infinity, color: Colors.black12),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 0),
              shrinkWrap: true,
              controller: scrollController,
              itemCount: song.quality?.length ?? 0,
              itemBuilder: (BuildContext context, int index) {
                var item = song.quality?[index];
                return ListTile(
                  title: Text("${item?.title}"),
                  subtitle: Text("${item?.size}"),
                  onTap: () {
                    var download = MixDownload.fromSong(song, item);

                    ApiFactory.api(package: item?.package ?? "")?.download(download).then((download) {
                          print("获取到的下载链接");
                          print(download.url);
                          if (download.url?.isNotEmpty == true) {
                            controller.addTask(download);
                          } else {
                            if (song.match == true) {
                              download.url = song.matchSong?.url;
                              controller.addTask(download);
                              showInfo("已将匹配链接加入下载列表");
                            } else {
                              showInfo("无法获取链接");
                            }
                          }
                        }) ??
                        showInfo("尚未实现该功能");
                    onTap?.call();
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
