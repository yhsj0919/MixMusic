import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/entity/mix_mv.dart';
import 'package:mix_music/entity/mix_quality.dart';

import '../../player/music_controller.dart';
import '../../widgets/message.dart';

class MvDetailPage extends StatefulWidget {
  const MvDetailPage({super.key});

  @override
  State<MvDetailPage> createState() => _MvDetailPageState();
}

class _MvDetailPageState extends State<MvDetailPage> {
  MusicController music = Get.put(MusicController());
  Rxn<MixMv> mv = Rxn();

  RxBool firstLoad = RxBool(true);

  RxList<MixQuality> quality = RxList();

  Rxn<MixQuality> selectQuality = Rxn();

  // Create a [Player] to control playback.
  late final player = Player();

  // Create a [VideoController] to handle video output from [Player].
  late final controller = VideoController(player);

  bool completed = false;
  Duration? position;

  @override
  void initState() {
    super.initState();
    music.pause();
    mv.value = Get.arguments;

    player.stream.position.listen(
      (Duration p) {
        position = p;
      },
    );

    Future.delayed(const Duration(milliseconds: 300)).then((value) {
      getAlbumInfo();
    });
  }

  void _initializeVideoPlayer(String source, {Duration? position}) async {
    if (position != null && position.inSeconds > 2) {
      player.open(Media(source, start: position - Duration(seconds: 2)));
    } else {
      player.open(Media(source, start: position));
    }
  }

  @override
  Widget build(BuildContext context) {
    var video = SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.width * 9 / 16,
      // Use [Video] widget to display video output.
      child: Video(controller: controller),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(mv.value?.title ?? ""),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Flexible(
              child: Obx(() => firstLoad.value
                  ? Container(
                      color: Colors.black,
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.width * 9 / 16,
                      // Use [Video] widget to display video output.
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : GetPlatform.isDesktop
                      ? desktopTheme(child: video, quality: quality.value)
                      : phoneTheme(child: video, quality: quality.value))),
        ],
      ),
    );
  }

  Widget desktopTheme({required Widget child, required List<MixQuality> quality}) {
    return MaterialDesktopVideoControlsTheme(
        normal: MaterialDesktopVideoControlsThemeData(
          buttonBarButtonSize: 24.0,
          buttonBarButtonColor: Colors.white,
          bottomButtonBar: [
            MaterialDesktopSkipPreviousButton(),
            MaterialDesktopPlayOrPauseButton(),
            MaterialDesktopSkipNextButton(),
            MaterialDesktopVolumeButton(),
            MaterialDesktopPositionIndicator(),
            Spacer(),
            PopupMenuButton<MixQuality>(
              tooltip: "清晰度",
              padding: const EdgeInsets.all(0),
              // elevation: 2,
              // shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5))),
              itemBuilder: (BuildContext context) {
                return quality
                    .map((e) => PopupMenuItem(
                          value: e,
                          child: Text(e.title ?? "未知"),
                          onTap: () {
                            selectQuality.value = e;
                            _initializeVideoPlayer(e.url ?? "", position: position);
                          },
                        ))
                    .toList();
              },
              child: Obx(() => Text(selectQuality.value?.title ?? "清晰度", style: TextStyle(color: Colors.white))),
            ),
            Gap(8),
            MaterialDesktopFullscreenButton(),
          ],
        ),
        fullscreen: MaterialDesktopVideoControlsThemeData(
          bottomButtonBar: [
            MaterialDesktopSkipPreviousButton(),
            MaterialDesktopPlayOrPauseButton(),
            MaterialDesktopSkipNextButton(),
            MaterialDesktopVolumeButton(),
            MaterialDesktopPositionIndicator(),
            Spacer(),
            PopupMenuButton<MixQuality>(
              tooltip: "清晰度",
              padding: const EdgeInsets.all(0),
              // elevation: 2,
              // shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5))),
              itemBuilder: (BuildContext context) {
                return quality
                    .map((e) => PopupMenuItem(
                          value: e,
                          child: Text(e.title ?? "未知"),
                          onTap: () {
                            selectQuality.value = e;
                            _initializeVideoPlayer(e.url ?? "", position: position);
                          },
                        ))
                    .toList();
              },
              child: Obx(() => Text(selectQuality.value?.title ?? "清晰度", style: TextStyle(color: Colors.white))),
            ),
            Gap(8),
            MaterialDesktopFullscreenButton(),
          ],
        ),
        child: child);
  }

  Widget phoneTheme({required Widget child, required List<MixQuality> quality}) {
    return MaterialVideoControlsTheme(
        normal: MaterialVideoControlsThemeData(
          buttonBarButtonSize: 24.0,
          buttonBarButtonColor: Colors.white,
          bottomButtonBar: [
            MaterialPositionIndicator(),
            Spacer(),
            PopupMenuButton<MixQuality>(
              tooltip: "清晰度",
              padding: const EdgeInsets.all(0),
              // elevation: 2,
              // shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5))),
              itemBuilder: (BuildContext context) {
                return quality
                    .map((e) => PopupMenuItem(
                          value: e,
                          child: Text(e.title ?? "未知"),
                          onTap: () {
                            selectQuality.value = e;
                            _initializeVideoPlayer(e.url ?? "", position: position);
                          },
                        ))
                    .toList();
              },
              child: Obx(() => Text(selectQuality.value?.title ?? "清晰度", style: TextStyle(color: Colors.white))),
            ),
            Gap(8),
            MaterialDesktopFullscreenButton(),
          ],
        ),
        fullscreen: MaterialVideoControlsThemeData(
          bottomButtonBar: [
            MaterialPositionIndicator(),
            Spacer(),
            PopupMenuButton<MixQuality>(
              tooltip: "清晰度",
              padding: const EdgeInsets.all(0),
              // elevation: 2,
              // shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5))),
              itemBuilder: (BuildContext context) {
                return quality
                    .map((e) => PopupMenuItem(
                          value: e,
                          child: Text(e.title ?? "未知"),
                          onTap: () {
                            selectQuality.value = e;
                            _initializeVideoPlayer(e.url ?? "", position: position);
                          },
                        ))
                    .toList();
              },
              child: Obx(() => Text(selectQuality.value?.title ?? "清晰度", style: TextStyle(color: Colors.white))),
            ),
            Gap(8),
            MaterialDesktopFullscreenButton(),
          ],
        ),
        child: child);
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  ///获取专辑
  void getAlbumInfo() {
    ApiFactory.api(package: mv.value?.package ?? "")?.mvInfo(mv: mv.value!).then((value) {
      firstLoad.value = false;

      mv.value = value.data;
      quality.clear();
      quality.addAll(mv.value?.quality ?? []);
      if (quality.isNotEmpty) {
        var ss = quality.reduce((a, b) => (a.quality ?? 0) < (b.quality ?? 0) ? a : b);
        selectQuality.value = ss;

        _initializeVideoPlayer(ss.url ?? "");
      }

      // showComplete("操作成功");
    }).catchError((e) {
      firstLoad.value = false;
      print(e);

      showError(e);
    });
  }
}
