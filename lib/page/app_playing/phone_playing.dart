import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lyric/lyrics_reader_widget.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/entity/mix_quality.dart';
import 'package:mix_music/entity/mix_song.dart';
import 'package:mix_music/page/app_playlist/app_download_type_page.dart';
import 'package:mix_music/page/app_playlist/app_play_quality_page.dart';
import 'package:mix_music/page/app_playlist/app_playlist_page.dart';
import 'package:mix_music/page/timer/TimerClosePage.dart';
import 'package:mix_music/player/Player.dart';
import 'package:mix_music/player/music_controller.dart';
import 'package:mix_music/route/routes.dart';
import 'package:mix_music/theme/app_theme.dart';
import 'package:mix_music/theme/new_surface_theme.dart';
import 'package:mix_music/theme/surface_color_enum.dart';
import 'package:mix_music/theme/theme_controller.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/ext.dart';
import 'package:mix_music/widgets/hyper/hyper_group.dart';
import 'package:mix_music/widgets/hyper/hyper_group_big_title.dart';
import 'package:mix_music/widgets/message.dart';
import 'package:mix_music/widgets/mix_quality_icon.dart';
import 'package:mix_music/widgets/mix_site_item.dart';

import '../../../player/ui_mix.dart';

class PhonePlaying extends StatefulWidget {
  PhonePlaying({super.key});

  @override
  State<PhonePlaying> createState() => _PhonePlayingState();
}

class _PhonePlayingState extends State<PhonePlaying> {
  ThemeController theme = Get.put(ThemeController());
  MusicController music = Get.put(MusicController());

