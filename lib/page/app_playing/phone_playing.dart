import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lyric/lyrics_reader_widget.dart';
import 'package:get/get.dart';
import 'package:get/get_rx/get_rx.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:mix_music/page/app_playlist/app_playlist_page.dart';
import 'package:mix_music/player/music_controller.dart';
import 'package:mix_music/theme/new_surface_theme.dart';
import 'package:mix_music/theme/surface_color_enum.dart';
import 'package:mix_music/theme/theme_controller.dart';
import 'package:mix_music/widgets/ext.dart';

import 'package:squiggly_slider/slider.dart';

import '../../../player/ui_mix.dart';
import '../../../widgets/BlurRectWidget.dart';

class PhonePlaying extends StatefulWidget {
  PhonePlaying({super.key});

  @override
  State<PhonePlaying> createState() => _PhonePlayingState();
}

class _PhonePlayingState extends State<PhonePlaying> {
  ThemeController theme = Get.put(ThemeController());
  MusicController music = Get.put(MusicController());

  var _isVisible = false;
  RxnDouble sliderValue = RxnDouble();
  RxBool showCover = RxBool(true);

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 100)).then((value) {
      setState(() {
        _isVisible = true;
      });
    });
  }

  @override
  Widget build(BuildContext context1) {
    // 获取状态栏的高度
    double statusBarHeight = max(MediaQuery.of(context1).padding.top, 16);

    return Obx(
      () => AnimatedTheme(
        data: ThemeData(
          colorSchemeSeed: theme.playingColor.value ?? Theme.of(context).colorScheme.primary,
          brightness: Theme.of(context1).brightness,
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return Scaffold(
              backgroundColor: NewSurfaceTheme.getSurfaceColor(SurfaceColorEnum.surfaceContainer, context),
              body: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: statusBarHeight),
                      // SliverAppBar( centerTitle: true, title: Text("正在播放"), backgroundColor: Colors.transparent),
                      Obx(() => Hero(
                            tag: "BarCover",
                            child: AnimatedContainer(
                                margin: const EdgeInsets.symmetric(horizontal: 16),
                                width: double.infinity,
                                height: showCover.value ? 250 : 0,
                                duration: Duration(milliseconds: 200),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: CachedNetworkImage(
                                    imageUrl: music.currentMusic.value?.pic?.toString() ?? "",
                                    fit: BoxFit.cover,
                                    useOldImageOnUrlChange: true,
                                  ),
                                )),
                          )),
                      Expanded(child: Obx(() => buildLrc(context))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(music.currentMusic.value?.title ?? "N/A", style: Theme.of(context).textTheme.headlineSmall),
                            Text(music.currentMusic.value?.subTitle ?? "N/A",
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.outline)),
                          ],
                        ),
                      ),
                      Container(
                          height: 30,
                          child: Obx(() => SquigglySlider(
                                onChangeStart: (value) {
                                  sliderValue.value = value;
                                },
                                onChangeEnd: (value) {
                                  music.seek(Duration(milliseconds: value.toInt()));
                                  Future.delayed(const Duration(milliseconds: 100)).then((value) {
                                    sliderValue.value = null;
                                  });
                                },
                                squiggleAmplitude: 5.0,
                                squiggleWavelength: 6,
                                squiggleSpeed: 0.3,
                                max: music.duration.value?.inMilliseconds.toDouble() ?? 1,
                                value: sliderValue.value ?? music.position.value?.inMilliseconds.toDouble() ?? 0,
                                onChanged: (double value) {
                                  sliderValue.value = value;
                                },
                              ))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Obx(() => Text("${music.position.value?.inMilliseconds.date("mm:ss")}")),
                            Expanded(child: Container()),
                            Obx(() => Text("${music.duration.value?.inMilliseconds.date("mm:ss")}")),
                          ],
                        ),
                      ),
                      Container(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                                child: IconButton.filled(
                                    onPressed: () {
                                      music.playOrPause();
                                    },
                                    icon: SizedBox(
                                        height: 40,
                                        child: Obx(
                                          () => Icon(
                                            music.state.value == PlayerState.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                            size: 30,
                                          ),
                                        )))),
                            Container(width: 16),
                            IconButton.filledTonal(
                                onPressed: () {
                                  music.previous();
                                },
                                icon: Container(width: 40, height: 40, child: const Icon(Icons.skip_previous_rounded, size: 24))),
                            Container(width: 16),
                            IconButton.filledTonal(
                                onPressed: () {
                                  music.next();
                                },
                                icon: Container(width: 40, height: 40, child: const Icon(Icons.skip_next_rounded, size: 24))),
                            // Container(width: 8),
                          ],
                        ),
                      ),
                      Container(height: 16),
                      Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              IconButton(onPressed: () {}, icon: Icon(Icons.chat_rounded)),
                              Expanded(child: Container()),
                              IconButton(onPressed: () {}, icon: Icon(Icons.download_rounded)),
                              Expanded(child: Container()),
                              IconButton(
                                  onPressed: () {
                                    showBottomPlayList(context);
                                  },
                                  icon: Icon(Icons.playlist_play)),
                              Expanded(child: Container()),
                              IconButton(onPressed: () {}, icon: Icon(Icons.more_vert_rounded)),
                            ],
                          )),
                      Container(height: 16),
                    ],
                  ),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _isVisible ? 1.0 : 0.0,
                    child: Container(
                      margin: EdgeInsets.only(top: statusBarHeight),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: IconButton.filledTonal(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.arrow_downward_rounded)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildLrc(BuildContext context) {
    return LyricsReader(
      position: music.position.value?.inMilliseconds ?? 0,
      lyricUi:
          UIMix(highlight: false, playingMainTextColor: Theme.of(context).colorScheme.primary, playingOtherMainTextColor: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
      model: music.lyricModel.value,
      playing: music.state.value == PlayerState.playing,
      onTap: () {
        showCover.value = !showCover.value;
      },
      emptyBuilder: () => Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Text(music.lyric.value, style: Theme.of(context).textTheme.bodyMedium),
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
                  child: BlurRectWidget(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    child: Text(
                      progress.date("mm:ss"),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
                    ),
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
    );
  }

  void showBottomPlayList(BuildContext context) {
    showModalBottomSheet(
        context: context,
        elevation: 0,
        backgroundColor: Colors.transparent,
        scrollControlDisabledMaxHeightRatio: 3 / 4,
        builder: (BuildContext context) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  blurRadius: 12.0,
                  color: Theme.of(context).shadowColor.withOpacity(0.1),
                ),
              ],
            ),
            margin: const EdgeInsets.all(16),
            child: AppPlayListPage(),
          );
        }).then((value) {});
  }
}
