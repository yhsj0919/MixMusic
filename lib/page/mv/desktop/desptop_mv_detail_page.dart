import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:mix_music/common/api/api_factory.dart';
import 'package:mix_music/common/entity/mix_mv.dart';
import 'package:mix_music/common/entity/mix_quality.dart';

import '../../../player/music_controller.dart';
import '../../../widgets/message.dart';

class DesktopMvDetailPage extends StatefulWidget {
  const DesktopMvDetailPage({super.key, required this.item});

  final MixMv item;

  @override
  State<DesktopMvDetailPage> createState() => _DesktopMvDetailPageState();
}

class _DesktopMvDetailPageState extends State<DesktopMvDetailPage> {
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
    mv.value = widget.item;

    player.stream.position.listen((Duration p) {
      position = p;
    });

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
    return Container(
      color: Colors.black,
      child: Stack(
        // mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Obx(
              () => firstLoad.value
                  ? Center(child: ProgressRing())
                  : desktopTheme(
                      child: Video(controller: controller),
                      quality: quality.value,
                    ),
            ),
          ),

        ],
      ),
    );
  }

  Widget desktopTheme({
    required Widget child,
    required List<MixQuality> quality,
  }) {
    return MaterialDesktopVideoControlsTheme(
      normal: MaterialDesktopVideoControlsThemeData(
        buttonBarButtonSize: 24.0,
        buttonBarButtonColor: Colors.white,
        topButtonBar: [Container(
          padding: EdgeInsets.symmetric(horizontal: 0, vertical: 12),
          child: Row(
            children: [
              IconButton(
                icon: Icon(FluentIcons.back, color: Colors.white),
                onPressed: () {
                  context.pop();
                },
              ),
              Gap(8),
              Text(
                mv.value?.title ?? "",
                style: FluentTheme.of(
                  context,
                ).typography.bodyLarge?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),],
        bottomButtonBar: [
          MaterialDesktopSkipPreviousButton(),
          MaterialDesktopPlayOrPauseButton(),
          MaterialDesktopSkipNextButton(),
          MaterialDesktopVolumeButton(),
          MaterialDesktopPositionIndicator(),
          Spacer(),
          material.PopupMenuButton<MixQuality>(
            tooltip: "清晰度",
            padding: const EdgeInsets.all(0),
            // elevation: 2,
            // shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5))),
            itemBuilder: (BuildContext context) {
              return quality
                  .map(
                    (e) => material.PopupMenuItem(
                      value: e,
                      child: Text(e.title ?? "未知"),
                      onTap: () {
                        selectQuality.value = e;
                        _initializeVideoPlayer(e.url ?? "", position: position);
                      },
                    ),
                  )
                  .toList();
            },
            child: Obx(
              () => Text(
                selectQuality.value?.title ?? "清晰度",
                style: TextStyle(color: Colors.white),
              ),
            ),
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

          material.PopupMenuButton<MixQuality>(
            tooltip: "清晰度",
            padding: const EdgeInsets.all(0),
            // elevation: 2,
            // shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5))),
            itemBuilder: (BuildContext context) {
              return quality
                  .map(
                    (e) => material.PopupMenuItem(
                      value: e,
                      child: Text(e.title ?? "未知"),
                      onTap: () {
                        selectQuality.value = e;
                        _initializeVideoPlayer(e.url ?? "", position: position);
                      },
                    ),
                  )
                  .toList();
            },
            child: Obx(
              () => Text(
                selectQuality.value?.title ?? "清晰度",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          Gap(8),
          MaterialDesktopFullscreenButton(),
        ],
      ),
      child: child,
    );
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  ///获取专辑
  void getAlbumInfo() {
    ApiFactory.api(package: mv.value?.package ?? "")
        ?.mvInfo(mv: mv.value!)
        .then((value) {
          firstLoad.value = false;

          mv.value = value.data;
          quality.clear();
          quality.addAll(mv.value?.quality ?? []);
          if (quality.isNotEmpty) {
            var ss = quality.reduce(
              (a, b) => (a.quality ?? 0) > (b.quality ?? 0) ? a : b,
            );
            selectQuality.value = ss;

            _initializeVideoPlayer(ss.url ?? "");
          }

          // showComplete("操作成功");
        })
        .catchError((e) {
          firstLoad.value = false;
          print(e);

          showError(e);
        });
  }
}