  final RxBool _isVisible = RxBool(false);
  final RxBool _showLrc = RxBool(false);
  RxnDouble sliderValue = RxnDouble();
  RxBool showCover = RxBool(true);

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 100)).then((value) {
      _isVisible.value = true;
    });
    Future.delayed(const Duration(milliseconds: 300)).then((value) {
      _showLrc.value = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 获取状态栏的高度
    double statusBarHeight = max(MediaQuery.of(context).padding.top, 16);
    double bottom = max(MediaQuery.of(context).padding.bottom, 16);
    final double width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: context.isPhone && context.isLandscape
          ? null
          : AppBar(
              toolbarHeight: 64,
              actions: [
                Obx(() => Container(
                    height: kToolbarHeight,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: MixSiteItem(
                      mixSong: music.currentMusic.value,
                      size: 20,
                    )))
              ],
            ),
      body: Stack(
        children: [
          Obx(() => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, // 渐变的开始位置
                    end: Alignment.bottomCenter, // 渐变的结束位置
                    colors: [
                      Theme.of(context).colorScheme.surface,
                      NewSurfaceTheme.getSurfaceColorWithSeed(SurfaceColorEnum.surfaceContainer, theme.playingColor.value ?? Theme.of(context).colorScheme.primary, context),
                    ], // 渐变的颜色
                  ),
                ),
              )),
          SafeArea(
              child: context.isLandscape
                  ? context.isPhone
                      ? Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    height: kToolbarHeight,
                                    child: Row(
                                      children: [
                                        IconButton(
                                            onPressed: () {
                                              Get.back();
                                            },
                                            icon: Icon(Icons.arrow_back)),
                                        Expanded(child: Container()),
                                        Obx(() => Container(
                                            alignment: Alignment.centerLeft,
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                            child: MixSiteItem(
                                              mixSong: music.currentMusic.value,
                                              size: 20,
                                            )))
                                      ],
                                    ),
                                  ),
                                  Expanded(child: Container()),
                                  buildTitle(width),
                                  buildProgressBar(),
                                  Container(height: 4),
                                  buildButton(),
                                  Container(height: 4),
                                  buildAction(),
                                  Gap(16),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 6,
                              child: PageView(
                                onPageChanged: (index) {
                                  _showLrc.value = index == 1;
                                },
                                children: [
                                  buildImage(),
                                  Obx(
                                    () => AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 500),
                                      child: _showLrc.value ? Obx(() => buildLrc(context)) : Container(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(height: statusBarHeight),
                                  Expanded(child: buildImage()),
                                  buildTitle(width),
                                  buildProgressBar(),
                                  Container(height: 8),
                                  buildButton(),
                                  Container(height: 8),
                                  buildAction(),
                                  Gap(16),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 6,
                              child: Container(
                                padding: EdgeInsets.only(top: 80, bottom: 150),
                                child: Obx(() => buildLrc(context)),
                              ),
                            )
                          ],
                        )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Container(height: statusBarHeight),
                        Expanded(
                          child: PageView(
                            onPageChanged: (index) {
                              _showLrc.value = index == 1;
                            },
                            children: [
                              buildImage(),
                              Obx(
                                () => AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 500),
                                  child: _showLrc.value ? Obx(() => buildLrc(context)) : Container(),
                                ),
                              ),
                            ],
                          ),
                        ),

                        buildTitle(width),

                        buildProgressBar(),
                        Container(height: 8),
                        buildButton(),
                        Container(height: 8),
                        buildAction(),
                        Gap(12),
                      ],
                    )),
          // Obx(() => AnimatedOpacity(
          //       duration: const Duration(milliseconds: 500),
          //       opacity: _isVisible.value ? 1.0 : 0.0,
          //       child: Container(
          //         margin: EdgeInsets.only(top: statusBarHeight),
          //         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          //         child: IconButton.filledTonal(
          //             onPressed: () {
          //               Navigator.of(context).pop();
          //             },
          //             icon: const Icon(Icons.arrow_downward_rounded)),
          //       ),
          //     )),
        ],
      ),
    );
  }

  Widget buildImage() {
    return Obx(
      () => Container(
        width: 300,
        height: 300,
        alignment: Alignment.center,
        margin: EdgeInsets.all(32),
        child: Hero(
            tag: "BarCover",
            child: AppImage(
              radius: 12,
              width: 300,
              height: 300,
              url: music.currentMusic.value?.pic?.toString() ?? "",
            )),
      ),
    );
  }

  //标题
  Widget buildTitle(double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Obx(
            () => Text(
              music.currentMusic.value?.title ?? "N/A",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Obx(
            () => InkWell(
              onTap: music.currentMusic.value?.album == null
                  ? null
                  : () {
                      Get.offAndToNamed(Routes.albumDetail, arguments: music.currentMusic.value?.album);
                    },
              child: Text(
                music.currentMusic.value?.album?.title ?? "N/A",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.outline),
              ),
            ),
          ),
          Obx(
            () => Container(
              height: 20,
              child: ListView.separated(
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                itemCount: music.currentMusic.value?.artist?.length ?? 0,
                itemBuilder: (BuildContext context, int index) {
                  var item = music.currentMusic.value?.artist?[index];

                  return InkWell(
                    onTap: item == null
                        ? null
                        : () {
                            Get.offAndToNamed(Routes.artistDetail, arguments: item);
                          },
                    child: Text(
                      item?.title ?? "N/A",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.outline),
                    ),
                  );
                },
                separatorBuilder: (BuildContext context, int index) {
                  return Gap(8);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(
        () => ProgressBar(
          progress: music.position.value ?? const Duration(),
          // buffered: const Duration(milliseconds: 2000),
          total: music.duration.value ?? const Duration(),
          timeLabelLocation: TimeLabelLocation.below,
          timeLabelTextStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).brightness == Brightness.light ? Colors.black54 : Colors.white54),
          thumbColor: Colors.transparent,
          barHeight: 2,
          baseBarColor: Theme.of(context).brightness == Brightness.light ? Colors.black38 : Colors.white38,
          progressBarColor: Theme.of(context).colorScheme.onSurface,
          onDragStart: (value) {},
          onSeek: (duration) {
            music.seek(duration);
          },
        ),
      ),
    );
  }

  Widget buildButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Obx(() => IconButton(
              onPressed: () {
                if (music.playMode.value == PlayMode.RepeatAll) {
                  music.playMode.value = PlayMode.RepeatOne;
                } else {
                  music.playMode.value = PlayMode.RepeatAll;
                }
              },
              icon: Icon(music.playMode.value == PlayMode.RepeatAll ? Icons.repeat_rounded : Icons.repeat_one_rounded, size: 25))),
          Flexible(child: Container(width: 14)),
          IconButton(
              onPressed: () {
                music.previous();
              },
              icon: Icon(Icons.skip_previous_rounded, size: 35)),
          Flexible(child: Container(width: 14)),
          Obx(
            () => IconButton(
              onPressed: music.state.value == MixPlayState.loading || music.state.value == MixPlayState.buffering
                  ? null
                  : () {
                      music.playOrPause();
                    },
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: child,
                  );
                },
                child: music.state.value == MixPlayState.loading || music.state.value == MixPlayState.buffering
                    ? AnimatedContainer(
                        width: 55,
                        height: 55,
                        padding: const EdgeInsets.all(4),
                        duration: const Duration(milliseconds: 200),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.playingColor.value ?? Theme.of(context).colorScheme.primary,
                          backgroundColor: Theme.of(context).brightness == Brightness.light ? Colors.black12 : Colors.white12,
                        ),
                      )
                    : Icon(music.isPlaying.value ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 55),
              ),
            ),
          ),
          Flexible(child: Container(width: 14)),
          IconButton(
              onPressed: () {
                music.next();
              },
              icon: Icon(Icons.skip_next_rounded, size: 35)),
          Flexible(child: Container(width: 14)),
          IconButton(
              onPressed: () {
                showBottomPlayList(context);
              },
              icon: const Icon(
                Icons.playlist_play_rounded,
                size: 25,
              )),
          // IconButton(
          //     onPressed: () {
          //       music.next();
          //     },
          //     icon: Icon(Icons.skip_next_rounded, size: 25)),
          // Container(width: 8),
        ],
      ),
    );
  }

  Widget buildAction() {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                showBottomQuality(context);
              },
              icon: Obx(() => MixQualityIcon(
                    quality: music.currentMusic.value?.playQuality,
                  )),
            ),
            Expanded(child: Container()),
            IconButton(
                onPressed: () {
                  showBottomTimer(context);
                },
                icon: Icon(Icons.timer_outlined)),
            Expanded(child: Container()),
            IconButton(
                onPressed: () {
                  if (music.currentMusic.value == null) {
                    showInfo("暂无可下载内容");
                  } else {
                    showBottomDownload(context, music.currentMusic.value!);
                  }
                },
                icon: Icon(Icons.download_rounded)),
            Expanded(child: Container()),
            IconButton(
                onPressed: music.currentMusic.value?.mv == null
                    ? null
                    : () {
                        Get.toNamed(Routes.mvDetail, arguments: music.currentMusic.value?.mv);
                      },
                icon: const Icon(Icons.music_video)),
            Expanded(child: Container()),
            IconButton(onPressed: () {}, icon: Icon(Icons.more_vert_outlined)),
          ],
        ));
  }

  Widget buildLrc(BuildContext context) {
    return LyricsReader(
      padding: EdgeInsets.symmetric(horizontal: 16),
      position: music.position.value.inMilliseconds,
      lyricUi: UIMix(
        defaultSize: context.isPhone ? 22 : 24,
        otherMainSize: context.isPhone ? 18 : 20,
        defaultExtSize: context.isPhone ? 20 : 22,
        highlight: false,
        playingMainTextColor: Theme.of(context).colorScheme.onSurface,
        playingOtherMainTextColor: Theme.of(context).colorScheme.onSecondary,
      ),
      model: music.lyricModel.value,
      playing: true,
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
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: (theme.playingColor.value ?? Theme.of(context).colorScheme.primary).withOpacity(0.5),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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

  void showBottomTimer(BuildContext context) {
    showModalBottomSheet(
        context: context,
        showDragHandle: true,
        useSafeArea: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0), // 设置圆角的大小
        ),
        scrollControlDisabledMaxHeightRatio: 1 / 2,
        builder: (BuildContext context) {
          return TimerClosePage();
        }).then((value) {});
  }

  void showBottomPlayList(BuildContext context) {
    showModalBottomSheet(
        context: context,
        showDragHandle: true,
        useSafeArea: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0), // 设置圆角的大小
        ),
        // backgroundColor: Colors.transparent,
        scrollControlDisabledMaxHeightRatio: 3 / 4,
        builder: (BuildContext context) {
          return AppPlayListPage(
            onTap: () {
              Navigator.of(context).pop();
            },
          );
        }).then((value) {});
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

  void showBottomQuality(BuildContext context) {
    showModalBottomSheet(
        context: context,
        showDragHandle: true,
        useSafeArea: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0), // 设置圆角的大小
        ),
        scrollControlDisabledMaxHeightRatio: 1 / 2,
        builder: (BuildContext context) {
          return AppPlayQualityPage(
            onTap: (MixQuality quality) {
              print('${quality.quality}');

              var song = music.currentMusic.value;

              if (song != null) {
                if (song.playQuality == quality.quality) {
                  showInfo("正在播放${quality.title}");
                } else {
                  song.playQuality = quality.quality;

                  music.playWithQuality(music: song);
                }
              } else {
                showError("音乐信息不存在");
              }

              Navigator.of(context).pop();
            },
          );
        }).then((value) {});
  }
}
