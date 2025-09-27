import 'package:fluent_ui/fluent_ui.dart';
import 'package:get/get.dart';
import 'package:mix_music/common/api/api_factory.dart';
import 'package:mix_music/common/entity/mix_download.dart';
import 'package:mix_music/common/entity/mix_song.dart';
import 'package:mix_music/page/download/download_controller.dart';
import 'package:mix_music/widgets/message.dart';

class DesktopAppDownloadTypePage extends StatelessWidget {
  DesktopAppDownloadTypePage({super.key, required this.song, this.scrollController, this.onTap});

  final GestureTapCallback? onTap;

  final ScrollController? scrollController;
  final MixSong song;

  // MusicController music = Get.put(MusicController());
  final DownloadController controller = Get.put(DownloadController());

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Text("下载", style: FluentTheme.of(context).typography.bodyLarge),
        ),
        Container(height: 1, width: double.infinity, color: Colors.black.withAlpha((255 * 0.1).toInt())),

        ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 0),
          shrinkWrap: true,
          controller: scrollController,
          itemCount: song.quality?.length ?? 0,
          itemBuilder: (BuildContext context, int index) {
            var item = song.quality?[index];
            return ListTile(
              title: Text("${item?.title}"),
              subtitle: Text("${item?.size}"),
              onPressed: () {
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
      ],
    );
  }
}
