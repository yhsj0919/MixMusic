import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:mix_music/player/music_controller.dart';
import 'package:mix_music/theme/theme_controller.dart';
import 'package:mix_music/widgets/OpacityRoute.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/mix_site_item.dart';

import 'phone_playing.dart';

class PlayBar extends StatefulWidget {
  PlayBar({super.key});

  @override
  State<PlayBar> createState() => _PlayBarState();
}

class _PlayBarState extends State<PlayBar> {
  ThemeController theme = Get.put(ThemeController());
  MusicController music = Get.put(MusicController());

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context1) {
    return Obx(() => music.currentMusic.value == null
        ? Container()
        : AnimatedTheme(
            data: ThemeData(
              colorSchemeSeed: theme.playingColor.value ?? Theme.of(context).colorScheme.primary,
              brightness: Theme.of(context1).brightness,
            ),
            child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,

                  borderRadius: BorderRadius.circular(16.0), // 圆角半径
                  boxShadow: [
                    // 添加阴影
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.light ? Colors.black26 : Colors.white24,
                      blurRadius: 5.0,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
                              // if (music.currentMusic.value != null) {
                              Navigator.of(context).push(OpacityRoute(
                                builder: (BuildContext context) => PhonePlaying(),
                              ));
                              // }
                            },
                            child: Container(
                                width: 56,
                                height: 56,
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    Hero(
                                      tag: "BarCover",
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: music.currentMusic.value == null
                                            ? Container(
                                                color: Theme.of(context).shadowColor.withOpacity(0.1),
                                                width: 56,
                                                height: 56,
                                              )
                                            : Obx(() => AppImage(
                                                  url: music.currentMusic.value?.pic ?? "",
                                                  width: 56,
                                                  height: 56,
                                                  fit: BoxFit.cover,
                                                )),
                                      ),
                                    ),
                                    Obx(() => MixSiteItem(
                                          mixSong: music.currentMusic.value,
                                          size: 15,
                                        ))
                                  ],
                                ))),
                        const Gap(8),
                        Obx(
                          () => AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return ScaleTransition(
                                scale: animation,
                                child: child,
                              );
                            },
                            child: music.isBuffering.value
                                ? AnimatedContainer(
                                    width: 48,
                                    height: 48,
                                    padding: const EdgeInsets.all(8),
                                    duration: const Duration(milliseconds: 200),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      backgroundColor: Theme.of(context).brightness == Brightness.light ? Colors.black12 : Colors.white12,
                                    ),
                                  )
                                : Container(
                                    width: 48,
                                    height: 48,
                                    child: IconButton(
                                      onPressed: () {
                                        music.playOrPause();
                                      },
                                      icon: Icon(music.state.value == PlayerState.playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                                    ),
                                  ),
                          ),
                        ),
                        const Gap(8),
                      ],
                    ),
                  ],
                ),
              );
            })));
  }
}
