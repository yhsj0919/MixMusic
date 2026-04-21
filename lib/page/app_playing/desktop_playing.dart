import 'package:flutter/material.dart';
import 'package:flutter_lyric/flutter_lyric.dart';
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
      backgroundColor: Theme.brightnessOf(context) == Brightness.light ? Colors.white : Colors.black,
      body: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          Center(
            child: Stack(
              children: [
                LyricView(
                  controller: music.lyricController,
                  style: buildMixLyricStyle(
                    defaultSize: 24,
                    otherMainSize: 20,
                    defaultExtSize: 22,
                    highlight: false,
                    playingMainTextColor: Theme.brightnessOf(context) == Brightness.light ? Colors.black : Colors.white,
                    playingOtherMainTextColor: Theme.brightnessOf(context) == Brightness.light ? Colors.black38 : Colors.white54,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),

                ),
                LyricSelectionProgress(
                  controller: music.lyricController,
                  style: buildMixLyricStyle(
                    defaultSize: 24,
                    otherMainSize: 20,
                    defaultExtSize: 22,
                    highlight: true,
                    playingMainTextColor: Theme.brightnessOf(context) == Brightness.light ? Colors.black : Colors.white,
                    playingOtherMainTextColor: Theme.brightnessOf(context) == Brightness.light ? Colors.black38 : Colors.white54,

                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onPlay: (state) {
                    music.seek(state.duration);
                  },
                ),
              ],
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
