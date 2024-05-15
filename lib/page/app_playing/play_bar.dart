import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:mix_music/player/music_controller.dart';
import 'package:mix_music/theme/theme_controller.dart';
import 'package:mix_music/widgets/OpacityRoute.dart';

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

  Future<void> getColorScheme(String? image) async {
    if (image != null) {
      var ss = await ColorScheme.fromImageProvider(provider: CachedNetworkImageProvider(image));
      theme.playingColor.value = ss.primary;
    }
  }

  @override
  Widget build(BuildContext context1) {
    return Obx(() => AnimatedTheme(
        data: ThemeData(
          colorSchemeSeed: theme.playingColor.value ?? Theme.of(context).colorScheme.primary,
          brightness: Theme.of(context1).brightness,
        ),
        child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {
                          Navigator.of(context).push(OpacityRoute(
                            widget: PhonePlaying(),
                          ));
                        },
                        child: Hero(
                          tag: "BarCover",
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: music.currentMusic.value == null
                                ? Container(
                                    color: Theme.of(context).shadowColor.withOpacity(0.1),
                                    width: 56,
                                    height: 56,
                                  )
                                : CachedNetworkImage(
                                    imageUrl: music.currentMusic.value?.pic ?? "",
                                    useOldImageOnUrlChange: true,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        )),
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
