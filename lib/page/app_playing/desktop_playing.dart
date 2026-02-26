import 'package:flutter/material.dart';
import 'package:flutter_lyric/lyrics_reader_widget.dart';
import 'package:get/get.dart';
import 'package:mix_music/common/api/api_factory.dart';
import 'package:mix_music/page/app_playing/desktop_play_bar.dart';
import 'package:mix_music/player/music_controller.dart';
import 'package:mix_music/player/ui_mix.dart';
import 'package:mix_music/theme/theme_controller.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/ext.dart';
import 'package:mix_music/widgets/mix_site_item.dart';

class DesktopPlaying extends StatefulWidget {
  const DesktopPlaying({super.key});

  @override
  State<DesktopPlaying> createState() => _DesktopPlayingState();
}

class _DesktopPlayingState extends State<DesktopPlaying> {
  MusicController music = Get.put(MusicController());
  ThemeController theme = Get.put(ThemeController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      backgroundColor: Theme.brightnessOf(context)==Brightness.light?Colors.white:Colors.black,
      body: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          Center(
            child: Obx(
              () => LyricsReader(
                padding: EdgeInsets.symmetric(horizontal: 16),
                position: music.position.value.inMilliseconds,
                lyricUi: UIMix(
                  defaultSize: 24,
                  otherMainSize: 20,
                  defaultExtSize: 22,
                  highlight: false,
                  playingMainTextColor: Theme.brightnessOf(context)==Brightness.light?Colors.black:Colors.white,
                  playingOtherMainTextColor: Theme.brightnessOf(context)==Brightness.light?Colors.black38:Colors.white54,
                ),
                model: music.lyricModel.value,
                playing: true,
                emptyBuilder: () => Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text("暂无歌词", style: Theme.of(context).textTheme.bodyMedium),
                  ),
                ),
                selectLineBuilder: (progress, confirm) {
                  return SizedBox(
                    height: 30,
                    child: Stack(
                      children: [
                        Container(
                          alignment: Alignment.centerLeft,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          child: InkWell(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: (theme.playingColor.value ?? Theme.of(context).colorScheme.primary).withOpacity(0.5),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              child: Text(progress.date("mm:ss"), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onPrimary)),
                            ),
                            onTap: () {
                              confirm.call();
                              music.seek(Duration(milliseconds: progress));
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Obx(
            () => Container(
              width: 250,
              height: 250,
              alignment: Alignment.center,
              margin: EdgeInsets.all(18),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Hero(
                    tag: "BarCover",
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: music.currentMusic.value == null
                          ? Container(color: Colors.black.withAlpha((0.1 * 255).toInt()), width: 250, height: 250)
                          : Obx(() => AppImage(url: music.currentMusic.value?.pic ?? "", width: 250, height: 250, radius: 4, fit: BoxFit.cover)),
                    ),
                  ),
                  Obx(
                    () => Hero(
                      tag: "BarSite",
                      child: MixSiteItem(mixSong: music.currentMusic.value, size: 25),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Container(
          //   alignment: Alignment.bottomRight,
          //   child: Column(
          //     mainAxisSize: MainAxisSize.min,
          //     // mainAxisAlignment: MainAxisAlignment.end,
          //     // crossAxisAlignment: CrossAxisAlignment.end,
          //     children: [
          //       TextButton(
          //         child: Text("获取歌词"),
          //         onPressed: () {
          //           ApiFactory.api(package: music.currentMusic.value!.package)?.lrc(music.currentMusic.value!).then((v) {
          //             print(v.lrc);
          //           });
          //         },
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
      bottomNavigationBar: Container(height: 118, child: DesktopPlayBar(showImage: false)),
    );
  }
}
