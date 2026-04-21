import 'dart:math';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:mix_music/common/entity/mix_quality.dart';
import 'package:mix_music/page/app_playing/desktop_playing.dart';
import 'package:mix_music/page/app_playlist/desktop_app_download_type_page.dart';
import 'package:mix_music/page/app_playlist/desktop_app_play_quality_page.dart';
import 'package:mix_music/page/app_playlist/desktop_app_playlist_page.dart';
import 'package:mix_music/page/mv/desktop/desptop_mv_detail_page.dart';
import 'package:mix_music/page/timer/DesktopTimerClosePage.dart';
import 'package:mix_music/player/Player.dart';
import 'package:mix_music/player/music_controller.dart';
import 'package:mix_music/route/routes.dart';
import 'package:mix_music/theme/theme_controller.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/fluent/FluentRoute.dart';
import 'package:mix_music/widgets/message.dart';
import 'package:mix_music/widgets/mix_quality_icon.dart';
import 'package:mix_music/widgets/mix_site_item.dart';

class DesktopPlayBar extends StatefulWidget {
  const DesktopPlayBar({super.key, this.showImage = true});

  final bool showImage;

  @override
  State<DesktopPlayBar> createState() => _DesktopPlayBarState();
}

class _DesktopPlayBarState extends State<DesktopPlayBar> {
  ThemeController theme = Get.put(ThemeController());
  MusicController music = Get.put(MusicController());
  FlyoutController volumeController = FlyoutController();
  FlyoutController clockController = FlyoutController();
  FlyoutController downloadController = FlyoutController();
  FlyoutController qualityController = FlyoutController();
  FlyoutController playListController = FlyoutController();
  RxnDouble position = RxnDouble(null);
  RxDouble volume = RxDouble(100);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context1) {
    return Obx(
      () => music.currentMusic.value == null
          ? Container()
          : Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Column(
                children: [
                  Obx(
                    () => Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          Text(formatTime(position.value ?? music.position.value.inMilliseconds.toDouble()), style: FluentTheme.of(context).typography.caption),
                          Expanded(
                            child: Container(
                              height: 4,
                              child: music.state.value == MixPlayState.loading || music.state.value == MixPlayState.buffering
                                  ? Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: ProgressBar(strokeWidth: 3))
                                  : Slider(
                                      style: SliderThemeData(trackHeight: WidgetStatePropertyAll(2)),
                                      value: position.value ?? music.position.value.inMilliseconds.toDouble(),
                                      max: max(music.duration.value.inMilliseconds.toDouble(), position.value ?? music.position.value.inMilliseconds.toDouble()),
                                      onChanged: (double value) {
                                        position.value = value;
                                      },
                                      onChangeStart: (v) {
                                        position.value = v;
                                      },
                                      onChangeEnd: (v) {
                                        position.value = null;
                                        music.seek(Duration(milliseconds: v.toInt()));
                                      },
                                    ),
                            ),
                          ),
                          Text(formatTime(music.duration.value.inMilliseconds.toDouble()), style: FluentTheme.of(context).typography.caption),
                        ],
                      ),
                    ),
                  ),
                  Expanded(child: Container()),
                  Obx(
                    () => Row(
                      children: [
                        Expanded(
                          child: IconButton(
                            icon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                widget.showImage
                                    ? Container(
                                        width: 70,
                                        height: 70,
                                        child: Stack(
                                          alignment: Alignment.bottomRight,
                                          children: [
                                            Hero(
                                              tag: "BarCover",
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(4),
                                                child: music.currentMusic.value == null
                                                    ? Container(color: Colors.black.withAlpha((0.1 * 255).toInt()), width: 70, height: 70)
                                                    : Obx(() => AppImage(url: music.currentMusic.value?.pic ?? "", width: 70, height: 70, radius: 4, fit: BoxFit.cover)),
                                              ),
                                            ),
                                            Obx(
                                              () => Hero(
                                                tag: "BarSite",
                                                child: MixSiteItem(mixSong: music.currentMusic.value, size: 15),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Container(height: 70),
                                Gap(16),
                                Expanded(
                                  child: Hero(
                                    tag: "BarTitle",
                                    child: Column(
                                      spacing: 8,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (music.currentMusic.value?.title ?? "").trim(),
                                          style: FluentTheme.of(context).typography.subtitle?.copyWith(fontWeight: FontWeight.w500),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(music.currentMusic.value?.artist?.map((e) => e.title ?? "").join("、") ?? "", maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            onPressed: () {
                              if (widget.showImage) {
                                Navigator.of(context, rootNavigator: true).push(FluentRoute(page: DesktopPlaying()));
                              } else {
                                Navigator.pop(context);
                              }
                            },
                          ),
                        ),

                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Obx(
                                () => IconButton(
                                  onPressed: () {
                                    if (music.playMode.value == PlayMode.RepeatAll) {
                                      music.playMode.value = PlayMode.RepeatOne;
                                    } else {
                                      music.playMode.value = PlayMode.RepeatAll;
                                    }
                                  },
                                  icon: Icon(music.playMode.value == PlayMode.RepeatAll ? FluentIcons.repeat_all : FluentIcons.repeat_one, size: 20),
                                ),
                              ),
                              Flexible(child: Container(width: 14)),
                              IconButton(
                                onPressed: () {
                                  music.previous();
                                },
                                icon: Icon(FluentIcons.previous, size: 25),
                              ),
                              Flexible(child: Container(width: 14)),
                              Obx(
                                () => IconButton(
                                  onPressed: music.state.value == MixPlayState.loading || music.state.value == MixPlayState.buffering
                                      ? null
                                      : () {
                                          music.playOrPause();
                                        },
                                  icon: Icon(music.isPlaying.value ? FluentIcons.pause : FluentIcons.play, size: 25),
                                ),
                              ),
                              Flexible(child: Container(width: 14)),
                              IconButton(
                                onPressed: () {
                                  music.next();
                                },
                                icon: Icon(FluentIcons.next, size: 25),
                              ),
                              Flexible(child: Container(width: 14)),
                              FlyoutTarget(
                                controller: qualityController,
                                child: IconButton(
                                  icon: Obx(() => MixQualityIcon(borderWidth: 1, size: 18, quality: music.currentMusic.value?.playQuality)),
                                  onPressed: () {
                                    if (music.currentMusic.value == null) {
                                      showInfo( "暂无可下载内容");
                                    } else {
                                      qualityController.showFlyout(
                                        autoModeConfiguration: FlyoutAutoConfiguration(preferredMode: FlyoutPlacementMode.topCenter),
                                        barrierDismissible: true,
                                        barrierColor: Colors.transparent,
                                        dismissOnPointerMoveAway: false,
                                        dismissWithEsc: true,
                                        navigatorKey: Routes.rootNavigatorKey.currentState,
                                        builder: (context) {
                                          return FlyoutContent(
                                            child: Container(
                                              width: 200,
                                              child: DesktopAppPlayQualityPage(
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
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            spacing: 8,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (music.currentMusic.value?.mv != null)
                                IconButton(
                                  icon: Icon(FluentIcons.my_movies_t_v, size: 20),
                                  onPressed: () {
                                    Navigator.of(
                                      context,
                                      rootNavigator: true,
                                    ).push(FluentPageRoute(builder: (context) => DesktopMvDetailPage(item: music.currentMusic.value!.mv!)));
                                  },
                                ),
                              FlyoutTarget(
                                controller: playListController,
                                child: IconButton(
                                  icon: Icon(FluentIcons.playlist_music, size: 20),
                                  onPressed: () {
                                    playListController.showFlyout(
                                      autoModeConfiguration: FlyoutAutoConfiguration(preferredMode: FlyoutPlacementMode.topCenter),
                                      barrierColor: Colors.transparent,
                                      transitionCurve: Curves.easeInOutCubic,
                                      dismissWithEsc: true,
                                      navigatorKey: Routes.rootNavigatorKey.currentState,
                                      builder: (context) {
                                        return FlyoutContent(
                                          child: Container(
                                            width: 350,
                                            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
                                            child: DesktopAppPlayListPage(
                                              onTap: () {
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                              FlyoutTarget(
                                controller: downloadController,
                                child: IconButton(
                                  icon: Icon(FluentIcons.download, size: 20),
                                  onPressed: () {
                                    if (music.currentMusic.value == null) {
                                       showInfo("暂无可下载内容");
                                    } else {
                                      downloadController.showFlyout(
                                        autoModeConfiguration: FlyoutAutoConfiguration(preferredMode: FlyoutPlacementMode.topCenter),
                                        barrierDismissible: true,
                                        barrierColor: Colors.transparent,
                                        dismissOnPointerMoveAway: false,
                                        dismissWithEsc: true,
                                        navigatorKey: Routes.rootNavigatorKey.currentState,
                                        builder: (context) {
                                          return FlyoutContent(
                                            child: Container(width: 200, child: DesktopAppDownloadTypePage(song: music.currentMusic.value!)),
                                          );
                                        },
                                      );
                                    }
                                  },
                                ),
                              ),
                              FlyoutTarget(
                                controller: clockController,
                                child: IconButton(
                                  icon: Icon(FluentIcons.clock, size: 20),
                                  onPressed: () {
                                    clockController.showFlyout(
                                      autoModeConfiguration: FlyoutAutoConfiguration(preferredMode: FlyoutPlacementMode.topCenter),
                                      barrierDismissible: true,
                                      barrierColor: Colors.transparent,
                                      dismissOnPointerMoveAway: false,
                                      dismissWithEsc: true,
                                      navigatorKey: Routes.rootNavigatorKey.currentState,
                                      builder: (context) {
                                        return FlyoutContent(child: Container(width: 350, child: DesktopTimerClosePage()));
                                      },
                                    );
                                  },
                                ),
                              ),

                              FlyoutTarget(
                                controller: volumeController,
                                child: IconButton(
                                  icon: Icon(
                                    volume.value > 66
                                        ? FluentIcons.volume3
                                        : volume.value > 33
                                        ? FluentIcons.volume2
                                        : volume.value > 0
                                        ? FluentIcons.volume1
                                        : FluentIcons.volume_disabled,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    volumeController.showFlyout(
                                      autoModeConfiguration: FlyoutAutoConfiguration(preferredMode: FlyoutPlacementMode.topCenter),
                                      barrierDismissible: true,
                                      barrierColor: Colors.transparent,
                                      dismissOnPointerMoveAway: false,
                                      dismissWithEsc: true,
                                      navigatorKey: Routes.rootNavigatorKey.currentState,
                                      builder: (context) {
                                        return FlyoutContent(
                                          child: Container(
                                            padding: EdgeInsets.only(left: 16, right: 10),
                                            height: 40,
                                            child: Obx(
                                              () => Row(
                                                spacing: 8,
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    volume.value > 66
                                                        ? FluentIcons.volume3
                                                        : volume.value > 33
                                                        ? FluentIcons.volume2
                                                        : volume.value > 0
                                                        ? FluentIcons.volume1
                                                        : FluentIcons.volume_disabled,
                                                  ),
                                                  Slider(
                                                    style: SliderThemeData(trackHeight: WidgetStatePropertyAll(2)),
                                                    value: volume.value,
                                                    onChanged: (v) {
                                                      volume.value = v;
                                                      Player.setVolume(v / 100);
                                                    },
                                                  ),
                                                  Container(
                                                    width: 26,
                                                    alignment: Alignment.center,
                                                    child: Text("${volume.value.toInt()}", style: FluentTheme.of(context).typography.caption),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                              IconButton(
                                icon: Icon(FluentIcons.more, size: 20),
                                onPressed: () {
                                   showInfo("暂未实现");
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String formatTime(double time) {
    var date = Duration(milliseconds: time.toInt());
    return '${(date.inMinutes % 60).toString().padLeft(2, '0')}:${(date.inSeconds % 60).toString().padLeft(2, '0')}';
  }
}
