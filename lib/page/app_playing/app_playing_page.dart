import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:mix_music/page/app_main/app_controller.dart';
import 'package:mix_music/page/app_playlist/app_playlist_page.dart';
import 'package:mix_music/player/music_controller.dart';
import 'package:mix_music/player/ui_mix.dart';
import 'package:mix_music/route/routes.dart';
import 'package:mix_music/widgets/BlurRectWidget.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:flutter_lyric/lyrics_reader.dart';
import 'package:mix_music/widgets/ext.dart';

class AppPlayingPage extends StatefulWidget {
  AppPlayingPage({super.key});

  @override
  State<AppPlayingPage> createState() => _AppPlayingPageState();
}

class _AppPlayingPageState extends State<AppPlayingPage> {
  AppController app = Get.put(AppController());
  MusicController music = Get.put(MusicController());

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.width,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.all(Radius.circular(16 - (app.type.value == 0 ? 16 * app.position.value : 0))),
      ),
      margin: EdgeInsets.all(16 - (app.type.value == 0 ? 16 * app.position.value : 0)),
      child: Obx(
        () => Visibility(
          //这里解决播放条和播放页重叠导致的点击失效
          visible: app.position.value > 0,
          child: Stack(
            children: [
              Visibility(
                visible: app.position.value == 1,
                child: AppImage(
                  url: music.media.value?.artUri?.toString() ?? "",
                  width: context.width,
                  height: context.height,
                  animationDuration: 1000,
                ),
              ),
          Visibility(
            visible: app.position.value == 1,
            child:BlurRectWidget(
                sigmaX: 300,
                sigmaY: 60,
                color: Theme.of(context).brightness == Brightness.light ? Colors.white38 : Colors.black38,
              )),
              Scaffold(
                backgroundColor: Colors.transparent,
                endDrawerEnableOpenDragGesture: false,
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  leading: IconButton(
                    icon: Transform.rotate(
                      angle: 270 * (3.14 / 180), // 将角度转换为弧度
                      child: const Icon(Icons.arrow_back_ios_rounded), // 要旋转的控件
                    ),
                    onPressed: () {
                      app.panelController.close();
                    },
                  ),
                  actions: [Container()],
                  title: Obx(
                    () => Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(music.currentMusic.value?.title ?? "N/A", style: Theme.of(context).textTheme.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                            music.currentMusic.value?.album != null
                                ? TextButton(
                                    onPressed: () {
                                      if (music.currentMusic.value?.album != null) {
                                        app.panelController.close();
                                        Get.toNamed(Routes.albumDetail, id: Routes.key, arguments: music.currentMusic.value?.album);
                                      }
                                    },
                                    child: Text("${music.currentMusic.value?.album?.title}", maxLines: 1, overflow: TextOverflow.ellipsis))
                                : Container()
                          ],
                        ),
                        Text(music.currentMusic.value?.subTitle ?? "N/A", style: Theme.of(context).textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  centerTitle: true,
                ),
                onEndDrawerChanged: (ch) {
                  app.panelController.tempDisableSlide(ch);
                },
                endDrawer: Container(
                  margin: const EdgeInsets.all(16), // 调整Drawer的外边距
                  child: Drawer(
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16.0)),
                    ),
                    child: AppPlayListPage(inPanel: false),
                  ),
                ),
                body: SafeArea(
                  child: context.isLandscape ? buildTablet() : buildPhone(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTablet() {
    return Row(
      children: [
        Expanded(
            child: Column(
          children: [
            Expanded(child: Container()),
            Obx(
              () => AppImage(url: music.currentMusic.value?.pic?.toString() ?? "", width: 150, height: 150),
            ),
            Expanded(child: Container()),
            buildControllerButton(),
            Expanded(child: Container()),
          ],
        )),
        Expanded(child: app.position.value == 1?buildLrc():Container()),
      ],
    );
  }

  Widget buildPhone() {
    return Column(
      children: [
        Container(height: 40),
        Obx(
          () => AppImage(url: music.currentMusic.value?.pic?.toString() ?? "", width: 250, height: 250),
        ),
        Container(height: 16),
        Expanded(child: app.position.value == 1?buildLrc():Container()),
        buildControllerButton(),
        Container(height: 32),
      ],
    );
  }

  Widget buildControllerButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Obx(
            () => ProgressBar(
              progress: music.position.value ?? const Duration(),
              // buffered: const Duration(milliseconds: 2000),
              total: music.duration.value ?? const Duration(),
              timeLabelLocation: TimeLabelLocation.sides,
              timeLabelTextStyle: Theme.of(context).textTheme.bodyMedium,
              onDragStart: (value) {
                app.panelController.tempDisableSlide(true);
              },
              onSeek: (duration) {
                app.panelController.tempDisableSlide(false);
                music.seek(duration);
              },
            ),
          ),
        ),
        Container(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Obx(() => IconButton(
                  icon: Icon(music.playMode.value == PlayMode.RepeatOne ? Icons.repeat_one_rounded : Icons.repeat),
                  onPressed: () {
                    if (music.playMode.value == PlayMode.RepeatOne) {
                      music.playMode.value = PlayMode.RepeatAll;
                    } else if (music.playMode.value == PlayMode.RepeatAll) {
                      music.playMode.value = PlayMode.RepeatOne;
                    }
                  },
                )),
            // IconButton(
            //   icon: const Icon(Icons.repeat),
            //   onPressed: () {},
            // ),
            IconButton(
              icon: const Icon(Icons.skip_previous_rounded, size: 45),
              onPressed: () {
                music.previous();
              },
            ),
            playButton(context),
            IconButton(
              icon: const Icon(Icons.skip_next_rounded, size: 45),
              onPressed: () {
                music.next();
              },
            ),
            IconButton(
              icon: const Icon(Icons.queue_music_outlined),
              onPressed: () {
                if (!context.isPhone) {
                  Scaffold.of(context).openEndDrawer();
                } else {
                  showBottomPlayList(context);
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  ///播放按钮
  Widget playButton(BuildContext context) {
    return IconButton(
      onPressed: () {
        music.playOrPause();
      },
      icon: Stack(
        alignment: Alignment.center,
        children: [
          Container(
              padding: const EdgeInsets.all(2),
              child: Obx(
                () => Icon(
                  music.state.value == PlayerState.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 50,
                ),
              )),
          SizedBox(
              width: 50,
              height: 50,
              child: Obx(() => music.isBuffering.value
                  ? CircularProgressIndicator(
                      strokeWidth: 2,
                      backgroundColor: Theme.of(context).brightness == Brightness.light ? Colors.black12 : Colors.white12,
                    )
                  : CircularProgressIndicator(
                      value: (music.position.value?.inMilliseconds ?? 0) / (music.duration.value?.inMilliseconds ?? 1),
                      strokeWidth: 1,
                      backgroundColor: Theme.of(context).brightness == Brightness.light ? Colors.black12 : Colors.white12,
                    ))),
        ],
      ),
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
            child: AppPlayListPage(inPanel: false),
          );
        }).then((value) {
      app.panelController.tempDisableSlide(false);
    });
  }

  Widget buildLrc() {
    return LyricsReader(
      position: music.position.value?.inMilliseconds ?? 0,
      lyricUi: UIMix(
          highlight: false,
          playingMainTextColor: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black,
          playingOtherMainTextColor: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5) ?? Colors.black),
      model: music.lyricModel.value,
      playing: music.state.value == PlayerState.playing,
      size: Size(400, MediaQuery.of(context).size.height / 1.4),
      onTap: () {
        app.panelController.tempDisableSlide(true);
        // showLrc.value = false;
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
              Center(
                child: Container(
                  height: 2,
                  width: 300,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    gradient: LinearGradient(
                      colors: [Theme.of(context).iconTheme.color ?? Colors.black12, Colors.transparent, Theme.of(context).iconTheme.color ?? Colors.black12], // 渐变色
                      begin: Alignment.centerLeft, // 渐变开始位置
                      end: Alignment.centerRight, // 渐变结束位置
                    ),
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: InkWell(
                  child: BlurRectWidget(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    color: Theme.of(context).primaryColor.withOpacity(0.5),
                    child: Text(progress.date("mm:ss")),
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
}
